vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable built-ins
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Editor behavior
vim.opt.mouse = "a"
-- Use OSC 52 for SSH and Herdr panes; prefer the native provider locally.
-- Herdr's long-lived server may outlive the original SSH environment.
if vim.env.SSH_CONNECTION or vim.env.HERDR_ENV == "1" then
  vim.g.clipboard = "osc52"
end
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.updatetime = 100
vim.opt.confirm = true
vim.opt.autoread = true

-- UI
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes:1"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showmode = false
vim.opt.showcmd = false
vim.opt.ruler = true
vim.opt.pumheight = 10
vim.opt.fillchars = { eob = " " }
vim.opt.cmdheight = 1

-- Block cursor in normal mode, thin bar in insert
vim.opt.guicursor = {
  "n-v-c:block",
  "i-ci-ve:ver25",
  "r-cr:hor20",
  "o:hor50",
  "a:blinkwait700-blinkoff400-blinkon250",
  "sm:block-blinkwait175-blinkoff150-blinkon175",
}

-- Search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Files
vim.opt.fileencoding = "utf-8"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Completion
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Filetype detection
vim.filetype.add({
  extension = { env = "dotenv" },
  filename = {
    [".env"] = "dotenv",
    [".envrc"] = "sh",
  },
})

-- ============================================================================
-- Plugins (specs live in lua/plugins/)
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "plugins" } }, {
  install = { missing = true, colorscheme = { "catppuccin-macchiato" } },
  checker = { enabled = true, notify = false },
  change_detection = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- ============================================================================
-- Keymaps
-- ============================================================================
local map = vim.keymap.set

-- Basic movement
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Windows
map("n", "<leader>w", "<C-w>", { remap = true })
map("n", "<leader>d", "<C-w>c", { desc = "Close window" })
map("n", "<leader>s", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>v", "<C-w>v", { desc = "Split vertical" })

-- Buffers
map("n", "<Tab>", ":bnext<CR>", { silent = true })
map("n", "<S-Tab>", ":bprev<CR>", { silent = true })

-- Search
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Yank file paths (shell-quote when path has spaces)
local function yank_path(p)
  if p:find(" ") then p = vim.fn.shellescape(p) end
  vim.fn.setreg("+", p)
  vim.notify("Copied: " .. p)
end
map("n", "<leader>yp", function() yank_path(vim.fn.expand("%:p")) end, { desc = "Yank absolute path" })
map("n", "<leader>yr", function() yank_path(vim.fn.fnamemodify(vim.fn.expand("%"), ":.")) end, { desc = "Yank relative path" })
map("n", "<leader>yn", function() yank_path(vim.fn.expand("%:t")) end, { desc = "Yank filename" })

-- Run the nearest Python or CMake project's tests in a terminal.
require("test_runner").setup()

-- Edit
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map("i", "jj", "<Esc>")

-- Git
map("n", "<leader>gg", function()
  vim.cmd("terminal lazygit")
  vim.cmd("startinsert")
end, { desc = "Lazygit" })

-- ============================================================================
-- Autocommands
-- ============================================================================
local api = vim.api

-- Highlight on yank
api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Return to last position
api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= api.nvim_buf_line_count(0) then
      pcall(api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Disable auto-comment
api.nvim_create_autocmd("BufEnter", {
  command = "set formatoptions-=cro",
})

-- Close with q
api.nvim_create_autocmd("FileType", {
  pattern = { "help", "lspinfo", "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Help opens as a vertical split rather than a squashed horizontal one
api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("vertical_help", { clear = true }),
  pattern = "help",
  callback = function()
    vim.bo.bufhidden = "unload"
    vim.cmd.wincmd("L")
    vim.cmd.wincmd("=")
  end,
})

-- Auto-close terminal on successful exit
api.nvim_create_autocmd("TermClose", {
  callback = function()
    if vim.v.event.status == 0 then
      vim.cmd("bdelete!")
    end
  end,
})

-- Spell check for prose
api.nvim_create_autocmd("FileType", {
  pattern = { "tex", "markdown", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us,it,fr"
  end,
})
