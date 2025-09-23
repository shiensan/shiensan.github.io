
" 仅显示 item.text（去掉 文件名|行|列）
function! s:OnlyTextQftf(info) abort
  let l = getloclist(a:info.winid, {'id': a:info.id, 'items': 1})
  let items = l.items
  let lines = []
  for i in range(a:info.start_idx - 1, a:info.end_idx - 1)
    call add(lines, get(items[i], 'text', ''))
  endfor
  return lines
endfunction

" :MdOutline                    → 全部层级、全文件
" :MdOutline 3                  → 1~3级、全文件
" :MdOutline 10 200             → 全部层级、仅第10~200行
" :MdOutline 3 10 200           → 1~3级、仅第10~200行
function! MarkdownOutline(...) abort
  " ---- 参数解析 ----
  let maxlevel = 0
  let startln  = 1
  let endln    = line('$')

  if a:0 == 1
    " 只有一个参数：当作 maxlevel
    let maxlevel = str2nr(a:1)
  elseif a:0 == 2
    " 两个参数：当作 start end
    let startln = str2nr(a:1)
    let endln   = str2nr(a:2)
  elseif a:0 >= 3
    " 三个参数：maxlevel start end
    let maxlevel = str2nr(a:1)
    let startln  = str2nr(a:2)
    let endln    = str2nr(a:3)
  endif

  if startln < 1 | let startln = 1 | endif
  if endln < 1   | let endln   = 1 | endif
  let last = line('$')
  if endln > last | let endln = last | endif
  if startln > endln
    let tmp = startln | let startln = endln | let endln = tmp
  endif

  " ---- 扫描并生成 items ----
  let items = []
  for lnum in range(startln, endln)
    let L = getline(lnum)

    " 1) ATX 标题：# 开头
    if L =~# '^#\+\s\+'
      let hlevel = strlen(matchstr(L, '^#\+'))
      if maxlevel == 0 || hlevel <= maxlevel
        call add(items, {'bufnr': bufnr('%'), 'lnum': lnum, 'col': 1, 'text': L})
      endif
      continue
    endif

    " 2) Setext 标题：下一行 ===/---（分别算 H1/H2）
    if lnum < endln
      let next = getline(lnum + 1)
      if next =~# '^=\{2,}\s*$' || next =~# '^-\{2,}\s*$'
        let hlevel = (next =~# '^=\{2,}\s*$') ? 1 : 2
        if L =~# '\S'
          if maxlevel == 0 || hlevel <= maxlevel
            call add(items, {'bufnr': bufnr('%'), 'lnum': lnum, 'col': 1, 'text': L})
          endif
        endif
      endif
    endif
  endfor

  " ---- 写入 loclist，并使用“只显示文本”的渲染 ----
  call setloclist(0, items, 'r')
  call setloclist(0, [], 'a', {'quickfixtextfunc': function('s:OnlyTextQftf')})

  " ---- 左侧打开并隐藏装饰 ----
  vertical leftabove lopen
  setlocal nonumber norelativenumber signcolumn=no foldcolumn=0 nowrap
endfunction

command! -nargs=* MdOutline call MarkdownOutline(<f-args>)

