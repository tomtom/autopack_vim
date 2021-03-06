" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2019-04-23
" @Revision:    225


if !exists('g:loaded_tlib') " optional
    " :nodoc:
    command! -nargs=+ -bang Tlibtrace :
endif


if !exists('g:autopack#packf')
    let g:autopack#packf = ['%s_vim', '%s.vim', 'vim-%s']   "{{{2
endif


if !exists('g:autopack#use_cmdundefined')
    " If true, use the |CmdUndefined| event for |:Autocommand|. This has 
    " the disadvantage that the command isn't known to vim. Hence, 
    " command-line completion doesn't work. It has the advantage that 
    " the functionality is provided by vim.
    let g:autopack#use_cmdundefined = 0   "{{{2
endif


if !exists('g:autopack#verbose')
    let g:autopack#verbose = &verbose >= 2   "{{{2
endif


if !exists('g:autopack#prelude_ignore_filenames_rx')
    " When creating |g:autopack_prelude|, ignore filenames matching this 
    " |regexp|.
    let g:autopack#prelude_ignore_filenames_rx = ''   "{{{2
endif


if !exists('g:autopack#use_packadd')
    let g:autopack#use_packadd = exists(':packadd') == 2   "{{{2
endif


function! autopack#NewAutocommand(args) abort "{{{3
    let [pack; cmds] = a:args
    for cmd in cmds
        if exists(':'. cmd) == 2
            echom 'Autopack: Skip already defined command:' cmd
        else
            if g:autopack#use_cmdundefined
                exec 'autocmd Autopack CmdUndefined' cmd 'call s:Loadplugin(' string(pack) ')'
            else
                exec printf('command! -bang -nargs=? %s call s:Loadcommand(%s, %s, %s .''<bang> ''. <q-args>)',
                            \ cmd,
                            \ string(pack),
                            \ string(cmd),
                            \ string(cmd))
            endif
        endif
    endfor
endf


let s:loaded_pack = {}

function! s:IsLoaded(pack) abort "{{{3
    return has_key(s:loaded_pack, a:pack)
endf


let s:undefine = {}


function! s:AddUndefine(pack, undef) abort "{{{3
    Tlibtrace 'autopack', a:pack, a:undef
    if empty(a:pack)
        echoerr string(a:pack) a:undef
    endif
    if !has_key(s:undefine, a:pack)
        let s:undefine[a:pack] = [a:undef]
    else
        call add(s:undefine[a:pack], a:undef)
    endif
endf


let s:loaded_config = {'ft': {}, 'after': {}, 'before': {}}

function! s:ConfigPack(packname, type) abort "{{{3
    Tlibtrace 'autopack', a:packname, a:type
    if !has_key(s:loaded_config[a:type], a:packname)
        let s:loaded_config[a:type][a:packname] = 1
        let cfg = g:autopack_configs_dir .'/'. a:type .'/'. a:packname .'.vim'
        Tlibtrace 'autopack', cfg
        call s:Message('Autopack: try loading "'. a:type .'" config for '. a:packname)
        exec 'runtime!' cfg
    endif
endf


function! s:GetPackName(filename) abort "{{{3
    return matchstr(a:filename, '[\/]pack[\/][^\/]\+[\/]\%(opt\|start\)[\/]\zs[^\/]\+')
endf


function! autopack#ConfigPack(filename) abort "{{{3
    let packname = s:GetPackName(a:filename)
    call s:ConfigPack(packname, 'before')
endf


function! autopack#AfterLoadingPack(filename) abort "{{{3
    let packname = s:GetPackName(a:filename)
    call s:ConfigPack(packname, 'after')
endf


function! autopack#Packadd(bang, packname) abort "{{{3
    call s:ConfigPack(a:packname, 'before')
    exec 'packadd'.a:bang a:packname
    call s:ConfigPack(a:packname, 'after')
endf


