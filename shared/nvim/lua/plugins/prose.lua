return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  {
    "lervag/vimtex",
    ft = { "tex" },
    config = function()
      -- macOS/Apple Silicon: zathura has no dbus, so the plain "zathura" backend
      -- can't drive SyncTeX. zathura_simple + synctex off is the vimtex-recommended
      -- setup; zathura still auto-reloads on recompile. Trade-off: no cursor<->PDF jump.
      vim.g.vimtex_view_method = "zathura_simple"
      vim.g.vimtex_view_zathura_use_synctex = 0
      vim.g.vimtex_compiler_method = "latexmk"
      -- Don't pop the quickfix window for warnings-only builds; still opens on errors.
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
  },
}
