" smartW - simple plugin for smart 'w' motion in normal mode
" Author:  XDcedar
" Version: 0.1
" License: MIT

if exists('g:loaded_smartW_plugin')
  finish
endif


nnoremap <silent> <Plug>(smartW)  :<C-u>call smartW#smartW()<CR>
nnoremap <Plug>(smartW-builtin-w)  w


let g:loaded_smartW_plugin = 1
