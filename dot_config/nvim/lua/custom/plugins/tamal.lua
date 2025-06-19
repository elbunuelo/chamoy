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
  { cmd = 'weekly', desc = 'Open weekly note', height = 0, key = 'w', use_note_path = true },
  { cmd = 'open', desc = 'Open a note', height = 0, key = 'o', use_telescope = true },
  { cmd = 'add-note', desc = 'Add a note', height = 15, key = 'n', needs_time_block = true },
  { cmd = 'three-p', desc = 'Add a 3P note', height = 15, key = 'p' },
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
  vim.api.nvim_win_set_option(win, 'winblend', 0)
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

-- Helper function to adjust time by 15 minutes (positive or negative)
local function adjust_time_by_15min(time_str, increment)
  local hours, minutes = time_str:match '(%d+):(%d+)'
  if not hours or not minutes then
    return time_str
  end

  hours, minutes = tonumber(hours), tonumber(minutes)

  -- Convert to total minutes and adjust
  local total_minutes = hours * 60 + minutes
  total_minutes = total_minutes + (increment and 15 or -15)

  -- Handle day wrapping
  if total_minutes < 0 then
    total_minutes = total_minutes + 24 * 60 -- Wrap to previous day
  elseif total_minutes >= 24 * 60 then
    total_minutes = total_minutes - 24 * 60 -- Wrap to next day
  end

  -- Convert back to hours and minutes
  local new_hours = math.floor(total_minutes / 60)
  local new_minutes = total_minutes % 60

  return string.format('%02d:%02d', new_hours, new_minutes)
end

-- Helper function to round time to nearest 15 minutes
local function round_time_to_15min(hours, minutes, round_up)
  local total_minutes = hours * 60 + minutes
  local remainder = total_minutes % 15

  if remainder == 0 then
    return hours, minutes
  end

  if round_up then
    total_minutes = total_minutes + (15 - remainder)
  else
    total_minutes = total_minutes - remainder
  end

  local new_hours = math.floor(total_minutes / 60)
  local new_minutes = total_minutes % 60

  return new_hours, new_minutes
end

-- Helper function to format time as HH:MM
local function format_time(hours, minutes)
  return string.format('%02d:%02d', hours, minutes)
end

