vim.api.nvim_create_user_command("ReloadClipboardProvider", function()
  if vim.g.loaded_clipboard_provider then
    vim.g.loaded_clipboard_provider = nil
    vim.cmd("runtime autoload/provider/clipboard.vim")
    print("Reloaded autoload/provider/clipboard.vim")
  end
end, { desc = "Reload autoload/provider/clipboard.vim" })
