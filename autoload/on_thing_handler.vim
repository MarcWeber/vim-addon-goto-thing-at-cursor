" Example:
" call on_thing_handler#AddOnThingHandler('g',"[substitute(expand('<cWORD>'),'\\.','/','g').'\.lhs']")
" call on_thing_handler#AddOnThingHandler('g',funcref#Function('foo#Bar'))
"
" handler returns one of
" a afile path:  "filename.file"
" a dict: { 'break': 1, 'filename' : file [, 'line_nr' line nr ] [, 'info' : 'shown before filename'] }
"
" if there is one match which has break set all matches which don't have this
" flag set are disregarded
function! on_thing_handler#AddOnThingHandler(scope, handler)
  if !exists(a:scope.':on_thing_handler')
    exec 'let '.a:scope.':on_thing_handler = []'
  endif
  exec 'call add('.a:scope.':on_thing_handler,'.string(a:handler).')'
endfunction

function! s:DoesFileExist(value)
  if type(a:value) == type("")
    let filename = a:value
  elseif type(a:value) == type({})
    let filename = a:value['filename']
  else
    let filename = a:value[0]
  endif
  return filereadable(expand(filename))
endif
endfunction

function! s:GotoLocation(value)
  if type(a:value) == type("")
    if a:value == ""
      return 
    endif
    let filename = a:value
    let line_nr = -1
  elseif type(a:value) == type({})
    let filename = a:value['filename']
    let line_nr = get(a:value, 'line_nr', -1)
  else
    let filename = a:value[0]
    let line_nr = a:value[1]
  endif
  exec ":e ".filename
  if line_nr >= 0
    exec line_nr
  endif
endfunction

function! s:ParseItemStr(value)
  if a:value =~ ', line '
    let line = matchstr('\d*$',a:value)
    return [ substitute(a:value,', line .*','',''), line ]
  else
    return a:value
  endif
endfunction
  
function! s:ToItemStr(value)
  if type(a:value) == type("")
    return a:value
  elseif type(a:value) == type({})
    if has_key(a:value,'line_nr')
      return a:value['filename'].', line '.a:value['line_nr']
    else
      return a:value['filename']
    endif
  else
    return a:value[0].', line '.a:value[1]
  endif
endfunction

fun! s:GotoFile(list)
  let list_shown = map(copy(a:list),'type(v:val) == type({}) ? ((has_key(v:val,"line_nr") ? v:val["info"]." " : "").v:val["filename"].(has_key(v:val,"line_nr") ? ":".v:val["line_nr"] : "")) : v:val')
  echo list_shown
  let index = tlib#input#List("i","choose file to jump to", list_shown)
  if index != ''
    call s:GotoLocation(a:list[index-1])
    return 1
  else
    return 0
  endif
endf

"|func  Use this function in your mapping in a ftplugin file like this:
"|code  noremap gf :call tovl#ui#open_thing_at_cursor#HandleOnThing()<cr>
function! on_thing_handler#HandleOnThing()
  let pos = getpos('.')
  let possibleFiles = []

  " collect buffer and global handlers:
  let buffer_handlers =
    \ exists('b:on_thing_handler')
    \ ? b:on_thing_handler
    \ : []
  let global_handlers =
    \ exists('g:on_thing_handler')
    \ ? g:on_thing_handler
    \ : []

  for h in buffer_handlers + global_handlers
    call setpos('.',pos)
    call extend(possibleFiles, funcref#Call(h))
    unlet h
  endfor

  " always use default handler as well
  call extend(possibleFiles, s:DefaultHandler())
  let possibleFiles = tlib#list#Uniq(possibleFiles)
  


  " one has break set?
  let breaks = filter(copy(possibleFiles), 'type(v:val) == type({}) && get(v:val,"break") == 1')
  if len(breaks) > 0
    let possibleFiles = breaks
  endif

  " if one file exists use that
  let existingFiles = filter(deepcopy(possibleFiles), 's:DoesFileExist(v:val)')

  if !s:GotoFile(existingFiles)
    call s:GotoFile(possibleFiles)
  endif
endfunction 

function! s:DefaultHandler()
  let s = expand('<cfile>')
  return s == "" ? [] : [s]
endfunction

function! on_thing_handler#OnThingTagList(tag)
  let l = []
  for match in taglist(a:tag)
    if match(get(match,'cmd',''),'^\d\+$') >= 0
      " we are lucky, line numbers are given
      call add(l, [match['filename'], match['cmd']])
    else
      call add(l, match['filename'])
    endif
  endfor
  return l
endfunction