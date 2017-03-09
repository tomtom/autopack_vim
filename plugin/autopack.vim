" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-16
" @Revision:    44
" GetLatestVimScripts: 5526 0 :AutoInstall: autopack.vim
" Load VIM packages as needed

if &cp || exists("loaded_autopack")
    finish
endif
let loaded_autopack = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:autopack_configs_dir')
    " The directory where |g:autopack_config| and other config files are 
    " located.
    " Pack-related configs are in `packrc/pack/NAME.vim`.
    " Filetype-related configs are in `packrc/ft/FILETYPE.vim`.
    let g:autopack_configs_dir = 'packrc'   "{{{2
endif


if !exists('g:autopack_config')
    " Load this file when enabling the autopack plugin. This file is 
    " useful for defining automaps and autocommands.
    let g:autopack_config = g:autopack_configs_dir .'/autorc.vim'   "{{{2
endif


" :display: :Autocommand PACK COMMAND...
" Load PACK when invoking COMMAND for the first time.
command! -nargs=+ Autocommand call autopack#NewAutocommand([<f-args>])

" :display: :Automap PACK MAP
" Load PACK when invoking MAP for the first time. MAP can be any |:map| 
" related command.
"
" Example >
"     Automap ttoc_vim nnoremap <Leader>cc :TToC<cr>
command! -nargs=+ Automap call autopack#NewMap([<f-args>])

" :display: :Autofiletype PACK FILETYPE...
" Load PACK when editing a file with FILETYPE for the first time. 
" Multiple filetypes can be gives.
command! -nargs=+ Autofiletype call autopack#NewFiletype([<f-args>])

" :display: :Autofilepattern PACK GLOB_PATTERN...
" Load PACK when editing a file matching GLOB_PATTERN for the first 
" time. Multiple filename patterns can be gives.
command! -nargs=+ Autofilepattern call autopack#NewFilepattern([<f-args>])

" command! -nargs=+ Autoautoload call autopack#Autoautoload(<q-args>)
" command! -nargs=+ Autofunction call autopack#Autofunction(<q-args>)


augroup Autopack
    autocmd!
    autocmd FuncUndefined * call autopack#FuncUndefined(expand("<afile>"))
    autocmd FileType * call autopack#AutoFiletype(expand("<amatch>"))
    autocmd SourcePre */pack/* call autopack#ConfigPack(expand("<amatch>"))
    autocmd BufReadPre,BufNew * call autopack#Filetypepatterns(expand("<afile>"))
augroup END


if has('vim_starting')
    autocmd Autopack VimEnter * exec 'runtime!' g:autopack_config
else
    exec 'runtime!' g:autopack_config
endif


let &cpo = s:save_cpo
unlet s:save_cpo
