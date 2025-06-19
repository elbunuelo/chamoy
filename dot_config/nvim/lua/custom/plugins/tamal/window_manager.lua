-- window_manager.lua: Window management functions for the tamal plugin

local ui_utils = require('custom.plugins.tamal.ui_utils')

local M = {}

-- Global table to track related windows (notes and their section selectors)
M.tamal_window_pairs = {}

-- Function to close all windows in a pair
M.close_window_pair = function(id)
  local pair = M.tamal_window_pairs[id]
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

  -- Close instructions window if valid
  if pair.instructions_win and vim.api.nvim_win_is_valid(pair.instructions_win) then
    pcall(vim.api.nvim_win_close, pair.instructions_win, true)
  end

  -- Close any field windows (for zendesk form)
  for key, win in pairs(pair) do
    if key:match '^field%d+_win$' and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  -- Remove from tracking table
  M.tamal_window_pairs[id] = nil
end

-- Helper function to setup window navigation between windows
M.setup_window_navigation = function(note_win, note_buf, selector_win, selector_buf)
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
    M.close_window_pair(window_id)
  end, { noremap = true, silent = true, buffer = selector_buf })
  vim.keymap.set('n', 'q', function()
    M.close_window_pair(window_id)
  end, { noremap = true, silent = true, buffer = note_buf })

  return window_id
end

-- Helper function to setup window autocmds for closing
M.setup_window_autocmds = function(selector_buf, selector_win, note_win_id)
  -- Create autocommand to close windows when leaving to a non-tamal window
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = selector_buf,
    callback = function()
      vim.schedule(function()
        -- Get the current window after leaving
        local current_win = vim.api.nvim_get_current_win()

        -- Check if we moved to a window that is part of our pairs
        local is_related_window = false
        for id, pair in pairs(M.tamal_window_pairs) do
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
          M.close_window_pair(note_win_id)
        end
      end)
    end,
  })

  -- Create autocommand to close the paired windows when this window is closed
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(selector_win),
    callback = function()
      if note_win_id then
        M.close_window_pair(note_win_id)
      end
    end,
  })
end

-- Function to open a file in a floating window
M.open_file_in_floating_window = function(file_path, is_weekly_note)
  -- Check if file exists
  if vim.fn.filereadable(file_path) == 0 then
    vim.notify('File not found: ' .. file_path, vim.log.levels.ERROR)
    return
  end

  -- Create a new buffer for the file content
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set up dimensions and position
  local dimensions = ui_utils.calculate_window_dimensions(0.8, 0.8)

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
  M.tamal_window_pairs[window_id] = { note_win = win }

  -- Set common window options
  ui_utils.set_common_win_options(win)

  -- Function to setup keybindings and autocmds for a buffer
  local function setup_buffer_keymaps_and_autocmds(buffer)
    -- Set keybindings for the window
    local keymap_opts = { noremap = true, silent = true, buffer = buffer }
    vim.keymap.set('n', 'q', function()
      M.close_window_pair(window_id)
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
          for id, pair in pairs(M.tamal_window_pairs) do
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
            M.close_window_pair(window_id)
          end
        end)
      end,
    })
  end

  -- Create autocommand to close the paired window when this window is closed
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(win),
    callback = function()
      M.close_window_pair(window_id)
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
      if M.tamal_window_pairs[window_id] and M.tamal_window_pairs[window_id].note_win == current_win then
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

return M
