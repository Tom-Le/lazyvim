-- Run bats tests (and any other runner vim-test supports) and OpenTofu tests
-- through neotest.
return {
  {
    "nvim-neotest/neotest",
    dependencies = { "vim-test/vim-test", "nvim-neotest/neotest-vim-test" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      -- The Rust extra's adapter loads rustaceanvim, which errors when
      -- rust-analyzer is missing. Only use it where a dev shell provides it.
      if vim.fn.executable("rust-analyzer") == 0 then
        opts.adapters["rustaceanvim.neotest"] = false
      end

      local adapter = require("neotest-vim-test")({ ignore_file_types = { "rust" } })
      adapter.root = require("neotest.lib").files.match_root_pattern(".jj", ".git")
      -- neotest asks adapters through a child Neovim started with -u NONE,
      -- whose runtimepath lacks vim-test. Use the adapter's in-process versions.
      adapter.is_test_file = adapter._is_test_file
      adapter.discover_positions = adapter._discover_positions
      adapter.build_spec = adapter._build_spec
      table.insert(opts.adapters, adapter)

      -- OpenTofu tests (*.tftest.hcl); vim-test has no runner for them.
      table.insert(opts.adapters, require("neotest-tofu"))
    end,
  },
}
