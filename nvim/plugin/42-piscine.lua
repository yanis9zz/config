local group = vim.api.nvim_create_augroup('forty_two_piscine', { clear = true })

if vim.fn.executable 'win32yank.exe' == 1 then
  vim.g.clipboard = {
    name = 'win32yank-wsl',
    copy = {
      ['+'] = 'win32yank.exe -i --crlf',
      ['*'] = 'win32yank.exe -i --crlf',
    },
    paste = {
      ['+'] = 'win32yank.exe -o --lf',
      ['*'] = 'win32yank.exe -o --lf',
    },
    cache_enabled = 0,
  }
end

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'c', 'cpp' },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = false
    vim.opt_local.textwidth = 80
    vim.opt_local.colorcolumn = '81'
  end,
})

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  group = group,
  callback = function()
    if vim.bo.filetype ~= 'codex' then
      return
    end

    vim.wo.winfixwidth = true
    pcall(vim.api.nvim_set_option_value, 'winfixbuf', true, { win = 0 })
  end,
})

local function save_current_buffer(require_file)
  if vim.bo.buftype ~= '' then
    return true
  end

  if vim.api.nvim_buf_get_name(0) == '' then
    if require_file then
      vim.notify("Sauvegarde d'abord ce fichier avec :w nom.c", vim.log.levels.WARN)
      return false
    end
    return true
  end

  vim.cmd 'write'
  return true
end

local function run_in_split(command, opts)
  opts = opts or {}
  if not save_current_buffer(opts.require_file) then
    return
  end

  vim.cmd 'botright 12split'
  vim.cmd('terminal ' .. command)
  vim.cmd 'startinsert'
end

vim.keymap.set('n', '<leader>cn', function()
  run_in_split('watch -n 0.1 norminette ' .. vim.fn.shellescape(vim.fn.expand '%:p'), { require_file = true })
end, { desc = '[C] [N]orminette file' })

vim.keymap.set('n', '<leader>cN', function()
  run_in_split 'norminette'
end, { desc = '[C] [N]orminette project' })

vim.keymap.set('n', '<leader>cw', function()
  run_in_split('cc -Wall -Wextra -Werror ' .. vim.fn.shellescape(vim.fn.expand '%:p'), { require_file = true })
end, { desc = '[C] compile with [W]arnings' })

vim.keymap.set('n', '<leader>cv', function()
  run_in_split 'valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./a.out'
end, { desc = '[C] [V]algrind ./a.out' })

vim.keymap.set('n', '<leader>cm', function()
  run_in_split 'make'
end, { desc = '[C] [M]ake' })

vim.keymap.set('n', '<leader>cR', function()
  run_in_split 'make re'
end, { desc = '[C] make [R]e' })
