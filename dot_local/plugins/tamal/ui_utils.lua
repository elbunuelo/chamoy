-- ui_utils.lua: UI-related utility functions for the tamal plugin

local M = {}

-- Helper function to calculate window dimensions and position
M.calculate_window_dimensions = function(width_percent, height_percent)
  local width = math.floor(vim.o.columns * width_percent)
  local height = math.floor(vim.o.lines * height_percent)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  return { width = width, height = height, col = col, row = row }
end

-- Helper function to get window position from config (handles different Neovim API versions)
M.get_win_position = function(win_config)
  local col, row, width
  if type(win_config.col) == "number" then
    -- Newer Neovim versions
    col = win_config.col
    row = win_config.row
    width = win_config.width
  else
    -- Older Neovim versions with indexable values
    col = win_config.col[false]
    row = win_config.row[false]
    width = win_config.width
  end
  return { col = col, row = row, width = width }
end

-- Helper function to set common window options
M.set_common_win_options = function(win)
  vim.api.nvim_win_set_option(win, "winblend", 0)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "wrap", true) -- Enable line wrapping
  vim.api.nvim_win_set_option(win, "linebreak", true) -- Wrap at word boundaries
  vim.api.nvim_win_set_option(win, "number", false) -- Disable line numbers
  vim.api.nvim_win_set_option(win, "textwidth", 80)

  vim.api.nvim_win_call(win, function()
    vim.opt_local.laststatus = 0 -- Disable status line in this window
  end)
end

-- Helper function to get visually selected text
M.get_visual_selection = function()
  local _, start_line, start_col, _ = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))

  -- Handle case where visual mode hasn't been used yet
  if start_line == 0 then
    return ""
  end

  local lines = vim.fn.getline(start_line, end_line)

  -- Adjust columns for the first and last lines
  if #lines == 0 then
    return ""
  end

  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end

  return table.concat(lines, "\n")
end

return M
