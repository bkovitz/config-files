" --- Plugins ---
call plug#begin('~/.vim/plugged')

" LSP-like IDE features
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" File finder (Ctrl+P-ish)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Git gutter
Plug 'airblade/vim-gitgutter'

" Rust niceties (optional but helpful)
Plug 'rust-lang/rust.vim'

call plug#end()

" Pre-configure CoC workspace folder so LSP starts even with no file open
"if getcwd() =~ '/app/rust'
"endif
if !empty(findfile('Cargo.toml', '.;'))
    let g:WorkspaceFolders = [fnamemodify(findfile('Cargo.toml', '.;'), ':p:h')]
endif

" -------------------------------- CoC settings --------------------------------
set hidden
set updatetime=300
set signcolumn=yes

let mapleader='\'

" Use Tab for completion menu
inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <silent><expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

" Go-to / hover / rename / code actions
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> <C-w>gd :split<CR><Plug>(coc-definition)
nmap <silent> <C-w>gi :split<CR><Plug>(coc-implementation)
nmap <silent> <C-w>gt :split<CR><Plug>(coc-type-definition)

function! s:FindReferences() abort
 let l:key = s:I18nKeyUnderCursor()

 " Preserve normal Coc behavior outside an i18n expression.
 if empty(l:key)
   call feedkeys("\<Plug>(coc-references)", 'm')
   return
 endif

 let l:start_dir = empty(expand('%:p'))
   \ ? getcwd()
   \ : expand('%:p:h')
 let l:ftl = findfile(
   \ 'impulse-design-system/locales/en-US/main.ftl',
   \ l:start_dir . ';')

 if empty(l:ftl)
   echohl ErrorMsg
   echom 'Could not find the Rust workspace'
   echohl None
   return
 endif

 let l:root = fnamemodify(l:ftl, ':p:h:h:h:h')
 let l:escaped_key = escape(l:key, '\.^$*+?()[]{}|')
 let l:pattern =
   \ '\b(?:t|t_args)!\s*\(\s*"' . l:escaped_key . '"'

 let l:args = [
   \ 'rg',
   \ '--vimgrep',
   \ '--glob', '*.rs',
   \ '--',
   \ l:pattern,
   \ l:root,
   \ ]
 let l:command =
   \ join(map(l:args, {_, value -> shellescape(value)}), ' ')
 let l:matches = systemlist(l:command)

 call setqflist([], 'r', {
   \ 'title': 'i18n references: ' . l:key,
   \ 'lines': l:matches,
   \ 'efm': '%f:%l:%c:%m',
   \ })

 if empty(l:matches)
   echom 'No references found: ' . l:key
 else
   copen
 endif
endfunction

"nmap <silent> gr <Plug>(coc-references)
nmap <silent> gr :call <SID>FindReferences()<CR>

nmap <silent> <leader>rn <Plug>(coc-rename)
nmap <silent> <leader>ca <Plug>(coc-codeaction)
nmap <silent> <leader>qf <Plug>(coc-fix-current)
nmap <silent> <leader>o :CocList outline<CR>
nmap <silent> <leader>s :CocList symbols<CR>

" 'hover' for type of a variable
"nmap <silent> K :call CocActionAsync('doHover')<CR>
" Hover documentation
nnoremap <silent> K :call ShowDocumentation()<CR>
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
" error msg
nmap <silent> <leader>e :call CocAction('diagnosticInfo')<CR>

" Inlay hints off by default
let g:coc_rust_analyzer_inlayHints_enable = 0
" Toggle with \h
nmap <silent> <leader>h :CocCommand document.toggleInlayHint<CR>

augroup CocHi
  autocmd!
  " Underline (not grey background) for unused code
  autocmd ColorScheme,VimEnter * hi CocUnusedHighlight gui=underline cterm=underline guibg=NONE ctermbg=NONE guisp=Grey           
  " Black text in compiler-error and -warning windows
  autocmd ColorScheme,VimEnter * hi CocErrorFloat   ctermfg=Black guifg=Black                                                       
  autocmd ColorScheme,VimEnter * hi CocWarningFloat ctermfg=Black guifg=Black                                                       
  autocmd ColorScheme,VimEnter * hi CocInfoFloat    ctermfg=Black guifg=Black                                                       
  autocmd ColorScheme,VimEnter * hi CocHintFloat    ctermfg=Black guifg=Black                                                       
