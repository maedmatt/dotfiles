local M = {}

local markers = {
  { name = "pyproject.toml", kind = "python" },
  { name = "CMakeLists.txt", kind = "cmake" },
}

local function marker_at(dir, preferred_kind)
  if preferred_kind then
    for _, marker in ipairs(markers) do
      if marker.kind == preferred_kind and vim.uv.fs_stat(vim.fs.joinpath(dir, marker.name)) then
        return marker
      end
    end
  end

  for _, marker in ipairs(markers) do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, marker.name)) then
      return marker
    end
  end
end

local function find_from(start, preferred_kind)
  local dir = vim.fs.normalize(start)
  while dir do
    local marker = marker_at(dir, preferred_kind)
    if marker then
      return { root = dir, kind = marker.kind, marker = marker.name }
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
end

function M.find_project(bufnr)
  bufnr = bufnr or 0
  local filetype = vim.bo[bufnr].filetype
  local preferred_kind = filetype == "python" and "python"
    or ({ c = true, cpp = true, objc = true, objcpp = true, cuda = true })[filetype] and "cmake"
    or nil
  local cwd = vim.fn.getcwd()
  local name = vim.api.nvim_buf_get_name(bufnr)

  if name ~= "" then
    local project = find_from(vim.fs.dirname(name), preferred_kind)
    if project then
      return project
    end
  end

  return find_from(cwd, preferred_kind)
end

local commands = {
  python = "uv run pytest",
  cmake = table.concat({
    "cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
    "cmake -E copy_if_different build/compile_commands.json compile_commands.json",
    "cmake --build build",
    "ctest --test-dir build --output-on-failure",
  }, " && "),
}

function M.run()
  local project = M.find_project(0)
  if not project then
    vim.notify("No pyproject.toml or CMakeLists.txt found above the buffer or working directory", vim.log.levels.ERROR)
    return
  end

  vim.cmd("botright new")
  local job = vim.fn.jobstart({ "sh", "-c", commands[project.kind] }, {
    cwd = project.root,
    term = true,
  })
  if job <= 0 then
    vim.cmd("bdelete!")
    vim.notify("Could not start test command", vim.log.levels.ERROR)
    return
  end
  vim.cmd("startinsert")
end

function M.setup()
  vim.api.nvim_create_user_command("RunTests", M.run, {
    desc = "Run tests for the nearest Python or CMake project",
  })
  vim.keymap.set("n", "<leader>tt", "<cmd>RunTests<cr>", {
    desc = "Run project tests",
    silent = true,
  })
end

return M
