local M = {}

function M.load_template()
  if not vim.bo.modifiable then
    return
  end
  local name = vim.fn.expand('%:t')
  local ext = vim.fn.expand('%:e')

  local dir = vim.env.HOME .. '/.config/nvim/templates/'
  if vim.fn.filereadable(dir .. name) ~= 0 then
    vim.cmd('0read ' .. dir .. name)
  elseif vim.fn.filereadable(dir .. 'template.' .. ext) ~= 0 then
    vim.cmd('0read ' .. dir .. 'template.' .. ext)
  else
    return
  end

  vim.cmd('silent s/{{dirname}}/' .. vim.fn.expand('%:p:h:t') .. '/ge')
end

vim.api.nvim_create_autocmd({ 'BufNewFile' }, {
  callback = function()
    M.load_template()
  end,
})
