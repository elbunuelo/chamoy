-- forms.lua: Form UI components for the tamal plugin

local window_manager = require('custom.plugins.tamal.window_manager')

local M = {}

-- Helper function to create a zendesk options input form with separate floating panes for each field
M.create_zendesk_options_input = function(callback)
  -- Define the form fields
  local fields = {
    { name = 'ticket_link', label = 'Ticket Link', value = '', required = true },
    { name = 'user_name', label = 'User Name', value = '' },
    { name = 'user_link', label = 'User Link', value = '' },
    { name = 'account_name', label = 'Account Name', value = '' },
    { name = 'account_link', label = 'Account Link', value = '' },
  }
  local current_field_idx = 1

  -- Window dimensions
  local width = 60
  local field_height = 1
  -- Increase field spacing to ensure titles are always visible
  local field_spacing = 3
  local base_col = math.floor((vim.o.columns - width) / 2)
  local base_row = math.floor(vim.o.lines / 2) - (#fields * field_spacing / 2)

  -- Create a buffer and window for each field
  local field_windows = {}
  local field_buffers = {}

  for i, field in ipairs(fields) do
    -- Create buffer for the field
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- Set initial content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { field.value })

    -- Label for the window title
    local title = field.label
    if field.required then
      title = title .. ' *'
    end

    -- Window options
    local opts = {
      relative = 'editor',
      width = width,
      height = field_height,
      col = base_col,
      row = base_row + (i - 1) * field_spacing,
      style = 'minimal',
      border = 'rounded',
      title = ' ' .. title .. ' ',
    }

    -- Create window
    local win = vim.api.nvim_open_win(buf, i == 1, opts) -- Focus the first field
    vim.api.nvim_win_set_option(win, 'winblend', 0)
    vim.api.nvim_win_set_option(win, 'cursorline', false)

    -- Store window and buffer
    field_windows[i] = win
    field_buffers[i] = buf
  end

  -- Generate a unique ID for this form
  local form_id = tostring(field_windows[1])

  -- Track all windows in the global table
  window_manager.tamal_window_pairs[form_id] = {
    note_win = field_windows[1], -- Use the first field as the main window
  }

  -- Add all windows to the tracking table
  for i, win in ipairs(field_windows) do
    if i > 1 then -- Skip the first one as it's already added as note_win
      window_manager.tamal_window_pairs[form_id]['field' .. i .. '_win'] = win
    end
  end

  -- Start in insert mode for the first field
  vim.cmd 'startinsert'

  -- Function to move focus to a specific field
  local function focus_field(idx)
    -- Save current field value
    local current_buf = field_buffers[current_field_idx]
    local current_content = vim.api.nvim_buf_get_lines(current_buf, 0, 1, false)[1] or ''
    fields[current_field_idx].value = current_content

    -- Update index
    current_field_idx = idx

    -- Focus the window
    vim.api.nvim_set_current_win(field_windows[idx])
    vim.cmd 'startinsert!'
  end

  -- Function to navigate to next/previous field
  local function navigate_field(direction)
    local new_idx
    if direction == 'next' then
      new_idx = current_field_idx % #fields + 1
    else
      new_idx = (current_field_idx - 2) % #fields + 1
    end
    focus_field(new_idx)
  end

  -- Function to submit the form
  local function submit_form()
    -- Save current field value
    local current_buf = field_buffers[current_field_idx]
    local current_content = vim.api.nvim_buf_get_lines(current_buf, 0, 1, false)[1] or ''
    fields[current_field_idx].value = current_content

    -- Collect all field values from our fields table
    local options = {}
    for _, field in ipairs(fields) do
      options[field.name] = field.value
    end

    -- Validate required fields
    for _, field in ipairs(fields) do
      if field.required and (not field.value or field.value == '') then
        vim.notify(field.label .. ' is required', vim.log.levels.WARN)

        -- Focus the required field
        for idx, f in ipairs(fields) do
          if f.name == field.name then
            focus_field(idx)
            return
          end
        end
        return
      end
    end

    -- Close all windows
    window_manager.close_window_pair(form_id)

    -- Call the callback with the options
    callback(options)
  end

  -- Function to cancel the form
  local function cancel_form()
    window_manager.close_window_pair(form_id)
    vim.notify('Cancelled', vim.log.levels.INFO)
  end

  -- Set up keybindings for all fields
  for i, buf in ipairs(field_buffers) do
    -- Tab to move to next field
    vim.keymap.set('i', '<Tab>', function()
      navigate_field 'next'
    end, { buffer = buf, noremap = true, silent = true })

    -- Shift+Tab to move to previous field
    vim.keymap.set('i', '<S-Tab>', function()
      navigate_field 'prev'
    end, { buffer = buf, noremap = true, silent = true })

    -- Enter to submit the form
    vim.keymap.set('i', '<CR>', submit_form, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set('n', '<CR>', submit_form, { buffer = buf, noremap = true, silent = true })

    -- Escape to cancel
    vim.keymap.set({ 'i', 'n' }, '<Esc>', cancel_form, { buffer = buf, noremap = true, silent = true })

    -- q to cancel
    vim.keymap.set('n', 'q', cancel_form, { buffer = buf, noremap = true, silent = true })

    -- Ctrl+j and Ctrl+k for navigation
    vim.keymap.set({ 'n', 'i' }, '<C-j>', function()
      if i < #fields then
        focus_field(i + 1)
      end
    end, { buffer = buf, noremap = true, silent = true })

    vim.keymap.set({ 'n', 'i' }, '<C-k>', function()
      if i > 1 then
        focus_field(i - 1)
      end
    end, { buffer = buf, noremap = true, silent = true })
  end

  -- Set up autocmds for closing when leaving to a non-form window
  for i, buf in ipairs(field_buffers) do
    vim.api.nvim_create_autocmd('WinLeave', {
      buffer = buf,
      callback = function()
        vim.schedule(function()
          -- Get the current window after leaving
          local current_win = vim.api.nvim_get_current_win()

          -- Check if we moved to a window that is part of our form
          local is_form_window = false
          local form_windows = window_manager.tamal_window_pairs[form_id] or {}

          for _, win_id in pairs(form_windows) do
            if win_id == current_win then
              is_form_window = true
              break
            end
          end

          -- If we moved to an unrelated window, close all form windows
          if not is_form_window then
            window_manager.close_window_pair(form_id)
          end
        end)
      end,
    })
  end

  return {
    windows = field_windows,
    buffers = field_buffers,
    form_id = form_id,
  }
end

return M
