" Run in Screen Command-window
"
" Revised script based on vicle.vim and slime.vim.
"
" Usage:
"  <Leader><CR>: send highlighted text or current paragraph as command
"  <Leader><Up>: re-send most recent command
"  <Leader>\   : type in a new one-line command and send
"  <Leader>rr  : select from a list of historical commands and send
"  <Leader>rv  : set screen variables
"  <Leader>rh  : show history of sent commands
"  <Leader>rs  : show all screen sessions

if !exists("g:risc_cmd_list")
  let g:risc_cmd_list = []
endif
let g:risc_max_history = 5


" Send command to Screen.
function! Send_To_Screen(text)
  if (a:text == "")
    echo "Empty string won't be sent to Screen"
    return
  end

  if !exists("g:screen_sessionname") || !exists("g:screen_windowname")
    call Screen_Vars()
  end

  echohl WarningMsg 
  echo "Send the following command(s) to Screen [" . g:screen_sessionname . "/" . g:screen_windowname . "]?\n"
  echohl None
  echo Compact_Cmd(a:text)
  echohl WarningMsg
  if input("(Y/n?) ", "Y") == "Y"
    call Update_Cmd_History(a:text)
    let cur_cmd = substitute(a:text, "'", "'\\\\''", 'g')
    echo system("screen -S " . g:screen_sessionname . " -p " . g:screen_windowname . " -X stuff '" . cur_cmd . "'")
  else
    let tmp = input("Cancelled", "")
  endif
  echohl None
endfunction

" Update list of historical commands.
function! Update_Cmd_History(cmd)
  if (get(g:risc_cmd_list, -1, "") != a:cmd)
    if len(g:risc_cmd_list) == g:risc_max_history
      unlet g:risc_cmd_list[0]
    endif
    call add(g:risc_cmd_list, a:cmd)
  endif
endfunction

" Per word file path completion.
function! PerWordFileComplete(A, L, P)
  let to_complete = a:A
  let rest = ''
  let pos = strridx(a:A, ' ')
  let tc_len = strlen(a:A) - pos - 1
  if pos >= 0 && tc_len > 0
    let to_complete = strpart(a:A, pos + 1, tc_len)
    let rest = strpart(a:A, 0, pos + 1)
  endif
  return substitute(globpath("./", to_complete . "*"), "\\./", rest, 'g')
endfunction

" Send a new one-line command to Screen.
function! Send_One_Line_Cmd()
  let g:one_line_cmd = input("$ ", "", "custom,PerWordFileComplete")
  call Send_To_Screen(g:one_line_cmd . "\n")
endfunction

" Send the most recent command to Screen.
function! Send_Most_Recent_Cmd()
  if len(g:risc_cmd_list) > 0
    call Send_To_Screen(g:risc_cmd_list[-1])
  endif
endfunction

" Ask to choose from a list historical command to send to Screen.
function! Send_Historical_Cmd()
  let g:cmd_choices = ['Select historical command:']
  let index = 1
  while index <= len(g:risc_cmd_list)
    call add(g:cmd_choices, "[" . index . "] " . Compact_Cmd(g:risc_cmd_list[index - 1]))
    let index = index + 1
  endwhile
  let g:choice = inputlist(g:cmd_choices) + 0
  if g:choice > 0
    call Send_To_Screen(g:risc_cmd_list[g:choice - 1])
  endif
endfunction

" Find GNU Screen names.
function! Screen_Session_Names(A, L, P)
  return system("screen -ls | awk '/Attached/ {print $1}'")
endfunction

" Set GNU Screen related parameters.
function! Screen_Vars()
  if !exists("g:screen_sessionname") || !exists("g:screen_windowname")
    let g:screen_sessionname = $STY
    let g:screen_windowname = "0"
  end

  let g:screen_sessionname = input("session name: ", $STY, "custom,Screen_Session_Names")
  let g:screen_windowname = input("window name: ", g:screen_windowname)
endfunction

" Show list of historical commmands.
function! Show_Cmd_History()
  if exists("g:risc_cmd_list")
    let index = 1
    while index <= len(g:risc_cmd_list)
      echo "[ -------------- " . index . " -------------- ]\n". g:risc_cmd_list[index - 1]
      let index = index + 1
    endwhile
  else
    echo "No command in history"
  endif
endfunction

" Compact multi-line command into a single line one.
function! Compact_Cmd(cmd)
  let cmp_cmd = substitute(a:cmd, " *\\\\ *\n *", ' ', 'g')
  return substitute(cmp_cmd, "\n", ' ¶ ' , 'g')
endfunction

" Show compact list of historical commands.
function! Show_Compact_Cmd_History()
  if exists("g:risc_cmd_list")
    let index = 1
    while index <= len(g:risc_cmd_list)
      echo "[" . index . "] ". Compact_Cmd(g:risc_cmd_list[index - 1])
      let index = index + 1
    endwhile
  else
    echo "No command in history"
  endif
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

vmap <Leader><CR> "ry :call Send_To_Screen(@r)<CR>
nmap <Leader><CR> vip"ry :call Send_To_Screen(@r)<CR>
nmap <Leader><Up> :call Send_Most_Recent_Cmd()<CR>
nmap <Leader>\ :call Send_One_Line_Cmd()<CR>

nmap <Leader>rr :call Send_Historical_Cmd()<CR>
nmap <Leader>rv :call Screen_Vars()<CR>
nmap <Leader>rh :call Show_Cmd_History()<CR>
nmap <Leader>rs :echo Screen_Session_Names()<CR>


