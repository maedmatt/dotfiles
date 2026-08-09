return {
  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        integrations = {
          blink_cmp = true,
          fidget = true,
          fzf = true,
          gitsigns = true,
          mason = true,
          mini = { enabled = true },
          native_lsp = { enabled = true },
          nvimtree = true,
          render_markdown = true,
          snacks = { enabled = true, indent_scope_color = "mauve" },
          treesitter = true,
          treesitter_context = true,
          which_key = true,
        },
      })
      vim.cmd.colorscheme("catppuccin-macchiato")
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin-macchiato",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "█", right = "█" },
      },
      sections = {
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "filetype" },
      },
    },
  },

  -- Diagnostics rendered inline next to the offending line
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        preset = "powerline",
        options = {
          add_messages = { display_count = true, messages = true },
          multilines = { always_show = true, enabled = true },
        },
      })
      vim.diagnostic.config({ virtual_text = false })
    end,
  },

  -- LSP progress in the corner
  {
    "j-hui/fidget.nvim",
    event = "BufEnter",
    opts = {
      notification = { window = { winblend = 100 } },
      progress = { display = { progress_icon = { "dots_negative" } } },
    },
  },

  -- Pending keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { delay = 400 },
  },
}
