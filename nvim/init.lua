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
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y<CR>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>d', '"+d<CR>')

vim.g.python3_host_prog = vim.fn.expand("~/.venvs/nvim/bin/python")
vim.pack.add({
    { src = "https://github.com/nyoom-engineering/oxocarbon.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/echasnovski/mini.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/chomosuke/typst-preview.nvim" },
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})
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
        component_separators = { left = '', right = '' },
        section_separators   = { left = '', right = '' },
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

-- Closing brackets
require "mini.pick".setup()
require("mini.comment").setup()
require("mini.pairs").setup()
require "nvim-treesitter.configs".setup({
    ensure_installed = { "python", "cpp", "c" },
    highlight = { enable = true }
})
require "oil".setup()

vim.keymap.set('n', '<leader>f', ":Pick files<CR>")
vim.keymap.set('n', '<leader>h', ":Pick help<CR>")
vim.keymap.set('n', '<leader>e', ":Oil<CR>")
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.lsp.enable({ "lua_ls", "biome", "tinymist", "emmetls" })
vim.cmd("colorscheme oxocarbon")

local lspconfig = require("lspconfig")
lspconfig.lua_ls.setup({
    settings = { Lua = { format = { enable = true } } }
})
lspconfig.clangd.setup({
    cmd = { "/opt/homebrew/opt/llvm/bin/clangd" },
})

-- Python LSP
lspconfig.pyright.setup({})
-- Python formatting
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        vim.keymap.set("n", "<leader>lf", function()
            vim.cmd("%!black -q -")
        end, { buffer = true, desc = "Format with Black" })
    end,
})

-- R LSP (with diagnostics disabled)
lspconfig.r_language_server.setup({
	handlers = {
		["textDocument/publishDiagnostics"] = function() end,
	},
})
