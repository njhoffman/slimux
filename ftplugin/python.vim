" These python keywords should not have extra newline at indentation level 0
let w:slimux_python_allowed_indent0 = ["elif", "else", "except", "finally"]

function! s:ShiftLeft(text, num)
  if a:num <= 0
      return a:text
  endif
  let l:result = substitute(a:text, '\v(^|\r?\n)\zs\s{1,' . a:num . '}', "", "g")
  return l:result
endfunction

function! s:CheckLeastIndent(text)
  let lines = split(a:text, '\n')
  let num_indent = len(a:text)
  for line in lines
      if match(line, '^\s*$') >= 0
          continue
      endif
      let indent = matchstr(line, '^\s*')
      let new_indent = len(indent)
      if new_indent >= 0 && new_indent < num_indent
          let num_indent = new_indent
      endif
  endfor
  return num_indent
endfunction

function! SlimuxEscape_python(text)
  " Remove Indent according to

  let notab_text = substitute(a:text, '\t', repeat(' ', &tabstop), 'g')
  let num_indent = s:CheckLeastIndent(notab_text)
  let l:shifted_text = s:ShiftLeft(notab_text, num_indent)

  "" Check if last line is empty in multiline selections
  let l:last_line_empty = match(l:shifted_text,'\n\W*\n$')

  "" Remove all empty lines and use soft linebreaks
  let no_empty_lines = substitute(l:shifted_text, '\n\s*\ze\n', "", "g")
  let no_empty_lines = substitute(no_empty_lines, "\n", "", "g")

  "" See if any non-empty lines sent at all
  if no_empty_lines == ""
      return ""
  endif

  "" Process line by line and insert needed linebreaks
  let l:non_processed_lines = split(no_empty_lines,"")
  let l:processed_lines = [l:non_processed_lines[0]]
  " Check initial indent level
  let l:first_word = matchstr(l:processed_lines[0],'^[a-zA-Z\"]\+')
  if !(l:first_word == "")
      let l:at_indent0 = 1
  else
      let l:at_indent0 = 0
  endif
  " Only actually anything to do if more than one line
  if len(l:non_processed_lines) > 1
      " Go through remaining lines
      for cur_line in l:non_processed_lines[1:]
          let l:first_word = matchstr(cur_line,'^[a-zA-Z\"]\+')
          if !(l:first_word == "")
              if index(w:slimux_python_allowed_indent0, l:first_word) > 0
                  " Keyword allowed at indent level 0
                  let l:processed_lines = l:processed_lines + [cur_line]
              else
                  if l:at_indent0
                      " Do not insert another newline when we are already
                      " at indent level 0
                      let l:processed_lines = l:processed_lines + [cur_line]
                  else
                      " Back at indent level 0. We need newline
                      let l:at_indent0 = 1
                      let l:processed_lines = l:processed_lines + ["".cur_line]
                  endif
              endif
          else
              " Not at indent level 0. Do not touch
              let l:at_indent0 = 0
              let l:processed_lines = l:processed_lines + [cur_line]
          endif
      endfor
  endif

  "" Return the processed lines
  if !l:at_indent0 && l:last_line_empty >= 0
      " We ended at indentation and last line was empty
      return join(l:processed_lines,"").""
  else
      return join(l:processed_lines,"").""
  endif
endfunction
