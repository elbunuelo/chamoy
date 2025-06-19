-- selectors.lua: Selector UI components for the tamal plugin

local ui_utils = require("tamal.ui_utils")
local window_manager = require("tamal.window_manager")
local time_utils = require("tamal.time_utils")

local M = {}

-- Helper function to create a selector window
local function create_selector_window(note_win, note_buf, items, title, position_above, initial_idx)
  -- Use initial_idx if provided, otherwise default to 1
  local current_idx = initial_idx or 1

  -- Create buffer for the selector
  local selector_buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(selector_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(selector_buf, "modifiable", true)

  -- Set initial content
  vim.api.nvim_buf_set_lines(selector_buf, 0, -1, false, { items.values[current_idx] })

  -- Calculate position relative to note window
  local note_win_config = vim.api.nvim_win_get_config(note_win)
  local pos = ui_utils.get_win_position(note_win_config)
  local height = 1
  local width = pos.width
  local row = position_above and (pos.row - 2) or (pos.row + note_win_config.height + 1)
  local col = pos.col

  -- Window options
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = title,
  }

  -- Create the window with the buffer
  local selector_win = vim.api.nvim_open_win(selector_buf, false, opts) -- Don't focus initially

  -- Set window options
  vim.api.nvim_win_set_option(selector_win, "winblend", 0)
  vim.api.nvim_win_set_option(selector_win, "cursorline", true)

  -- Find the associated note window and update the pair in the tracking table
  local note_win_id = nil
  for id, pair in pairs(window_manager.tamal_window_pairs) do
    if pair.note_win == note_win then
      note_win_id = id
      if items.type == "section" then
        pair.section_win = selector_win
      elseif items.type == "time_block" then
        pair.time_block_win = selector_win
      end
      break
    end
  end

  -- Setup navigation between windows
  window_manager.setup_window_navigation(note_win, note_buf, selector_win, selector_buf)

  -- Setup autocmds for window closing
  window_manager.setup_window_autocmds(selector_buf, selector_win, note_win_id)

  -- Function to update the selector display
  local function update_display()
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(selector_buf) then
        vim.api.nvim_buf_set_option(selector_buf, "modifiable", true)
        vim.api.nvim_buf_set_lines(selector_buf, 0, -1, false, { items.values[current_idx] })
        vim.api.nvim_buf_set_option(selector_buf, "modifiable", false)
      end
    end)
  end

  -- Tab in selector: Cycle through values
  vim.keymap.set("n", "<Tab>", function()
    current_idx = (current_idx % #items.values) + 1
    update_display()
  end, { noremap = true, silent = true, buffer = selector_buf })

  -- Add time adjustment keybindings for time blocks
  if items.type == "time_block" then
    -- Function to determine if cursor is on start time or end time
    local function get_time_part_at_cursor()
      -- Get cursor position
      local cursor_pos = vim.api.nvim_win_get_cursor(selector_win)[2]
      local line = vim.api.nvim_buf_get_lines(selector_buf, 0, 1, false)[1]

      -- Calculate positions in the line, accounting for the prefix
      local time_block = line
      local start_time, end_time = time_block:match("(%d%d:%d%d)%s*-%s*(%d%d:%d%d)")

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
        return "start", start_time
      elseif cursor_pos >= end_pos - 1 and cursor_pos < end_pos + #end_time - 1 then
        return "end", end_time
      end

      return nil
    end

    -- Function to adjust time block based on cursor position
    local function adjust_time_block(increment)
      -- Get current time block
      local time_block = items.values[current_idx]
      local start_time, end_time = time_block:match("(%d%d:%d%d)%s*-%s*(%d%d:%d%d)")

      if not start_time or not end_time then
        return
      end

      -- Check cursor position and adjust appropriate time
      local time_part, time_value = get_time_part_at_cursor()

      if not time_part then
        return
      end

      -- Adjust the time
      local new_time = time_utils.adjust_time_by_15min(time_value, increment)

      -- Create new time block string
      local new_time_block
      if time_part == "start" then
        -- Ensure start time doesn't exceed end time
        if time_utils.parse_time_to_minutes(new_time) < time_utils.parse_time_to_minutes(end_time) then
          new_time_block = new_time .. " - " .. end_time
        else
          return -- Invalid adjustment
        end
      else -- end time
        -- Ensure end time doesn't precede start time
        if time_utils.parse_time_to_minutes(new_time) > time_utils.parse_time_to_minutes(start_time) then
          new_time_block = start_time .. " - " .. new_time
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
    vim.keymap.set("n", "+", function()
      adjust_time_block(true)
    end, { noremap = true, silent = true, buffer = selector_buf })
    vim.keymap.set("n", "-", function()
      adjust_time_block(false)
    end, { noremap = true, silent = true, buffer = selector_buf })
  end

  -- Make the selector display read-only after initial setup
  vim.api.nvim_buf_set_option(selector_buf, "modifiable", false)

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

-- Function to create a section selector for three-p command
M.create_section_selector = function(note_win, note_buf)
  local sections = { "Progress", "Planned", "Problems" }

  -- Create selector with sections
  return create_selector_window(note_win, note_buf, {
    values = sections,
    type = "section",
  }, "3P", true) -- Position above note window
end

-- Function to create a time block selector for add-task command
M.create_time_block_selector = function(note_win, note_buf)
  -- Get available time blocks from tamal
  local time_blocks_output = vim.fn.systemlist("tamal --time-blocks")

  -- If no time blocks available, create a default block around current time
  if #time_blocks_output == 0 then
    -- Get current time
    local current_time = os.date("%H:%M")
    local current_hours, current_minutes = current_time:match("(%d+):(%d+)")
    current_hours = tonumber(current_hours)
    current_minutes = tonumber(current_minutes)

    -- Round down to nearest 15 min for start time
    local start_hours, start_minutes = time_utils.round_time_to_15min(current_hours, current_minutes, false)
    -- Round up to nearest 15 min for end time (at least 15 min after start)
    local end_hours, end_minutes = time_utils.round_time_to_15min(current_hours, current_minutes + 15, true)

    -- Create a time block
    local time_block = time_utils.format_time(start_hours, start_minutes)
      .. " - "
      .. time_utils.format_time(end_hours, end_minutes)
    time_blocks_output = { time_block }

    -- Create selector with the single time block
    return create_selector_window(note_win, note_buf, {
      values = time_blocks_output,
      type = "time_block",
      parse_value = function(time_block)
        local start_time, end_time = time_block:match("(%d%d:%d%d)%s*-%s*(%d%d:%d%d)")
        return start_time, end_time
      end,
    }, "Time Block", true, 1) -- Position above note window, with index 1
  end

  -- Find the time block containing current time or create a gap filler
  local function find_or_create_time_block()
    -- Get current time
    local current_time = os.date("%H:%M")
    local current_hours, current_minutes = current_time:match("(%d+):(%d+)")
    local current_minutes_total = tonumber(current_hours) * 60 + tonumber(current_minutes)

    -- Parse all time blocks and their start/end times
    local blocks = {}
    for i, block in ipairs(time_blocks_output) do
      local start_time, end_time = block:match("(%d+:%d+)%s*-%s*(%d+:%d+)")
      if start_time and end_time then
        local start_minutes = time_utils.parse_time_to_minutes(start_time)
        local end_minutes = time_utils.parse_time_to_minutes(end_time)

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
      local end_hours, end_minutes =
        time_utils.round_time_to_15min(tonumber(current_hours), tonumber(current_minutes) + 15, true)
      end_time = time_utils.format_time(end_hours, end_minutes)
    elseif next_block then
      -- Case 3: Before all blocks - use current time rounded and start of first block
      local start_hours, start_minutes =
        time_utils.round_time_to_15min(tonumber(current_hours), tonumber(current_minutes), false)
      start_time = time_utils.format_time(start_hours, start_minutes)
      end_time = next_block.start_time
    else
      -- Case 4: No blocks at all (shouldn't happen here but just in case)
      local start_hours, start_minutes =
        time_utils.round_time_to_15min(tonumber(current_hours), tonumber(current_minutes), false)
      local end_hours, end_minutes =
        time_utils.round_time_to_15min(tonumber(current_hours), tonumber(current_minutes) + 15, true)
      start_time = time_utils.format_time(start_hours, start_minutes)
      end_time = time_utils.format_time(end_hours, end_minutes)
    end

    -- Create the dynamic block and add it to the list
    local dynamic_block = start_time .. " - " .. end_time
    table.insert(time_blocks_output, dynamic_block)

    return #time_blocks_output -- Return the index of the new block
  end

  -- Get the best time block index or create a dynamic one
  local current_block_idx = find_or_create_time_block()

  -- Create selector with time blocks, passing the best time block index
  return create_selector_window(note_win, note_buf, {
    values = time_blocks_output,
    type = "time_block",
    parse_value = function(time_block)
      local start_time, end_time = time_block:match("(%d%d:%d%d)%s*-%s*(%d%d:%d%d)")
      return start_time, end_time
    end,
  }, "Time Block", true, current_block_idx) -- Position above note window, with best time block index
end

-- Function to create a zendesk section selector
M.create_zendesk_section_selector = function(note_win, note_buf)
  local sections = { "Internal", "Public" }
  return create_selector_window(note_win, note_buf, {
    values = sections,
    type = "section",
  }, "Zendesk Section", true) -- Position above note window
end

return M
