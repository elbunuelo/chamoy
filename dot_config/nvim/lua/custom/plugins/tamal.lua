local MAX_TIMESTAMP = 23 * 60 + 59
local MIN_TIMESTAMP = 0
local ONE_HOUR = 60
local FIFTEEN_MINUTES = 15

function close_fields(fields)
  for _, field in ipairs(fields) do
    if vim.api.nvim_win_is_valid(field.window) then
      vim.api.nvim_win_close(field.window, true)
    end
  end
end

function next_field(opts)
  if opts.current_field == #opts.fields then
    opts.current_field = 1
  else
    opts.current_field = opts.current_field + 1
  end
  vim.api.nvim_set_current_win(opts.fields[opts.current_field].window)
end

function previous_field(opts)
  if opts.current_field == 1 then
    opts.current_field = #opts.fields
  else
    opts.current_field = opts.current_field - 1
  end
  vim.api.nvim_set_current_win(opts.fields[opts.current_field].window)
end

function add_field(opts, form_opts)
  opts = opts or {}

  local name = opts.name or ''
  local width = opts.width or 50
  local height = opts.height or 1
  local col = (vim.o.columns - width) / 2 -- 0 es la parte de arriba
  local row = vim.o.lines / 2
  for _, field in ipairs(form_opts.fields) do
    row = row + 2 + field.height
  end

  local buf = vim.api.nvim_create_buf(false, true)
  if opts.init then
    opts.init(buf, opts.init_config or {})
  end

  local window_opts = {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    border = 'rounded',
    title = name,
  }

  local win = vim.api.nvim_open_win(buf, false, window_opts)

  vim.keymap.set('n', 'q', function()
    form_opts.on_close()
  end, {
    desc = 'Close floating window.',
    buffer = buf,
  })

  vim.keymap.set('n', '<C-j>', function()
    next_field(form_opts)
  end, {
    desc = 'Focus next field.',
    buffer = buf,
  })

  vim.keymap.set('n', '<C-k>', function()
    previous_field(form_opts)
  end, {
    desc = 'Focus previous field.',
    buffer = buf,
  })

  local previous_buffer = -1
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    callback = function()
      previous_buffer = vim.fn.bufnr()
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    callback = function()
      local current_buffer = vim.fn.bufnr()
      local was_in_current_form = false
      for _, field in ipairs(form_opts.fields) do
        if previous_buffer == field.buf then
          was_in_current_form = true
          break
        end
      end

      if not was_in_current_form then
        return
      end

      for _, field in ipairs(form_opts.fields) do
        if current_buffer == field.buf then
          return
        end
      end
      form_opts.on_close()
    end,
  })

  return {
    name = name,
    height = height,
    window = win,
    buf = buf,
  }
end

function create_form(opts)
  local form_fields = opts.fields or {}

  local form_opts = {
    fields = {},
    current_field = 1,
  }
  function on_close()
    close_fields(form_opts.fields)
    form_opts.fields = {}
  end
  form_opts.on_close = on_close

  for _, field in ipairs(form_fields) do
    local new_field = add_field(field, form_opts)
    table.insert(form_opts.fields, new_field)
  end

  function submit()
    if not opts.on_submit then
      on_close()
      return
    end

    local result = {}
    for _, field in ipairs(form_opts.fields) do
      local lines = vim.api.nvim_buf_get_lines(field.buf, 0, -1, false)
      local content = table.concat(lines, '\n')
      table.insert(result, {
        name = field.name,
        content = content,
      })
    end

    opts.on_submit(result)
    on_close()
  end

  for _, field in ipairs(form_opts.fields) do
    vim.keymap.set('n', '<Enter>', submit, {
      desc = 'Submit',
      buffer = field.buf,
    })
  end

  vim.api.nvim_set_current_win(form_opts.fields[form_opts.current_field].window)
end

function parse_buf_time(buf)
  local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]

  local start_hours = string.sub(line, 1, 2)
  local start_minutes = string.sub(line, 4, 5)
  local start_timestamp = tonumber(start_hours) * 60 + tonumber(start_minutes)

  local end_hours = string.sub(line, 9, 10)
  local end_minutes = string.sub(line, 12, 13)
  local end_timestamp = tonumber(end_hours) * 60 + tonumber(end_minutes)

  local current_word = vim.fn.expand '<cWORD>'
  local colon_location = string.find(current_word, ':')
  if not colon_location then
    return
  end

  local cursor_location = vim.api.nvim_win_get_cursor(0)[2]
  local changing_time = 'end'
  if cursor_location < 7 then
    changing_time = 'start'
  end

  local changing_part = 'minutes'
  if cursor_location < 3 or (cursor_location >= 7 and cursor_location < 11) then
    changing_part = 'hours'
  end

  return {
    start_timestamp = start_timestamp,
    end_timestamp = end_timestamp,
    changing_time = changing_time,
    changing_part = changing_part,
  }
