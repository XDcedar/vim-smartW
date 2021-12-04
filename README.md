# smartW

A simple plugin for smart `w` motion in normal mode.

This is my first vim plugin.

## Install

For [vim-plug](https://github.com/junegunn/vim-plug): `Plug 'XDcedar/vim-smartW'`

## Usage

Add this to your .vimrc or init.vim
```vim
nmap <silent> w <Plug>(smartW)
" if you want to keep built-in w motion, uncomment this line
"nmap <silent> <leader>w <Plug>(smartW-builtin-w)
```

And this is what it does when pressing `w` in normal mode.
```
sample text       https://example.com/show-examples-about-this?
with this plugin  |--->|->|------>|-->|--->|------->|---->|-->|-> to next line
(9 keystrokes)    w    w  w       w   w    w        w     w   w
without it        |--->|->|----->||->||-->||------>||--->||-->|-> to next line
(14 keystrokes)   w    w  w      ww  ww   ww       ww    ww   w
```
Notice the cursor acts normally, but skips one-character words (except for the one at the end of line, i.e. the word `?`).

**Plugin only affects normal mode.**

## Why this plugin

The reason is simple but hard to explain, it might take more words than this tiny plugin needs to clarify, please forgive me for my lengthy explanation.

In most modern apps, when typing `<C-Left>` or `<C-Right>` in text-edit area, the cursor would skip special characters like `/-+&=,`, and then jumps to the beginning of the next word.

For example, in Chrome address bar:
```
text       https://example.com/show-examples-about-this?
cursor     |------>|------>|-->|--->|------->|---->|--->|-> to the end of line
keystrokes CTRL+→  CTRL+→  C+→ C+→  CTRL+→   C+→   C+→  C+→
(8 keystrokes)
```

While in (n)vim this would happen when pressing `w`:
```
text       https://example.com/show-examples-about-this?
cursor     |--->|->|----->||->||-->||------>||--->||-->|-> to next line
keystrokes w    w  w      ww  ww   ww       ww    ww   w
(14 keystrokes)
```
Modern apps treat special characters as trailing part of the preceding words, thus the cursor skips `://`, `/` and `-`,
While (n)vim treats those words as text-objects and stops at the beginning of them.
Notice how many fewer keystrokes Chrome needs than (n)vim.

However the change of modern apps isn't that good. See the example below.
```
modern apps
text       matchstr(getline('.'),'\%'.col('.').'c.')
cursor     |------->|---------------->|-------->|-->|
keystrokes CTRL+→   CTRL+→            CTRL+→    CTRL+→

vim
text       matchstr(getline('.'),'\%'.col('.').'c.')
cursor     |------>||----->|--------->|->|----->||->|
keystrokes w       ww      w          w  w      ww
```
When coding we might want to change the parameter of `getline()` (i.e. `'.'`), or the string `'\%'`,
but the cursor of modern apps would jump straight forward to `col`, skipping the whole part after `getline`,
which forces us to type lots of `←` to move back.

The built-in method in (n)vim does not do it well either.
In my opinion, `w` should always do something `hjkl` cannot,
but notice the awkward double `w` keystrokes in (n)vim from the examples above,
the first keystroke just moves cursor one character forward.
It seems like single-character words turn into an impassable barrier that almost all horizontal movements have to stop there.

To compromise these two circumstances, I come up with a simple solution:
Treat one-character words like `/`, `-`, `s`, `g` (including `[a-zA-Z0-9]` etc) as the trailing part of the preceding word and skip it when moving,
but treat longer words as normal words and move forward as usual.
Then we could reduce the number of keystrokes and move faster, but not too fast.
If you want to edit that single character, just type `wh` instead of `w`, or `el` if you wish.

## implementation
The implementation is simple.
After pressing `w`, plugin will execute `normal! w`, then check whether the cursor is on a one-character word, if true, execute `normal! w` again.

However if executing `normal! w` the second time would let cursor move to the next line, then don't do it.
