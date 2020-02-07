if !exists('g:vim_addon_goto_thing_at_cursor') | let g:vim_addon_goto_thing_at_cursor = {} | endif | let s:c = g:vim_addon_goto_thing_at_cursor
let s:c['goto-thing-handler-mapping-lhs'] = get(s:c, 'goto-thing-handler-mapping-lhs', '\gf')

exec 'noremap '.s:c['goto-thing-handler-mapping-lhs'].' :call on_thing_handler#HandleOnThing()<cr>'
