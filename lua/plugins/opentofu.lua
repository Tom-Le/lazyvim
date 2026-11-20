-- The terraform extra uses HashiCorp's tools (terraform-ls, terraform fmt,
-- terraform validate). Use the OpenTofu equivalents from the dev shell instead.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = { enabled = false },
        tofu_ls = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        terraform = { "tofu_fmt" },
        tf = { "tofu_fmt" },
        ["terraform-vars"] = { "tofu_fmt" },
        -- Test files get the generic hcl filetype; leave other HCL to packer.
        hcl = function(bufnr)
          local name = vim.api.nvim_buf_get_name(bufnr)
          if name:match("%.tftest%.hcl$") or name:match("%.tofutest%.hcl$") then
            return { "tofu_fmt" }
          end
          return { "packer_fmt" }
        end,
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        terraform = { "tofu" },
        tf = { "tofu" },
      },
    },
  },
}
