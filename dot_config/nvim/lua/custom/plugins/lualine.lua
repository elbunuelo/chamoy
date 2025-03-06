return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = function(_, opts)
    opts.icons_enabled = true;
    opts.theme = 'onedark';
    opts.component_separators = { left = '', right = '' }
    opts.section_separators = { left = '', right = '' }
    opts.sections = {
      lualine_x = { require("capslock").status_string },
    }
  end
}
