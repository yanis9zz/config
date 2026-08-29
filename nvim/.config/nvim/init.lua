vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- These optional providers are not used by this configuration.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

require 'config.options'
require 'config.keymaps'
require 'config.lazy'
