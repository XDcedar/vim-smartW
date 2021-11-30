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
" function! s:SkipSingleCharacter(originalMapping) abort
"   " echo 'start'
"   let l:line = getline('.')
"   let l:col = col('.')
"   let l:expr_prefix = '\%'.l:col.'c' " \%23c表a示从第23列开始匹配 see :help \%c
"   let l:currentchar = matchstr(l:line, l:expr_prefix.'.') " see https://stackoverflow.com/questions/23323747/
"   " case 1: cursor on keyword but not digits
"   if l:currentchar =~# '\K' " see :help \K
"     " echo 'is keyword'
"     " \v表示very magic模式(基本所有特殊符号默认为特殊含义)
"     " {-1,} 表示匹配至少1个但越少越好，见 :help /\{-
"     " (....)@! 是负向零宽断言(见:help /\@!)，仅判断位置而不记入匹配字符，所以后面要跟'.'来匹配零宽断言命中的字符
"     " expr 含义为 从当前位置开始匹配，匹配模式为:(多个keyword)(下1个字符不是keywkeyword)(再下1个字符是keyword)
"     let l:expr = l:expr_prefix.'\v\K{-1,}(\K)@!.(\K|\s)'
"   elseif l:currentchar !~# '\K'
"     " echo 'is not keyword'
"     " 注意中间的 '\k' 为小写，见 :help \k
"     let l:expr = l:expr_prefix.'\v(\K{-1,})@!.\k(\K)@!.'
"   endif
"   " echo l:expr
"   let l:endidx = matchend(l:line, l:expr)
"   if l:endidx >= 0
"     call cursor('.', l:endidx)
"     echo 'matched'
"     return
"   endif
"   " use '!' to not use mappings. see :help normal
"   normal! w
" endfunc

function! s:SkipSingleCharacter(originalMapping) abort
  let l:line = getline('.')
  let l:col = col('.')
  let l:currentchar = matchstr(l:line, '\%'.l:col.'c.') " see https://stackoverflow.com/questions/23323747/
  " 如果光标在符号上，则expand('<cword>')返回的是光标所在行内右侧的首个word。要先筛掉这种情况。
  echo "currentchar: ".l:currentchar
  " 光标在空白字符上，则触发普通w
  if l:currentchar =~# '\s'
    normal! w
    return
  endif
  " 光标不在空白字符上但也不是keyword，触发普通w
  if l:currentchar !~# '\k'
    normal! w
    return
  endif
  let l:cword = expand('<cword>') " see :help expand()
  echo "cword: ".l:cword
  " 搜索位置为光标所在位置左移一个<cword>长度，这样光标即使在word的正中间，使用 \%>c 也能匹配光标所在word。
  " 简单证明可知不必担心光标左移太多（比如aaa.aaa匹配到了左边那个aaa，或者诸如abababab的长回文匹配到了某个子串）
  let l:searchidx = max([l:col-len(l:cword), 0])
  echo "searchidx: ".l:searchidx
  let l:expr = '\%>'.l:searchidx.'c'.l:cword.'\s*' " \%>23c表a示从第23列往后开始查找匹配 see :help /\%>c
  echo "expr: ".l:expr
  let l:endidx = matchend(l:line, l:expr)
  " 到句尾则正常跳转
  echo "endidx: ".l:endidx
  if l:endidx == len(l:line)
    normal! w
    return
  endif
  " 否则移动光标后判断下一个word的长度
  normal! w
  " call cursor('.', l:endidx)
  let l:cword = expand('<cword>')
  echo "cword: ".l:cword
  " 下个单词词长超过1则不需要继续操作
  if strchars(l:cword) > 1
    return
  endif
  let l:col = col('.')
  let l:endidx = matchend(l:line, '\%'.l:col.'c'.l:cword.'\s*')+1 " 因为光标肯定在词首所以不需要减去单词长度
  echo "endidx: ".l:endidx
  normal! w
endfunc
" testing map
noremap <leader>w w
noremap <silent> w :<C-U>call <SID>SkipSingleCharacter('w')<CR>


" TODO
" 设计初衷：让经常出现在句中的(,":等不再像一面挡住所有移动操作的铁壁
" 多种类型：
" 英文字符abc 符号:,# 数字0-9 空格\s
" 不同类型属于不同group？搞不明白.. :help iskeyword
" 旧想法：只要满足 ABBBBX 或者 AAAABX 模式 自动跳到X位置，不同字母表示不同类型
" 最新想法：先触发normal! w，然后根据光标移动划过的内容判断是否需要再进行一次normal! w
