" 整体思路：先触发normal! w，然后根据光标移动划过的内容和所在的位置判断是否需要再进行一次normal! w
function! smartW#smartW() abort
  let l:line = getline('.')
  let l:startlnum = line('.')
  let l:startcol = col('.')
  normal! w
  let l:endlnum = line('.')
  " 跨行移动无需操作
  if l:startlnum != l:endlnum
    "echo 'cross line movement'
    return
  endif
  let l:stopcol = col('.')
  let l:currentchar = matchstr(l:line, '\%'.l:stopcol.'c.') " see https://stackoverflow.com/questions/23323747/
  "echo 'move to char: '.l:currentchar
  " 光标在最后一个字符上，无需操作。
  " 使用 + len() 用于处理多字节字符
  " 使用 >= 而非 == 是为了处理空行
  " 可用这个命令检验-> :echo [col('.'), col('$')]
  if l:stopcol + len(l:currentchar) >= col('$')
    "echo 'end of line'
    return
  endif
  " 光标划过的是 word with trailing space 或者单纯的空格，则无需操作
  " 注意 \%Nc 表示恰好从第N列开始匹配
  " 补充：
  " 希望 \%>Nc 匹配第x列及之后时 N要取x-1，因为它指定的是大于第N列的字符(而非大于等于)。
  " 希望 \%<Mc 匹配第x列及之前时 M要取x+1，因为它匹配的是小于第M列的字符(而非小于等于)。
  " 在搜索时(比如调用match函数时)，末尾的 \%<Mc 或者 \%Nc 所匹配的字符并不计入结果
  " 所以此时 \%>Nc 与 \%<Mc 囊括的匹配区域相当于左闭右开区间 [N+1, M-1)
  let l:prevword = matchstr(l:line, '\%'.l:startcol.'c' . '.\+' . '\%'.l:stopcol.'c')
  "echo 'startcol: '.l:startcol.' endcol: '.l:stopcol.' matchstr: '.l:prevword
  if l:prevword =~# '^\v\S*(\s|　)+$' " 全角空格(Full-Width Space)也要匹配
    return
  endif
  " 如果光标划过的word只有一个字符，则再向前移动一个word
  " 要考虑一下到底要不要这么做。暂时不加上这一条。
  "if l:prevword =~# '^.$'
  "  "echo 'one char word'
  "  normal! w
  "  return
  "endif
  let l:cword = expand('<cword>') " see :help expand()
  "echo 'cword: '.l:cword
  " 如果光标不在word上，则expand('<cword>')返回的是光标右侧的首个word。故要分情况处理
  " 注意 match() 返回的下标从0开始计算，这与从1开始的 col() 不同，所以 +1 以使下标统一
  let l:nextcol = match(l:line, '\%>'.(l:stopcol-1).'c' . l:cword) + 1
  if l:nextcol == l:stopcol
    " 判断cword长度，长度小于等于1的话，再向前移动一个word
    if strchars(l:cword) <= 1
      "echo 'long cword'
      normal! w
      return
    endif
  else
    " 看看cword与光标之间是什么内容
    let l:middlechars = matchstr(l:line, '\%>'.(l:stopcol-1).'c' . '.\+' . '\%<'.(l:nextcol+1).'c')
    "echo 'middlechars: '.l:middlechars
    " 如果两者之间仅有1个字符，即cword的位置仅在右侧1个字符外，再向前移动一个word
    if strchars(l:middlechars) <= 1
      normal! w
      return
    endif
  endif
endfunc