end

function update_times(buf, start_timestamp, end_timestamp)
  local start_hour = math.floor(start_timestamp / 60)
  local start_minutes = start_timestamp - start_hour * 60
  local end_hour = math.floor(end_timestamp / 60)
  local end_minutes = end_timestamp - end_hour * 60

  local updated_time = string.format('%02d:%02d - %02d:%02d', start_hour, start_minutes, end_hour, end_minutes)

  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { updated_time })
end

function increase_timestamp(timestamp, increase)
  return math.min(math.floor((timestamp / 15)) * 15 + increase, MAX_TIMESTAMP)
end

function decrease_timestamp(timestamp, decrease)
  return math.max(math.ceil((timestamp / 15)) * 15 - decrease, MIN_TIMESTAMP)
end

function initialize_section_selector(buf, opts)
  local sections = opts.sections
  local current_section = opts.current_section or 1

  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { sections[current_section] })

  vim.keymap.set('n', '<Tab>', function()
    current_section = current_section + 1
    if current_section > #sections then
      current_section = 1
    end
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { sections[current_section] })
  end, { buffer = buf })

  vim.keymap.set('n', '<S-Tab>', function()
    current_section = current_section - 1
    if current_section == 0 then
      current_section = #sections
    end
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { sections[current_section] })
  end, { buffer = buf })
end

function initialize_time_selector(buf, opts)
  if opts.sections then
    initialize_section_selector(buf, opts)
  else
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { opts.initial_time })
  end

  vim.keymap.set('n', '+', function()
    local parsed_time = parse_buf_time(buf)
    if not parsed_time then
      return
    end

    local start_timestamp = parsed_time.start_timestamp
    local end_timestamp = parsed_time.end_timestamp
    local increase = (parsed_time.changing_part == 'hours' and ONE_HOUR) or FIFTEEN_MINUTES
    if parsed_time.changing_time == 'start' then
      start_timestamp = increase_timestamp(start_timestamp, increase)
    end
    if parsed_time.changing_time == 'end' then
      end_timestamp = increase_timestamp(end_timestamp, increase)
    end
    if start_timestamp >= end_timestamp then
      end_timestamp = increase_timestamp(end_timestamp, increase)
    end
    update_times(buf, start_timestamp, end_timestamp)
  end, { buffer = buf })

  vim.keymap.set('n', '-', function()
    local parsed_time = parse_buf_time(buf)
    if not parsed_time then
      return
    end

    local start_timestamp = parsed_time.start_timestamp
    local end_timestamp = parsed_time.end_timestamp
    local decrease = (parsed_time.changing_part == 'hours' and ONE_HOUR) or FIFTEEN_MINUTES
    if parsed_time.changing_time == 'end' then
      end_timestamp = decrease_timestamp(end_timestamp, decrease)
    end
    if parsed_time.changing_time == 'start' then
      start_timestamp = decrease_timestamp(start_timestamp, decrease)
    end
    if start_timestamp >= end_timestamp then
      start_timestamp = decrease_timestamp(start_timestamp, decrease)
    end
    update_times(buf, start_timestamp, end_timestamp)
  end, { buffer = buf })
end

function escape_shell_arg(arg)
  return string.gsub(arg, '(["\'])', '%1')
end

function open_weekly_note()
  local weekly_output = io.popen 'tamal --weekly'
  local file_path = weekly_output:read()

  local day_numbers_output = io.popen 'tamal --day-line-numbers'
  local day_lines = {}
  local day_line = day_numbers_output:read()
  while day_line do
    local parts = vim.split(day_line, ',')
    day_lines[parts[2]] = tonumber(parts[1])
    day_line = day_numbers_output:read()
  end
  local todays_line = day_lines[os.date '%a']
  if not todays_line then
    return
  end
  open_file_in_floating_window(file_path, line)
end

function select_file(opts)
  if not opts.on_select then
    return
  end
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local directory = opts.directory or vim.uv.cwd()
  require('telescope.builtin').find_files {
    cwd = directory,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        opts.on_select(directory .. selection[1])
      end)
      return true
    end,
  }
end

