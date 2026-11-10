-- Don't install tools with Mason: language servers, linters and formatters
-- come from PATH instead (Nix dev shells via direnv, or the user profile).
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Not covered by any enabled LazyVim extra; start them when on PATH.
        nixd = {},
        just = {}, -- just-lsp
      },
    },
  },
}
