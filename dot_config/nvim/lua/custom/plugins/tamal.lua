-- Plugin: tamal.lua
-- Description: Interface for the tamal task management system with mnemonic keybindings

-- Tamal commands and their descriptions
local tamal_commands = {
  { cmd = 'add-task', desc = 'Add a new task', height = 1, key = 'a' },
  { cmd = 'tasks', desc = 'View tasks', height = 15, key = 't' },
  { cmd = 'weekly', desc = 'Open weekly note', height = 0, key = 'w', use_note_path = true, path_cmd = 'weekly-note-path' },
  { cmd = 'open', desc = 'Open a note', height = 1, param_name = 'NOTE_NAME', key = 'o', use_note_path = true, path_cmd = 'note-path' },
  { cmd = 'add-note', desc = 'Add a note', height = 3, key = 'n' },
  { cmd = 'three-p', desc = 'Add a 3P note', height = 3, param_name = 'SECTION', key = 'p' },
}

-- Function to open a file in a floating window
local function open_file_in_floating_window(file_path)
  -- Check if file exists
  if vim.fn.filereadable(file_path) == 0 then
    vim.notify('File not found: ' .. file_path, vim.log.levels.ERROR)
    return
  end

  -- Create a new buffer for the file content
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set up dimensions and position for the floating window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
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
    title = ' ' .. vim.fn.fnamemodify(file_path, ':t') .. ' ',
  }

  -- Set buffer options first
  vim.api.nvim_buf_set_option(buf, 'buftype', '') -- Regular file buffer
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown') -- Assuming notes are markdown

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Load the file content into the buffer - more reliable method
  vim.cmd('edit ' .. vim.fn.fnameescape(file_path))

  -- Set window options
  vim.api.nvim_win_set_option(win, 'winblend', 10)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'wrap', true) -- Enable line wrapping
  vim.api.nvim_win_set_option(win, 'linebreak', true) -- Wrap at word boundaries
  vim.api.nvim_win_set_option(win, 'number', false) -- Disable line numbers
  vim.api.nvim_win_set_option(win, 'textwidth', 120) -- Wrap at 120 characters

  -- Set buffer options for the window
  vim.api.nvim_win_call(win, function()
    vim.opt_local.laststatus = 0 -- Disable status line in this window
  end)

  -- Set keybindings for the window
  local keymap_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', ':q<CR>', keymap_opts)

  -- Enable render-markdown with a slight delay to ensure content is loaded
  vim.defer_fn(function()
    -- Ensure we're still in a valid state
    if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)) then
      return
    end

    -- Ensure treesitter is attached to the buffer
    pcall(function()
      vim.treesitter.start(buf, 'markdown')
    end)

    -- Enable render-markdown for this buffer if the plugin is available
    local ok, render_markdown = pcall(require, 'render-markdown')
    if ok then
      -- Focus the window to ensure we're operating on the right buffer
      vim.api.nvim_set_current_win(win)
      render_markdown.buf_enable()

      -- Force a refresh
      vim.cmd 'redraw'
    end
  end, 100) -- 100ms delay

  return { buf = buf, win = win }
end

-- Function to open a floating terminal and run a command
local function open_floating_terminal(cmd)
  -- Create a new buffer for the terminal
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set up dimensions and position for the floating window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
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

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Open terminal in the buffer and run the command
  vim.fn.termopen(cmd, {
    on_exit = function()
      -- Close the window when terminal command exits
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  -- Enter terminal mode automatically
  vim.cmd 'startinsert'

  return { buf = buf, win = win }
end

-- Function to create and display the popup window
local function open_tamal_popup(command_info)
  -- Fixed width but variable height based on command
  local width = 160
  local height = command_info.height

  -- Some commands don't need a popup
  if height == 0 then
    -- If this command should use note path
    if command_info.use_note_path then
      local path_cmd = command_info.path_cmd or command_info.cmd .. '-note-path'
      -- Get the path to the note file
      local file_path = vim.fn.system('tamal --' .. path_cmd):gsub('\n$', '')
      -- Open the file in a floating window
      open_file_in_floating_window(file_path)
    else
      -- Execute command directly
      vim.fn.system('tamal --' .. command_info.cmd)
      -- Reload the current buffer
      vim.cmd 'e!'
    end
    return
  end

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
    title = 'Tamal: ' .. command_info.desc,
  }

  -- Create buffer for the popup
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- If we're viewing tasks, populate with current tasks
  if command_info.cmd == 'tasks' then
    -- Get tasks and populate buffer
    local tasks_output = vim.fn.systemlist 'tamal --tasks'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, tasks_output)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false) -- Make read-only
  end

  -- Create the window with the buffer
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, 'winblend', 10)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Set keybindings for the popup
  local keymap_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', ':q<CR>', keymap_opts)

  -- If it's a read-only view (like tasks)
  if command_info.cmd == 'tasks' then
    return { buf = buf, win = win }
  end

  -- For commands that require input, set up Enter key binding
  vim.keymap.set({ 'n', 'i' }, '<CR>', function()
    -- Exit insert mode if we're in it
    if vim.fn.mode() == 'i' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
    end

    -- Get the content of the buffer
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')

    -- Construct the command
    local cmd = 'tamal --' .. command_info.cmd

    -- Add parameter name if specified
    if command_info.param_name then
      cmd = cmd .. ' ' .. content
    else
      cmd = cmd .. ' ' .. vim.fn.shellescape(content)
    end

    -- Close the input window
    vim.api.nvim_win_close(win, true)

    -- If this command should use note path
    if command_info.use_note_path then
      -- For the 'open' command, we need to get the path to the note file
      local path_cmd = 'tamal --note-path ' .. content
      local file_path = vim.fn.system(path_cmd):gsub('\n$', '')
      -- Open the file in a floating window
      open_file_in_floating_window(file_path)
    else
      -- Execute the command
      local output = vim.fn.system(cmd)
      -- Reload the current buffer
      vim.cmd 'e!'
    end
  end, keymap_opts)

  -- Start in insert mode for commands that need input
  vim.cmd 'startinsert'

  -- Return the buffer and window IDs for future reference
  return { buf = buf, win = win }
end

-- Create Vim commands for each Tamal function
for _, cmd_info in ipairs(tamal_commands) do
  -- Create command name from the cmd field (e.g., 'add-task' -> 'TamalAddTask')
  local command_name = 'Tamal' .. cmd_info.cmd:gsub('^%l', string.upper):gsub('%-(%l)', function(c)
    return c:upper()
  end)

  -- Register the command
  vim.api.nvim_create_user_command(command_name, function()
    open_tamal_popup(cmd_info)
  end, { desc = 'Tamal: ' .. cmd_info.desc })

  -- Create mnemonic keybinding with <leader>T prefix
  vim.keymap.set('n', '<leader>T' .. cmd_info.key, function()
    open_tamal_popup(cmd_info)
  end, { desc = 'Tamal: ' .. cmd_info.desc, silent = true })
end

return {}