augroup END                                                                                                                       

" Diagnostics nav
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" All diagnostics (cross-buffer) in quickfix window
function! s:CocDiagsToQF() abort
  let l:diags = CocAction('diagnosticList')
  let l:items = map(copy(l:diags), {_, d -> {
    \ 'filename': d.file,
    \ 'lnum': d.lnum,
    \ 'col': d.col,
    \ 'text': '[' . d.severity . '] ' . d.message,
    \ 'type': d.severity ==# 'Error' ? 'E' : 'W',
    \ }})
  call setqflist([], 'r', {'title': 'CoC Diagnostics', 'items': l:items})
  copen
endfunction
command! CD call s:CocDiagsToQF()

nmap <silent> <leader>p :CD<CR>

" FZF mappings
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-w><C-p> :split<CR>:Files<CR>
nnoremap <silent> <leader>fg :Rg<CR>

" Format Rust on save (rustfmt via CoC command)
autocmd BufWritePre *.rs :silent! call CocAction('format')

" Disable automatic completion popup
let g:coc_auto_trigger = 0

" Use Ctrl-Space to trigger completion manually
inoremap <silent><expr> <C-Space> coc#refresh()

" Restore Vim’s native Ctrl-P / Ctrl-N
inoremap <C-p> <C-p>
inoremap <C-n> <C-n>

" Remap :tag to fuzzy search of symbols
" (Tab completion removed — getWorkspaceSymbols blocks Vim for 60s on timeout;
" use :CocList symbols for interactive fuzzy browsing instead)

