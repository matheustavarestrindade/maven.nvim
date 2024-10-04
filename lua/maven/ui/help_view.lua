local NuiPopup = require('nui.popup')
local NuiLine = require('nui.line')
local event = require('nui.utils.autocmd').event
local highlights = require('maven.highlights')
local MavenConfig = require('maven.config')
local M = {}

local help_keys = {
  { key = 'E', desc = 'Execute mvn command' },
  { key = 'D', desc = '[Projects] analyze dependencies' },
  { key = '/, s', desc = '[Dependencies] search' },
  { key = '<Ctrl>s', desc = '[Dependencies] switch window' },
  { key = '<Esc>, q', desc = 'Close' },
}

M.mount = function()
  local popup = NuiPopup({
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
      style = 'rounded',
      text = {
        top = ' Maven Help? ',
        top_align = 'center',
      },
    },
    size = {
      width = '80%',
      height = '20%',
    },
  })

  popup:mount()

  popup:on(event.BufLeave, function()
    popup:unmount()
  end)
  popup:map('n', { '<esc>', 'q' }, function()
    popup:unmount()
  end)
  local keys_header = NuiLine()
  keys_header:append(string.format(' %14s', 'KEY(S)'), highlights.SPECIAL_TITLE)
  keys_header:append('    ', highlights.DIM_TEXT)
  keys_header:append('COMMAND', highlights.SPECIAL_TITLE)
  keys_header:render(popup.bufnr, MavenConfig.namespace, 2)
  for index, value in pairs(help_keys) do
    local line = NuiLine()
    line:append(string.format(' %14s', value.key), highlights.SPECIAL_TEXT)
    line:append(' -> ', highlights.DIM_TEXT)
    line:append(value.desc)
    line:render(popup.bufnr, MavenConfig.namespace, index + 2)
  end
end

return M
