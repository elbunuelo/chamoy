local PLUGIN_DIR = os.getenv 'HOME' .. '/Projects/aha.nvim'

if (vim.uv or vim.lop).fs_stat(PLUGIN_DIR) then
  return {
    { dir = PLUGIN_DIR },
  }
end

return {}
