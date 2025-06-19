-- commands.lua: Command handling functions for the tamal plugin

local window_manager = require("tamal.window_manager")
local selectors = require("tamal.selectors")
local forms = require("tamal.forms")

local M = {}

-- Function to open notes using Telescope
M.open_note_with_telescope = function()
  local telescope = require("telescope.builtin")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  telescope.find_files({
    prompt_title = "Open Note",
    cwd = "~/notes",
    find_command = { "find", ".", "-type", "f", "-not", "-path", "*/.*", "-printf", "%T@ %p\n", "|", "sort", "-n" },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local file_path = "~/notes/" .. selection.value
          -- Expand the path to handle the tilde
          file_path = vim.fn.expand(file_path)
          window_manager.open_file_in_floating_window(file_path)
        end
      end)
      return true
    end,
  })
end

-- Function to open Zendesk note using Telescope
M.open_zendesk_note_with_telescope = function(command_info)
  local telescope = require("telescope.builtin")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  telescope.find_files({
    prompt_title = "Select Zendesk Note",
    cwd = "~/notes/zendesk",
    find_command = { "find", ".", "-type", "f", "-not", "-path", "*/.*", "-printf", "%T@ %p\n", "|", "sort", "-n" },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          -- Get the full file path
          local file_path = "~/notes/zendesk/" .. selection.value
          -- Expand the path to handle the tilde
          file_path = vim.fn.expand(file_path)

          -- Extract note ID from filename (remove .md extension)
          local note_id = selection.value:gsub("%.md$", "")

          -- If open_only flag is true, just open the file in a floating window
          if command_info.open_only then
            window_manager.open_file_in_floating_window(file_path, false)
            return
          end

          -- We don't want to load the content of the markdown file into the note field
          -- Just extract the note ID from the filename

          -- Create a popup for the section selector and note input
          local width = 80
          local height = 15
          local col = math.floor((vim.o.columns - width) / 2)
          local row = math.floor((vim.o.lines - height) / 2)

          local opts = {
            relative = "editor",
            width = width,
            height = height,
            col = col,
            row = row,
            style = "minimal",
            border = "rounded",
            title = "Zendesk Note: " .. note_id,
          }

          -- Create buffer for the popup
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

          -- Set empty content for user to input the note
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

          -- Create the window with the buffer
          local win = vim.api.nvim_open_win(buf, true, opts)

          -- Set window options
          vim.api.nvim_win_set_option(win, "winblend", 0)
          vim.api.nvim_win_set_option(win, "cursorline", true)

          -- Start in insert mode for the user to input the note content
          vim.cmd("startinsert")

          -- Register this window in the global tracking table
          local window_id = tostring(win)
          window_manager.tamal_window_pairs[window_id] = { note_win = win }

          -- Set keybindings for the popup
          local keymap_opts = { noremap = true, silent = true, buffer = buf }
          vim.keymap.set("n", "q", function()
            window_manager.close_window_pair(window_id)
          end, keymap_opts)

          -- Allow Enter key in insert mode to insert a new line
          vim.keymap.set("i", "<CR>", function()
            return "\n"
          end, { expr = true, noremap = true, silent = true, buffer = buf })

          -- Create section selector for zendesk-note
          local zendesk_section_selector = selectors.create_zendesk_section_selector(win, buf)

          -- Set up Enter key binding to immediately call tamal with the note content
          vim.keymap.set("n", "<CR>", function()
            -- Get the content of the buffer
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local note_content = table.concat(lines, "\n")

            -- Get the selected section
            local selected_section = zendesk_section_selector.get_current_value()

            -- Close the note window and section selector
            window_manager.close_window_pair(window_id)

            -- Build the command with the proper options
            -- We need to use --note to set the note content and --section for the section
            -- The --zendesk option sets the ticket_id
            local cmd = "tamal --zendesk "
              .. note_id
              .. " --section "
              .. selected_section:lower()
              .. " --note "
              .. vim.fn.shellescape(note_content)

            -- Execute the command
            local output = vim.fn.system(cmd)

            -- Show notification of success
            vim.notify("Zendesk note added successfully", vim.log.levels.INFO)
          end, keymap_opts)
        end
      end)
      return true
    end,
  })
