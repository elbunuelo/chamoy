-- Plugin: tamal.lua
-- Description: Creates a popup window for task management

-- Function to create and display the popup window
local function open_tamal_popup()
  -- Calculate window size (based on percentage of editor size)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.7)

  -- Calculate starting position to center the window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- Window options
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
  }

  -- Create buffer for the popup
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- Create the window with the buffer
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, 'winblend', 10)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Add a title to the popup
  local title = 'Tamal'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    title,
    string.rep('-', #title),
    '',
    'Press <Esc> to close this window',
  })

  -- Set keybindings for the popup
  local keymap_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', ':q<CR>', keymap_opts)

  -- Return the buffer and window IDs for future reference
  return { buf = buf, win = win }
end

-- Create a Neovim command to open the popup
vim.api.nvim_create_user_command('Tamal', function()
  open_tamal_popup()
end, { desc = 'Open Tamal' })

-- Add normal mode keybinding using <leader>t
vim.keymap.set('n', '<leader>T', ':Tamal<CR>', { desc = 'Open Tamal', silent = true })

return {}
