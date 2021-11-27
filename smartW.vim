" function! SkipSingleCharacter(originalMapping) abort
"   let isOnKeyword = matchstr(getline('.'), '\%'.col('.').'c.') =~# '\k'
"   if isOnKeyword
"     return a:originalMapping
"   endif
"   let isOneCharBeforeKeyword = col('.') == stridx(getline('.'), expand("<cword>"), col('.')-1)
"   if isOneCharBeforeKeyword
"     return '2' . a:originalMapping
"   endif
"   return a:originalMapping
" endfunc
" nnoremap <expr> w SkipSingleCharacter('w')

" 可能会用到的函数(函数名有char表示字符串，没有char表示字节串)
" matchstr({expr}, {pat} [, {start} [, {count}]])
" matchstrpos({expr}, {pat} [, {start} [, {count}]])
" matchend({expr}, {pat} [, {start} [, {count}]])
" strcharlen({expr})
" strcharpart({str}, {start} [, {len} [, {skipcc}]])
" strpart({str}, {start} [, {len} [, {chars}]])

" 下面是个简单的 operator-pending mode 示例，设置后输入 yil 会复制 当前字符~光标右侧5个字符
" onoremap <silent> il :call cursor('.', col('.')+5)<CR>
" 这个就是复刻了w
" onoremap <silent> il :normal! w<CR>
" 也可以这样写
" onoremap <silent> <expr> il 'w'
function! s:SkipSingleCharacter(originalMapping) abort
  " echo 'start'
  let l:line = getline('.')
  let l:col = col('.')
  let l:expr_prefix = '\%'.l:col.'c' " \%23c表a示从第23列开始匹配 see :help \%c
  let l:currentchar = matchstr(l:line, l:expr_prefix.'.') " see https://stackoverflow.com/questions/23323747/
  " case 1: cursor on keyword but not digits
  if l:currentchar =~# '\K' " see :help \K
    " echo 'is keyword'
    " \v表示very magic模式(基本所有特殊符号默认为特殊含义)
    " {-1,} 表示匹配至少1个但越少越好，见 :help /\{-
    " (....)@! 是负向零宽断言(见:help /\@!)，仅判断位置而不记入匹配字符，所以后面要跟'.'来匹配零宽断言命中的字符
    " expr 含义为 从当前位置开始匹配，匹配模式为:(多个keyword)(下1个字符不是keywkeyword)(再下1个字符是keyword)
    let l:expr = l:expr_prefix.'\v\K{-1,}(\K)@!.(\K|\s)'
  elseif l:currentchar !~# '\K'
    " echo 'is not keyword'
    " 注意中间的 '\k' 为小写，见 :help \k
    let l:expr = l:expr_prefix.'\v(\K{-1,})@!.\k(\K)@!.'
  endif
  " echo l:expr
  let l:endidx = matchend(l:line, l:expr)
  if l:endidx >= 0
    call cursor('.', l:endidx)
    echo 'matched'
    return
  endif
  " use '!' to not use mappings. see :help normal
  normal! w
endfunc
" testing map
noremap <leader>w w
noremap <buffer> <silent> w :<C-U>call <SID>SkipSingleCharacter('w')<CR>
