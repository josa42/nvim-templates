local M = {}

local function trim(str)
  return vim.trim(tostring(str))
end

function M.load_template()
  if not vim.bo.modifiable then
    return
  end
  local name = vim.fn.expand('%:t')
  local type = vim.fn.expand('%:t:r:e')
  local ext = vim.fn.expand('%:e')

  local dir = vim.fs.joinpath(vim.fn.stdpath('config'), 'templates')

  local tpls = {
    ('%s/%s'):format(dir, name),
    ('%s/template.%s.%s'):format(dir, type, ext),
    ('%s/template.%s'):format(dir, ext),
  }

  for _, tpl in ipairs(tpls) do
    if vim.fn.filereadable(tpl) ~= 0 then
      local content = table.concat(vim.fn.readfile(tpl), '\n')

      -- replace: {{ dirname }}
      content = content:gsub('{{%s*dirname%s*}}', function()
        return vim.fn.expand('%:p:h:t')
      end)

      -- replace: {{ expand: %:r }}
      content = content:gsub('{{%s*expand:([^}]+)}}', function(pattern)
        return vim.fn.expand(trim(pattern))
      end)

      -- replace: {{ lua:vim.fn.system('date') }}
      content = content:gsub('({{%s*lua:([^}]*)}})', function(k, code)
        local fn = load('return ' .. code)
        if fn ~= nil then
          local ok, replace = pcall(fn)
          if ok and replace ~= nil then
            return trim(replace)
          end
        end
        return k
      end)

      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(content, '\n', { plain = true }))

      break
    end
  end
end

vim.api.nvim_create_autocmd({ 'BufNewFile' }, {
  group = vim.api.nvim_create_augroup('templates', { clear = true }),
  callback = function()
    M.load_template()
  end,
})
