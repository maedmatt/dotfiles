return {
  {
    "echasnovski/mini.nvim",
    config = function()
      require("mini.ai").setup({ n_lines = 500 })
      require("mini.surround").setup()
      require("mini.pairs").setup()
      -- statusline is lualine, see plugins/ui.lua
    end,
  },

  -- Completion
  { "L3MON4D3/LuaSnip" },
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "*",
    opts = {
      snippets = { preset = "luasnip" },
      completion = { documentation = { auto_show = true } },
    },
  },

  -- Symbol outline, for long files and thesis sections
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline" },
    keys = { { "<leader>o", "<cmd>Outline<cr>", desc = "Toggle symbol outline" } },
    opts = {},
  },
}
