
fun! vim_addon_goto_thing_at_cursor#by_language#SETUP()
  augroup jslike
  silent! au!
  au BufRead,BufNewFile *.ts,*.js call on_thing_handler#AddOnThingHandler('b', funcref#Function('vim_addon_goto_thing_at_cursor#by_language#JS_LIKE_REQUIRE'))
  au BufRead,BufNewFile *.nix call on_thing_handler#AddOnThingHandler('b', funcref#Function('vim_addon_goto_thing_at_cursor#by_language#gfHandler'))
  buf
  augroup end
endf

fun! vim_addon_goto_thing_at_cursor#by_language#JS_LIKE_REQUIRE()
  let rel = matchstr(getline('.'), "require(['\"]\\zs[^'\"]*\\ze['\"])")
  if rel == "" | return [] | endif
  let r = []
  for ext in ['.js', '.ts', '/index.js', '/index.ts']
    call add(r, expand('%:h').'/' . rel . ext)
  endfor

  call extend(r, split(glob( 'node_modules/' . rel . '/index.js' ), "\n"))
  call extend(r, split(glob( 'node_modules/' . rel . '/index.ts' ), "\n"))
  return map(r, 'expand(v:val)')
endf

fun! vim_addon_goto_thing_at_cursor#by_language#gfHandler()
  let res = [ expand(expand('%:h').'/'.matchstr(expand('<cWORD>'),'[^;()[\]]*')) ]
  for match in [matchstr(getline('.'), 'import\s*\zs[^;) \t]\+\ze'), matchstr(getline('.'), 'call\S*\s*\zs[^;) \t]\+\ze')]
    if match == "" | continue | endif
    call add(res, expand('%:h').'/'.match)
  endfor

  " if import string is a directory append '/default.nix' :
  " everything not having an extension is treated as directory

  call map(res, 'v:val =~ '.string('\.[^./]\+$').' ? v:val : v:val.'.string('/default.nix'))

  let list = matchlist(getline('.'), '.*selectVersion\s\+\(\S*\)\s\+"\([^"]\+\)"')
  if (!empty(list))
    " something like this has been matched selectVersion ../applications/version-management/codeville "0.8.0"
    call add(res, expand('%:h').'/'.list[1].'/'.list[2].'.nix')
  else
    " something with var instead of "0.8.x" has been matched
    let list = matchlist(getline('.'), '.*selectVersion\s\+\(\S*\)\s\+\(\S\+\)')
    if (!empty(list))
      call extend(res, split(glob(expand('%:h').'/'.list[1].'/*.nix'), "\n"))
      " also add subdirectory files (there won't be that many)
      call extend(res, filter(split(glob(expand('%:h').'/'.list[1].'/*/*.nix'), "\n"),'1'))
    endif
  endif
  return res
endf
