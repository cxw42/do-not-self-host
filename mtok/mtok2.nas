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
:main_loop

    ; Get the token code
    in                  ; char ]

    ; Are we done?
    dup                 ; char char ]
    iseof               ; char flag ]
    cjump &main_done    ; char ]

    ; Save the token code
    dup                 ; char char ]
    store &curr_token   ; char ]

    ; Get the count
    numin               ; char count ]
    store &data_len     ; char ]

    call &read_token_text   ; char ]

    ; Strip T_IGNORE
    dup                 ; char char ]
    eq T_IGNORE         ; char flag ]
    jump &main_loop     ; char char ]

    ; TODO rewrite barewords

    ; Emit the token code
    dup                 ; char char ]
    out                 ; char ]

    ; TODO emit the token text if necessary

    jump &main_loop     ; char ]

; end main loop }}}2

:main_done
    end

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

    return;

; Read *&data_len characters into the buffer
    ; Initialize
    .lit &buf
    store &curr_char_ptr


; === Data === {{{2
:curr_char_ptr
    .data 0

:buf
    .reserve 256
; }}}2
; }}}1

; vi: set fdm=marker fdl=1:
