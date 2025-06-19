-- tamal/init.lua: Main entry point for the tamal plugin

local ui_utils = require("tamal.ui_utils")
local commands = require("tamal.commands")

-- Tamal commands and their descriptions
local tamal_commands = {
  { cmd = "add-task", desc = "Add a new task", height = 1, key = "a" },
  { cmd = "tasks", desc = "View tasks", height = 15, key = "t" },
  { cmd = "weekly", desc = "Open weekly note", height = 0, key = "w", use_note_path = true },
  { cmd = "open", desc = "Open a note", height = 0, key = "o", use_telescope = true },
  { cmd = "add-note", desc = "Add a note", height = 15, key = "n", needs_time_block = true },
  { cmd = "three-p", desc = "Add a 3P note", height = 15, key = "p" },
  { cmd = "zendesk", desc = "Create Zendesk ticket note", height = 0, key = "zc", needs_ticket_id = true },
  {
    cmd = "zendesk-note",
    desc = "Add note to Zendesk ticket",
    height = 15,
    key = "Z",
    needs_section = true,
    use_zendesk_telescope = true,
  },
  {
    cmd = "open-zendesk",
    desc = "Open existing Zendesk note",
    height = 0,
    key = "zz",
    use_zendesk_telescope = true,
    open_only = true,
  },
}

local M = {}

function M.setup()
  -- Create Vim commands for each Tamal function
  for _, cmd_info in ipairs(tamal_commands) do
    -- Create command name from the cmd field (e.g., 'add-task' -> 'TamalAddTask')
    local command_name = "Tamal"
      .. cmd_info.cmd:gsub("^%l", string.upper):gsub("%-(%l)", function(c)
        return c:upper()
      end)

    -- Register the command
    vim.api.nvim_create_user_command(command_name, function()
      commands.open_tamal_popup(cmd_info)
    end, { desc = "Tamal: " .. cmd_info.desc })

    -- Create mnemonic keybinding with <leader>T prefix
    vim.keymap.set("n", "<leader>T" .. cmd_info.key, function()
      commands.open_tamal_popup(cmd_info)
    end, { desc = "Tamal: " .. cmd_info.desc, silent = true })

    -- Add visual mode keybindings for add-note, three-p, and zendesk-note
    if cmd_info.cmd == "add-note" or cmd_info.cmd == "three-p" or cmd_info.cmd == "zendesk-note" then
      vim.keymap.set("v", "<leader>T" .. cmd_info.key, function()
        -- Get the selected text
        local selected_text = ui_utils.get_visual_selection()
        -- Clear the visual selection
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
        -- Open the popup with the selected text
        commands.open_tamal_popup(cmd_info, selected_text)
      end, { desc = "Tamal: " .. cmd_info.desc .. " with selection", silent = true })
    end
  end
end

return M