-- Helper function to parse time string into minutes
local function parse_time_to_minutes(time_str)
  local hours, minutes = time_str:match '(%d+):(%d+)'
  if hours and minutes then
    return tonumber(hours) * 60 + tonumber(minutes)
  end
  return nil
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
  vim.api.nvim_buf_set_lines(selector_buf, 0, -1, false, { items.values[current_idx] })

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
  vim.api.nvim_win_set_option(selector_win, 'winblend', 0)
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
        vim.api.nvim_buf_set_lines(selector_buf, 0, -1, false, { items.values[current_idx] })
        vim.api.nvim_buf_set_option(selector_buf, 'modifiable', false)
      end
    end)
  end

  -- Tab in selector: Cycle through values
  vim.keymap.set('n', '<Tab>', function()
    current_idx = (current_idx % #items.values) + 1
    update_display()
  end, { noremap = true, silent = true, buffer = selector_buf })

  -- Add time adjustment keybindings for time blocks
  if items.type == 'time_block' then
    -- Function to determine if cursor is on start time or end time
    local function get_time_part_at_cursor()
      -- Get cursor position
      local cursor_pos = vim.api.nvim_win_get_cursor(selector_win)[2]
      local line = vim.api.nvim_buf_get_lines(selector_buf, 0, 1, false)[1]

      -- Calculate positions in the line, accounting for the prefix
      local time_block = line
      local start_time, end_time = time_block:match '(%d%d:%d%d)%s*-%s*(%d%d:%d%d)'

      if not start_time or not end_time then
        return nil
      end

      -- Find positions of start and end times in the line
      local start_pos = line:find(start_time, 1, true)
      local end_pos = line:find(end_time, 1, true)

      if not start_pos or not end_pos then
        return nil
      end

      -- Determine if cursor is on start time or end time
      if cursor_pos >= start_pos - 1 and cursor_pos < start_pos + #start_time - 1 then
        return 'start', start_time
      elseif cursor_pos >= end_pos - 1 and cursor_pos < end_pos + #end_time - 1 then
        return 'end', end_time
      end

      return nil
    end

    -- Function to adjust time block based on cursor position
    local function adjust_time_block(increment)
      -- Get current time block
      local time_block = items.values[current_idx]
      local start_time, end_time = time_block:match '(%d%d:%d%d)%s*-%s*(%d%d:%d%d)'

      if not start_time or not end_time then
        return
      end

      -- Check cursor position and adjust appropriate time
      local time_part, time_value = get_time_part_at_cursor()

      if not time_part then
        return
      end

      -- Adjust the time
      local new_time = adjust_time_by_15min(time_value, increment)

      -- Create new time block string
      local new_time_block
      if time_part == 'start' then
        -- Ensure start time doesn't exceed end time
        if parse_time_to_minutes(new_time) < parse_time_to_minutes(end_time) then
          new_time_block = new_time .. ' - ' .. end_time
        else
          return -- Invalid adjustment
        end
      else -- end time
        -- Ensure end time doesn't precede start time
        if parse_time_to_minutes(new_time) > parse_time_to_minutes(start_time) then
          new_time_block = start_time .. ' - ' .. new_time
        else
          return -- Invalid adjustment
        end
      end

      -- Update the time block in the values array
      items.values[current_idx] = new_time_block

      -- Update display
      update_display()
    end

    -- Add keybindings for + and -
    vim.keymap.set('n', '+', function()
      adjust_time_block(true)
    end, { noremap = true, silent = true, buffer = selector_buf })
    vim.keymap.set('n', '-', function()
      adjust_time_block(false)
    end, { noremap = true, silent = true, buffer = selector_buf })
  end

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
local function open_file_in_floating_window(file_path, is_weekly_note)
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
    width = 80,
    height = dimensions.height,
    col = 80,
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

  -- Register this window in the global tracking table
  local window_id = tostring(win)
  tamal_window_pairs[window_id] = { note_win = win }

  -- Set common window options
  set_common_win_options(win)

  -- Function to setup keybindings and autocmds for a buffer
  local function setup_buffer_keymaps_and_autocmds(buffer)
    -- Set keybindings for the window
    local keymap_opts = { noremap = true, silent = true, buffer = buffer }
    vim.keymap.set('n', 'q', function()
      close_window_pair(window_id)
    end, keymap_opts)

    -- Create autocommand to close window when leaving to a non-tamal window
    -- This needs to be recreated for each buffer change
    vim.api.nvim_create_autocmd('WinLeave', {
      buffer = buffer,
      group = vim.api.nvim_create_augroup('TamalWinLeave_' .. window_id, { clear = true }),
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
          if not is_related_window then
            close_window_pair(window_id)
          end
        end)
      end,
    })
  end

  -- Create autocommand to close the paired window when this window is closed
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(win),
    callback = function()
      close_window_pair(window_id)
    end,
  })

  -- Initial setup of keybindings and autocmds
  setup_buffer_keymaps_and_autocmds(buf)

  -- Create autocmds to maintain keybindings and autocmds after buffer changes
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'BufWritePost' }, {
    callback = function(args)
      local current_buf = args.buf
      local current_win = vim.api.nvim_get_current_win()

      -- Check if this is our floating window
      if tamal_window_pairs[window_id] and tamal_window_pairs[window_id].note_win == current_win then
        -- Re-apply keybindings and autocmds for the current buffer
        vim.schedule(function()
          setup_buffer_keymaps_and_autocmds(current_buf)
        end)
      end
    end,
  })

  -- Load the file content into the buffer - more reliable method
  vim.cmd('edit ' .. vim.fn.fnameescape(file_path))

  -- If this is a weekly note, position the cursor on the current day's line
  if is_weekly_note then
    vim.schedule(function()
      -- Get the current day of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
      local current_day = tonumber(os.date '%w')
      -- Convert to day name (Mon, Tue, Wed, Thu, Fri)
      local day_names = { [1] = 'Mon', [2] = 'Tue', [3] = 'Wed', [4] = 'Thu', [5] = 'Fri' }
      local day_name = day_names[current_day == 0 and 5 or current_day] -- Map Sunday(0) to Friday(5) as fallback

      -- If it's a weekend, default to Monday
      if not day_name then
        day_name = 'Mon'
      end

      -- Get day line numbers from tamal
      local day_lines_output = vim.fn.systemlist 'tamal --day-line-numbers'
      local target_line = nil

      -- Parse the output to find the line number for the current day
      for _, line in ipairs(day_lines_output) do
        local line_num, line_day = line:match '(%d+),(%a+)'
        if line_day == day_name then
          target_line = tonumber(line_num)
          break
        end
      end

      -- Set cursor to the current day's line if found
      if target_line then
        vim.api.nvim_win_set_cursor(win, { target_line, 0 })
        -- Position the selected line at the top of the window
        vim.cmd 'normal! zt'
      end
    end)
  end
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

