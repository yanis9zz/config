local M = { buffers = {} }

local function project_root()
  return vim.fs.root(0, '.git') or vim.uv.cwd()
end

local function open_native_terminal(root)
  local buffer = M.buffers[root]
  vim.cmd 'botright 15split'

  if buffer and vim.api.nvim_buf_is_valid(buffer) then
    vim.api.nvim_win_set_buf(0, buffer)
  else
    vim.cmd 'enew'
    buffer = vim.api.nvim_get_current_buf()
    M.buffers[root] = buffer
    vim.api.nvim_buf_set_name(buffer, 'codex://' .. root)
    vim.fn.termopen({ 'codex' }, { cwd = root })
  end

  vim.cmd 'startinsert'
end

function M.open()
  if vim.fn.executable 'codex' ~= 1 then
    vim.notify('Codex CLI introuvable. Voir https://developers.openai.com/codex/cli/', vim.log.levels.ERROR)
    return
  end

  local root = project_root()
  local helper = vim.fn.expand '$HOME/config/scripts/codex-popup'

  if vim.env.TMUX and vim.fn.executable 'tmux' == 1 and vim.fn.executable(helper) == 1 then
    local job = vim.fn.jobstart({ helper, root }, { detach = true })
    if job > 0 then
      return
    end

    vim.notify('Impossible de lancer la popup tmux, ouverture dans Neovim.', vim.log.levels.WARN)
  end

  open_native_terminal(root)
end

return M
