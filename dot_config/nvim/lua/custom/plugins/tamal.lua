-- Plugin: tamal.lua
-- Description: Interface for the tamal task management system with mnemonic keybindings

return {
  dir = '~/.local/plugins/tamal',
  config = function()
    -- Add the plugin directory to the Lua path
    local plugin_path = vim.fn.expand '~/.local/plugins'
    package.path = package.path .. ';' .. plugin_path .. '/?.lua;' .. plugin_path .. '/?/init.lua'

    require('tamal').setup()
  end,
}
