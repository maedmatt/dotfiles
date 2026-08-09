-- nvim-treesitter main branch: parsers are installed with install(), and
-- highlighting must be started per buffer. `ensure_installed` in setup() is a
-- master-branch option and is silently ignored here.
--
-- latex is deliberately absent: vimtex owns tex syntax and the two fight over
-- conceal.
local languages = {
  "bash", "c", "cmake", "cpp", "css", "diff", "gitcommit", "html",
  "javascript", "json", "lua", "markdown", "markdown_inline", "python",
  "query", "regex", "toml", "typescript", "vim", "vimdoc", "xml", "yaml",
}

local function install_missing()
  local ts = require("nvim-treesitter")
  local installed = {}
  for _, lang in ipairs(ts.get_installed()) do
    installed[lang] = true
  end

  local missing = vim.tbl_filter(function(lang)
    return not installed[lang]
  end, languages)

  if #missing > 0 then
    ts.install(missing)
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = function()
      local ts = require("nvim-treesitter")
      ts.install(languages):wait(300000)
      ts.update(languages):wait(300000)
    end,
    config = function()
      require("nvim-treesitter").setup({})
      install_missing()

      -- main does not start highlighting on its own
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- af/if for a function, ac/ic for a class, ]f/[f to jump between functions
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local map = vim.keymap.set

      local objects = {
        f = "@function.outer",
        c = "@class.outer",
        a = "@parameter.outer",
      }
      for key, capture in pairs(objects) do
        map({ "x", "o" }, "a" .. key, function()
          select.select_textobject(capture, "textobjects")
        end, { desc = "around " .. key })
        map({ "x", "o" }, "i" .. key, function()
          select.select_textobject(capture:gsub("outer", "inner"), "textobjects")
        end, { desc = "inside " .. key })
      end

      map("n", "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
      map("n", "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function" })
      -- ]] and [[ rather than ]c and [c: gitsigns owns those for hunks
      map("n", "]]", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
      map("n", "[[", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class" })
    end,
  },

  -- Sticky header showing the enclosing function or class
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = { max_lines = 3, trim_scope = "inner" },
  },
}
