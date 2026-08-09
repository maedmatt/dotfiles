return {
  { "mason-org/mason.nvim", lazy = false, config = true },
  { "mason-org/mason-lspconfig.nvim", lazy = false, dependencies = { "neovim/nvim-lspconfig" } },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    opts = {
      ensure_installed = { "basedpyright", "ruff", "texlab", "stylua", "shfmt" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lspconfig = require("lspconfig")

      require("mason-lspconfig").setup({
        handlers = {
          function(server_name)
            lspconfig[server_name].setup({})
          end,
          ["basedpyright"] = function()
            lspconfig.basedpyright.setup({
              settings = {
                basedpyright = { typeCheckingMode = "standard" },
              },
            })
          end,
          ["ruff"] = function()
            lspconfig.ruff.setup({})
          end,
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
          end

          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
          map("n", "gd", vim.lsp.buf.definition, "Definition")
          map("n", "gi", vim.lsp.buf.implementation, "Implementation")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("n", "[d", function() vim.diagnostic.goto_prev() vim.cmd("normal! zz") end, "Prev Diagnostic")
          map("n", "]d", function() vim.diagnostic.goto_next() vim.cmd("normal! zz") end, "Next Diagnostic")
        end,
      })

      -- virtual_text off: tiny-inline-diagnostic renders them instead
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
      })
    end,
  },
}
