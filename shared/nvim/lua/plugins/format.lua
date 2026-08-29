-- Formatting on save through conform, with the LSP as fallback.
-- :ConformDisable  turns it off globally, :ConformDisable! for this buffer only.
vim.api.nvim_create_user_command("ConformDisable", function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { desc = "Disable format on save", bang = true })

vim.api.nvim_create_user_command("ConformEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, { desc = "Re-enable format on save" })

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>lf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        desc = "Format",
      },
    },
    opts = {
      notify_on_error = false,
      default_format_opts = { timeout_ms = 1000, lsp_format = "fallback" },
      format_after_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end,
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        lua = { "stylua" },
        json = { "jq" },
        sh = { "shfmt" },
      },
    },
  },
}