function! s:GetRealPackName(pack, ...) abort "{{{3
    if !exists('s:packs')
        let opt_packs = globpath(&packpath, 'pack/*/opt/*', 1, 1)
        " let start_packs = globpath(&packpath, 'pack/*/start/*', 1, 1)
        let s:packs = {}
        for packdir in opt_packs
            let packname = s:GetPackName(packdir)
            let s:packs[packname] = packdir
        endfor
    endif
    if has_key(s:packs, a:pack)
        return a:pack
    else
        let pack0 = a:0 >= 1 ? a:1 : a:pack
        let fmts = a:0 >= 2 ? a:2 : copy(g:autopack#packf)
        if empty(fmts)
            return ''
        else
            let fmt = remove(fmts, 0)
            let pack1 = printf(fmt, pack0)
            return s:GetRealPackName(pack1, pack0, fmts)
        endif
    endif
endf


function! s:Loadplugin(pack) abort "{{{3
    Tlibtrace 'autopack', a:pack
    let pack = s:GetRealPackName(a:pack)
    if !empty(pack) && !s:IsLoaded(pack)
        let s:loaded_pack[pack] = 1
        if has_key(s:undefine, pack)
            for undef in s:undefine[pack]
                Tlibtrace 'autopack', undef
                silent! exec undef
            endfor
            call remove(s:undefine, pack)
        endif
        call s:ConfigPack(pack, 'before')
        call s:Message('Autopack: Load plugin '. a:pack)
        if g:autopack#use_packadd
            exec 'packadd' fnameescape(pack)
        else
            let rtp = split(&runtimepath, ',')
            let paths = map(globpath(&runtimepath, 'pack/*/*/'. pack, 0, 1), 'fnamemodify(v:val, ":p")')
            for path in paths
                call insert(rtp, escape(substitute(path, '[\/]$', '', ''), ','), 1)
                let after = path .'/after'
                if isdirectory(after)
                    call insert(rtp, escape(after, ','), -1)
                endif
            endfor
            let &runtimepath = join(rtp, ',')
            exec 'runtime pack/*/*/'. pack .'/plugin/*.vim'
        endif
        call s:ConfigPack(pack, 'after')
    endif
endf


function! s:Loadcommand(pack, cmd, exec) abort "{{{3
    Tlibtrace 'autopack', a:pack, a:cmd, a:exec
    exec 'delcommand' a:cmd
    call s:Loadplugin(a:pack)
    try
        exec a:exec
    catch
        echohl ErrorMsg
        echom 'Autopack: Error loading command:' a:cmd
        echom 'Autopack: Error when calling:' a:exec
        echom 'Autopack:' v:exception
        echohl NONE
    endtry
endf


function! autopack#FuncUndefined(pattern) abort "{{{3
    let pack = matchstr(a:pattern, '^[a-zA-Z_]\+\ze#')
    Tlibtrace 'autopack', a:pattern, pack
    if !empty(pack)
        call s:Loadplugin(pack)
    endif
endf


let s:filepatternpacks = {}

function! autopack#NewFilepattern(args) abort "{{{3
    let [pack; filepatterns] = a:args
    Tlibtrace 'autopack', pack, filepatterns
    let frxs = map(filepatterns, 'glob2regpat(v:val)')
    Tlibtrace 'autopack', frxs
    for frx in frxs
        if !has('fname_case')
            let frx = '\c'. frx
        endif
        let fpacks = get(s:filepatternpacks, frx, [])
        let fpacks = add(fpacks, pack)
        let s:filepatternpacks[frx] = fpacks
    endfor
endf


function! autopack#Filetypepatterns(filename) abort "{{{3
    Tlibtrace 'autopack', a:filename
    for [frx, packs] in items(s:filepatternpacks)
        if a:filename =~# frx
            Tlibtrace 'autopack', frx, packs
            unlet! s:filepatternpacks[frx]
            for pack in packs
                call s:Loadplugin(pack)
            endfor
        endif
    endfor
endf


let s:filetypepacks = {}

function! autopack#NewFiletype(args) abort "{{{3
    let [filetype; packs] = a:args
    let fpacks = get(s:filetypepacks, filetype, []) + packs
    let s:filetypepacks[filetype] = fpacks
    let [pack; filetypes] = a:args
    for ft in filetypes
        let fpacks = get(s:filetypepacks, ft, [])
        call add(fpacks, pack)
        let s:filetypepacks[ft] = fpacks
    endfor
endf


let s:loaded_ft = {}

function! autopack#AutoFiletype(ft) abort "{{{3
    Tlibtrace 'autopack', a:ft
    if !has_key(s:loaded_ft, a:ft)
        let s:loaded_ft[a:ft] = 1
        call s:ConfigPack(a:ft, 'ft')
        let packs = globpath(&runtimepath, 'pack/ft_'. a:ft .'/opt/*', 0, 1)
        Tlibtrace 'autopack', packs
        if has_key(s:filetypepacks, a:ft)
            let packs = s:filetypepacks[a:ft]
            Tlibtrace 'autopack', a:ft, packs
            unlet s:filetypepacks[a:ft]
            for pack in packs
                call s:Loadplugin(pack)
            endfor
        endif
        for packdir in packs
            let pack = matchstr(packdir, '[^\\/]\+$')
            Tlibtrace 'autopack', packdir, pack
            if !empty(pack)
                call s:Loadplugin(pack)
            endif
        endfor
        exec 'doautocmd FileType' a:ft
    endif
endf


" Define a dummy map that will load PACK upon first invocation.
" Examples:
"   call autopack#Map(['tmarks_vim', '<silent> <f2> :TMarks<cr>'])
"   call autopack#Map(['tmarks_vim', '<silent>', '<f2>', ':TMarks<cr>'])
function! autopack#NewMap(args) abort "{{{3
    let [pack; argl] = a:args
    if s:IsLoaded(pack)
        return
    endif
    Tlibtrace 'autopack', pack, argl
    let mcmd = 'map'
    let args = []
    let lhs = ''
    let rhs = ''
    let mode = 'cmd'
    let idx = 0
    let margs = type(argl) == 3 ? argl : split(argl, ' \+')
    Tlibtrace 'autopack', margs
    let nargs = len(margs)
    while idx < nargs
        let item = margs[idx]
        if mode ==# 'cmd'
            if item =~# '^.\?\(nore\)\?map$'
                let mcmd = item
            else
                let mode = 'args'
                continue
            endif
        elseif mode ==# 'args'
            if item =~# '^<\(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>$'
                call add(args, item)
            else
                let mode = 'lhs'
                continue
            endif
        elseif mode ==# 'lhs'
            let lhs = item
            let mode = 'rhs'
        elseif mode ==# 'rhs'
            let rhs = join(margs[idx : -1])
            break
        endif
        let idx += 1
    endwh
    Tlibtrace 'autopack', mcmd, lhs, rhs
    let mapmode = matchstr(mcmd, '^.\?\ze\(nore\)\?map$')
    if !empty(maparg(lhs, mapmode))
        echom 'Autopack: Skip already defined map:' mcmd lhs rhs
    else
        let sargs = join(args)
        let unmap = substitute(mcmd, '\(nore\)\?\zemap$', 'un', '')
        call s:AddUndefine(pack, unmap .' '. lhs)
        if empty(rhs)
            let rhs1 = rhs
        else
            let undef = printf('%s %s %s %s', mcmd, sargs, lhs, rhs)
            call s:AddUndefine(pack, undef)
            let rhs1 = substitute(rhs, '<', '<lt>', 'g')
        endif
        let lhs1 = substitute(lhs, '<', '<lt>', 'g')
        let [pre, post] = s:GetMapPrePost(mcmd)
        let cmd = printf('%s:call <SID>Autopackmap(%s, %s, %s, %s, %s)<cr>%s',
                    \ pre, string(mcmd), string(sargs), string(lhs1), string(pack), string(rhs1), post)
        let map = [mcmd, sargs, lhs, cmd]
        Tlibtrace 'autopack', map
        exec join(map)
    endif
endf


function! s:GetMapPrePost(map) abort "{{{3
    let mode = matchstr(a:map, '\([incvoslx]\?\)\ze\(nore\)\?map')
    if mode ==# 'n'
        let pre  = ''
        let post = ''
    elseif mode ==# 'i'
        let pre = '<c-\><c-o>'
        let post = ''
    elseif mode ==# 'v' || mode ==# 'x'
        let pre = '<c-c>'
        let post = '<C-\><C-G>'
    elseif mode ==# 'c'
        let pre = '<c-c>'
        let post = '<C-\><C-G>'
    elseif mode ==# 'o'
        let pre = '<c-c>'
        let post = '<C-\><C-G>'
    else
        let pre  = ''
        let post = ''
    endif
    return [pre, post]
endf


function! s:Autopackmap(mcmd, args, lhs, pack, rhs) abort "{{{3
    " TLogVAR a:mcmd, a:args, a:lhs, a:pack, a:rhs
    " let unmap = substitute(a:mcmd, '\(nore\)\?\zemap$', 'un', '')
    " " TLogVAR unmap, a:lhs
    " exec unmap a:lhs
    call s:Loadplugin(a:pack)
    if !empty(a:rhs)
        exec a:mcmd a:args a:lhs a:rhs
    endif
    let lhs = a:lhs
    let ml = exists('g:mapleader') ? g:mapleader : '\'
    let lhs = substitute(lhs, '\c<leader>', escape(ml, '\'), 'g')
    if exists('g:maplocalleader')
        let lhs = substitute(lhs, '\c<localleader>', escape(g:maplocalleader, '\'), 'g')
    endif
    let lhs = substitute(lhs, '<\ze\w\+\(-\w\+\)*>', '\\<', 'g')
    let lhs = eval('"'. escape(lhs, '"') .'"')
    if a:mcmd =~# '^[vx]'
        let lhs = 'gv'. lhs
    elseif a:mcmd =~# '^[s]'
        let lhs = "<c-g>gv". lhs
    endif
    " TLogVAR lhs
    call feedkeys(lhs, 't')
endf


function! s:Message(text) abort "{{{3
    if g:autopack#verbose
        echohl Message
        echom a:text
        echohl NONE
    endif
endf


" Generate the |g:autopack_prelude|, which currently only includes:
" - ftdetect files
function! autopack#MakePrelude() abort "{{{3
    let packrcs = globpath(&runtimepath, g:autopack_configs_dir, 0, 1)
    if empty(packrcs)
        echoerr 'Cannot find' g:autopack_configs_dir 'in &runtimepath'
    else
        let lines = []
        let ftdetect = globpath(&packpath, 'pack/*/opt/*/ftdetect/*.vim', 0, 1)
        if !empty(g:autopack#prelude_ignore_filenames_rx)
            let ftdetect = filter(ftdetect, 'v:val !~# g:autopack#prelude_ignore_filenames_rx')
        endif
        if !empty(ftdetect)
            let pattern_done = {}
            for filename in ftdetect
                let pack = matchstr(filename, '[\/]pack[\/][^\/]\+[\/]opt[\/]\zs[^\/]\+')
                let flines = readfile(filename)
                for fline in flines
                    let pattern = matchstr(fline, '^\s*au\%[tocmd]\s\+\S\{-}\<\%(BufNewFile\|BufRead\)\>\S*\s\+\zs\S\+')
                    " let patterns = matchstr(fline, '^\s*au\%[tocmd]\s\+\S\{-}\<\%(BufNewFile\|BufRead\)\>\S*\s\+\zs\S\+')
                    " for pattern in split(patterns, ',')
                        let id = pack .'|'. pattern
                        if !empty(pattern) && !has_key(pattern_done, id)
                            let pattern_done[id] = 1
                            call add(lines, printf('Autofilepattern %s %s', pack, pattern))
                        endif
                    " endfor
                endfor
                " let flines = filter(flines, 'v:val !~# ''^\s*aug\%[roup]\>''')
                " let lines += flines
            endfor
        endif
        let lines = filter(lines, 'v:val =~# ''\S'' && v:val !~# ''^\s*"''')
        call insert(lines, '" This file was automatically generated. Do not edit!')
        let prelude = substitute(packrcs[0], '[\/]*$', '/', '') . g:autopack_prelude
        Tlibtrace 'autopack', prelude, len(lines)
        call writefile(lines, prelude)
        echom 'Autopack: Wrote' prelude
    endif
endf

