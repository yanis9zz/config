local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>m', vim.diagnostic.open_float, { desc = 'Show diagnostic [M]essage' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<left>', '<cmd>echo "Use h to move"<CR>')
map('n', '<right>', '<cmd>echo "Use l to move"<CR>')
map('n', '<up>', '<cmd>echo "Use k to move"<CR>')
map('n', '<down>', '<cmd>echo "Use j to move"<CR>')

map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus left' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus right' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus down' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus up' })
map('n', '<C-S-h>', '<C-w>H', { desc = 'Move window left' })
map('n', '<C-S-l>', '<C-w>L', { desc = 'Move window right' })
map('n', '<C-S-j>', '<C-w>J', { desc = 'Move window down' })
map('n', '<C-S-k>', '<C-w>K', { desc = 'Move window up' })

map('n', '<leader>ol', function()
  vim.cmd 'only'
  vim.cmd 'vsplit'
  vim.cmd 'wincmd l'
  vim.cmd 'split'
  vim.cmd 'wincmd k'
  vim.cmd 'resize 12'
  vim.cmd 'terminal'
  vim.cmd 'wincmd j'
  vim.cmd 'wincmd h'
end, { desc = '[O]pen [L]ayout (term top right)' })

local open_codex = function()
  require('config.codex').open()
end

map({ 'n', 't' }, '<leader>cc', open_codex, { desc = 'Open [C]odex CLI' })
map({ 'n', 't' }, '<leader>cw', open_codex, { desc = 'Open [C]odex CLI (compatibility)' })
