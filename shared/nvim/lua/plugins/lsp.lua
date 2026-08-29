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
      -- Mason installs the managed servers, but activation stays explicit so
      -- system servers such as clangd follow the same predictable path.
      require("mason-lspconfig").setup({
        automatic_enable = false,
      })

      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
            },
          },
        },
      })

      -- clangd comes from Xcode/Homebrew rather than Mason. Including
      -- CMakeLists.txt lets each classroom exercise form its own LSP root.
      vim.lsp.config("clangd", {
        root_markers = {
          ".clangd",
          ".clang-tidy",
          ".clang-format",
          "compile_commands.json",
          "compile_flags.txt",
          "CMakeLists.txt",
          ".git",
        },
      })

      vim.lsp.enable({ "basedpyright", "ruff", "texlab", "clangd" })

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