-- Function to create a time block selector for add-task command
local function create_time_block_selector(note_win, note_buf)
  -- Get available time blocks from tamal
  local time_blocks_output = vim.fn.systemlist 'tamal --time-blocks'

  -- If no time blocks available, create a default block around current time
  if #time_blocks_output == 0 then
    -- Get current time
    local current_time = os.date '%H:%M'
    local current_hours, current_minutes = current_time:match '(%d+):(%d+)'
    current_hours = tonumber(current_hours)
    current_minutes = tonumber(current_minutes)

    -- Round down to nearest 15 min for start time
    local start_hours, start_minutes = round_time_to_15min(current_hours, current_minutes, false)
    -- Round up to nearest 15 min for end time (at least 15 min after start)
    local end_hours, end_minutes = round_time_to_15min(current_hours, current_minutes + 15, true)

    -- Create a time block
    local time_block = format_time(start_hours, start_minutes) .. ' - ' .. format_time(end_hours, end_minutes)
    time_blocks_output = { time_block }

    -- Create selector with the single time block
    return create_selector_window(note_win, note_buf, {
      values = time_blocks_output,
      type = 'time_block',
      parse_value = function(time_block)
        local start_time, end_time = time_block:match '(%d%d:%d%d)%s*-%s*(%d%d:%d%d)'
        return start_time, end_time
      end,
    }, 'Time Block', true, 1) -- Position above note window, with index 1
  end

  -- Find the time block containing current time or create a gap filler
  local function find_or_create_time_block()
    -- Get current time
    local current_time = os.date '%H:%M'
    local current_hours, current_minutes = current_time:match '(%d+):(%d+)'
    local current_minutes_total = tonumber(current_hours) * 60 + tonumber(current_minutes)

    -- Parse all time blocks and their start/end times
    local blocks = {}
    for i, block in ipairs(time_blocks_output) do
      local start_time, end_time = block:match '(%d+:%d+)%s*-%s*(%d+:%d+)'
      if start_time and end_time then
        local start_minutes = parse_time_to_minutes(start_time)
        local end_minutes = parse_time_to_minutes(end_time)

        if start_minutes and end_minutes then
          table.insert(blocks, {
            index = i,
            start_time = start_time,
            end_time = end_time,
            start_minutes = start_minutes,
            end_minutes = end_minutes,
          })
        end
      end
    end

    -- Sort blocks by start time
    table.sort(blocks, function(a, b)
      return a.start_minutes < b.start_minutes
    end)

    -- First try to find a time block that contains the current time
    for _, block in ipairs(blocks) do
      if current_minutes_total >= block.start_minutes and current_minutes_total <= block.end_minutes then
        return block.index -- Return the index of the containing block
      end
    end

    -- If no containing block found, create a gap filler block
    local prev_block = nil
    local next_block = nil

    -- Find previous and next blocks
    for i, block in ipairs(blocks) do
      if block.start_minutes > current_minutes_total then
        next_block = block
        if i > 1 then
          prev_block = blocks[i - 1]
        end
        break
      end
      -- If we reach the end without finding a next block, this is the prev block
      if i == #blocks then
        prev_block = block
      end
    end

    -- Create a new block based on the situation
    local start_time, end_time

    if prev_block and next_block then
      -- Case 1: Between two blocks - use end of prev and start of next
      start_time = prev_block.end_time
      end_time = next_block.start_time
    elseif prev_block then
      -- Case 2: After all blocks - use end of last block and current time + 15min rounded
      start_time = prev_block.end_time
      local end_hours, end_minutes = round_time_to_15min(tonumber(current_hours), tonumber(current_minutes) + 15, true)
      end_time = format_time(end_hours, end_minutes)
    elseif next_block then
      -- Case 3: Before all blocks - use current time rounded and start of first block
      local start_hours, start_minutes = round_time_to_15min(tonumber(current_hours), tonumber(current_minutes), false)
      start_time = format_time(start_hours, start_minutes)
      end_time = next_block.start_time
    else
      -- Case 4: No blocks at all (shouldn't happen here but just in case)
      local start_hours, start_minutes = round_time_to_15min(tonumber(current_hours), tonumber(current_minutes), false)
      local end_hours, end_minutes = round_time_to_15min(tonumber(current_hours), tonumber(current_minutes) + 15, true)
      start_time = format_time(start_hours, start_minutes)
      end_time = format_time(end_hours, end_minutes)
    end

    -- Create the dynamic block and add it to the list
    local dynamic_block = start_time .. ' - ' .. end_time
    table.insert(time_blocks_output, dynamic_block)

    return #time_blocks_output -- Return the index of the new block
  end

  -- Get the best time block index or create a dynamic one
  local current_block_idx = find_or_create_time_block()

  -- Create selector with time blocks, passing the best time block index
  return create_selector_window(note_win, note_buf, {
    values = time_blocks_output,
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
    type = 'section',
  }, '3P', true) -- Position above note window
end

-- Helper function to get visually selected text
local function get_visual_selection()
  local _, start_line, start_col, _ = unpack(vim.fn.getpos "'<")
  local _, end_line, end_col, _ = unpack(vim.fn.getpos "'>")

  -- Handle case where visual mode hasn't been used yet
  if start_line == 0 then
    return ''
  end

  local lines = vim.fn.getline(start_line, end_line)

  -- Adjust columns for the first and last lines
  if #lines == 0 then
    return ''
  end

  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end

  return table.concat(lines, '\n')
end

-- Modified open_tamal_popup to accept initial content
local function open_tamal_popup(command_info, initial_content)
  -- Check if this command should use telescope
  if command_info.use_telescope then
    open_note_with_telescope()
    return
  end

  -- Some commands don't need a popup
  if command_info.height == 0 then
    -- If this command should use note path
    if command_info.use_note_path then
      -- Get the path to the note file
      local path_cmd = command_info.path_cmd or command_info.cmd .. '-note-path'
      -- Get the path to the note file
      local file_path = vim.fn.system('tamal --' .. path_cmd):gsub('\n$', '')
      -- Open the file in a floating window (pass true for weekly notes to position cursor)
      open_file_in_floating_window(file_path, command_info.cmd == 'weekly')
    else
      -- Execute command directly
      vim.fn.system('tamal --' .. command_info.cmd)
      -- Reload the current buffer if it's a real file
      local current_buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_get_name(current_buf) ~= '' then
        vim.cmd 'e!'
      end
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

    -- Store the original task data for later reference when updating status
    local task_data = {}

    -- Process tasks to add status indicators
    local processed_tasks = {}
    for i, line in ipairs(tasks_output) do
      -- Parse the status and task text (format: "status,task text")
      local status, task_text = line:match '^([^,]+),(.*)$'

      if status then
        -- Map status to ASCII character
        local status_char = ''
        if status == 'pending' then
          status_char = ' ' -- Space for pending
        elseif status == 'done' then
          status_char = 'x' -- x for done
        elseif status == 'canceled' then
          status_char = '~' -- ~ for canceled
        else
          status_char = '?' -- ? for unknown status
        end

        -- Create line with status character and task text
        local modified_line = '[' .. status_char .. '] ' .. task_text
        table.insert(processed_tasks, modified_line)

        -- Store the original task data
        task_data[#processed_tasks] = {
          status = status,
          text = task_text,
          line_index = #processed_tasks,
        }
      else
        -- Not a task line or couldn't parse, keep as is
        table.insert(processed_tasks, line)
        task_data[#processed_tasks] = nil -- Mark as not a task line
      end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, processed_tasks)

    -- Function to cycle task status
    local function cycle_task_status()
      -- Get the current window and the current line number (1-based index)
      local current_win = vim.api.nvim_get_current_win()
      local cursor_pos = vim.api.nvim_win_get_cursor(current_win)
      local line_num = cursor_pos[1]

      -- Check if this line is a task
      local task = task_data[line_num]
      if not task then
        vim.notify('Not a task line', vim.log.levels.WARN)
        return
      end

      -- Determine the next status in the cycle
      local next_status = 'pending' -- Default fallback
      if task.status == 'pending' then
        next_status = 'done'
      elseif task.status == 'done' then
        next_status = 'canceled'
      elseif task.status == 'canceled' then
        next_status = 'pending'
      end

      -- Update the task status in our data
      task.status = next_status

      -- Update the display with the new status character
      local new_char = '?'
      if next_status == 'pending' then
        new_char = ' '
      elseif next_status == 'done' then
        new_char = 'x'
      elseif next_status == 'canceled' then
        new_char = '~'
      end

      -- Make the buffer modifiable temporarily
      vim.api.nvim_buf_set_option(buf, 'modifiable', true)

      -- Get the current line content
      local line = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1]

      -- Replace the status character in the brackets
      local new_line = '[' .. new_char .. ']' .. line:sub(4) -- Replace character in brackets
      vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, { new_line })

      -- Make the buffer read-only again
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)

      -- Update the task status in tamal
      local cmd = 'tamal --update-task "' .. task.text .. '" --status ' .. next_status
      vim.fn.system(cmd)

      -- Show notification
      vim.notify('Task updated to: ' .. next_status, vim.log.levels.INFO)
    end

    -- Add Tab key mapping to cycle through task statuses
    vim.keymap.set('n', '<Tab>', cycle_task_status, { noremap = true, silent = true, buffer = buf })

    -- Make the buffer read-only
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  else
    -- For input commands, add initial content if provided
    if initial_content and #initial_content > 0 then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(initial_content, '\n'))
    end
  end

  -- Create the window with the buffer
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, 'winblend', 0)
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

  -- Create time block selector for commands that need time blocks
  local time_block_selector = nil
  if command_info.cmd == 'add-task' or command_info.needs_time_block then
    time_block_selector = create_time_block_selector(win, buf)
  end

  -- For commands that require input, set up Enter key binding (normal mode only)
  vim.keymap.set('n', '<CR>', function()
    -- Get the content of the buffer
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')

    -- Construct the command
    local cmd = 'tamal'

    -- For three-p command, get the selected section and add it as --section argument
    if command_info.cmd == 'three-p' and section_selector then
      local selected_section = section_selector.get_current_value()
      cmd = cmd .. ' --three-p ' .. selected_section:lower() .. ' --note ' .. vim.fn.shellescape(content)

      -- Use our centralized function to close both windows
      close_window_pair(window_id)
    -- For add-task command, get the selected time block and add start/end time arguments
    elseif command_info.cmd == 'add-task' and time_block_selector then
      local start_time, end_time = time_block_selector.parse_value()
      cmd = cmd .. ' --add-task ' .. vim.fn.shellescape(content) .. ' --start-time "' .. start_time .. '" --end-time "' .. end_time .. '"'

      -- Use our centralized function to close all windows
      close_window_pair(window_id)
    -- For add-note command, we need the time block too
    elseif command_info.cmd == 'add-note' and time_block_selector then
      local start_time, end_time = time_block_selector.parse_value()
      cmd = cmd .. ' --note ' .. vim.fn.shellescape(content) .. ' --start-time "' .. start_time .. '" --end-time "' .. end_time .. '"'

      -- Use our centralized function to close all windows
      close_window_pair(window_id)
    else
      -- Add parameter name if specified
      if command_info.param_name then
        cmd = cmd .. ' ' .. content
      else
        cmd = cmd .. ' --' .. command_info.cmd .. ' ' .. vim.fn.shellescape(content)
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
      open_file_in_floating_window(file_path, false)
    else
      -- Execute the command
      local output = vim.fn.system(cmd)

      -- Show a notification of success
      local success_message = ''
      if command_info.cmd == 'add-task' then
        success_message = 'Task added successfully'
      elseif command_info.cmd == 'add-note' then
        success_message = 'Note added successfully'
      elseif command_info.cmd == 'three-p' then
        success_message = '3P note added successfully'
      else
        success_message = 'Command executed successfully'
      end
      vim.notify(success_message, vim.log.levels.INFO)

      -- Reload the current buffer only if it's a real file
      local current_buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_get_name(current_buf) ~= '' then
        pcall(function()
          vim.cmd 'e!'
        end)
      end
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

  -- Add visual mode keybindings for add-note and three-p
  if cmd_info.cmd == 'add-note' or cmd_info.cmd == 'three-p' then
    vim.keymap.set('v', '<leader>T' .. cmd_info.key, function()
      -- Get the selected text
      local selected_text = get_visual_selection()
      -- Clear the visual selection
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
      -- Open the popup with the selected text
      open_tamal_popup(cmd_info, selected_text)
    end, { desc = 'Tamal: ' .. cmd_info.desc .. ' with selection', silent = true })
  end
end

return {}
