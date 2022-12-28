local M = {}

function M.load_template()
  if not vim.bo.modifiable then
    return
  end
  local name = vim.fn.expand('%:t')
  local type = vim.fn.expand('%:t:r:e')
  local ext = vim.fn.expand('%:e')

  local dir = vim.env.HOME .. '/.config/nvim/templates'

  local tpls = {
    ('%s/%s'):format(dir, name),
    ('%s/template.%s.%s'):format(dir, type, ext),
    ('%s/template.%s'):format(dir, ext),
  }

  for _, tpl in ipairs(tpls) do
    if vim.fn.filereadable(tpl) ~= 0 then
      vim.cmd('0read ' .. tpl)

      -- replace: {{ dirname }}
      vim.cmd('silent s/{{%s*dirname%s*}}/' .. vim.fn.expand('%:p:h:t') .. '/ge')

      local content = vim.fn.join(vim.fn.getline(1, '$'), '\n')

      -- replace: {{ expand: %:r }}
      for k, pattern in content:gmatch('({{%s*expand:([^}]+)%s*}})') do
        vim.cmd(('silent s#%s#%s#ge'):format(k, vim.fn.expand(pattern)))
      end

      -- replace: {{ lua:vim.fn.system('date') }}
      for k, code in content:gmatch('({{%s*lua:([^}]*)%s*}})') do
        local fn = loadstring('return ' .. code)
        if fn ~= nil then
          local ok, replace = pcall(fn)
          if ok then
            pcall(vim.cmd, ('silent %%s#%s#%s#ge'):format(k, vim.fn.trim(replace)))
          end
        end
      end

      break
    end
  end
end

vim.api.nvim_create_autocmd({ 'BufNewFile' }, {
  callback = function()
    M.load_template()
  end,
})
