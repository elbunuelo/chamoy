-- Plugin: tamal.lua
-- Description: Interface for the tamal task management system with mnemonic keybindings

-- Global table to track related windows (notes and their section selectors)
local tamal_window_pairs = {}

-- Function to close all windows in a pair
local function close_window_pair(id)
  local pair = tamal_window_pairs[id]
  if not pair then
    return
  end

  -- Close note window if valid
  if pair.note_win and vim.api.nvim_win_is_valid(pair.note_win) then
    pcall(vim.api.nvim_win_close, pair.note_win, true)
  end

  -- Close section window if valid
  if pair.section_win and vim.api.nvim_win_is_valid(pair.section_win) then
    pcall(vim.api.nvim_win_close, pair.section_win, true)
  end

  -- Close time block window if valid
  if pair.time_block_win and vim.api.nvim_win_is_valid(pair.time_block_win) then
    pcall(vim.api.nvim_win_close, pair.time_block_win, true)
  end

  -- Remove from tracking table
  tamal_window_pairs[id] = nil
end

-- Tamal commands and their descriptions
local tamal_commands = {
  { cmd = 'add-task', desc = 'Add a new task', height = 1, key = 'a' },
  { cmd = 'tasks', desc = 'View tasks', height = 15, key = 't' },
  { cmd = 'weekly', desc = 'Open weekly note', height = 0, key = 'w', use_note_path = true, path_cmd = 'weekly-note-path' },
  { cmd = 'open', desc = 'Open a note', height = 0, key = 'o', use_telescope = true },
  { cmd = 'add-note', desc = 'Add a note', height = 3, key = 'n' },
  { cmd = 'three-p', desc = 'Add a 3P note', height = 3, key = 'p' },
}

-- Helper function to calculate window dimensions and position
local function calculate_window_dimensions(width_percent, height_percent)
  local width = math.floor(vim.o.columns * width_percent)
  local height = math.floor(vim.o.lines * height_percent)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  return { width = width, height = height, col = col, row = row }
end

-- Helper function to get window position from config (handles different Neovim API versions)
local function get_win_position(win_config)
  local col, row, width
  if type(win_config.col) == 'number' then
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
local function set_common_win_options(win)
  vim.api.nvim_win_set_option(win, 'winblend', 10)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'wrap', true) -- Enable line wrapping
  vim.api.nvim_win_set_option(win, 'linebreak', true) -- Wrap at word boundaries
  vim.api.nvim_win_set_option(win, 'number', false) -- Disable line numbers
  vim.api.nvim_win_set_option(win, 'textwidth', 120) -- Wrap at 120 characters

  vim.api.nvim_win_call(win, function()
    vim.opt_local.laststatus = 0 -- Disable status line in this window
  end)
end

-- Helper function to create navigation between windows
local function setup_window_navigation(note_win, note_buf, selector_win, selector_buf)
  -- CTRL+K: Move to selector
  vim.keymap.set({ 'n', 'i' }, '<C-k>', function()
    if vim.api.nvim_win_is_valid(selector_win) then
      -- If in insert mode, switch to normal mode first
      if vim.fn.mode() == 'i' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
      end
      vim.api.nvim_set_current_win(selector_win)
    end
  end, { noremap = true, silent = true, buffer = note_buf })

  -- CTRL+J: Move to note window
  vim.keymap.set('n', '<C-j>', function()
    if vim.api.nvim_win_is_valid(note_win) then
      vim.api.nvim_set_current_win(note_win)
      -- Return to insert mode in the note window
      vim.cmd 'startinsert'
    end
  end, { noremap = true, silent = true, buffer = selector_buf })

  -- Set up 'q' key to close windows
  local window_id = tostring(note_win)
  vim.keymap.set('n', 'q', function()
    close_window_pair(window_id)
  end, { noremap = true, silent = true, buffer = selector_buf })
  vim.keymap.set('n', 'q', function()
    close_window_pair(window_id)
  end, { noremap = true, silent = true, buffer = note_buf })

  return window_id
end