function open_file_in_floating_window(file, line)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 80
  local height = math.floor(vim.o.lines * 0.8)
  local col = (vim.o.columns - width) / 2 -- 0 es la parte de arriba
  local row = (vim.o.lines - height) / 2
  line = line or 0

  local window_opts = {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    border = 'rounded',
    title = file,
  }

  local win = vim.api.nvim_open_win(buf, true, window_opts)
  local lines = vim.fn.readfile(file)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(buf, 'textwidth', 80)
  vim.api.nvim_buf_set_option(buf, 'wrap', true)

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, {
    desc = 'Close floating window.',
    buffer = buf,
  })

  vim.api.nvim_win_set_cursor(win, { line, 0 })

  return {
    buf = buf,
    win = win,
  }
end

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local conf = require('telescope.config').values

local live_multigrep = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == '' then
        return nil
      end

      local parts = vim.split(prompt, '  ')
      local args = { 'rg' }

      for i, part in ipairs(parts) do
        if i == 1 then
          table.insert(args, '-e')
          table.insert(args, part)
        elseif i == 2 then
          table.insert(args, '-g')
          table.insert(args, part)
        else
          table.insert(args, part)
        end
      end

      return vim.tbl_flatten {
        args,
        { '--color=never', '--no-heading', '--with-filename', '--line-number', '--column', '--smart-case' },
      }
    end,
    on_select = function(file)
      print('Selected ' .. file)
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  local picker_opts = {
    debounce = 100,
    prompt_title = opts.title or 'Search',
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require('telescope.sorters').empty(),
  }

  -- Add custom selection handling if provided
  if opts.on_select then
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    picker_opts.attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local file_path = selection.filename
          local line_nr = selection.lnum
          local col_nr = selection.col
          opts.on_select(opts.cwd .. file_path, line_nr, col_nr)
        end
      end)
      return true
    end
  end

  pickers.new(opts, picker_opts):find()
end

-- Tamal Actions
function search_zendesk_note()
  live_multigrep {
    title = 'Zendesk Notes',
    cwd = vim.fn.expand '~/notes/zendesk/',
    on_select = open_file_in_floating_window,
  }
end

function open_note()
  select_file {
    directory = vim.fn.expand '~/notes/',
    on_select = open_file_in_floating_window,
  }
end

function open_zendesk_note()
  select_file {
    directory = vim.fn.expand '~/notes/zendesk',
    on_select = open_file_in_floating_window,
  }
end

function add_three_p_note()
  create_form {
    fields = {
      {
        name = 'Section',
        init = initialize_section_selector,
        init_config = {
          sections = { 'Progress', 'Planned', 'Problems' },
        },
      },
      {
        name = 'Notes',
        height = 5,
      },
    },
    on_submit = function(values)
      local section = escape_shell_arg(values[1].content)
      local note = escape_shell_arg(values[2].content)

      os.execute(string.format('tamal --three-p %s --note "%s"', section, note))
    end,
  }
end

function extract_zendesk_id(file_path)
  local id_start, id_end = string.find(file_path, '%d+')
  return string.sub(file_path, id_start, id_end)
end

function create_zendesk_note()
  create_form {
    fields = {
      {
        name = 'Ticket Link',
      },
      {
        name = 'User Name',
      },
      {
        name = 'User Link',
      },
      {
        name = 'Account Name',
      },
      {
        name = 'Account Link',
      },
    },
    on_submit = function(values)
      local ticket_link = escape_shell_arg(values[1].content)
      local ticket_id = escape_shell_arg(extract_zendesk_id(values[1].content))
      local user_name = escape_shell_arg(values[2].content)
      local user_link = escape_shell_arg(values[3].content)
      local account_name = escape_shell_arg(values[4].content)
      local account_link = escape_shell_arg(values[5].content)

      os.execute(
        string.format(
          'tamal --zendesk %s --ticket_link %s --user-name %s --user-link %s --account-name %s --account-link %s',
          ticket_id,
          ticket_link,
          user_name,
          user_link,
          account_name,
          account_link
        )
      )
    end,
  }
end

function add_zendesk_note()
  function on_select(file)
    local note_id = extract_zendesk_id(file)
    if not note_id or note_id == '' then
      return
    end

    create_form {
      fields = {
        {
          name = 'Section',
          init = initialize_section_selector,
          init_config = {
            sections = { 'Description', 'Hypothesis', 'Investigation', 'Notes', 'Resolution' },
            current_section = 4,
          },
        },
        {
          name = 'Note',
          height = 5,
        },
      },
      on_submit = function(values)
        local section = escape_shell_arg(values[1].content)
        local note = escape_shell_arg(values[2].content)
        os.execute(string.format('tamal --zendesk %s --note "%s" --section %s', note_id, note, section))
      end,
    }
  end
  select_file {
    directory = vim.fn.expand '~/notes/zendesk/',
    on_select = on_select,
  }
