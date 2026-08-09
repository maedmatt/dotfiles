return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ff", function() require("fzf-lua").files() end, desc = "Find files" },
      { "<leader>fg", function() require("fzf-lua").live_grep() end, desc = "Live grep" },
      { "<leader>fb", function() require("fzf-lua").buffers() end, desc = "Buffers" },
      { "<leader>fh", function() require("fzf-lua").help_tags() end, desc = "Help tags" },
    },
    opts = {
      fzf_opts = {
        ["--layout"] = "default",
        ["--info"] = "inline-right",
      },
      files = { cwd_prompt = false, previewer = "bat" },
      grep = { previewer = "bat" },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" } },
    config = function()
      local api = require("nvim-tree.api")

      local function on_attach(bufnr)
        local function opts(desc)
          return { buffer = bufnr, desc = desc, noremap = true, silent = true, nowait = true }
        end
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
        vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close directory"))
      end

      require("nvim-tree").setup({
        on_attach = on_attach,
        sync_root_with_cwd = true,
        update_focused_file = { enable = true, update_root = false },
        view = { width = 35, side = "left", preserve_window_proportions = true },
        renderer = { highlight_opened_files = "all" },
        git = { enable = true },
        filesystem_watchers = { enable = true },
        actions = { open_file = { quit_on_open = false, resize_window = true } },
      })
    end,
  },
}
