-- Plugin: tamal.lua
-- Description: Interface for the tamal task management system with mnemonic keybindings

return {
  -- No dependencies needed for this plugin
  dependencies = {},

  -- Plugin configuration
  config = function()
    -- Load and setup the tamal plugin
    require('custom.plugins.tamal.init').setup()
  end,
}
