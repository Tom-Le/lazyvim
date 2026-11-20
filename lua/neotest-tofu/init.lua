-- neotest adapter for OpenTofu tests (*.tftest.hcl, *.tofutest.hcl).
--
-- Each `run "name" {` block is a test. `tofu test` can only filter by file,
-- so running one test runs its whole file; the results for every run block in
-- that file are reported.
local lib = require("neotest.lib")
local nio = require("nio")
local Tree = require("neotest.types").Tree

local M = { name = "neotest-tofu" }

M.root = lib.files.match_root_pattern(".jj", ".git")

function M.filter_dir(name)
  return name ~= ".terraform" and name ~= ".git" and name ~= ".jj" and name ~= "node_modules"
end

function M.is_test_file(path)
  return path:match("%.tftest%.hcl$") ~= nil or path:match("%.tofutest%.hcl$") ~= nil
end

-- tofu fmt puts a top-level block's closing brace alone in column 0, so a run
-- block ends at the first line that is exactly "}".
function M.discover_positions(path)
  local lines = lib.files.read_lines(path)
  local file = { type = "file", id = path, path = path, name = vim.fs.basename(path), range = { 0, 0, #lines, 0 } }
  local tree = { file }
  local open
  for i, line in ipairs(lines) do
    local name = line:match('^run%s+"([^"]+)"%s*{')
    if name then
      open = { type = "test", id = path .. "::" .. name, path = path, name = name, range = { i - 1, 0, i - 1, #line } }
      table.insert(tree, { open })
    elseif open and line == "}" then
      open.range[3], open.range[4] = i - 1, 1
      open = nil
    end
  end
  return Tree.from_list(tree, function(pos)
    return pos.id
  end)
end

-- Test files live in the module directory or its tests/ directory.
local function module_dir(path)
  local dir = vim.fs.dirname(path)
  if vim.fs.basename(dir) == "tests" then
    return vim.fs.dirname(dir)
  end
  return dir
end

function M.build_spec(args)
  local pos = args.tree:data()
  if pos.type ~= "file" and pos.type ~= "test" then
    return nil -- neotest then runs each file under a directory on its own
  end
  local dir = module_dir(pos.path)
  local rel = pos.path:sub(#dir + 2)
  local json = nio.fn.tempname()
  -- Initialise without a backend on first use, like `just tf-init`.
  local script = [[
    if [ ! -d .terraform ]; then tofu init -backend=false -input=false -no-color || exit $?; fi
    exec tofu test -no-color -filter="$1" -json-into="$2"
  ]]
  return {
    command = vim.list_extend({ "sh", "-c", script, "sh", rel, json }, args.extra_args or {}),
    cwd = dir,
    context = { path = pos.path, rel = rel, json = json },
  }
end

local status_map = { pass = "passed", fail = "failed", error = "failed", skip = "skipped", pending = "skipped" }

function M.results(spec, result, tree)
  local ctx = spec.context
  local results = {}
  local file_errors = {}
  local ok, lines = pcall(lib.files.read_lines, ctx.json)
  for _, line in ipairs(ok and lines or {}) do
    local ok_decode, ev = pcall(vim.json.decode, line)
    if ok_decode and type(ev) == "table" and ev["@testfile"] == ctx.rel then
      local run = ev["@testrun"]
      local id = run and (ctx.path .. "::" .. run) or ctx.path
      if ev.type == "test_run" then
        results[id] = vim.tbl_extend("keep", results[id] or {}, { status = status_map[ev.test_run.status] or "failed" })
      elseif ev.type == "test_file" then
        results[id] = vim.tbl_extend("keep", results[id] or {}, { status = status_map[ev.test_file.status] or "failed" })
      elseif ev.type == "diagnostic" and ev.diagnostic.severity == "error" then
        local d = ev.diagnostic
        local err = {
          message = d.summary .. (d.detail and d.detail ~= "" and (": " .. d.detail) or ""),
          line = d.range and d.range.filename == ctx.rel and d.range.start.line - 1 or nil,
        }
        results[id] = results[id] or { status = "failed" }
        results[id].errors = results[id].errors or {}
        table.insert(results[id].errors, err)
        if not run then
          table.insert(file_errors, err)
        end
      end
    end
  end
  os.remove(ctx.json)

  -- No JSON (init failed, tofu missing, ...): fail everything that was run.
  local status = result.code == 0 and "passed" or "failed"
  for _, node in tree:iter_nodes() do
    local id = node:data().id
    results[id] = results[id] or { status = status, errors = file_errors }
    results[id].output = result.output
    if results[id].errors then
      results[id].short = table.concat(
        vim.tbl_map(function(e)
          return e.message
        end, results[id].errors),
        "\n"
      )
    end
  end
  return results
end

return M
