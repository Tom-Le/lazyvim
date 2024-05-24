return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, _)
        hl.LineNr = { fg = "#7482bc" }
        hl.LineNrAbove = { fg = "#7482bc" }
        hl.LineNrBelow = { fg = "#7482bc" }
      end,
    },
  },
}