end

function add_task()
  local time_blocks_output = io.popen 'tamal --time-blocks'
  local time_blocks = {}
  local time_block = time_blocks_output:read()
  while time_block do
    table.insert(time_blocks, time_block)
    time_block = time_blocks_output:read()
  end

  create_form {
    fields = {
      {
        name = 'Time block',
        init = initialize_time_selector,
        init_config = {
          sections = time_blocks,
        },
      },
      {
        name = 'Task',
      },
    },
    on_submit = function(values)
      local task = escape_shell_arg(values[2].content)
      local time_parts = vim.split(values[1].content, '-')
      local start_time = escape_shell_arg(vim.trim(time_parts[1]))
      os.execute(string.format('tamal --add-task "%s" --time %s', task, start_time))
    end,
  }
end

function add_note()
  local time_blocks_output = io.popen 'tamal --time-blocks'
  local time_blocks = {}
  local time_block = time_blocks_output:read()
  while time_block do
    table.insert(time_blocks, time_block)
    time_block = time_blocks_output:read()
  end

  create_form {
    fields = {
      {
        name = 'Time block',
        init = initialize_time_selector,
        init_config = {
          sections = time_blocks,
        },
      },
      {
        name = 'Note',
        height = 5,
      },
    },
    on_submit = function(values)
      local task = escape_shell_arg(values[2].content)
      local time_parts = vim.split(values[1].content, '-')
      local start_time = escape_shell_arg(vim.trim(time_parts[1]))
      local end_time = escape_shell_arg(vim.trim(time_parts[2]))
      os.execute(string.format('tamal --note "%s" --start-time %s --end-time %s', task, start_time, end_time))
    end,
  }
end

function initialize_task_manager(buf, opts)
  local tasks = opts.tasks or {}
  local status_sequence = { 'pending', 'done', 'canceled' }
  local status_char = {
    pending = '',
    done = '',
    canceled = '',
  }

  function update_task_list(tasks)
    for i, task in ipairs(tasks) do
      local display_task = string.format('%s %s', status_char[task.status], task.task)
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { display_task })
    end
  end
  update_task_list(tasks)

  vim.keymap.set('n', '<Tab>', function()
    local cursor_location = vim.api.nvim_win_get_cursor(0)[1]
    local current_task = tasks[cursor_location]
    if not current_task then
      return
    end

    local current_sequence_index = -1
    for i, v in ipairs(status_sequence) do
      if current_task.status == v then
        current_sequence_index = i
        break
      end
    end

    local next_sequence_index = current_sequence_index < #status_sequence and current_sequence_index + 1 or 1
    current_task.status = status_sequence[next_sequence_index]
    os.execute(string.format('tamal --update-task "%s" --status %s', current_task.task, current_task.status))

    update_task_list(tasks)
  end, { buffer = buf })
end

function tasks()
  local tasks_output = io.popen 'tamal --tasks'
  local tasks = {}
  local task = tasks_output:read()
  while task do
    local task_parts = vim.split(task, ',')
    table.insert(tasks, {
      status = task_parts[1],
      task = task_parts[2],
    })
    task = tasks_output:read()
  end

  create_form {
    fields = {
      {
        name = 'Tasks',
        init = initialize_task_manager,
        height = 10,
        init_config = {
          tasks = tasks,
        },
      },
    },
  }
end

vim.keymap.set('n', '<leader>Tw', open_weekly_note, { desc = 'Open weekly note' })
vim.keymap.set('n', '<leader>Ta', add_task, { desc = 'Add task' })
vim.keymap.set('n', '<leader>Tt', tasks, { desc = 'View tasks' })
vim.keymap.set('n', '<leader>Tn', add_note, { desc = 'Add note' })

vim.keymap.set('n', '<leader>To', open_note, { desc = 'Open note' })
vim.keymap.set('n', '<leader>Tza', add_zendesk_note, { desc = 'Add zendesk note' })
vim.keymap.set('n', '<leader>Tzs', search_zendesk_note, { desc = 'Add zendesk note' })
vim.keymap.set('n', '<leader>Tzo', open_zendesk_note, { desc = 'Open zendesk note' })
vim.keymap.set('n', '<leader>TZ', create_zendesk_note, { desc = 'Create zendesk note' })

vim.keymap.set('n', '<leader>Tp', add_three_p_note, { desc = 'Add 3P note' })

return {}
