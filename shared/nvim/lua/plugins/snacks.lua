-- folke/snacks.nvim, only the modules that earn their place:
--   notifier  popup notifications, also takes over vim.notify
--   toggle    option toggles that announce themselves
--   input     replaces the plain vim.ui.input prompt
--   bigfile   disables the expensive stuff on huge files (logs, csv dumps)
--   words     highlights other references to the symbol under the cursor
--   indent    indent guides
--   scratch   throwaway buffers
--   rename    keeps LSP in sync when a file is renamed
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000, style = "fancy" },
      rename = { enabled = true },
      scratch = { enabled = true },
      toggle = { enabled = true },
      words = { enabled = true },
    },
    keys = {
      {
        "<leader>uw",
        function() Snacks.toggle.option("wrap", { name = "Wrap" }):toggle() end,
        desc = "Toggle wrap",
      },
      {
        "<leader>ud",
        function() Snacks.toggle.diagnostics():toggle() end,
        desc = "Toggle diagnostics",
      },
      {
        "<leader>ul",
        function() Snacks.toggle.option("relativenumber", { name = "Relative Number" }):toggle() end,
        desc = "Toggle relative numbers",
      },
      {
        "<leader>uh",
        function() Snacks.toggle.inlay_hints():toggle() end,
        desc = "Toggle inlay hints",
      },
      {
        "<leader>nh",
        function() Snacks.notifier.show_history() end,
        desc = "Notification history",
      },
      {
        "<leader>.",
        function() Snacks.scratch() end,
        desc = "Toggle scratch buffer",
      },
    },
  },
}
