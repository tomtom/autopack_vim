" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-01-19
" @Revision:    106


if !exists('g:loaded_tlib')
    " :nodoc:
    command! -nargs=+ -bang Tlibtrace :
    " :nodoc:
    command! -nargs=+ -bang Tlibassert :
    " :nodoc:
    command! -nargs=+ Tlibtype :
endif


if !exists('g:autopack#packf')
    let g:autopack#packf = ['%s_vim', '%s.vim', 'vim-%s']   "{{{2
endif


function! autopack#Autocommand(args) abort "{{{3
    let [pack, cmd] = a:args
    exec printf('command! -bang -nargs=? %s call s:Loadcommand(%s, %s, %s .''<bang> ''. <q-args>)',
                \ cmd,
                \ string(pack),
                \ string(cmd),
                \ string(cmd))
endf


let s:loaded_pack = {}

function! s:IsLoaded(pack) abort "{{{3
    return has_key(s:loaded_pack, a:pack)
endf


let s:undefine = {}


function! s:AddUndefine(pack, undef) "{{{3
    Tlibtrace 'autopack', a:pack, a:undef
    if empty(a:pack)
        echoerr string(a:plugins) a:undef
    endif
    if !has_key(s:undefine, a:pack)
        let s:undefine[a:pack] = [a:undef]
    else
        call add(s:undefine[a:pack], a:undef)
    endif
endf


let s:loaded_config = {}

function! s:ConfigPack(packname, type) abort "{{{3
    if !has_key(s:loaded_config, a:packname)
        let s:loaded_config[a:packname] = 1
        let cfg = g:autopack_configs_dir .'/'. a:type .'/'. a:packname .'.vim'
        exec 'runtime!' cfg
        Tlibtrace 'autopack', cfg
    endif
endf


function! s:GetPackName(filename) abort "{{{3
    return matchstr(a:filename, '[\/]pack[\/][^\/]\+[\/]\%(opt\|start\)[\/]\zs[^\/]\+')
endf


function! autopack#ConfigPack(filename) abort "{{{3
    let packname = s:GetPackName(a:filename)
    call s:ConfigPack(packname, 'pack')
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
        call s:ConfigPack(pack, 'pack')
        if exists(':packadd') == 2
            exec 'packadd' fnameescape(pack)
        else
            let rtp = split(&rtp, ',')
            let rtp1 = join(map(globpath(&rtp, 'pack/*/*/'. pack), 'escape(v:val, ",")') ',')
            call insert(rtp, rtp1, 1)
            let &rtp = join(rtp, ',')
            exec 'runtime pack/*/*/'. pack .'/plugin/*.vim'
        endif
    endif
endf


function! s:Loadcommand(pack, cmd, exec) abort "{{{3
    Tlibtrace 'autopack', a:pack, a:cmd, a:exec
    exec 'delcommand' a:cmd
    call s:Loadplugin(a:pack)
    exec a:exec
endf


function! autopack#FuncUndefined(pattern) abort "{{{3
    let pack = matchstr(a:pattern, '^[a-zA-Z_]\+\ze#')
    Tlibtrace 'autopack', a:pattern, pack
    if !empty(pack)
        call s:Loadplugin(pack)
    endif
endf


let s:loaded_ft = {}

function! autopack#AutoFiletype(ft) abort "{{{3
    Tlibtrace 'autopack', a:ft
    if !has_key(s:loaded_ft, a:ft)
        let s:loaded_ft[a:ft] = 1
        call s:ConfigPack(a:ft, 'ft')
        let packs = globpath(&rtp, 'pack/ft_'. a:ft .'/opt/*', 0, 1)
        Tlibtrace 'autopack', packs
        for packdir in packs
            let pack = matchstr(packdir, '[\\/]\+$')
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
function! autopack#Map(args) abort "{{{3
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
        if mode == 'cmd'
            if item =~# '^.\?\(nore\)\?map$'
                let mcmd = item
            else
                let mode = 'args'
                continue
            endif
        elseif mode == 'args'
            if item =~# '^<\(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>$'
                call add(args, item)
            else
                let mode = 'lhs'
                continue
            endif
        elseif mode == 'lhs'
            let lhs = item
            let mode = 'rhs'
        elseif mode == 'rhs'
            let rhs = join(margs[idx : -1])
            break
        endif
        let idx += 1
    endwh
    Tlibtrace 'autopack', mcmd, lhs, rhs
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
endf


function! s:GetMapPrePost(map) "{{{3
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


function! s:Autopackmap(mcmd, args, lhs, pack, rhs) "{{{3
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
    if a:mcmd =~ '^[vx]'
        let lhs = 'gv'. lhs
    elseif a:mcmd =~ '^[s]'
        let lhs = "<c-g>gv". lhs
    endif
    " TLogVAR lhs
    call feedkeys(lhs, 't')
endf