-- Helper function to setup window autocmds for closing
local function setup_window_autocmds(selector_buf, selector_win, note_win_id)
  -- Create autocommand to close windows when leaving to a non-tamal window
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = selector_buf,
    callback = function()
      vim.schedule(function()
        -- Get the current window after leaving
        local current_win = vim.api.nvim_get_current_win()

        -- Check if we moved to a window that is part of our pairs
        local is_related_window = false
        for id, pair in pairs(tamal_window_pairs) do
          if
            (pair.section_win and current_win == pair.section_win)
            or (pair.note_win and current_win == pair.note_win)
            or (pair.time_block_win and current_win == pair.time_block_win)
          then
            is_related_window = true
            break
          end
        end

        -- If we moved to an unrelated window, close all windows in the pair
        if not is_related_window and note_win_id then
          close_window_pair(note_win_id)
        end
      end)
    end,
  })

  -- Create autocommand to close the paired windows when this window is closed
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(selector_win),
    callback = function()
      if note_win_id then
        close_window_pair(note_win_id)
      end
    end,
  })
end

-- Helper function to create a selector window
local function create_selector_window(note_win, note_buf, items, title, position_above, initial_idx)
  -- Use initial_idx if provided, otherwise default to 1
  local current_idx = initial_idx or 1

  -- Create buffer for the selector
  local selector_buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(selector_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(selector_buf, 'modifiable', true)

  -- Set initial content
  vim.api.nvim_buf_set_lines(selector_buf, 0, -1, false, { items.prefix .. items.values[current_idx] })

  -- Calculate position relative to note window
  local note_win_config = vim.api.nvim_win_get_config(note_win)
  local pos = get_win_position(note_win_config)
  local height = 1
  local width = pos.width
  local row = position_above and (pos.row - 2) or (pos.row + note_win_config.height + 1)
  local col = pos.col

  -- Window options
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = title,
  }

  -- Create the window with the buffer
  local selector_win = vim.api.nvim_open_win(selector_buf, false, opts) -- Don't focus initially

  -- Set window options
  vim.api.nvim_win_set_option(selector_win, 'winblend', 10)
  vim.api.nvim_win_set_option(selector_win, 'cursorline', true)

  -- Find the associated note window and update the pair in the tracking table
  local note_win_id = nil
  for id, pair in pairs(tamal_window_pairs) do
    if pair.note_win == note_win then
      note_win_id = id
      if items.type == 'section' then
        pair.section_win = selector_win
      elseif items.type == 'time_block' then
        pair.time_block_win = selector_win
      end
      break
    end
  end

  -- Setup navigation between windows
  setup_window_navigation(note_win, note_buf, selector_win, selector_buf)

  -- Setup autocmds for window closing
  setup_window_autocmds(selector_buf, selector_win, note_win_id)

  -- Function to update the selector display
  local function update_display()
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(selector_buf) then
        vim.api.nvim_buf_set_option(selector_buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(selector_buf, 0, -1, false, { items.prefix .. items.values[current_idx] })
        vim.api.nvim_buf_set_option(selector_buf, 'modifiable', false)
      end
    end)
  end

  -- Tab in selector: Cycle through values
  vim.keymap.set('n', '<Tab>', function()
    current_idx = (current_idx % #items.values) + 1
    update_display()
  end, { noremap = true, silent = true, buffer = selector_buf })

  -- Make the selector display read-only after initial setup
  vim.api.nvim_buf_set_option(selector_buf, 'modifiable', false)

  return {
    win = selector_win,
    buf = selector_buf,
    get_current_value = function()
      return items.values[current_idx]
    end,
    parse_value = items.parse_value and function()
      return items.parse_value(items.values[current_idx])
    end or nil,
  }
end

-- Function to open a file in a floating window
local function open_file_in_floating_window(file_path)
  -- Check if file exists
  if vim.fn.filereadable(file_path) == 0 then
    vim.notify('File not found: ' .. file_path, vim.log.levels.ERROR)
    return
  end

  -- Create a new buffer for the file content
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set up dimensions and position
  local dimensions = calculate_window_dimensions(0.8, 0.8)

  -- Window options
  local opts = {
    relative = 'editor',
    width = dimensions.width,
    height = dimensions.height,
    col = dimensions.col,
    row = dimensions.row,
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

  -- Set common window options
  set_common_win_options(win)

  -- Register this window in the global tracking table
  local window_id = tostring(win)
  tamal_window_pairs[window_id] = { note_win = win }

  -- Check if this is a weekly note and position cursor on the current day's line
  local filename = vim.fn.fnamemodify(file_path, ':t')
  if string.match(filename, '^%d%d%d%d%-%d%d%-%d%d_week%.md$') then
    -- Get the current day of the week (1 = Monday, 7 = Sunday)
    local current_day = tonumber(os.date '%w')
    if current_day == 0 then
      current_day = 7
    end -- Convert Sunday from 0 to 7

    -- Get day line numbers from tamal
    local day_lines_output = vim.fn.systemlist 'tamal --day-line-numbers'

    -- Find the line for the current day
    local target_line = nil
    local day_names = { [1] = 'Mon', [2] = 'Tue', [3] = 'Wed', [4] = 'Thu', [5] = 'Fri', [6] = 'Sat', [7] = 'Sun' }
    local current_day_name = day_names[current_day]

    for _, line_info in ipairs(day_lines_output) do
      local line_num, day = line_info:match '(%d+),(%a+)'
      if day == current_day_name and line_num then
        target_line = tonumber(line_num)
        break
      end
    end

    -- Position cursor on the target line if found and ensure it's visible
    if target_line then
      -- Use a longer delay to ensure the buffer is fully loaded
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
          -- Set cursor position
          vim.api.nvim_win_set_cursor(win, { target_line, 0 })

          -- Center the view on the cursor line
          vim.cmd 'normal! zz'

          -- Ensure the UI updates
          vim.cmd 'redraw'
        end
      end, 100) -- 100ms delay
    end
  end

  -- Create autocommand to close window when leaving to a non-tamal window
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = buf,
    callback = function()
      vim.schedule(function()
        -- Get the current window after leaving
        local current_win = vim.api.nvim_get_current_win()

        -- Check if we moved to a window that is part of our pairs
        local is_related_window = false
        for id, pair in pairs(tamal_window_pairs) do
          if
            (pair.section_win and current_win == pair.section_win)
            or (pair.note_win and current_win == pair.note_win)
            or (pair.time_block_win and current_win == pair.time_block_win)
          then
            is_related_window = true
            break
          end
        end

        -- If we moved to an unrelated window, close both windows in the pair
        if not is_related_window then
          close_window_pair(window_id)
        end
      end)
    end,
  })

  -- Create autocommand to close the paired window when this window is closed
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(win),
    callback = function()
      close_window_pair(window_id)
    end,
  })

  -- Set keybindings for the window
  local keymap_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function()
    close_window_pair(window_id)
  end, keymap_opts)

  return { buf = buf, win = win }
