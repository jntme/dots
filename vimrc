
" Set standard file encoding
set encoding=utf8

" No special per file vim override configs
set nomodeline

" Stop word wrapping
set nowrap
" Except... on Markdown. That's good stuff.
autocmd FileType markdown setlocal wrap

" Adjust system undo levels
set undolevels=100

" Use system clipboard
set clipboard=unnamed

" Set tab width and convert tabs to spaces
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Don't let Vim hide characters or make loud dings
set conceallevel=1
set noerrorbells

" Number gutter
set number

set wrap "turn on line wrapping
set wrapmargin=8 " wrap lines when coming within n characters from side
set linebreak " set soft wrapping
set showbreak=… " show ellipsis at breaking

" Use search highlighting
set hlsearch

" Space above/beside cursor from screen edges
set scrolloff=1
set sidescrolloff=5

set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮

" clear highlighted search
noremap <space> :set hlsearch! hlsearch?<cr>

"split the right way
map <leader>\| :vs<cr>
map <leader>- :sp<cr>

" switch between current and last buffer
nmap <leader>. <c-^>

" scroll the viewport faster
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

if has('mouse')
  set mouse=a
endif

"set Leader
let mapleader=","

"no mouse
set mouse=r
let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1

"save on <Leader><Leader>
nnoremap <Leader><Leader> :w<CR>

" remap esc
inoremap jj <esc>

"disable Ex mode
noremap Q <NOP>"

nmap <leader>q :q<cr>
"quit current window
nmap <leader>Q :qa!<cr>
"quit all windows

vnoremap <leader>s :sort<cr>

" edit ~/.vimrc
map <leader>ev :e! ~/.dots/vimrc<cr>
" edit ~/.zshrc
map <leader>ez :e! ~/.zshrc<cr>
" edit gitconfig
map <leader>eg :e! ~/.gitconfig<cr>
" edit tmux config
map <leader>et :e! ~/.tmux.conf<cr>

map <silent> <C-h> :wincmd h<cr>
map <silent> <C-j> :wincmd j<cr>
map <silent> <C-k> :wincmd k<cr>
map <silent> <C-l> :wincmd l<cr>

"------------set to my own config----------------
"
"nnoremap <Left> :vertical resize -1<CR>
nnoremap <Right> :vertical resize +1<CR>
nnoremap <Up> :resize -1<CR>
nnoremap <Down> :resize +1<CR>
" Disable arrow keys completely in Insert Mode
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

"--------------------------------------------------
"


call plug#begin('~/.local/share/nvim/plugged')
Plug 'Shougo/unite.vim' "makes vim behave like normal ui
Plug 'Yggdroot/indentLine' "makes intendation possible
Plug 'airblade/vim-gitgutter' "git gutter
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ctrlpvim/ctrlp.vim', { 'on': 'CtrlP' } "fuzzy finder
Plug 'mhinz/vim-grepper' "find in files
Plug 'Shougo/vimfiler.vim', { 'on': 'VimFiler' } "file tree view
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'w0rp/ale' "async linting
Plug 'justinmk/vim-sneak' "sneaking in code
Plug 'chriskempson/base16-vim' "colors in vim
Plug 'christoomey/vim-tmux-navigator' "tmux integration
Plug 'Chiel92/vim-autoformat' " turn on autoformat
Plug 'tpope/vim-surround' " surrounding 
Plug 'mattn/emmet-vim' "emmet makes html easy
"Plug 'vim-syntastic/syntastic' "syntax highlighting for a lot of languages
"syntastic inteferes with ale...
Plug 'scrooloose/nerdcommenter' "makes multi line commenting possible
Plug 'scrooloose/nerdtree' "finder in vim
Plug 'jistr/vim-nerdtree-tabs' "allows to have only one tree and multiple tabs
Plug 'othree/javascript-libraries-syntax.vim' "javascript hotness :)
Plug 'leafgarland/typescript-vim' "insert typescript support
Plug 'matthewsimo/angular-vim-snippets' "snippets for angular
Plug 'pangloss/vim-javascript'
Plug 'othree/html5.vim'
Plug 'shawncplus/phpcomplete.vim'


call plug#end()

"Plug 'chriskempson/base16-vim' " colorschemes
if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

"indentLine
let g:indentLine_enabled = 1
"let g:indentLine_char = "❯"

"airline
let g:airline#extensions#tabline#enabled=1
let g:airline_powerline_fonts=1
let g:airline_theme='base16'
set laststatus=2

"CtrlP
nnoremap <Leader>p :CtrlP<CR>
nnoremap <Leader>t :CtrlP<CR>

"vim-grepper
nnoremap <Leader>fp :Grepper<Space>-query<Space>
nnoremap <Leader>fb :Grepper<Space>-buffers<Space>-query<Space>-<Space>

"vimfiler
"map ` :VimFiler -explorer<CR>
"map ~ :VimFilerCurrentDir -explorer -find<CR>

"deoplete
let g:deoplete#enable_at_startup = 1
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"

"vim-sneak
let g:sneak#s_next = 1
nmap f <Plug>Sneak_f
nmap F <Plug>Sneak_F
xmap f <Plug>Sneak_f
xmap F <Plug>Sneak_F
omap f <Plug>Sneak_f
omap F <Plug>Sneak_F

"tmux-navieator
nnoremap <silent> <BS> :TmuxNavigateLeft<cr>

"emmet
let g:user_emmet_leader_key='<C-space>'

"syntastic

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" map fuzzyfinder (CtrlP) plugin
let g:ctrlp_map='<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_dotfiles=1
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_user_command = 'find %s -type f' " MacOSX/Linux

"NERDTree settings
" close NERDTree after a file is opened
let g:NERDTreeQuitOnOpen=0
" show hidden files in NERDTree
let NERDTreeShowHidden=1
" Toggle NERDTree
map <Leader>k <plug>NERDTreeTabsToggle<CR>
let g:NERDTreeWinPos = "right"

"ale 

let g:ale_linters = {
\   'javascript': ['jslint'],
\}
