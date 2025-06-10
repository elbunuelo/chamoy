-- Plugin: tamal.lua
-- Description: Interface for the tamal task management system with mnemonic keybindings

-- Tamal commands and their descriptions
local tamal_commands = {
  { cmd = 'add-task', desc = 'Add a new task', height = 1, key = 'a' },
  { cmd = 'tasks', desc = 'View tasks', height = 15, key = 't' },
  { cmd = 'weekly', desc = 'Open weekly note', height = 0, key = 'w' },
  { cmd = 'open', desc = 'Open a note', height = 1, param_name = 'NOTE_NAME', key = 'o' },
  { cmd = 'add-note', desc = 'Add a note', height = 3, key = 'n' },
  { cmd = 'three-p', desc = 'Add a 3P note', height = 3, param_name = 'SECTION', key = 'p' },
}

-- Function to create and display the popup window
local function open_tamal_popup(command_info)
  -- Fixed width but variable height based on command
  local width = 160
  local height = command_info.height

  -- Some commands don't need a popup
  if height == 0 then
    -- Execute command directly
    vim.fn.system('tamal --' .. command_info.cmd)
    vim.notify('Executed: tamal --' .. command_info.cmd, vim.log.levels.INFO)
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

    -- Construct and execute the command
    local cmd = 'tamal --' .. command_info.cmd

    -- Add parameter name if specified
    if command_info.param_name then
      cmd = cmd .. ' ' .. content
    else
      cmd = cmd .. ' ' .. vim.fn.shellescape(content)
    end

    -- Execute the command
    local output = vim.fn.system(cmd)

    -- Close the window
    vim.api.nvim_win_close(win, true)

    -- Show notification with result
    vim.notify('Tamal: ' .. (output:gsub('^%s*(.-)%s*$', '%1') or 'Command executed'), vim.log.levels.INFO)
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