end

-- Modified open_tamal_popup to accept initial content
M.open_tamal_popup = function(command_info, initial_content)
  -- Check if this command should use zendesk telescope
  if command_info.use_zendesk_telescope then
    M.open_zendesk_note_with_telescope(command_info)
    return
  end

  -- Check if this command needs a ticket ID input first
  if command_info.needs_ticket_id then
    forms.create_zendesk_options_input(function(options)
      -- For zendesk command, open the ticket note directly
      if command_info.cmd == "zendesk" then
        -- Build the command with all provided options
        local cmd = "tamal --zendesk"

        -- Add ticket_id if provided, otherwise let tamal extract it from ticket_link
        if options.ticket_id and options.ticket_id ~= "" then
          cmd = cmd .. " " .. options.ticket_id
        end

        -- Add all other options
        if options.ticket_link and options.ticket_link ~= "" then
          cmd = cmd .. " --ticket-link " .. vim.fn.shellescape(options.ticket_link)
        end
        if options.user_name and options.user_name ~= "" then
          cmd = cmd .. " --user-name " .. vim.fn.shellescape(options.user_name)
        end
        if options.user_link and options.user_link ~= "" then
          cmd = cmd .. " --user-link " .. vim.fn.shellescape(options.user_link)
        end
        if options.account_name and options.account_name ~= "" then
          cmd = cmd .. " --account-name " .. vim.fn.shellescape(options.account_name)
        end
        if options.account_link and options.account_link ~= "" then
          cmd = cmd .. " --account-link " .. vim.fn.shellescape(options.account_link)
        end

        local file_path = vim.fn.system(cmd):gsub("\n$", "")
        window_manager.open_file_in_floating_window(file_path, false)
      end
    end)
    return
  end

  -- Check if this command should use telescope
  if command_info.use_telescope then
    M.open_note_with_telescope()
    return
  end

  -- Some commands don't need a popup
  if command_info.height == 0 then
    -- If this command should use note path
    if command_info.use_note_path then
      -- Get the path to the note file using the regular command
      local file_path = vim.fn.system("tamal --" .. command_info.cmd):gsub("\n$", "")
      -- Open the file in a floating window (pass true for weekly notes to position cursor)
      window_manager.open_file_in_floating_window(file_path, command_info.cmd == "weekly")
    else
      -- Execute command directly
      vim.fn.system("tamal --" .. command_info.cmd)
      -- Reload the current buffer if it's a real file
      local current_buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_get_name(current_buf) ~= "" then
        vim.cmd("e!")
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
  if command_info.cmd == "three-p" then
    title = ""
  elseif command_info.cmd == "zendesk-note" then
    title = "Zendesk Note for Ticket #" .. command_info.ticket_id
  end

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

  -- Create buffer for the popup
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- If we're viewing tasks, populate with current tasks
  if command_info.cmd == "tasks" then
    -- Get tasks and populate buffer
    local tasks_output = vim.fn.systemlist("tamal --tasks")

    -- Store the original task data for later reference when updating status
    local task_data = {}

    -- Process tasks to add status indicators
    local processed_tasks = {}
    for i, line in ipairs(tasks_output) do
      -- Parse the status and task text (format: "status,task text")
      local status, task_text = line:match("^([^,]+),(.*)$")

      if status then
        -- Map status to ASCII character
        local status_char = ""
        if status == "pending" then
          status_char = " " -- Space for pending
        elseif status == "done" then
          status_char = "x" -- x for done
        elseif status == "canceled" then
          status_char = "~" -- ~ for canceled
        else
          status_char = "?" -- ? for unknown status
        end

        -- Create line with status character and task text
        local modified_line = "[" .. status_char .. "] " .. task_text
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
        vim.notify("Not a task line", vim.log.levels.WARN)
        return
      end

      -- Determine the next status in the cycle
      local next_status = "pending" -- Default fallback
      if task.status == "pending" then
        next_status = "done"
      elseif task.status == "done" then
        next_status = "canceled"
      elseif task.status == "canceled" then
        next_status = "pending"
      end

      -- Update the task status in our data
      task.status = next_status

      -- Update the display with the new status character
      local new_char = "?"
      if next_status == "pending" then
        new_char = " "
      elseif next_status == "done" then
        new_char = "x"
      elseif next_status == "canceled" then
        new_char = "~"
      end

      -- Make the buffer modifiable temporarily
      vim.api.nvim_buf_set_option(buf, "modifiable", true)

      -- Get the current line content
      local line = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1]

      -- Replace the status character in the brackets
      local new_line = "[" .. new_char .. "]" .. line:sub(4) -- Replace character in brackets
      vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, { new_line })

      -- Make the buffer read-only again
      vim.api.nvim_buf_set_option(buf, "modifiable", false)

      -- Update the task status in tamal
      local cmd = 'tamal --update-task "' .. task.text .. '" --status ' .. next_status
      vim.fn.system(cmd)

      -- Show notification
      vim.notify("Task updated to: " .. next_status, vim.log.levels.INFO)
    end

    -- Add Tab key mapping to cycle through task statuses
    vim.keymap.set("n", "<Tab>", cycle_task_status, { noremap = true, silent = true, buffer = buf })

    -- Make the buffer read-only
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  else
    -- For input commands, add initial content if provided
    if initial_content and #initial_content > 0 then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(initial_content, "\n"))
    end
  end

  -- Create the window with the buffer
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, "winblend", 0)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- Register this window in the global tracking table if it's not already there
  local window_id = tostring(win)
  if not window_manager.tamal_window_pairs[window_id] then
    window_manager.tamal_window_pairs[window_id] = { note_win = win }
  end

  -- Set keybindings for the popup
  local keymap_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set("n", "q", function()
    window_manager.close_window_pair(window_id)
  end, keymap_opts)

  -- Allow Enter key in insert mode to insert a new line
  vim.keymap.set("i", "<CR>", function()
    return "\n"
  end, { expr = true, noremap = true, silent = true, buffer = buf })

  -- If it's a read-only view (like tasks)
  if command_info.cmd == "tasks" then
    return { buf = buf, win = win }
  end

  -- Create section selector for three-p command
  local section_selector = nil
  if command_info.cmd == "three-p" then
    section_selector = selectors.create_section_selector(win, buf)
  end

  -- Create section selector for zendesk-note command
  local zendesk_section_selector = nil
  if command_info.cmd == "zendesk-note" and command_info.needs_section then
    zendesk_section_selector = selectors.create_zendesk_section_selector(win, buf)
  end

  -- Create time block selector for commands that need time blocks
  local time_block_selector = nil
  if command_info.cmd == "add-task" or command_info.needs_time_block then
    time_block_selector = selectors.create_time_block_selector(win, buf)
  end

  -- For commands that require input, set up Enter key binding (normal mode only)
  vim.keymap.set("n", "<CR>", function()
    -- Get the content of the buffer
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")

    -- Construct the command
    local cmd = "tamal"

    -- For three-p command, get the selected section and add it as --section argument
    if command_info.cmd == "three-p" and section_selector then
      local selected_section = section_selector.get_current_value()
      cmd = cmd .. " --three-p " .. selected_section:lower() .. " --note " .. vim.fn.shellescape(content)

      -- Use our centralized function to close both windows
      window_manager.close_window_pair(window_id)
    -- For zendesk-note command, get the selected section and add as --section argument
    elseif command_info.cmd == "zendesk-note" and zendesk_section_selector then
      local selected_section = zendesk_section_selector.get_current_value()

      -- Build the command with all provided options
      cmd = "tamal --zendesk"

      -- Add ticket_id if provided, otherwise let tamal extract it from ticket_link
      local options = command_info.zendesk_options
      if options.ticket_id and options.ticket_id ~= "" then
        cmd = cmd .. " " .. options.ticket_id
      end

      -- Add all other options
      if options.ticket_link and options.ticket_link ~= "" then
        cmd = cmd .. " --ticket-link " .. vim.fn.shellescape(options.ticket_link)
      end
      if options.user_name and options.user_name ~= "" then
        cmd = cmd .. " --user-name " .. vim.fn.shellescape(options.user_name)
      end
      if options.user_link and options.user_link ~= "" then
        cmd = cmd .. " --user-link " .. vim.fn.shellescape(options.user_link)
      end
      if options.account_name and options.account_name ~= "" then
        cmd = cmd .. " --account-name " .. vim.fn.shellescape(options.account_name)
      end
      if options.account_link and options.account_link ~= "" then
        cmd = cmd .. " --account-link " .. vim.fn.shellescape(options.account_link)
      end

      -- Add section and note
      cmd = cmd .. " --section " .. selected_section:lower() .. " --note " .. vim.fn.shellescape(content)

      -- Use our centralized function to close both windows
      window_manager.close_window_pair(window_id)
    -- For add-task command, get the selected time block and add start/end time arguments
    elseif command_info.cmd == "add-task" and time_block_selector then
      local start_time, end_time = time_block_selector.parse_value()
      cmd = cmd
        .. " --add-task "
        .. vim.fn.shellescape(content)
        .. ' --start-time "'
        .. start_time
        .. '" --end-time "'
        .. end_time
        .. '"'

      -- Use our centralized function to close all windows
      window_manager.close_window_pair(window_id)
    -- For add-note command, we need the time block too
    elseif command_info.cmd == "add-note" and time_block_selector then
      local start_time, end_time = time_block_selector.parse_value()
      cmd = cmd
        .. " --note "
        .. vim.fn.shellescape(content)
        .. ' --start-time "'
        .. start_time
        .. '" --end-time "'
        .. end_time
        .. '"'

      -- Use our centralized function to close all windows
      window_manager.close_window_pair(window_id)
    else
      -- Add parameter name if specified
      if command_info.param_name then
        cmd = cmd .. " " .. content
      else
        cmd = cmd .. " --" .. command_info.cmd .. " " .. vim.fn.shellescape(content)
      end

      -- Close the input window
      window_manager.close_window_pair(window_id)
    end

    -- If this command should use note path
    if command_info.use_note_path then
      -- For the 'open' command, we need to get the path to the note file
      local file_path = vim.fn.system("tamal --open " .. content):gsub("\n$", "")
      -- Open the file in a floating window
      window_manager.open_file_in_floating_window(file_path, false)
    else
      -- Execute the command
      local output = vim.fn.system(cmd)

      -- For zendesk-note command, open the ticket note after adding the note
      if command_info.cmd == "zendesk-note" then
        -- Build the command with all provided options
        local options = command_info.zendesk_options
        local zendesk_cmd = "tamal --zendesk"

        -- Add ticket_id if provided, otherwise let tamal extract it from ticket_link
        if options.ticket_id and options.ticket_id ~= "" then
          zendesk_cmd = zendesk_cmd .. " " .. options.ticket_id
        end

        -- Add ticket_link option (needed to extract ticket_id if not provided)
        if options.ticket_link and options.ticket_link ~= "" then
          zendesk_cmd = zendesk_cmd .. " --ticket-link " .. vim.fn.shellescape(options.ticket_link)
        end

        local file_path = vim.fn.system(zendesk_cmd):gsub("\n$", "")
        window_manager.open_file_in_floating_window(file_path, false)
      else
        -- Show a notification of success
        local success_message = ""
        if command_info.cmd == "add-task" then
          success_message = "Task added successfully"
        elseif command_info.cmd == "add-note" then
          success_message = "Note added successfully"
        elseif command_info.cmd == "three-p" then
          success_message = "3P note added successfully"
        elseif command_info.cmd == "zendesk-note" then
          success_message = "Zendesk note added successfully"
        else
          success_message = "Command executed successfully"
        end
        vim.notify(success_message, vim.log.levels.INFO)

        -- Reload the current buffer only if it's a real file
        local current_buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_get_name(current_buf) ~= "" then
          pcall(function()
            vim.cmd("e!")
          end)
        end
      end
    end
  end, keymap_opts)

  -- Start in insert mode for commands that need input
  vim.cmd("startinsert")

  -- Return the buffer and window IDs for future reference
  return { buf = buf, win = win }
end

return M