end

-- Function to open notes using Telescope
local function open_note_with_telescope()
  local telescope = require 'telescope.builtin'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  telescope.find_files {
    prompt_title = 'Open Note',
    cwd = '~/notes',
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local file_path = '~/notes/' .. selection.value
          -- Expand the path to handle the tilde
          file_path = vim.fn.expand(file_path)
          open_file_in_floating_window(file_path)
        end
      end)
      return true
    end,
  }
end

-- Function to open a floating terminal and run a command
local function open_floating_terminal(cmd)
  -- Create a new buffer for the terminal
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set up dimensions and position
  local dimensions = calculate_window_dimensions(0.8, 0.8)

  -- Window options
  local opts = {
    relative = 'editor',
    width = dimensions.width,
    height = dimensions.height,
    col = dimensions.col,
    row = dimensions.row,
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

-- Function to create a time block selector for add-task command
local function create_time_block_selector(note_win, note_buf)
  -- Get available time blocks from tamal
  local time_blocks_output = vim.fn.systemlist 'tamal --time-blocks'

  -- If no time blocks available, return nil
  if #time_blocks_output == 0 then
    vim.notify('No time blocks available', vim.log.levels.WARN)
    return nil
  end

  -- Find the time block containing current time or the closest one
  local function find_best_time_block()
    -- Get current time
    local current_time = os.date '%H:%M'
    local current_hours, current_minutes = current_time:match '(%d+):(%d+)'
    local current_minutes_total = tonumber(current_hours) * 60 + tonumber(current_minutes)

    -- First try to find a time block that contains the current time
    for i, block in ipairs(time_blocks_output) do
      local start_time, end_time = block:match '(%d+:%d+)%s*-%s*(%d+:%d+)'
      if start_time and end_time then
        local start_hours, start_minutes = start_time:match '(%d+):(%d+)'
        local end_hours, end_minutes = end_time:match '(%d+):(%d+)'

        if start_hours and start_minutes and end_hours and end_minutes then
          local start_minutes_total = tonumber(start_hours) * 60 + tonumber(start_minutes)
          local end_minutes_total = tonumber(end_hours) * 60 + tonumber(end_minutes)

          -- Check if current time is within this block
          if current_minutes_total >= start_minutes_total and current_minutes_total <= end_minutes_total then
            return i -- Return the index of the containing block
          end
        end
      end
    end

    -- If no containing block found, find the closest one by start time
    local closest_idx = 1
    local min_diff = math.huge

    for i, block in ipairs(time_blocks_output) do
      local start_time = block:match '(%d+:%d+)%s*-'
      if start_time then
        local hours, minutes = start_time:match '(%d+):(%d+)'
        if hours and minutes then
          local minutes_total = tonumber(hours) * 60 + tonumber(minutes)
          local diff = math.abs(minutes_total - current_minutes_total)

          if diff < min_diff then
            min_diff = diff
            closest_idx = i
          end
        end
      end
    end

    return closest_idx
  end

  -- Get the best time block index
  local current_block_idx = find_best_time_block()

  -- Create selector with time blocks, passing the best time block index
  return create_selector_window(note_win, note_buf, {
    values = time_blocks_output,
    prefix = 'Time: ',
    type = 'time_block',
    parse_value = function(time_block)
      local start_time, end_time = time_block:match '(%d%d:%d%d)%s*-%s*(%d%d:%d%d)'
      return start_time, end_time
    end,
  }, 'Time Block', true, current_block_idx) -- Position above note window, with best time block index
end

-- Function to create a section selector for three-p command
local function create_section_selector(note_win, note_buf)
  local sections = { 'Progress', 'Planned', 'Problems' }

  -- Create selector with sections
  return create_selector_window(note_win, note_buf, {
    values = sections,
    prefix = 'Section: ',
    type = 'section',
  }, '3P', true) -- Position above note window
end

-- Function to create and display the popup window
local function open_tamal_popup(command_info)
  -- Check if this command should use telescope
  if command_info.use_telescope then
    open_note_with_telescope()
    return
  end

  -- Some commands don't need a popup
  if command_info.height == 0 then
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

  -- Calculate dimensions for the popup
  local width = 80 -- Reduced from 160 to match section selector
  local height = command_info.height
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local title = command_info.desc
  if command_info.cmd == 'three-p' then
    title = ''
  end

  -- Window options
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = title,
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

  -- Register this window in the global tracking table if it's not already there
  local window_id = tostring(win)
  if not tamal_window_pairs[window_id] then
    tamal_window_pairs[window_id] = { note_win = win }
  end

  -- Set keybindings for the popup
  local keymap_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function()
    close_window_pair(window_id)
  end, keymap_opts)

  -- If it's a read-only view (like tasks)
  if command_info.cmd == 'tasks' then
    return { buf = buf, win = win }
  end

  -- Create section selector for three-p command
  local section_selector = nil
  if command_info.cmd == 'three-p' then
    section_selector = create_section_selector(win, buf)
  end

  -- Create time block selector for add-task command
  local time_block_selector = nil
  if command_info.cmd == 'add-task' then
    time_block_selector = create_time_block_selector(win, buf)
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

    -- For three-p command, get the selected section and add it as --section argument
    if command_info.cmd == 'three-p' and section_selector then
      local selected_section = section_selector.get_current_value()
      cmd = cmd .. ' --section ' .. selected_section:lower() .. ' ' .. vim.fn.shellescape(content)

      -- Use our centralized function to close both windows
      close_window_pair(window_id)
    -- For add-task command, get the selected time block and add start/end time arguments
    elseif command_info.cmd == 'add-task' and time_block_selector then
      local start_time, end_time = time_block_selector.parse_value()
      cmd = cmd .. ' --start-time "' .. start_time .. '" --end-time "' .. end_time .. '" ' .. vim.fn.shellescape(content)

      -- Use our centralized function to close all windows
      close_window_pair(window_id)
    else
      -- Add parameter name if specified
      if command_info.param_name then
        cmd = cmd .. ' ' .. content
      else
        cmd = cmd .. ' ' .. vim.fn.shellescape(content)
      end

      -- Close the input window
      close_window_pair(window_id)
    end

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
