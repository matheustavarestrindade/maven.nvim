local Layout = require('nui.layout')
local Input = require('nui.input')
local Tree = require('nui.tree')
local Line = require('nui.line')
local Text = require('nui.text')
local Popup = require('nui.popup')
local icons = require('maven.ui.icons')
local Sources = require('maven.sources')
local highlights = require('maven.highlights')
local MavenConfig = require('maven.config')
local Utils = require('maven.utils')
local Console = require('maven.utils.console')

---@class Option
---@field name string
---@field description string

local options = {} ---@type Option[]

---@class ExecuteView
---@field private _input_component NuiInput
---@field private _options_component NuiPopup
---@field private _options_tree NuiTree
---@field private _prev_win number
---@field private _default_opts table
---@field private _layout NuiLayout
---@field private _input_prompt NuiText
local ExecuteView = {}
ExecuteView.__index = ExecuteView

---@return ExecuteView
function ExecuteView.new()
  return setmetatable({
    _default_opts = {
      ns_id = MavenConfig.namespace,
      buf_options = {
        buftype = 'nofile',
        swapfile = false,
        filetype = 'maven',
        undolevels = -1,
      },
      win_options = {
        colorcolumn = '',
        signcolumn = 'no',
        number = false,
        relativenumber = false,
        spell = false,
        list = false,
      },
    },
    _prev_win = vim.api.nvim_get_current_win(),
    _input_prompt = Text(icons.default.command .. '  maven ', 'SpecialChar'),
  }, ExecuteView)
end

---Create a option node
---@param option Option
local function create_option_node(option)
  return Tree.Node({ text = option.name, name = option.name, description = option.description })
end

---@private Load options nodes
function ExecuteView:_load_options_nodes()
  Sources.load_help_options(function(state, help_options)
    vim.schedule(function()
      if Utils.SUCCEED_STATE == state then
        table.sort(help_options, function(a, b)
          return a.name < b.name
        end)
        options = help_options
        local options_nodes = {}
        for _, option in ipairs(options) do
          local node = create_option_node(option)
          table.insert(options_nodes, node)
        end
        self._options_tree:set_nodes(options_nodes)
        self._options_tree:render(1)
      end
    end)
  end)
end

---@private Create the options tree list
function ExecuteView:_create_options_tree_list()
  self._options_tree = Tree({
    ns_id = MavenConfig.namespace,
    bufnr = self._options_component.bufnr,
    prepare_node = function(node)
      local line = Line()
      line:append(' ')
      if node.type == 'loading' then
        line:append(node.text, highlights.SPECIAL_TEXT)
        return line
      end
      line:append(icons.default.maven, 'SpecialChar')
      line:append(' ' .. node.text)
      if node.description then
        line:append(' (' .. node.description .. ')', highlights.DIM_TEXT)
      end
      return line
    end,
  })
  self._options_tree:add_node(Tree.Node({ text = '...Loading options', type = 'loading' }))
  self._options_tree:render()
  self:_load_options_nodes()
end

---@private On input change handler
---@param query any
function ExecuteView:_on_input_change(query)
  local current_node = self._options_tree:get_node()
  if query == '' and current_node and current_node.type == 'loading' then
    return
  end
  query = string.match(query, '%s$') and '' or query -- reset if end on space
  query = string.match(query, '(%S+)$') or '' -- take the last option to query
  vim.schedule(function()
    query = string.gsub(query, '%W', '%%%1')
    local nodes = {}
    for _, option in ipairs(options) do
      if query == '' or string.match(option.name, query) then
        local node = create_option_node(option)
        table.insert(nodes, node)
      end
    end
    self._options_tree:set_nodes(nodes)
    self._options_tree:render()
  end)
end

---@private Create the input component
function ExecuteView:_create_input_component()
  self._input_component = Input({
    enter = true,
    ns_id = MavenConfig.namespace,
    relative = 'win',
    position = {
      row = 1,
      col = 0,
    },
    size = {
      width = '100%',
      height = 20,
    },
    zindex = 60,
    border = {
      style = 'rounded',
      text = {
        top = ' Execute Command ',
        top_align = 'center',
      },
    },
  }, {
    prompt = self._input_prompt,
    on_submit = function(value)
      local args = {}
      for item in string.gmatch(value, '[^%s]+') do
        table.insert(args, item)
      end
      Console.execute_command(MavenConfig.options.mvn_executable, args, true, function(state)
        vim.schedule(function()
          if Utils.FAILED_STATE == state then
            vim.notify('Error loading Maven Options', vim.log.levels.ERROR)
          end
        end)
      end)
    end,
    on_change = function(query)
      self:_on_input_change(query)
    end,
  })
  self._input_component:map('i', { '<C-n>', '<Down>' }, function()
    vim.api.nvim_set_current_win(self._options_component.winid)
    vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
  end)
  self._input_component:map('n', { '<esc>', 'q' }, function()
    self._layout:unmount()
    vim.api.nvim_set_current_win(self._prev_win)
  end)
end

---@private Create the options component
function ExecuteView:_create_options_component()
  self._options_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    win_options = { cursorline = true },
    border = {
      style = 'rounded',
    },
  }))
  self:_create_options_tree_list()
  self._options_component:map('n', '<enter>', function()
    local current_node = self._options_tree:get_node()
    if not current_node then
      return
    end
    vim.schedule(function()
      local line_text = vim.api.nvim_buf_get_lines(self._input_component.bufnr, 0, 1, false)[1]
      line_text = string.gsub(line_text, '(%S+)$', '')
      local text = line_text .. current_node.name
      vim.api.nvim_buf_set_lines(self._input_component.bufnr, 0, 1, false, { text })
      self._input_prompt:highlight(self._input_component.bufnr, MavenConfig.namespace, 1, 0)
      vim.api.nvim_set_current_win(self._input_component.winid)
    end)
  end)
  self._options_component:map('n', { '<esc>', 'q' }, function()
    self._layout:unmount()
    vim.api.nvim_set_current_win(self._prev_win)
  end)
end

---@private Crete the layout
function ExecuteView:_create_layout()
  self._layout = Layout(
    {
      ns_id = MavenConfig.namespace,
      relative = 'editor',
      position = '50%',
      size = {
        width = '40%',
        height = '60%',
      },
    },
    Layout.Box({
      Layout.Box(self._input_component, { size = { height = 1, width = '100%' } }),
      Layout.Box(self._options_component, { size = '100%' }),
    }, { dir = 'col' })
  )

  self._layout:mount()
  for _, component in pairs({ self._input_component, self._options_component }) do
    component:on('BufLeave', function()
      vim.schedule(function()
        local current_bufnr = vim.api.nvim_get_current_buf()
        for _, p in pairs({ self._input_component, self._options_component }) do
          if p.bufnr == current_bufnr then
            return
          end
        end
        self._layout:unmount()
      end)
    end)
  end
end

---Mount the window view
function ExecuteView:mount()
  -- crete the list of options
  self:_create_options_component()
  -- create the input component
  self:_create_input_component()
  -- create the layout
  self:_create_layout()
  -- mount the layout
end

return ExecuteView
