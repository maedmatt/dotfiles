vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.termguicolors = true
vim.o.wrap = true
vim.o.tabstop = 4
vim.o.swapfile = false
vim.g.mapleader = " "
vim.o.winborder = "rounded"
vim.o.clipboard = "unnamedplus"

vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>d', '"+d')

vim.g.python3_host_prog = vim.fn.expand("~/.venvs/nvim/bin/python")

-- Plugins
vim.pack.add({
    "https://github.com/nyoom-engineering/oxocarbon.nvim",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/echasnovski/mini.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/chomosuke/typst-preview.nvim",
    "https://github.com/nvim-lualine/lualine.nvim",
    "https://github.com/nvim-tree/nvim-web-devicons",
    "https://github.com/ojroques/nvim-osc52",
})

-- LSP auto-completion
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
    end,
})
vim.cmd("set completeopt+=noselect")

-- Status line
require('lualine').setup {
    options = {
        icons_enabled        = false,
        theme                = 'auto',
        component_separators = { left = '', right = '' },
        section_separators   = { left = '', right = '' },
        globalstatus         = false,
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype', 'location' },
        lualine_y = {},
        lualine_z = {},
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {},
    },
}

-- Mini plugins
require("mini.pick").setup()
require("mini.comment").setup()
require("mini.pairs").setup()

-- Treesitter
require("nvim-treesitter.configs").setup({
    ensure_installed = { "python", "cpp", "c", "lua" },
    highlight = { enable = true }
})

-- Oil file explorer
require("oil").setup()

-- Keymaps
vim.keymap.set('n', '<leader>f', ":Pick files<CR>")
vim.keymap.set('n', '<leader>h', ":Pick help<CR>")
vim.keymap.set('n', '<leader>e', ":Oil<CR>")
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)

-- Colorscheme
vim.cmd("colorscheme oxocarbon")

-- LSP Configuration (New Neovim 0.11+ API)
vim.lsp.config.lua_ls = {
    cmd = { 'lua-language-server' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
    settings = { Lua = { format = { enable = true } } }
}

vim.lsp.config.clangd = {
    cmd = { 'clangd' },
    root_markers = { '.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', 'configure.ac', '.git' },
}

vim.lsp.config.pyright = {
    cmd = { 'pyright-langserver', '--stdio' },
    root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
}

vim.lsp.config.ruff = {
    cmd = { 'ruff-lsp' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
}

vim.lsp.config.r_language_server = {
    cmd = { 'R', '--slave', '-e', 'languageserver::run()' },
    root_markers = { '.git' },
    handlers = {
        ["textDocument/publishDiagnostics"] = function() end,
    },
}

-- Enable LSP servers
vim.lsp.enable({ 'lua_ls', 'clangd', 'pyright', 'ruff' })

-- Python formatting with Ruff
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        vim.keymap.set("n", "<leader>lf", function()
            vim.lsp.buf.format({ async = false })
        end, { buffer = true, desc = "Format with Ruff" })
    end,
})
