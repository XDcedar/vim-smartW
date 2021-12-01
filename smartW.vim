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

function! s:getChar(str, col) " input is byte column, not char index
  return matchstr(a:str, '\%'.a:col.'c.') " see https://stackoverflow.com/questions/23323747/
endfunc


" 设计初衷：让经常出现在句中的(,":等不再像一面挡住所有移动操作的铁壁
" 整体思路：先触发normal! w，然后根据光标移动划过的内容判断是否需要再进行一次normal! w
function! s:SkipSingleCharacter(originalMapping) abort
  let l:line = getline('.')
  let l:startlnum = line('.')
  let l:startcol = col('.')
  normal! w
  " execute 'normal! '.a:originalMapping
  let l:endlnum = line('.')
  " 跨行移动无需操作
  if l:startlnum != l:endlnum
    echo 'cross line movement'
    return
  endif
  let l:stopcol = col('.')
  let l:currentchar = s:getChar(l:line, l:stopcol)
  echo 'move to char: '.l:currentchar
  " 光标在最后一个字符上，无需操作。
  " 使用 + len() 用于处理多字节字符
  " 使用 >= 而非 == 是为了处理空行
  " 可用这个命令检验-> :echo [col('.'), col('$')]
  if l:stopcol + len(l:currentchar) >= col('$')
    echo 'end of line'
    return
  endif
  " 光标划过的范围是 word with trailing space 或者单纯的空格，则无需操作
  " 注意 \%Nc 表示恰好从第N列开始计算
  " 补充：
  " 希望 \%>Nc 匹配第x列及之后时 N取x-1，因为它指定的是大于第N列的字符(而非大于等于)。
  " 希望 \%<Mc 匹配第x列及之前时 M取x+1，因为它匹配的是小于第M列的字符(而非小于等于)。
  " 在搜索时(比如调用match函数时)，末尾的 \%<Mc 或者 \%Nc 所匹配的字符并不计入结果
  " 所以此时 \%>Nc 与 \%<Mc 囊括的匹配区域相当于左闭右开区间 [N+1, M-1)
  echo 'startcol: '.l:startcol.' endcol: '.l:stopcol.' matchidx: '.match(l:line, '\%'.l:startcol.'c' . '\S*\s\+' . '\%'.l:stopcol.'c')
  if match(l:line, '\%'.l:startcol.'c' . '\S*\s\+' . '\%'.l:stopcol.'c') >= 0
    return
  endif
  " 如果光标停止的位置是空格（理论上说其实不可能是空格）
  let l:currentchar = s:getChar(l:line, l:stopcol)
  if l:currentchar =~# '\s'
    normal! w
    return
  endif
  let l:cword = expand('<cword>') " see :help expand()
  echo 'cword: '.l:cword
  " 如果光标不在word上，则expand('<cword>')返回的是光标右侧的首个word。故要分情况处理
  " 注意 match() 返回的下标从0开始计算，这与从1开始的 col() 不同，所以 +1 以使下标统一
  let l:nextcol = match(l:line, '\%>'.(l:stopcol-1).'c' . l:cword) + 1
  if l:nextcol == l:stopcol
    " 判断cword长度，长度大于等于2的话，也无需操作
    if strchars(l:cword) >= 2
      echo 'long cword'
      return
    endif
    " 否则再向前移动一个word
    normal! w
  else
    " 看看cword与光标之间是什么内容
    let l:middlechars = matchstr(l:line, '\%>'.(l:stopcol-1).'c' . '.\+' . '\%<'.(l:nextcol+1).'c')
    echo 'middlechars: '.l:middlechars
    " 如果两者之间有多个字符，即cword的位置在右侧2个字符外，则无需操作
    if strchars(l:middlechars) >= 2
      return
    endif
    " 否则再向前移动一个word
    normal! w
  endif
endfunc
" testing map
noremap <leader>w w
noremap <silent> w :<C-U>call <SID>SkipSingleCharacter('w')<CR>
