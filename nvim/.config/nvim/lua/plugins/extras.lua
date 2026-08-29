local function leet(command)
  local info = vim.api.nvim_get_commands({}).Leet

  -- First launch: initialize leetcode.nvim.
  if not info or info.nargs == '0' then
    vim.cmd 'Leet'
  end

  local attempts = 0

  local function run_when_ready()
    local config = require 'leetcode.config'

    if config.auth and config.auth.is_signed_in then
      vim.cmd('Leet ' .. command)
      return
    end

    attempts = attempts + 1

    if attempts >= 100 then
      vim.notify('LeetCode authentication timed out', vim.log.levels.ERROR)
      return
    end

    vim.defer_fn(run_when_ready, 100)
  end

  run_when_ready()
end

return {
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<leader>e', '<cmd>NvimTreeToggle<cr>', desc = '[E]xplore Tree' },
    },
    opts = {
      actions = {
        open_file = {
          window_picker = {
            enable = false,
          },
        },
      },
    },
  },

  {
    '42Paris/42header',
    cmd = 'Stdheader',
    keys = {
      { '<leader>H', '<cmd>Stdheader<cr>', desc = '42 [H]eader' },
    },
  },
  {
    'alex-popov-tech/store.nvim',
    dependencies = {
      'OXY2DEV/markview.nvim', -- optional, for pretty readme preview / help window
    },
    cmd = 'Store',
    keys = {
      { '<leader>os', '<cmd>Store<cr>', desc = '[O]pen Plugin [S]tore' },
    },
    opts = {
      -- optional configuration here
    },
  },
  {
    'rmagatti/goto-preview',
    opts = {},
    keys = {
      {
        '<leader>gpd',
        function()
          require('goto-preview').goto_preview_definition()
        end,
        desc = '[G]oto [P]review [D]efinition',
      },
      {
        '<leader>gpD',
        function()
          require('goto-preview').goto_preview_declaration()
        end,
        desc = '[G]oto [P]review [D]eclaration',
      },
      {
        '<leader>gpi',
        function()
          require('goto-preview').goto_preview_implementation()
        end,
        desc = '[G]oto [P]review [I]mplementation',
      },
      {
        '<leader>gpt',
        function()
          require('goto-preview').goto_preview_type_definition()
        end,
        desc = '[G]oto [P]review [T]ype definition',
      },
      {
        '<leader>gpr',
        function()
          require('goto-preview').goto_preview_references()
        end,
        desc = '[G]oto [P]review [R]eferences',
      },
      {
        '<leader>gpc',
        function()
          require('goto-preview').close_all_win()
        end,
        desc = '[G]oto [P]review [C]lose all preview windows',
      },
    },
  },
  {
    'kawre/leetcode.nvim',

    cmd = 'Leet',

    build = ':TSUpdate html',

    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },

    keys = {
      {
        '<leader>ll',
        function()
          leet 'list'
        end,
        desc = '[L]eetCode [L]ist',
      },
      {
        '<leader>lr',
        function()
          leet 'run'
        end,
        desc = '[L]eetCode [R]un',
      },
      {
        '<leader>ls',
        function()
          leet 'submit'
        end,
        desc = '[L]eetCode [S]ubmit',
      },
      {
        '<leader>lc',
        function()
          leet 'console'
        end,
        desc = '[L]eetCode [C]onsole',
      },
      {
        '<leader>ld',
        function()
          leet 'daily'
        end,
        desc = '[L]eetCode [D]aily',
      },
      {
        '<leader>lt',
        function()
          leet 'tabs'
        end,
        desc = '[L]eetCode [T]abs',
      },
      {
        '<leader>li',
        function()
          leet 'info'
        end,
        desc = '[L]eetCode [I]nfo',
      },
      {
        '<leader>lo',
        function()
          leet 'open'
        end,
        desc = '[L]eetCode [O]pen in browser',
      },
      {
        '<leader>lD',
        function()
          leet 'desc'
        end,
        desc = '[L]eetCode [D]escription',
      },
      {
        '<leader>lm',
        function()
          leet 'menu'
        end,
        desc = '[L]eetCode [M]enu',
      },
    },

    opts = {
      lang = 'c',
      picker = {
        provider = 'telescope',
      },

      plugins = {
        non_standalone = true,
      },
    },
  },
  { 'mg979/vim-visual-multi', event = 'VeryLazy' },
}
