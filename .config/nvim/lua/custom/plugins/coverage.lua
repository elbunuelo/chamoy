return {
  'andythigpen/nvim-coverage',
  version = '*',
  config = function()
    require('coverage').setup {
      commands = true,
      auto_reload = true,
      lcov_file = 'packages/aha-editor-v2/editor_js/lcov.info',
    }
  end,
}
