local PLUGIN_DIR = os.getenv 'HOME' .. '/Projects/training-wheels.nvim'

local wheels_config = {
  wheels_path = os.getenv 'HOME' .. '/Projects/wheels',
  default_wheel = '01',
}

if (vim.uv or vim.lop).fs_stat(PLUGIN_DIR) then
  return {
    {
      dir = PLUGIN_DIR,
      opts = wheels_config,
    },
  }
end

return {
  'elbunuelo/training-wheels',
  opts = wheels_config,
}
