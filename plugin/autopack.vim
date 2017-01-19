" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-01-18
" @Revision:    26
" GetLatestVimScripts: 0 0 :AutoInstall: autopack.vim
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


command! -nargs=+ Autocommand call autopack#Autocommand([<f-args>])
command! -nargs=+ Automap call autopack#Map([<f-args>])

" command! -nargs=+ Autofilepattern call autopack#Filetypepatterns([<f-args>])
" command! -nargs=+ Autoautoload call autopack#Autoautoload(<q-args>)
" command! -nargs=+ Autofunction call autopack#Autofunction(<q-args>)


augroup Autopack
    autocmd!
    autocmd FuncUndefined * call autopack#FuncUndefined(expand("<afile>"))
    autocmd FileType * call autopack#AutoFiletype(expand("<amatch>"))
    autocmd SourcePre */pack/* call autopack#ConfigPack(expand("<amatch>"))
    " autocmd BufReadPre,BufNew * call autopack#Filetypepatterns(expand("<afile>"))
augroup END


exec 'runtime!' g:autopack_config


let &cpo = s:save_cpo
unlet s:save_cpo
