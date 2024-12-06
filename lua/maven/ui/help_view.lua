local NuiPopup = require('nui.popup')
local NuiLine = require('nui.line')
local event = require('nui.utils.autocmd').event
local highlights = require('maven.config.highlights')
local MavenConfig = require('maven.config')
local M = {}

local help_keys = {
  { key = 'c', desc = 'Create a new project' },
  { key = 'e', desc = 'Execute command' },
  { key = 'a', desc = '[Projects] analyze dependencies' },
  { key = '/, s', desc = '[Dependencies] search' },
  { key = '<Ctrl>s', desc = '[Dependencies] switch window' },
  { key = '<Esc>, q', desc = 'Close' },
}

M.mount = function()
  local opts = vim.tbl_deep_extend('force', {
    enter = true,
    ns_id = MavenConfig.namespace,
    relative = 'win',
    position = '50%',
    win_options = {
      cursorline = false,
      scrolloff = 2,
      sidescrolloff = 1,
      cursorcolumn = false,
      colorcolumn = '',
      spell = false,
      list = false,
      wrap = false,
    },
    border = {
      text = {
        top = ' Maven Help? ',
        top_align = 'center',
      },
    },
    size = MavenConfig.options.help_view.size,
  }, { border = MavenConfig.options.help_view.border })
  local popup = NuiPopup(opts)

  popup:mount()

  popup:on(event.BufLeave, function()
    popup:unmount()
  end)
  popup:map('n', { '<esc>', 'q' }, function()
    popup:unmount()
  end)
  local keys_header = NuiLine()
  keys_header:append(string.format(' %14s', 'KEY(S)'), highlights.TITLE)
  keys_header:append('    ', highlights.COMMENT)
  keys_header:append('COMMAND', highlights.TITLE)
  keys_header:render(popup.bufnr, MavenConfig.namespace, 2)
  for index, value in pairs(help_keys) do
    local line = NuiLine()
    line:append(string.format(' %14s', value.key), highlights.SPECIAL)
    line:append(' -> ', highlights.COMMENT)
    line:append(value.desc)
    line:render(popup.bufnr, MavenConfig.namespace, index + 2)
  end
end

return M
