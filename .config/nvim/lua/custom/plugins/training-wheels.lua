local PLUGIN_DIR = os.getenv 'HOME' .. '/Projects/training-wheels.nvim'

if (vim.uv or vim.lop).fs_stat(PLUGIN_DIR) then
  return {
    {
      dir = PLUGIN_DIR,
      opts = {
        wheels_path = os.getenv 'HOME' .. '/Projects/wheels',
        default_wheel = '01',
      },
    },
  }
end

return {}
