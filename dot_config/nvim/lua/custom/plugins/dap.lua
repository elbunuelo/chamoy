-- Reapply DAP highlight groups after colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  desc = "prevent colorscheme clears self-defined DAP icon colors.",
  callback = function()
    local sign_column_hl = vim.api.nvim_get_hl(0, { name = 'SignColumn' })
    local sign_column_bg = (sign_column_hl.bg ~= nil) and ('#%06x'):format(sign_column_hl.bg) or 'bg'
    local sign_column_ctermbg = (sign_column_hl.ctermbg ~= nil) and sign_column_hl.ctermbg or 'Black'

    vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#00ff00', bg = sign_column_bg, ctermbg = sign_column_ctermbg })
    vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#2e4d3d', ctermbg = 'Green' })
    vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#c23127', bg = sign_column_bg, ctermbg = sign_column_ctermbg })
    vim.api.nvim_set_hl(0, 'DapBreakpointRejected',
      { fg = '#888ca6', bg = sign_column_bg, ctermbg = sign_column_ctermbg })
    vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#61afef', bg = sign_column_bg, ctermbg = sign_column_ctermbg })
  end
})

vim.fn.sign_define('DapBreakpoint', {
  text = '⟿',
  texthl = 'DapBreakpoint',
  linehl = 'DapBreakpoint',
  numhl = 'DapBreakpoint',
})
vim.fn.sign_define('DapBreakpointCondition',
  { text = 'ﳁ', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
vim.fn.sign_define('DapBreakpointRejected',
  { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
vim.fn.sign_define('DapLogPoint',
  { text = '', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
vim.fn.sign_define('DapStopped',
  { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })

return {

  -- Build dependency: JS debug adapter compiled from source
  {
    "microsoft/vscode-js-debug",
    version = "1.x",
    build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
    lazy = true,
  },

  -- Inline virtual text for variable values during debug
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
  },

  -- Debug UI panels
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end,     desc = "Eval", mode = { "n", "v" } },
    },
  },

  -- Main DAP engine + JS/TS configuration
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mxsdev/nvim-dap-vscode-js",
      "microsoft/vscode-js-debug",
      "rcarriga/nvim-dap-ui",
    },
    keys = {
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,         desc = "Continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end,    desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end,            desc = "Go to Line (No Execute)" },
      { "<leader>di", function() require("dap").step_into() end,        desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end,             desc = "Down" },
      { "<leader>dk", function() require("dap").up() end,               desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end,         desc = "Run Last" },
      { "<leader>do", function() require("dap").step_out() end,         desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end,        desc = "Step Over" },
      { "<leader>dp", function() require("dap").pause() end,            desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end,      desc = "Toggle REPL" },
      { "<leader>dS", function() require("dap").session() end,          desc = "Session" },
      { "<leader>dt", function() require("dap").terminate() end,        desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
      })

      for _, language in ipairs({ "typescript", "javascript", "svelte", "vue", "typescriptreact" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "attach",
            processId = require('dap.utils').pick_process,
            name = "Attach debugger to existing `node --inspect` process",
            sourceMaps = true,
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
              "!**/node_modules/**",
            },
            cwd = "${workspaceFolder}/src",
            skipFiles = { "${workspaceFolder}/node_modules/**/*.js" },
            localRoot = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            name = "Launch Chrome to debug client",
            request = "launch",
            url = "http://localhost:5173",
            sourceMaps = true,
            protocol = "inspector",
            port = 9222,
            webRoot = "${workspaceFolder}/src",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            name = "Debug Editor",
            request = "launch",
            url = "http://localhost:8000",
            sourceMaps = true,
            protocol = "inspector",
            port = 9222,
            webRoot = "${workspaceFolder}/examples/demo",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            name = "Debug Aha",
            request = "launch",
            url = "https://reallybigaha.ahalocalhost.com:3000",
            sourceMaps = true,
            protocol = "inspector",
            port = 9222,
            webRoot = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
          },
        }
      end

      dapui.setup()
      dap.set_log_level("WARN")

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({ reset = true })
      end
      dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      dap.listeners.before.event_exited["dapui_config"] = dapui.close
    end,
  },
}