function! s:JumpToSymbol(name) abort
  let l:symbols = CocAction('getWorkspaceSymbols', a:name)
  if type(l:symbols) != v:t_list || empty(l:symbols)
	  echohl ErrorMsg | echo 'Symbol not found: ' . a:name | echohl None
	  return
  endif
  let l:exact = filter(copy(l:symbols), {_, s -> s.name ==# a:name})
  let l:loc = (empty(l:exact) ? l:symbols[0] : l:exact[0]).location
  let l:path = substitute(l:loc.uri, '^file://', '', '')
  let l:line = l:loc.range.start.line + 1
  let l:col = l:loc.range.start.character + 1
  execute 'edit +' . l:line . ' ' . fnameescape(l:path)
  call cursor(l:line, l:col)
endfunction

command! -nargs=1 Tag call s:JumpToSymbol(<q-args>)
cnoreabbrev <expr> tag (getcmdtype() == ':' && getcmdline() ==# 'tag') ? 'Tag' : 'tag'
cnoreabbrev <expr> ta (getcmdtype() == ':' && getcmdline() ==# 'ta') ? 'Tag' : 'ta'

function! s:SplitJumpToSymbol(name) abort
  let l:symbols = CocAction('getWorkspaceSymbols', a:name)
  if type(l:symbols) != v:t_list || empty(l:symbols)
	  echohl ErrorMsg | echo 'Symbol not found: ' . a:name | echohl None
	  return
  endif
  let l:exact = filter(copy(l:symbols), {_, s -> s.name ==# a:name})
  let l:loc = (empty(l:exact) ? l:symbols[0] : l:exact[0]).location
  let l:path = substitute(l:loc.uri, '^file://', '', '')
  let l:line = l:loc.range.start.line + 1
  let l:col = l:loc.range.start.character + 1
  execute 'split +' . l:line . ' ' . fnameescape(l:path)
  call cursor(l:line, l:col)
endfunction                                                                                             
command! -nargs=1 Stag call s:SplitJumpToSymbol(<q-args>)
cnoreabbrev <expr> stag (getcmdtype() == ':' && getcmdline() ==# 'stag') ? 'Stag' : 'stag'
cnoreabbrev <expr> sta (getcmdtype() == ':' && getcmdline() ==# 'sta') ? 'Stag' : 'sta'

" Make Ctrl-] go to the definition of the symbol under the cursor (like normal
" vim but using the Rust LSP).
set tagfunc=CocTagFunc                                                                                  
" Auto-update the buffer whenever the underlying file changes
set autoread
autocmd CursorHold,CursorHoldI,FocusGained,BufEnter * checktime

" Start rust-analyzer when vim starts up, regardless of whether a file is open
"autocmd VimEnter * if getcwd() =~ '/app/rust' && expand('%') == '' | set filetype=rust | endif
autocmd VimEnter * if !empty(findfile('Cargo.toml', '.;')) && expand('%') == '' | set filetype=rust | endif

" Inlay hints off by default; \h toggles per-document
function! s:DisableInlayHints(bufnr, timer) abort
  if bufnr('%') != a:bufnr || get(b:, 'inlay_hints_disabled', 0)
    return
  endif
  try
    let l:has = CocAction('hasProvider', 'inlayHint')
  catch
    call timer_start(100, function('s:DisableInlayHints', [a:bufnr]))
    return
  endtry
  if l:has
    let b:inlay_hints_disabled = 1
    call CocActionAsync('runCommand', 'document.toggleInlayHint')
  else
    call timer_start(100, function('s:DisableInlayHints', [a:bufnr]))
  endif
endfunction
autocmd FileType rust call timer_start(0, function('s:DisableInlayHints', [bufnr('%')]))

" -------------------------------- Generic preferences --------------------------------

set nocompatible
map Q gq
set backspace=2
set fileencodings=utf-8,latin1
set formatoptions=tcql
" set guifont=LucidaTypewriter\ 9
" set guifont=Monaco:h10
set guifont=Lucida\ Sans\ Typewriter:h11
set antialias

function! s:AdjustFontSize(delta) abort
  let l:size = matchstr(&guifont, ':h\zs\d\+')
  if empty(l:size) | return | endif
  let &guifont = substitute(&guifont, ':h\d\+', ':h' . max([1, str2nr(l:size) + a:delta]), '')
endfunction
nnoremap <C-=> :call <SID>AdjustFontSize(1)<CR>
nnoremap <C-_> :call <SID>AdjustFontSize(-1)<CR>
set history=50
set hlsearch
set mouse=a
set ruler
if &syntax != 'help'
set syntax=help
endif
set textwidth=78
set viminfo='20,\"50

set sw=3 ts=3 ai
set wildignore=*.class,*.pyc,*.aux,*.bbl,*.bcf,*.fdb_latexmk,*.fls,*.run.xml,*.pdf,*.db
set tags=tags
set nohls
set expandtab
set showmatch

" Show no menus for completion (C-N, C-P)
set completeopt=

" enable filetype plugin
filetype plugin on

" Ctrl-] goes to definition: of code item or of i18n string if inside !t("...")
function! s:I18nKeyUnderCursor() abort
let l:text = getline('.')
let l:cursor = col('.') - 1
let l:offset = 0
let l:pattern = '\C&t!\s*(\s*"[^"]\+"\s*)'

while 1
  let [l:expr, l:start, l:end] =
    \ matchstrpos(l:text, l:pattern, l:offset)

  if l:start < 0
    return ''
  endif

  if l:cursor >= l:start && l:cursor < l:end
    return matchstr(l:expr, '"\zs[^"]\+\ze"')
  endif

  let l:offset = l:end
endwhile
endfunction

function! s:JumpToI18nDefinition() abort
let l:key = s:I18nKeyUnderCursor()
if empty(l:key)
  return 0
endif

let l:start_dir = empty(expand('%:p'))
  \ ? getcwd()
  \ : expand('%:p:h')
let l:path = findfile(
  \ 'impulse-design-system/locales/en-US/main.ftl',
  \ l:start_dir . ';')

if empty(l:path)
  echohl ErrorMsg
  echom 'Could not find en-US/main.ftl'
  echohl None
  return 1
endif

let l:pattern =
  \ '^' . escape(l:key, '\.^$*~[]') . '\s*='
let l:index = match(readfile(l:path), l:pattern)

if l:index < 0
  echohl ErrorMsg
  echom 'Translation not found: ' . l:key
  echohl None
  return 1
endif

" Preserve Ctrl-T / your Ctrl-[ tag-stack return behavior.
let l:from = [bufnr()] + getcurpos()[1:]
let l:line = l:index + 1

execute 'edit +' . l:line . ' '
  \ . fnameescape(fnamemodify(l:path, ':p'))
call cursor(l:line, 1)

let l:stack = gettagstack(win_getid())
let l:stack['items'] = [{
  \ 'bufnr': l:from[0],
  \ 'from': l:from,
  \ 'tagname': l:key,
  \ }]
call settagstack(win_getid(), l:stack, 't')

return 1
endfunction

function! s:FollowDefinition() abort
if !s:JumpToI18nDefinition()
  execute "normal! g\<C-]>"
endif
endfunction

nnoremap <silent> <C-]> :call <SID>FollowDefinition()<CR>

" Ctrl-[ pops the tag stack (note: also intercepts Esc in normal mode)
nnoremap <C-[> <C-T>

" Ctrl-T and Alt-T open symbol browser
nnoremap <C-t> :CocList symbols<CR>
nnoremap <D-t> :CocList symbols<CR>
nnoremap <silent> <C-w><C-t> :split<CR>:CocList symbols<CR>

" turn off both beeps and visual bells
set vb t_vb=

" make Cmd-N and Cmd-P do the same as Ctrl-N and Ctrl-P
" BUG: Remapping Cmd-N doesn't seem to work in MacVim 6.2
inoremap <D-n> <C-n>
inoremap <D-p> <C-p>

" make F1 do an Esc, to prevent "fat-finger" annoyance
inoremap <F1> <Esc>
nnoremap <F1> <Esc>
vnoremap <F1> <Esc>
cnoremap <F1> <Esc>
onoremap <F1> <Esc>
lnoremap <F1> <Esc>

" make :E do the same as :e (ignoring a common typo)
:command -complete=file -nargs=1 E e <args>

" make :f and :F do the same as :find
":command -complete=file_in_path -nargs=1 F find <args>
:cabbrev f <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'find' : 'f')<CR>
:cabbrev F <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'find' : 'F')<CR>

" Don't show matching parens all the time.
let loaded_matchparen = 1
"NoMatchParen

" <C-L> types lambda
inoremap <C-L> <C-K>l*
" <C-A> types alpha
inoremap <C-A> <C-K>a*
" Type <Ctrl-K>ll to get ℓ
digraph ll 8467

syntax on
"set nolisp
"
"hi Normal ctermfg=LightGrey ctermbg=Black
"hi Statement ctermfg=LightGrey ctermbg=Black
"hi Constant ctermfg=DarkCyan ctermbg=Black
"hi Type ctermfg=DarkYellow ctermbg=Black
"hi PreProc ctermfg=DarkCyan ctermbg=Black
"hi Comment ctermfg=DarkYellow ctermbg=Black
"hi Cursor ctermbg=Yellow ctermfg=Black
"hi Error guibg=DarkOrange ctermbg=Black

" xterm-256color chart is at:
" https://upload.wikimedia.org/wikipedia/en/1/15/Xterm_256color_chart.svg
" hi Normal ctermfg=Black ctermbg=230             " dull yellow background
hi Statement ctermfg=124 cterm=bold term=bold   " dark red
hi Constant ctermfg=55                          " dark purple
hi Type ctermfg=28 cterm=bold                   " green
hi PreProc ctermfg=91 cterm=bold                " purple
hi Comment ctermfg=26                           " unsaturated blue
hi Function ctermfg=20                          " blue
"hi Cursor ctermbg=Yellow ctermfg=Black
"hi Error guibg=DarkOrange ctermbg=Black

augroup EditVim
autocmd!
autocmd VimEnter * set nodiff foldcolumn=0 noscrollbind wrap

" Michael Small's C++11 syntax file (Nov 2011)
autocmd BufNewFile,BufRead *.cpp,*.h set syntax=cpp11

" Tabs appropriate to language
"autocmd BufNewFile,BufRead *.c,*.cpp,*.cc,*.h,*.html,*.hs,*.scala,*.html,*.js set ts=2 sw=2 ai et tw=0
autocmd BufNewFile,BufRead *.cpp,*.cc,*.html,*.hs,*.scala,*.html,*.js set ts=2 sw=2 ai et tw=0
autocmd BufNewFile,BufRead *.c,*.h set ts=4 sw=4 ai et tw=0
autocmd BufNewFile,BufRead *.py set ts=4 sw=4 ai et tw=0
autocmd BufNewFile,BufRead *.s,*.asm set ts=8 sw=8 ai noet
autocmd BufNewFile,BufRead *.ss,*.scm set ts=2 sw=2 ai et nolisp
autocmd BufNewFile,BufRead *.farg set ts=2 sw=2 ai et
autocmd BufNewFile,BufRead *.clj,*.cljs,*.cljc set ts=2 sw=2 ai et lisp
autocmd BufNewFile,BufRead *.tex set ts=2 sw=2 ai et
autocmd BufNewFile,BufRead *.rs set ts=4 sw=4 ai et

" jump to position in file when last edited
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g'\"" | endif
augroup END

"execute pathogen#infect()
syntax on
"filetype plugin indent on
set lispwords=def,definline,definterface,defmacro,defmulti,defn,defn-,defonce,defprotocol,defrecord,deftest,deftest-,extend,extend-protocol,extend-type,fn,ns,proxy,reify,set-test,as->,binding,doall,dorun,doseq,doto,for,if-let,letfn,locking,loop,testing,when-first,when-let,with-bindings,with-in-str,with-local-vars,with-open,with-precision,with-redefs,with-redefs-fn,with-test,cond->,cond->>,condp,if-not,when-not,while,catch,try,pmatch,deftrace
" let g:rainbow_active = 1

set path-=/usr/include
set path+=src/*/,test/*/,scratch/

" Ctrlp settings: Hit Ctrl-P to quickly select a file
set runtimepath^=~/.vim/bundle/ctrlp.vim
let g:ctrlp_by_filename = 1  " consider filename only, not path to it
let g:ctrlp_follow_symlinks = 1
" let g:ctrlp_working_path_mode = 'rw'
let g:ctrlp_user_command = 
  \ ['.git', 'cd %s && find . | grep -v \.git/'] 

set nowildmenu  " disable menu for filename-completion

" Make Alt-X,C,V work the same on GNOME as they do on MacOS
nnoremap <M-x> "+d
vnoremap <M-x> "+d
nnoremap <M-c> "+yy
vnoremap <M-c> "+y
nnoremap <M-v> "+p
inoremap <M-v> <C-r>+

" Make Ctrl-W Ctrl-F jump to the line number of the file under the cursor, if
" it's there.
noremap <C-w><C-f> <C-w>F

"See line numbers
set number

" Make Ctrl-W _ (and Ctrl-W Ctrl-_) set the current window to 2/3 of the
" number of rows, dividing the remaining rows equally among the other windows.
" No effect when only one window is open.
function! s:TwoThirdsHeight() abort
  if v:count
    execute v:count . 'wincmd _'
    return
  endif

  " Do nothing if there is no window above or below this one.
  if winnr('j') == winnr() && winnr('k') == winnr()
    return
  endif

  let l:tabline = &showtabline == 2 || (&showtabline == 1 && tabpagenr('$') > 1)
  let l:rows = &lines - &cmdheight - l:tabline

  let l:old = &l:winfixheight
  execute 'resize ' . (l:rows * 2 / 3)
  setlocal winfixheight
  wincmd =
  let &l:winfixheight = l:old
endfunction

nnoremap <silent> <C-w>_ :<C-u>call <SID>TwoThirdsHeight()<CR>
nnoremap <silent> <C-w><C-_> :<C-u>call <SID>TwoThirdsHeight()<CR>
