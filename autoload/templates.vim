function! templates#load()
  if !&modifiable | return | endif

  let name = expand('%:t')
  let ext = expand('%:e')
  let dir = $HOME . "/.config/nvim/templates/"

  if filereadable(dir . name)
    exec "0read " . dir . name

  elseif filereadable(dir . "template." . ext)
    exec "0read " . dir . "template." . ext

  else
    return
  endif

  silent exec "s/{{dirname}}/" . expand('%:p:h:t') . "/ge"
endfunction
