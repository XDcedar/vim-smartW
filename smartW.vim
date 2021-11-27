function! SkipSingleCharacter(originalMapping) abort
  let isOnKeyword = matchstr(getline('.'), '\%'.col('.').'c.') =~# '\k'
  if isOnKeyword
    return a:originalMapping
  endif
  let isOneCharBeforeKeyword = col('.') == stridx(getline('.'), expand("<cword>"), col('.')-1)
  if isOneCharBeforeKeyword
    return '2' . a:originalMapping
  endif
  return a:originalMapping
endfunc
nnoremap <expr> w SkipSingleCharacter('w')
