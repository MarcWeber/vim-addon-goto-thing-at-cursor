*vim-plugin-goto-thing-at-cursor.txt*

Add your own handlers to gf mapping.
This way you can jump to tags, git hashs, class names etc.

------------------------------------------------------------------------------
customization ~
You can use another lhs of a mapping this way: >
  let g['config']['goto-thing-handler-mapping-lhs'] = 'gf'
>
>
Adding your own handlers: >

  call add(g:on_thing_handler)
<



