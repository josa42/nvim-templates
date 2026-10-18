vim.cmd.runtime('plugin/templates.lua')

local root

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end

local function template(name, lines)
  write(vim.fs.joinpath(root, 'config', 'nvim', 'templates', name), lines)
end

local function edit(name)
  vim.cmd.edit(vim.fs.joinpath(root, 'work', 'my.dir', name))
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe('templates', function()
  before_each(function()
    root = vim.fn.tempname()
    vim.env.XDG_CONFIG_HOME = vim.fs.joinpath(root, 'config')
  end)

  after_each(function()
    vim.cmd('silent! %bwipeout!')
    vim.fn.delete(root, 'rf')
  end)

  it('leaves the buffer empty without a template', function()
    assert.same({ '' }, edit('foo.go'))
  end)

  it('loads template.<ext>', function()
    template('template.go', { 'package main', '', 'func main() {}' })
    assert.same({ 'package main', '', 'func main() {}' }, edit('foo.go'))
  end)

  it('prefers template.<type>.<ext> over template.<ext>', function()
    template('template.js', { 'js' })
    template('template.test.js', { 'test' })
    assert.same({ 'test' }, edit('foo.test.js'))
    assert.same({ 'js' }, edit('foo.js'))
  end)

  it('prefers a template matching the file name', function()
    template('LICENSE', { 'MIT' })
    template('template.go', { 'go' })
    template('main.go', { 'main' })
    assert.same({ 'MIT' }, edit('LICENSE'))
    assert.same({ 'main' }, edit('main.go'))
  end)

  it('does not load a template for existing files', function()
    template('template.go', { 'go' })
    write(vim.fs.joinpath(root, 'work', 'my.dir', 'foo.go'), { 'existing' })
    assert.same({ 'existing' }, edit('foo.go'))
  end)

  it('replaces {{ dirname }}', function()
    template('template.go', { 'package {{ dirname }}', '// {{dirname}} {{  dirname  }}' })
    assert.same({ 'package my.dir', '// my.dir my.dir' }, edit('foo.go'))
  end)

  it('replaces {{ expand: ... }}', function()
    template('template.go', { 'name: {{ expand: %:t:r }}', '{{expand:%:e}}' })
    assert.same({ 'name: foo', 'go' }, edit('foo.go'))
  end)

  it('replaces {{ lua: ... }}', function()
    template('template.go', { 'sum: {{ lua: 1 + 2 }}', '{{lua:vim.fn.expand("%:t")}}' })
    assert.same({ 'sum: 3', 'foo.go' }, edit('foo.go'))
  end)

  it('keeps special characters in lua results', function()
    template('template.go', { [[{{ lua: 'a/b&c#d\\~%1' }}]] })
    assert.same({ [[a/b&c#d\~%1]] }, edit('foo.go'))
  end)

  it('splits multi-line lua results into lines', function()
    template('template.go', { [[x {{ lua: 'a\nb' }} y]] })
    assert.same({ 'x a', 'b y' }, edit('foo.go'))
  end)

  it('keeps lua placeholders that fail or return nil', function()
    template('template.go', { '{{ lua: error("x") }}', '{{ lua: nil }}', '{{ lua: ) }}' })
    assert.same({ '{{ lua: error("x") }}', '{{ lua: nil }}', '{{ lua: ) }}' }, edit('foo.go'))
  end)

  it('does not register the autocmd twice when sourced again', function()
    vim.cmd.runtime('plugin/templates.lua')
    template('template.go', { 'go' })
    assert.same({ 'go' }, edit('foo.go'))
    assert.equals(1, #vim.api.nvim_get_autocmds({ group = 'templates' }))
  end)
end)
