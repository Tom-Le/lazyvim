-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymaps.set("n", "<leader>fy", function()
  vim.cmd('let @+ = expand("%")')
  print(vim.fn.expand("%") .. " yanked to + register")
end, { desc = "Yank buffer's path to +" })
