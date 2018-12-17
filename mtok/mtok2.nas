; mtok2.nas: Minhi tokenizer, pass 2.
; Copyright (c) 201T8 Chris White.
;
; mtok.nas produces tokens and token values.  This pass filters out the
; token values for all except identifiers and numbers, and removes all "Ignore"
; tokens.
; It also rewrites bareword operators to the operator tokens.

    .include ../minhi-constants.nas

; === Globals ============================================================= {{{1

:curr_token     ; The token we're currently processing
    .data 0

:data_len       ; How many chars of token to eat
    .data 0

; }}}1
; === Main ================================================================ {{{1

:main

    ; Main loop.  Each time through handles one token.  {{{2
:main_loop              ; ]

    ; Get the token code
    in                  ; char ]

    ; Are we done?
    dup                 ; char char ]
    iseof               ; char flag ]   - EOF on the input stream
    cjump &main_done    ; char ]

    dup                 ; char char ]
    eq T_EOF            ; char flag ]   - EOF token from mtok
    cjump &main_done    ; char ]

    ; Save the token code
    dup                 ; char char ]
    store &curr_token   ; char ]

    ; Get the count
    numin               ; char count ]
    dup                 ; char count count ]
    store &data_len     ; char count ]

    ; out '` ; DEBUG
    call &read_token_text   ; char count ]
    ; out '' ; DEBUG

    ; Strip T_IGNORE
    swap                ; count char ]
    dup                 ; count char char ]
    eq T_IGNORE         ; count char flag ]
    cjump &main_ignore  ; count char ]

    ; TODO rewrite barewords that are operators to tokens for those operators

    ; TODO merge adjacent string literals so 'x''y' -> q{'x'y'}

    ; Emit the token
    out                 ; count ]
    dup                 ; count count ]
    numout              ; count ]

    ; Emit the token text.
    call &write_token_text

    drop                ; ]
    jump &main_loop     ; ]

; end main loop }}}2

:main_done
    out T_EOF
    out 'A                  ; == numout 0 => no token data

:main_done_silent
    end

:main_ignore            ; count char ]
    drop                ; count ]
    drop                ; count ]
    jump &main_loop

; }}}1
; === Buffer routines and data ============================================ {{{1

; Add the character at TOS to the buffer
:stash_char                 ; char ]

    ; Save the char
    fetch &curr_char_ptr    ; char ptr ]
    store                   ; ]

    ; Increment the pointer
    fetch &curr_char_ptr    ; ptr ]
    add 1
    store &curr_char_ptr

    return

; read_token_text: Read TOS characters into &buf.  Leaves the stack unchanged. {{{2
:read_token_text            ; count ]
    ; Initialize
    dup                     ; count count ]
    lit &buf
    store &curr_char_ptr
    ; FALL THROUGH into &rtt_loop

:rtt_loop                   ; c count ]
    dup                     ; c count count ]
    eq 0                    ; c count flag ]
    cjump &rtt_done         ; c count ]
    sub 1                   ; c adjusted_count ]

    in                      ; c adjusted_count char ]
    fetch &curr_char_ptr    ; c adjusted_count char *char]
    store                   ; c adjusted_count ]

    ; Increment pointer
    fetch &curr_char_ptr
    add 1
    store &curr_char_ptr

    jump &rtt_loop

:rtt_done                   ; count 0 ]
    drop                    ; count ]
    return  ; }}}2

; write_token_text: Write TOS characters from &buf.  Leaves the stack unchanged. {{{2
:write_token_text           ; count ]
    ; Initialize
    dup                     ; count count ]
    lit &buf                ; c count ptr ]
    swap                    ; c ptr count ]
    ; FALL THROUGH into &wtt_loop

:wtt_loop                   ; c ptr count ]

    ; Test count
    dup                     ; c ptr count count ]
    eq 0                    ; c ptr count flag ]
    cjump &wtt_done         ; c ptr count ]
    sub 1                   ; c ptr adjusted_count ]

    ; Write the current char
    swap                    ; c adjusted_count ptr ]
    dup                     ; c ac ptr ptr
    fetch                   ; c ac ptr char ]
    out                     ; c ac ptr ]

    ; Point to next char
    add 1                   ; c ac adjusted_ptr ]
    swap                    ; c adjusted_ptr adjusted_count ]

    jump &wtt_loop

:wtt_done                   ; count ptr 0 ]
    drop                    ; count ptr ]
    drop                    ; count ]
    return ; }}}2


; === Data === {{{2
:curr_char_ptr
    .data 0

:buf
    .reserve 256
; }}}2
; }}}1

; vi: set fdm=marker fdl=1:
