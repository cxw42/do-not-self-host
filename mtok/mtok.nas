; mtok.nas: tokenizer for Minhi.
; Copyright (c) 2018 cxw42.  Licensed MIT.

.include ../minhi-constants.nas

; This tokenizer recognizes the language:
;   <sigil><alpha>(<alpha>|<specialalpha...>|<digit>)*
; | <digit>+
; (future) | 0[obx]<digit>+
; | '(<alpha>|<specialalpha...>|<digit>|<other nonquote>)*'
;       (for now, no way to represent "'"!)
; | <=>                         (spaceship)
; | ?? | :: | -> | -
; | <= | >= | < | > | == | <> | =
; |
; | not | and | or | neg | mod
; | <operpunc>
;
; P: <operpunc> ::= [()"\[\]^*/+,;]
; D: digits ::= [0-9]
; S: sigil ::= [&$#!@%]
; specialalpha ::= n|o|t|a|d|r|e|g|m
;   (letters used in named operators)
; B: all other alpha
; N: other nonquote ::= all punc not otherwise accounted for, except "'"
;   = [`~_{}\\|;". ]
; Q: [?]

; In https://cyberzhg.github.io/toolbox/nfa2dfa , that becomes:
; S(n|o|t|a|d|r|e|g|m|B)(n|o|t|a|d|r|e|g|m|B|D)*|D+|'(n|o|t|a|d|r|e|g|m|B|D|P|N)*'|QQ|::|<=>|->|<=|>=|==|<>|<|>|=|P|not|and|or|neg|mod
; with the result given in ./mtok.xlsx.

; === Character classes ====================================================

; these are from mtok.csv.
.const CC_QUOTE     ''
.const CC_HYPHEN    '-
.const CC_COLON     ':
.const CC_LT        '<
.const CC_EQUAL     '=
.const CC_GT        '>
.const CC_XB        1
.const CC_XD        2
.const CC_XN        3
.const CC_XP        4
.const CC_XQ        5
.const CC_XS        6
.const CC_a         'a
.const CC_d         'd
.const CC_e         'e
.const CC_g         'g
.const CC_m         'm
.const CC_n         'n
.const CC_o         'o
.const CC_r         'r
.const CC_t         't

; === States ===============================================================

; Reminder: update this from below if you re-run state-machine.py

; STATE TABLE
; zero-based so they can be used in a jump table

.const S_A 0
.const S_B 1
.const S_C 2
.const S_D 3
.const S_E 4
.const S_F 5
.const S_G 6
.const S_H 7
.const S_I 8
.const S_J 9
.const S_K 10
.const S_L 11
.const S_M 12
.const S_N 13
.const S_O 14
.const S_P 15
.const S_Q 16
.const S_R 17
.const S_S 18
.const S_T 19
.const S_U 20
.const S_V 21
.const S_W 22
.const S_X 23
.const S_Y 24
.const S_Z 25
.const S_AA 26
.const S_AB 27
.const S_AC 28
.const S_AD 29
.const S_AE 30
.const S_AF 31
.const S_AG 32
.const S_AH 33
.const S_AI 34
.const S_AJ 35
.const S_AK 36
.const S_AL 37
.const S_AM 38
.const S_AN 39
.const S_AO 40
.const S_AP 41
.const S_AQ 42
.const S_AR 43
.const S_AS 44
.const S_AT 45
.const S_AU 46
.const S_AV 47
.const S_AW 48
.const S_AX 49
.const S_AY 50
.const S_AZ 51
.const S_BA 52
.const S_BB 53
.const S_BC 54
.const S_BD 55
.const S_BE 56
.const S_BF 57
.const S_BG 58
.const S_BH 59
.const S_BI 60
.const S_BJ 61
.const S_BK 62
.const S_BL 63
.const S_BM 64
.const S_BN 65
.const S_BO 66
.const S_BP 67

.const S_COMPLETE 65534     ; a token is complete
;.const S_NONE 65535

; === Globals ==============================================================

:state
    .data 0

; ASCII values of the current and next char (if any)
;:char
;    .data 0
;:nextchar
;    .data 0

; Character classes of the current char
;:issigil
;    .data 0
;:isalpha
;    .data 0
;:isalnum
;    .data 0
;:isdigit
;    .data 0
;:isnonquote     ; valid in a string: [^']
;    .data 0
;:ispunc         ; single-char operator punctuation: [()"\[\]^-*/%+,;]
;    .data 0

; === Get character class ==================================================

:get_cclass
    end ; TODO

; === Main =================================================================
:main

    ; Initialize
    .lit S_A
    store &state

    jump &next  ; condition is at the bottom of the loop

:loop           ; char ]

    ; Get the character class
    call &get_cclass    ; cclass ]

    ; Check state transitions
    fetch &state            ; cclass state ]
    call &get_next_state    ; next_state ]

    dup                 ; next_state next_state ]
    neq S_COMPLETE      ; next_state flag ]
    cjump next          ; next_state ]

    ; a token is complete; emit it
    call emit_token     ; ]

:next
    in          ; char ]
    iseof       ; char flag ]
    cjump &done ; char ]

    ;; Put the current character at TOS and in &char.
    ;dup             ; char char ]
    ;store &char     ; char ]

    jump &loop

:done
end

; === State machine ========================================================

; Jump table for state routines
:state_table


; === State machine ========================================================

; Jump table for state routines.  Call this.
; Inputs are:
;   TOS: The current state
;   NOS: The next character class
; Outputs are:
;   - On failure, abort
;   - On success, leave the next state at TOS, above the next cclass.

:get_next_state
    .lit &state_handler_list    ; cclass state baseaddr ]
    add                         ; cclass jumpaddr ]
    jump    ; to the right routine for this state.  ; cclass ]
:state_handler_list

.lit &state_handler_A
.lit &state_handler_B
.lit &state_handler_C
.lit &state_handler_D
.lit &state_handler_E
.lit &state_handler_F
.lit &state_handler_G
.lit &state_handler_H
.lit &state_handler_I
.lit &state_handler_J
.lit &state_handler_K
.lit &state_handler_L
.lit &state_handler_M
.lit &state_handler_N
.lit &state_handler_O
.lit &state_handler_P
.lit &state_handler_Q
.lit &state_handler_R
.lit &state_handler_S
.lit &state_handler_T
.lit &state_handler_U
.lit &state_handler_V
.lit &state_handler_W
.lit &state_handler_X
.lit &state_handler_Y
.lit &state_handler_Z
.lit &state_handler_AA
.lit &state_handler_AB
.lit &state_handler_AC
.lit &state_handler_AD
.lit &state_handler_AE
.lit &state_handler_AF
.lit &state_handler_AG
.lit &state_handler_AH
.lit &state_handler_AI
.lit &state_handler_AJ
.lit &state_handler_AK
.lit &state_handler_AL
.lit &state_handler_AM
.lit &state_handler_AN
.lit &state_handler_AO
.lit &state_handler_AP
.lit &state_handler_AQ
.lit &state_handler_AR
.lit &state_handler_AS
.lit &state_handler_AT
.lit &state_handler_AU
.lit &state_handler_AV
.lit &state_handler_AW
.lit &state_handler_AX
.lit &state_handler_AY
.lit &state_handler_AZ
.lit &state_handler_BA
.lit &state_handler_BB
.lit &state_handler_BC
.lit &state_handler_BD
.lit &state_handler_BE
.lit &state_handler_BF
.lit &state_handler_BG
.lit &state_handler_BH
.lit &state_handler_BI
.lit &state_handler_BJ
.lit &state_handler_BK
.lit &state_handler_BL
.lit &state_handler_BM
.lit &state_handler_BN
.lit &state_handler_BO
.lit &state_handler_BP

; Handler routines.
; Input: the current input type on the top of the stack
; Output: the new state on top of the stack, if any.
;         Aborts the program if no match.

:state_handler_A ;-----------
:sh_A_0
    dup
    neq 0
    cjump sh_A_1
    .lit S_B
    return

:sh_A_1
    dup
    neq 1
    cjump sh_A_2
    .lit S_C
    return

:sh_A_2
    dup
    neq 2
    cjump sh_A_3
    .lit S_D
    return

:sh_A_3
    dup
    neq 3
    cjump sh_A_4
    .lit S_E
    return

:sh_A_4
    dup
    neq 4
    cjump sh_A_5
    .lit S_F
    return

:sh_A_5
    dup
    neq 5
    cjump sh_A_6
    .lit S_G
    return

:sh_A_6
    dup
    neq 7
    cjump sh_A_7
    .lit S_H
    return

:sh_A_7
    dup
    neq 9
    cjump sh_A_8
    .lit S_I
    return

:sh_A_8
    dup
    neq 10
    cjump sh_A_9
    .lit S_J
    return

:sh_A_9
    dup
    neq 11
    cjump sh_A_10
    .lit S_K
    return

:sh_A_10
    dup
    neq 12
    cjump sh_A_11
    .lit S_L
    return

:sh_A_11
    dup
    neq 16
    cjump sh_A_12
    .lit S_M
    return

:sh_A_12
    dup
    neq 17
    cjump sh_A_13
    .lit S_N
    return

:sh_A_13
    dup
    neq 18
    cjump sh_A_14
    .lit S_O
    return

:sh_A_14
    end

:state_handler_B ;-----------
:sh_B_0
    dup
    neq 0
    cjump sh_B_1
    .lit S_P
    return

:sh_B_1
    dup
    neq 6
    cjump sh_B_2
    .lit S_Q
    return

:sh_B_2
    dup
    neq 7
    cjump sh_B_3
    .lit S_R
    return

:sh_B_3
    dup
    neq 8
    cjump sh_B_4
    .lit S_S
    return

:sh_B_4
    dup
    neq 9
    cjump sh_B_5
    .lit S_T
    return

:sh_B_5
    dup
    neq 12
    cjump sh_B_6
    .lit S_U
    return

:sh_B_6
    dup
    neq 13
    cjump sh_B_7
    .lit S_V
    return

:sh_B_7
    dup
    neq 14
    cjump sh_B_8
    .lit S_W
    return

:sh_B_8
    dup
    neq 15
    cjump sh_B_9
    .lit S_X
    return

:sh_B_9
    dup
    neq 16
    cjump sh_B_10
    .lit S_Y
    return

:sh_B_10
    dup
    neq 17
    cjump sh_B_11
    .lit S_Z
    return

:sh_B_11
    dup
    neq 18
    cjump sh_B_12
    .lit S_AA
    return

:sh_B_12
    dup
    neq 19
    cjump sh_B_13
    .lit S_AB
    return

:sh_B_13
    dup
    neq 20
    cjump sh_B_14
    .lit S_AC
    return

:sh_B_14
    end

:state_handler_C ;-----------
:sh_C_0
    dup
    neq 5
    cjump sh_C_1
    .lit S_AD
    return

:sh_C_1
    end

:state_handler_D ;-----------
:sh_D_0
    dup
    neq 2
    cjump sh_D_1
    .lit S_AE
    return

:sh_D_1
    end

:state_handler_E ;-----------
:sh_E_0
    dup
    neq 4
    cjump sh_E_1
    .lit S_AF
    return

:sh_E_1
    dup
    neq 5
    cjump sh_E_2
    .lit S_AG
    return

:sh_E_2
    .lit S_COMPLETE
    return

:state_handler_F ;-----------
:sh_F_0
    dup
    neq 4
    cjump sh_F_1
    .lit S_AH
    return

:sh_F_1
    .lit S_COMPLETE
    return

:state_handler_G ;-----------
:sh_G_0
    dup
    neq 4
    cjump sh_G_1
    .lit S_AI
    return

:sh_G_1
    .lit S_COMPLETE
    return

:state_handler_H ;-----------
:sh_H_0
    dup
    neq 7
    cjump sh_H_1
    .lit S_AJ
    return

:sh_H_1
    .lit S_COMPLETE
    return

:state_handler_I ;-----------
:sh_I_0
    .lit S_COMPLETE
    return

:state_handler_J ;-----------
:sh_J_0
    dup
    neq 10
    cjump sh_J_1
    .lit S_AK
    return

:sh_J_1
    end

:state_handler_K ;-----------
:sh_K_0
    dup
    neq 6
    cjump sh_K_1
    .lit S_AL
    return

:sh_K_1
    dup
    neq 12
    cjump sh_K_2
    .lit S_AM
    return

:sh_K_2
    dup
    neq 13
    cjump sh_K_3
    .lit S_AN
    return

:sh_K_3
    dup
    neq 14
    cjump sh_K_4
    .lit S_AO
    return

:sh_K_4
    dup
    neq 15
    cjump sh_K_5
    .lit S_AP
    return

:sh_K_5
    dup
    neq 16
    cjump sh_K_6
    .lit S_AQ
    return

:sh_K_6
    dup
    neq 17
    cjump sh_K_7
    .lit S_AR
    return

:sh_K_7
    dup
    neq 18
    cjump sh_K_8
    .lit S_AS
    return

:sh_K_8
    dup
    neq 19
    cjump sh_K_9
    .lit S_AT
    return

:sh_K_9
    dup
    neq 20
    cjump sh_K_10
    .lit S_AU
    return

:sh_K_10
    end

:state_handler_L ;-----------
:sh_L_0
    dup
    neq 17
    cjump sh_L_1
    .lit S_AV
    return

:sh_L_1
    end

:state_handler_M ;-----------
:sh_M_0
    dup
    neq 18
    cjump sh_M_1
    .lit S_AW
    return

:sh_M_1
    end

:state_handler_N ;-----------
:sh_N_0
    dup
    neq 14
    cjump sh_N_1
    .lit S_AX
    return

:sh_N_1
    dup
    neq 18
    cjump sh_N_2
    .lit S_AY
    return

:sh_N_2
    end

:state_handler_O ;-----------
:sh_O_0
    dup
    neq 19
    cjump sh_O_1
    .lit S_AZ
    return

:sh_O_1
    end

:state_handler_P ;-----------
:sh_P_0
    .lit S_COMPLETE
    return

:state_handler_Q ;-----------
:sh_Q_0
    dup
    neq 0
    cjump sh_Q_1
    .lit S_P
    return

:sh_Q_1
    dup
    neq 6
    cjump sh_Q_2
    .lit S_Q
    return

:sh_Q_2
    dup
    neq 7
    cjump sh_Q_3
    .lit S_R
    return

:sh_Q_3
    dup
    neq 8
    cjump sh_Q_4
    .lit S_S
    return

:sh_Q_4
    dup
    neq 9
    cjump sh_Q_5
    .lit S_T
    return

:sh_Q_5
    dup
    neq 12
    cjump sh_Q_6
    .lit S_U
    return

:sh_Q_6
    dup
    neq 13
    cjump sh_Q_7
    .lit S_V
    return

:sh_Q_7
    dup
    neq 14
    cjump sh_Q_8
    .lit S_W
    return

:sh_Q_8
    dup
    neq 15
    cjump sh_Q_9
    .lit S_X
    return

:sh_Q_9
    dup
    neq 16
    cjump sh_Q_10
    .lit S_Y
    return

:sh_Q_10
    dup
    neq 17
    cjump sh_Q_11
    .lit S_Z
    return

:sh_Q_11
    dup
    neq 18
    cjump sh_Q_12
    .lit S_AA
    return

:sh_Q_12
    dup
    neq 19
    cjump sh_Q_13
    .lit S_AB
    return

:sh_Q_13
    dup
    neq 20
    cjump sh_Q_14
    .lit S_AC
    return

:sh_Q_14
    end

:state_handler_R ;-----------
:sh_R_0
    dup
    neq 0
    cjump sh_R_1
    .lit S_P
    return

:sh_R_1
    dup
    neq 6
    cjump sh_R_2
    .lit S_Q
    return

:sh_R_2
    dup
    neq 7
    cjump sh_R_3
    .lit S_R
    return

:sh_R_3
    dup
    neq 8
    cjump sh_R_4
    .lit S_S
    return

:sh_R_4
    dup
    neq 9
    cjump sh_R_5
    .lit S_T
    return

:sh_R_5
    dup
    neq 12
    cjump sh_R_6
    .lit S_U
    return

:sh_R_6
    dup
    neq 13
    cjump sh_R_7
    .lit S_V
    return

:sh_R_7
    dup
    neq 14
    cjump sh_R_8
    .lit S_W
    return

:sh_R_8
    dup
    neq 15
    cjump sh_R_9
    .lit S_X
    return

:sh_R_9
    dup
    neq 16
    cjump sh_R_10
    .lit S_Y
    return

:sh_R_10
    dup
    neq 17
    cjump sh_R_11
    .lit S_Z
    return

:sh_R_11
    dup
    neq 18
    cjump sh_R_12
    .lit S_AA
    return

:sh_R_12
    dup
    neq 19
    cjump sh_R_13
    .lit S_AB
    return

:sh_R_13
    dup
    neq 20
    cjump sh_R_14
    .lit S_AC
    return

:sh_R_14
    end

:state_handler_S ;-----------
:sh_S_0
    dup
    neq 0
    cjump sh_S_1
    .lit S_P
    return

:sh_S_1
    dup
    neq 6
    cjump sh_S_2
    .lit S_Q
    return

:sh_S_2
    dup
    neq 7
    cjump sh_S_3
    .lit S_R
    return

:sh_S_3
    dup
    neq 8
    cjump sh_S_4
    .lit S_S
    return

:sh_S_4
    dup
    neq 9
    cjump sh_S_5
    .lit S_T
    return

:sh_S_5
    dup
    neq 12
    cjump sh_S_6
    .lit S_U
    return

:sh_S_6
    dup
    neq 13
    cjump sh_S_7
    .lit S_V
    return

:sh_S_7
    dup
    neq 14
    cjump sh_S_8
    .lit S_W
    return

:sh_S_8
    dup
    neq 15
    cjump sh_S_9
    .lit S_X
    return

:sh_S_9
    dup
    neq 16
    cjump sh_S_10
    .lit S_Y
    return

:sh_S_10
    dup
    neq 17
    cjump sh_S_11
    .lit S_Z
    return

:sh_S_11
    dup
    neq 18
    cjump sh_S_12
    .lit S_AA
    return

:sh_S_12
    dup
    neq 19
    cjump sh_S_13
    .lit S_AB
    return

:sh_S_13
    dup
    neq 20
    cjump sh_S_14
    .lit S_AC
    return

:sh_S_14
    end

:state_handler_T ;-----------
:sh_T_0
    dup
    neq 0
    cjump sh_T_1
    .lit S_P
    return

:sh_T_1
    dup
    neq 6
    cjump sh_T_2
    .lit S_Q
    return

:sh_T_2
    dup
    neq 7
    cjump sh_T_3
    .lit S_R
    return

:sh_T_3
    dup
    neq 8
    cjump sh_T_4
    .lit S_S
    return

:sh_T_4
    dup
    neq 9
    cjump sh_T_5
    .lit S_T
    return

:sh_T_5
    dup
    neq 12
    cjump sh_T_6
    .lit S_U
    return

:sh_T_6
    dup
    neq 13
    cjump sh_T_7
    .lit S_V
    return

:sh_T_7
    dup
    neq 14
    cjump sh_T_8
    .lit S_W
    return

:sh_T_8
    dup
    neq 15
    cjump sh_T_9
    .lit S_X
    return

:sh_T_9
    dup
    neq 16
    cjump sh_T_10
    .lit S_Y
    return

:sh_T_10
    dup
    neq 17
    cjump sh_T_11
    .lit S_Z
    return

:sh_T_11
    dup
    neq 18
    cjump sh_T_12
    .lit S_AA
    return

:sh_T_12
    dup
    neq 19
    cjump sh_T_13
    .lit S_AB
    return

:sh_T_13
    dup
    neq 20
    cjump sh_T_14
    .lit S_AC
    return

:sh_T_14
    end

:state_handler_U ;-----------
:sh_U_0
    dup
    neq 0
    cjump sh_U_1
    .lit S_P
    return

:sh_U_1
    dup
    neq 6
    cjump sh_U_2
    .lit S_Q
    return

:sh_U_2
    dup
    neq 7
    cjump sh_U_3
    .lit S_R
    return

:sh_U_3
    dup
    neq 8
    cjump sh_U_4
    .lit S_S
    return

:sh_U_4
    dup
    neq 9
    cjump sh_U_5
    .lit S_T
    return

:sh_U_5
    dup
    neq 12
    cjump sh_U_6
    .lit S_U
    return

:sh_U_6
    dup
    neq 13
    cjump sh_U_7
    .lit S_V
    return

:sh_U_7
    dup
    neq 14
    cjump sh_U_8
    .lit S_W
    return

:sh_U_8
    dup
    neq 15
    cjump sh_U_9
    .lit S_X
    return

:sh_U_9
    dup
    neq 16
    cjump sh_U_10
    .lit S_Y
    return

:sh_U_10
    dup
    neq 17
    cjump sh_U_11
    .lit S_Z
    return

:sh_U_11
    dup
    neq 18
    cjump sh_U_12
    .lit S_AA
    return

:sh_U_12
    dup
    neq 19
    cjump sh_U_13
    .lit S_AB
    return

:sh_U_13
    dup
    neq 20
    cjump sh_U_14
    .lit S_AC
    return

:sh_U_14
    end

:state_handler_V ;-----------
:sh_V_0
    dup
    neq 0
    cjump sh_V_1
    .lit S_P
    return

:sh_V_1
    dup
    neq 6
    cjump sh_V_2
    .lit S_Q
    return

:sh_V_2
    dup
    neq 7
    cjump sh_V_3
    .lit S_R
    return

:sh_V_3
    dup
    neq 8
    cjump sh_V_4
    .lit S_S
    return

:sh_V_4
    dup
    neq 9
    cjump sh_V_5
    .lit S_T
    return

:sh_V_5
    dup
    neq 12
    cjump sh_V_6
    .lit S_U
    return

:sh_V_6
    dup
    neq 13
    cjump sh_V_7
    .lit S_V
    return

:sh_V_7
    dup
    neq 14
    cjump sh_V_8
    .lit S_W
    return

:sh_V_8
    dup
    neq 15
    cjump sh_V_9
    .lit S_X
    return

:sh_V_9
    dup
    neq 16
    cjump sh_V_10
    .lit S_Y
    return

:sh_V_10
    dup
    neq 17
    cjump sh_V_11
    .lit S_Z
    return

:sh_V_11
    dup
    neq 18
    cjump sh_V_12
    .lit S_AA
    return

:sh_V_12
    dup
    neq 19
    cjump sh_V_13
    .lit S_AB
    return

:sh_V_13
    dup
    neq 20
    cjump sh_V_14
    .lit S_AC
    return

:sh_V_14
    end

:state_handler_W ;-----------
:sh_W_0
    dup
    neq 0
    cjump sh_W_1
    .lit S_P
    return

:sh_W_1
    dup
    neq 6
    cjump sh_W_2
    .lit S_Q
    return

:sh_W_2
    dup
    neq 7
    cjump sh_W_3
    .lit S_R
    return

:sh_W_3
    dup
    neq 8
    cjump sh_W_4
    .lit S_S
    return

:sh_W_4
    dup
    neq 9
    cjump sh_W_5
    .lit S_T
    return

:sh_W_5
    dup
    neq 12
    cjump sh_W_6
    .lit S_U
    return

:sh_W_6
    dup
    neq 13
    cjump sh_W_7
    .lit S_V
    return

:sh_W_7
    dup
    neq 14
    cjump sh_W_8
    .lit S_W
    return

:sh_W_8
    dup
    neq 15
    cjump sh_W_9
    .lit S_X
    return

:sh_W_9
    dup
    neq 16
    cjump sh_W_10
    .lit S_Y
    return

:sh_W_10
    dup
    neq 17
    cjump sh_W_11
    .lit S_Z
    return

:sh_W_11
    dup
    neq 18
    cjump sh_W_12
    .lit S_AA
    return

:sh_W_12
    dup
    neq 19
    cjump sh_W_13
    .lit S_AB
    return

:sh_W_13
    dup
    neq 20
    cjump sh_W_14
    .lit S_AC
    return

:sh_W_14
    end

:state_handler_X ;-----------
:sh_X_0
    dup
    neq 0
    cjump sh_X_1
    .lit S_P
    return

:sh_X_1
    dup
    neq 6
    cjump sh_X_2
    .lit S_Q
    return

:sh_X_2
    dup
    neq 7
    cjump sh_X_3
    .lit S_R
    return

:sh_X_3
    dup
    neq 8
    cjump sh_X_4
    .lit S_S
    return

:sh_X_4
    dup
    neq 9
    cjump sh_X_5
    .lit S_T
    return

:sh_X_5
    dup
    neq 12
    cjump sh_X_6
    .lit S_U
    return

:sh_X_6
    dup
    neq 13
    cjump sh_X_7
    .lit S_V
    return

:sh_X_7
    dup
    neq 14
    cjump sh_X_8
    .lit S_W
    return

:sh_X_8
    dup
    neq 15
    cjump sh_X_9
    .lit S_X
    return

:sh_X_9
    dup
    neq 16
    cjump sh_X_10
    .lit S_Y
    return

:sh_X_10
    dup
    neq 17
    cjump sh_X_11
    .lit S_Z
    return

:sh_X_11
    dup
    neq 18
    cjump sh_X_12
    .lit S_AA
    return

:sh_X_12
    dup
    neq 19
    cjump sh_X_13
    .lit S_AB
    return

:sh_X_13
    dup
    neq 20
    cjump sh_X_14
    .lit S_AC
    return

:sh_X_14
    end

:state_handler_Y ;-----------
:sh_Y_0
    dup
    neq 0
    cjump sh_Y_1
    .lit S_P
    return

:sh_Y_1
    dup
    neq 6
    cjump sh_Y_2
    .lit S_Q
    return

:sh_Y_2
    dup
    neq 7
    cjump sh_Y_3
    .lit S_R
    return

:sh_Y_3
    dup
    neq 8
    cjump sh_Y_4
    .lit S_S
    return

:sh_Y_4
    dup
    neq 9
    cjump sh_Y_5
    .lit S_T
    return

:sh_Y_5
    dup
    neq 12
    cjump sh_Y_6
    .lit S_U
    return

:sh_Y_6
    dup
    neq 13
    cjump sh_Y_7
    .lit S_V
    return

:sh_Y_7
    dup
    neq 14
    cjump sh_Y_8
    .lit S_W
    return

:sh_Y_8
    dup
    neq 15
    cjump sh_Y_9
    .lit S_X
    return

:sh_Y_9
    dup
    neq 16
    cjump sh_Y_10
    .lit S_Y
    return

:sh_Y_10
    dup
    neq 17
    cjump sh_Y_11
    .lit S_Z
    return

:sh_Y_11
    dup
    neq 18
    cjump sh_Y_12
    .lit S_AA
    return

:sh_Y_12
    dup
    neq 19
    cjump sh_Y_13
    .lit S_AB
    return

:sh_Y_13
    dup
    neq 20
    cjump sh_Y_14
    .lit S_AC
    return

:sh_Y_14
    end

:state_handler_Z ;-----------
:sh_Z_0
    dup
    neq 0
    cjump sh_Z_1
    .lit S_P
    return

:sh_Z_1
    dup
    neq 6
    cjump sh_Z_2
    .lit S_Q
    return

:sh_Z_2
    dup
    neq 7
    cjump sh_Z_3
    .lit S_R
    return

:sh_Z_3
    dup
    neq 8
    cjump sh_Z_4
    .lit S_S
    return

:sh_Z_4
    dup
    neq 9
    cjump sh_Z_5
    .lit S_T
    return

:sh_Z_5
    dup
    neq 12
    cjump sh_Z_6
    .lit S_U
    return

:sh_Z_6
    dup
    neq 13
    cjump sh_Z_7
    .lit S_V
    return

:sh_Z_7
    dup
    neq 14
    cjump sh_Z_8
    .lit S_W
    return

:sh_Z_8
    dup
    neq 15
    cjump sh_Z_9
    .lit S_X
    return

:sh_Z_9
    dup
    neq 16
    cjump sh_Z_10
    .lit S_Y
    return

:sh_Z_10
    dup
    neq 17
    cjump sh_Z_11
    .lit S_Z
    return

:sh_Z_11
    dup
    neq 18
    cjump sh_Z_12
    .lit S_AA
    return

:sh_Z_12
    dup
    neq 19
    cjump sh_Z_13
    .lit S_AB
    return

:sh_Z_13
    dup
    neq 20
    cjump sh_Z_14
    .lit S_AC
    return

:sh_Z_14
    end

:state_handler_AA ;-----------
:sh_AA_0
    dup
    neq 0
    cjump sh_AA_1
    .lit S_P
    return

:sh_AA_1
    dup
    neq 6
    cjump sh_AA_2
    .lit S_Q
    return

:sh_AA_2
    dup
    neq 7
    cjump sh_AA_3
    .lit S_R
    return

:sh_AA_3
    dup
    neq 8
    cjump sh_AA_4
    .lit S_S
    return

:sh_AA_4
    dup
    neq 9
    cjump sh_AA_5
    .lit S_T
    return

:sh_AA_5
    dup
    neq 12
    cjump sh_AA_6
    .lit S_U
    return

:sh_AA_6
    dup
    neq 13
    cjump sh_AA_7
    .lit S_V
    return

:sh_AA_7
    dup
    neq 14
    cjump sh_AA_8
    .lit S_W
    return

:sh_AA_8
    dup
    neq 15
    cjump sh_AA_9
    .lit S_X
    return

:sh_AA_9
    dup
    neq 16
    cjump sh_AA_10
    .lit S_Y
    return

:sh_AA_10
    dup
    neq 17
    cjump sh_AA_11
    .lit S_Z
    return

:sh_AA_11
    dup
    neq 18
    cjump sh_AA_12
    .lit S_AA
    return

:sh_AA_12
    dup
    neq 19
    cjump sh_AA_13
    .lit S_AB
    return

:sh_AA_13
    dup
    neq 20
    cjump sh_AA_14
    .lit S_AC
    return

:sh_AA_14
    end

:state_handler_AB ;-----------
:sh_AB_0
    dup
    neq 0
    cjump sh_AB_1
    .lit S_P
    return

:sh_AB_1
    dup
    neq 6
    cjump sh_AB_2
    .lit S_Q
    return

:sh_AB_2
    dup
    neq 7
    cjump sh_AB_3
    .lit S_R
    return

:sh_AB_3
    dup
    neq 8
    cjump sh_AB_4
    .lit S_S
    return

:sh_AB_4
    dup
    neq 9
    cjump sh_AB_5
    .lit S_T
    return

:sh_AB_5
    dup
    neq 12
    cjump sh_AB_6
    .lit S_U
    return

:sh_AB_6
    dup
    neq 13
    cjump sh_AB_7
    .lit S_V
    return

:sh_AB_7
    dup
    neq 14
    cjump sh_AB_8
    .lit S_W
    return

:sh_AB_8
    dup
    neq 15
    cjump sh_AB_9
    .lit S_X
    return

:sh_AB_9
    dup
    neq 16
    cjump sh_AB_10
    .lit S_Y
    return

:sh_AB_10
    dup
    neq 17
    cjump sh_AB_11
    .lit S_Z
    return

:sh_AB_11
    dup
    neq 18
    cjump sh_AB_12
    .lit S_AA
    return

:sh_AB_12
    dup
    neq 19
    cjump sh_AB_13
    .lit S_AB
    return

:sh_AB_13
    dup
    neq 20
    cjump sh_AB_14
    .lit S_AC
    return

:sh_AB_14
    end

:state_handler_AC ;-----------
:sh_AC_0
    dup
    neq 0
    cjump sh_AC_1
    .lit S_P
    return

:sh_AC_1
    dup
    neq 6
    cjump sh_AC_2
    .lit S_Q
    return

:sh_AC_2
    dup
    neq 7
    cjump sh_AC_3
    .lit S_R
    return

:sh_AC_3
    dup
    neq 8
    cjump sh_AC_4
    .lit S_S
    return

:sh_AC_4
    dup
    neq 9
    cjump sh_AC_5
    .lit S_T
    return

:sh_AC_5
    dup
    neq 12
    cjump sh_AC_6
    .lit S_U
    return

:sh_AC_6
    dup
    neq 13
    cjump sh_AC_7
    .lit S_V
    return

:sh_AC_7
    dup
    neq 14
    cjump sh_AC_8
    .lit S_W
    return

:sh_AC_8
    dup
    neq 15
    cjump sh_AC_9
    .lit S_X
    return

:sh_AC_9
    dup
    neq 16
    cjump sh_AC_10
    .lit S_Y
    return

:sh_AC_10
    dup
    neq 17
    cjump sh_AC_11
    .lit S_Z
    return

:sh_AC_11
    dup
    neq 18
    cjump sh_AC_12
    .lit S_AA
    return

:sh_AC_12
    dup
    neq 19
    cjump sh_AC_13
    .lit S_AB
    return

:sh_AC_13
    dup
    neq 20
    cjump sh_AC_14
    .lit S_AC
    return

:sh_AC_14
    end

:state_handler_AD ;-----------
:sh_AD_0
    .lit S_COMPLETE
    return

:state_handler_AE ;-----------
:sh_AE_0
    .lit S_COMPLETE
    return

:state_handler_AF ;-----------
:sh_AF_0
    dup
    neq 5
    cjump sh_AF_1
    .lit S_BA
    return

:sh_AF_1
    .lit S_COMPLETE
    return

:state_handler_AG ;-----------
:sh_AG_0
    .lit S_COMPLETE
    return

:state_handler_AH ;-----------
:sh_AH_0
    .lit S_COMPLETE
    return

:state_handler_AI ;-----------
:sh_AI_0
    .lit S_COMPLETE
    return

:state_handler_AJ ;-----------
:sh_AJ_0
    dup
    neq 7
    cjump sh_AJ_1
    .lit S_AJ
    return

:sh_AJ_1
    .lit S_COMPLETE
    return

:state_handler_AK ;-----------
:sh_AK_0
    .lit S_COMPLETE
    return

:state_handler_AL ;-----------
:sh_AL_0
    dup
    neq 6
    cjump sh_AL_1
    .lit S_BB
    return

:sh_AL_1
    dup
    neq 7
    cjump sh_AL_2
    .lit S_BC
    return

:sh_AL_2
    dup
    neq 12
    cjump sh_AL_3
    .lit S_BD
    return

:sh_AL_3
    dup
    neq 13
    cjump sh_AL_4
    .lit S_BE
    return

:sh_AL_4
    dup
    neq 14
    cjump sh_AL_5
    .lit S_BF
    return

:sh_AL_5
    dup
    neq 15
    cjump sh_AL_6
    .lit S_BG
    return

:sh_AL_6
    dup
    neq 16
    cjump sh_AL_7
    .lit S_BH
    return

:sh_AL_7
    dup
    neq 17
    cjump sh_AL_8
    .lit S_BI
    return

:sh_AL_8
    dup
    neq 18
    cjump sh_AL_9
    .lit S_BJ
    return

:sh_AL_9
    dup
    neq 19
    cjump sh_AL_10
    .lit S_BK
    return

:sh_AL_10
    dup
    neq 20
    cjump sh_AL_11
    .lit S_BL
    return

:sh_AL_11
    .lit S_COMPLETE
    return

:state_handler_AM ;-----------
:sh_AM_0
    dup
    neq 6
    cjump sh_AM_1
    .lit S_BB
    return

:sh_AM_1
    dup
    neq 7
    cjump sh_AM_2
    .lit S_BC
    return

:sh_AM_2
    dup
    neq 12
    cjump sh_AM_3
    .lit S_BD
    return

:sh_AM_3
    dup
    neq 13
    cjump sh_AM_4
    .lit S_BE
    return

:sh_AM_4
    dup
    neq 14
    cjump sh_AM_5
    .lit S_BF
    return

:sh_AM_5
    dup
    neq 15
    cjump sh_AM_6
    .lit S_BG
    return

:sh_AM_6
    dup
    neq 16
    cjump sh_AM_7
    .lit S_BH
    return

:sh_AM_7
    dup
    neq 17
    cjump sh_AM_8
    .lit S_BI
    return

:sh_AM_8
    dup
    neq 18
    cjump sh_AM_9
    .lit S_BJ
    return

:sh_AM_9
    dup
    neq 19
    cjump sh_AM_10
    .lit S_BK
    return

:sh_AM_10
    dup
    neq 20
    cjump sh_AM_11
    .lit S_BL
    return

:sh_AM_11
    .lit S_COMPLETE
    return

:state_handler_AN ;-----------
:sh_AN_0
    dup
    neq 6
    cjump sh_AN_1
    .lit S_BB
    return

:sh_AN_1
    dup
    neq 7
    cjump sh_AN_2
    .lit S_BC
    return

:sh_AN_2
    dup
    neq 12
    cjump sh_AN_3
    .lit S_BD
    return

:sh_AN_3
    dup
    neq 13
    cjump sh_AN_4
    .lit S_BE
    return

:sh_AN_4
    dup
    neq 14
    cjump sh_AN_5
    .lit S_BF
    return

:sh_AN_5
    dup
    neq 15
    cjump sh_AN_6
    .lit S_BG
    return

:sh_AN_6
    dup
    neq 16
    cjump sh_AN_7
    .lit S_BH
    return

:sh_AN_7
    dup
    neq 17
    cjump sh_AN_8
    .lit S_BI
    return

:sh_AN_8
    dup
    neq 18
    cjump sh_AN_9
    .lit S_BJ
    return

:sh_AN_9
    dup
    neq 19
    cjump sh_AN_10
    .lit S_BK
    return

:sh_AN_10
    dup
    neq 20
    cjump sh_AN_11
    .lit S_BL
    return

:sh_AN_11
    .lit S_COMPLETE
    return

:state_handler_AO ;-----------
:sh_AO_0
    dup
    neq 6
    cjump sh_AO_1
    .lit S_BB
    return

:sh_AO_1
    dup
    neq 7
    cjump sh_AO_2
    .lit S_BC
    return

:sh_AO_2
    dup
    neq 12
    cjump sh_AO_3
    .lit S_BD
    return

:sh_AO_3
    dup
    neq 13
    cjump sh_AO_4
    .lit S_BE
    return

:sh_AO_4
    dup
    neq 14
    cjump sh_AO_5
    .lit S_BF
    return

:sh_AO_5
    dup
    neq 15
    cjump sh_AO_6
    .lit S_BG
    return

:sh_AO_6
    dup
    neq 16
    cjump sh_AO_7
    .lit S_BH
    return

:sh_AO_7
    dup
    neq 17
    cjump sh_AO_8
    .lit S_BI
    return

:sh_AO_8
    dup
    neq 18
    cjump sh_AO_9
    .lit S_BJ
    return

:sh_AO_9
    dup
    neq 19
    cjump sh_AO_10
    .lit S_BK
    return

:sh_AO_10
    dup
    neq 20
    cjump sh_AO_11
    .lit S_BL
    return

:sh_AO_11
    .lit S_COMPLETE
    return

:state_handler_AP ;-----------
:sh_AP_0
    dup
    neq 6
    cjump sh_AP_1
    .lit S_BB
    return

:sh_AP_1
    dup
    neq 7
    cjump sh_AP_2
    .lit S_BC
    return

:sh_AP_2
    dup
    neq 12
    cjump sh_AP_3
    .lit S_BD
    return

:sh_AP_3
    dup
    neq 13
    cjump sh_AP_4
    .lit S_BE
    return

:sh_AP_4
    dup
    neq 14
    cjump sh_AP_5
    .lit S_BF
    return

:sh_AP_5
    dup
    neq 15
    cjump sh_AP_6
    .lit S_BG
    return

:sh_AP_6
    dup
    neq 16
    cjump sh_AP_7
    .lit S_BH
    return

:sh_AP_7
    dup
    neq 17
    cjump sh_AP_8
    .lit S_BI
    return

:sh_AP_8
    dup
    neq 18
    cjump sh_AP_9
    .lit S_BJ
    return

:sh_AP_9
    dup
    neq 19
    cjump sh_AP_10
    .lit S_BK
    return

:sh_AP_10
    dup
    neq 20
    cjump sh_AP_11
    .lit S_BL
    return

:sh_AP_11
    .lit S_COMPLETE
    return

:state_handler_AQ ;-----------
:sh_AQ_0
    dup
    neq 6
    cjump sh_AQ_1
    .lit S_BB
    return

:sh_AQ_1
    dup
    neq 7
    cjump sh_AQ_2
    .lit S_BC
    return

:sh_AQ_2
    dup
    neq 12
    cjump sh_AQ_3
    .lit S_BD
    return

:sh_AQ_3
    dup
    neq 13
    cjump sh_AQ_4
    .lit S_BE
    return

:sh_AQ_4
    dup
    neq 14
    cjump sh_AQ_5
    .lit S_BF
    return

:sh_AQ_5
    dup
    neq 15
    cjump sh_AQ_6
    .lit S_BG
    return

:sh_AQ_6
    dup
    neq 16
    cjump sh_AQ_7
    .lit S_BH
    return

:sh_AQ_7
    dup
    neq 17
    cjump sh_AQ_8
    .lit S_BI
    return

:sh_AQ_8
    dup
    neq 18
    cjump sh_AQ_9
    .lit S_BJ
    return

:sh_AQ_9
    dup
    neq 19
    cjump sh_AQ_10
    .lit S_BK
    return

:sh_AQ_10
    dup
    neq 20
    cjump sh_AQ_11
    .lit S_BL
    return

:sh_AQ_11
    .lit S_COMPLETE
    return

:state_handler_AR ;-----------
:sh_AR_0
    dup
    neq 6
    cjump sh_AR_1
    .lit S_BB
    return

:sh_AR_1
    dup
    neq 7
    cjump sh_AR_2
    .lit S_BC
    return

:sh_AR_2
    dup
    neq 12
    cjump sh_AR_3
    .lit S_BD
    return

:sh_AR_3
    dup
    neq 13
    cjump sh_AR_4
    .lit S_BE
    return

:sh_AR_4
    dup
    neq 14
    cjump sh_AR_5
    .lit S_BF
    return

:sh_AR_5
    dup
    neq 15
    cjump sh_AR_6
    .lit S_BG
    return

:sh_AR_6
    dup
    neq 16
    cjump sh_AR_7
    .lit S_BH
    return

:sh_AR_7
    dup
    neq 17
    cjump sh_AR_8
    .lit S_BI
    return

:sh_AR_8
    dup
    neq 18
    cjump sh_AR_9
    .lit S_BJ
    return

:sh_AR_9
    dup
    neq 19
    cjump sh_AR_10
    .lit S_BK
    return

:sh_AR_10
    dup
    neq 20
    cjump sh_AR_11
    .lit S_BL
    return

:sh_AR_11
    .lit S_COMPLETE
    return

:state_handler_AS ;-----------
:sh_AS_0
    dup
    neq 6
    cjump sh_AS_1
    .lit S_BB
    return

:sh_AS_1
    dup
    neq 7
    cjump sh_AS_2
    .lit S_BC
    return

:sh_AS_2
    dup
    neq 12
    cjump sh_AS_3
    .lit S_BD
    return

:sh_AS_3
    dup
    neq 13
    cjump sh_AS_4
    .lit S_BE
    return

:sh_AS_4
    dup
    neq 14
    cjump sh_AS_5
    .lit S_BF
    return

:sh_AS_5
    dup
    neq 15
    cjump sh_AS_6
    .lit S_BG
    return

:sh_AS_6
    dup
    neq 16
    cjump sh_AS_7
    .lit S_BH
    return

:sh_AS_7
    dup
    neq 17
    cjump sh_AS_8
    .lit S_BI
    return

:sh_AS_8
    dup
    neq 18
    cjump sh_AS_9
    .lit S_BJ
    return

:sh_AS_9
    dup
    neq 19
    cjump sh_AS_10
    .lit S_BK
    return

:sh_AS_10
    dup
    neq 20
    cjump sh_AS_11
    .lit S_BL
    return

:sh_AS_11
    .lit S_COMPLETE
    return

:state_handler_AT ;-----------
:sh_AT_0
    dup
    neq 6
    cjump sh_AT_1
    .lit S_BB
    return

:sh_AT_1
    dup
    neq 7
    cjump sh_AT_2
    .lit S_BC
    return

:sh_AT_2
    dup
    neq 12
    cjump sh_AT_3
    .lit S_BD
    return

:sh_AT_3
    dup
    neq 13
    cjump sh_AT_4
    .lit S_BE
    return

:sh_AT_4
    dup
    neq 14
    cjump sh_AT_5
    .lit S_BF
    return

:sh_AT_5
    dup
    neq 15
    cjump sh_AT_6
    .lit S_BG
    return

:sh_AT_6
    dup
    neq 16
    cjump sh_AT_7
    .lit S_BH
    return

:sh_AT_7
    dup
    neq 17
    cjump sh_AT_8
    .lit S_BI
    return

:sh_AT_8
    dup
    neq 18
    cjump sh_AT_9
    .lit S_BJ
    return

:sh_AT_9
    dup
    neq 19
    cjump sh_AT_10
    .lit S_BK
    return

:sh_AT_10
    dup
    neq 20
    cjump sh_AT_11
    .lit S_BL
    return

:sh_AT_11
    .lit S_COMPLETE
    return

:state_handler_AU ;-----------
:sh_AU_0
    dup
    neq 6
    cjump sh_AU_1
    .lit S_BB
    return

:sh_AU_1
    dup
    neq 7
    cjump sh_AU_2
    .lit S_BC
    return

:sh_AU_2
    dup
    neq 12
    cjump sh_AU_3
    .lit S_BD
    return

:sh_AU_3
    dup
    neq 13
    cjump sh_AU_4
    .lit S_BE
    return

:sh_AU_4
    dup
    neq 14
    cjump sh_AU_5
    .lit S_BF
    return

:sh_AU_5
    dup
    neq 15
    cjump sh_AU_6
    .lit S_BG
    return

:sh_AU_6
    dup
    neq 16
    cjump sh_AU_7
    .lit S_BH
    return

:sh_AU_7
    dup
    neq 17
    cjump sh_AU_8
    .lit S_BI
    return

:sh_AU_8
    dup
    neq 18
    cjump sh_AU_9
    .lit S_BJ
    return

:sh_AU_9
    dup
    neq 19
    cjump sh_AU_10
    .lit S_BK
    return

:sh_AU_10
    dup
    neq 20
    cjump sh_AU_11
    .lit S_BL
    return

:sh_AU_11
    .lit S_COMPLETE
    return

:state_handler_AV ;-----------
:sh_AV_0
    dup
    neq 13
    cjump sh_AV_1
    .lit S_BM
    return

:sh_AV_1
    end

:state_handler_AW ;-----------
:sh_AW_0
    dup
    neq 13
    cjump sh_AW_1
    .lit S_BN
    return

:sh_AW_1
    end

:state_handler_AX ;-----------
:sh_AX_0
    dup
    neq 15
    cjump sh_AX_1
    .lit S_BO
    return

:sh_AX_1
    end

:state_handler_AY ;-----------
:sh_AY_0
    dup
    neq 20
    cjump sh_AY_1
    .lit S_BP
    return

:sh_AY_1
    end

:state_handler_AZ ;-----------
:sh_AZ_0
    .lit S_COMPLETE
    return

:state_handler_BA ;-----------
:sh_BA_0
    .lit S_COMPLETE
    return

:state_handler_BB ;-----------
:sh_BB_0
    dup
    neq 6
    cjump sh_BB_1
    .lit S_BB
    return

:sh_BB_1
    dup
    neq 7
    cjump sh_BB_2
    .lit S_BC
    return

:sh_BB_2
    dup
    neq 12
    cjump sh_BB_3
    .lit S_BD
    return

:sh_BB_3
    dup
    neq 13
    cjump sh_BB_4
    .lit S_BE
    return

:sh_BB_4
    dup
    neq 14
    cjump sh_BB_5
    .lit S_BF
    return

:sh_BB_5
    dup
    neq 15
    cjump sh_BB_6
    .lit S_BG
    return

:sh_BB_6
    dup
    neq 16
    cjump sh_BB_7
    .lit S_BH
    return

:sh_BB_7
    dup
    neq 17
    cjump sh_BB_8
    .lit S_BI
    return

:sh_BB_8
    dup
    neq 18
    cjump sh_BB_9
    .lit S_BJ
    return

:sh_BB_9
    dup
    neq 19
    cjump sh_BB_10
    .lit S_BK
    return

:sh_BB_10
    dup
    neq 20
    cjump sh_BB_11
    .lit S_BL
    return

:sh_BB_11
    .lit S_COMPLETE
    return

:state_handler_BC ;-----------
:sh_BC_0
    dup
    neq 6
    cjump sh_BC_1
    .lit S_BB
    return

:sh_BC_1
    dup
    neq 7
    cjump sh_BC_2
    .lit S_BC
    return

:sh_BC_2
    dup
    neq 12
    cjump sh_BC_3
    .lit S_BD
    return

:sh_BC_3
    dup
    neq 13
    cjump sh_BC_4
    .lit S_BE
    return

:sh_BC_4
    dup
    neq 14
    cjump sh_BC_5
    .lit S_BF
    return

:sh_BC_5
    dup
    neq 15
    cjump sh_BC_6
    .lit S_BG
    return

:sh_BC_6
    dup
    neq 16
    cjump sh_BC_7
    .lit S_BH
    return

:sh_BC_7
    dup
    neq 17
    cjump sh_BC_8
    .lit S_BI
    return

:sh_BC_8
    dup
    neq 18
    cjump sh_BC_9
    .lit S_BJ
    return

:sh_BC_9
    dup
    neq 19
    cjump sh_BC_10
    .lit S_BK
    return

:sh_BC_10
    dup
    neq 20
    cjump sh_BC_11
    .lit S_BL
    return

:sh_BC_11
    .lit S_COMPLETE
    return

:state_handler_BD ;-----------
:sh_BD_0
    dup
    neq 6
    cjump sh_BD_1
    .lit S_BB
    return

:sh_BD_1
    dup
    neq 7
    cjump sh_BD_2
    .lit S_BC
    return

:sh_BD_2
    dup
    neq 12
    cjump sh_BD_3
    .lit S_BD
    return

:sh_BD_3
    dup
    neq 13
    cjump sh_BD_4
    .lit S_BE
    return

:sh_BD_4
    dup
    neq 14
    cjump sh_BD_5
    .lit S_BF
    return

:sh_BD_5
    dup
    neq 15
    cjump sh_BD_6
    .lit S_BG
    return

:sh_BD_6
    dup
    neq 16
    cjump sh_BD_7
    .lit S_BH
    return

:sh_BD_7
    dup
    neq 17
    cjump sh_BD_8
    .lit S_BI
    return

:sh_BD_8
    dup
    neq 18
    cjump sh_BD_9
    .lit S_BJ
    return

:sh_BD_9
    dup
    neq 19
    cjump sh_BD_10
    .lit S_BK
    return

:sh_BD_10
    dup
    neq 20
    cjump sh_BD_11
    .lit S_BL
    return

:sh_BD_11
    .lit S_COMPLETE
    return

:state_handler_BE ;-----------
:sh_BE_0
    dup
    neq 6
    cjump sh_BE_1
    .lit S_BB
    return

:sh_BE_1
    dup
    neq 7
    cjump sh_BE_2
    .lit S_BC
    return

:sh_BE_2
    dup
    neq 12
    cjump sh_BE_3
    .lit S_BD
    return

:sh_BE_3
    dup
    neq 13
    cjump sh_BE_4
    .lit S_BE
    return

:sh_BE_4
    dup
    neq 14
    cjump sh_BE_5
    .lit S_BF
    return

:sh_BE_5
    dup
    neq 15
    cjump sh_BE_6
    .lit S_BG
    return

:sh_BE_6
    dup
    neq 16
    cjump sh_BE_7
    .lit S_BH
    return

:sh_BE_7
    dup
    neq 17
    cjump sh_BE_8
    .lit S_BI
    return

:sh_BE_8
    dup
    neq 18
    cjump sh_BE_9
    .lit S_BJ
    return

:sh_BE_9
    dup
    neq 19
    cjump sh_BE_10
    .lit S_BK
    return

:sh_BE_10
    dup
    neq 20
    cjump sh_BE_11
    .lit S_BL
    return

:sh_BE_11
    .lit S_COMPLETE
    return

:state_handler_BF ;-----------
:sh_BF_0
    dup
    neq 6
    cjump sh_BF_1
    .lit S_BB
    return

:sh_BF_1
    dup
    neq 7
    cjump sh_BF_2
    .lit S_BC
    return

:sh_BF_2
    dup
    neq 12
    cjump sh_BF_3
    .lit S_BD
    return

:sh_BF_3
    dup
    neq 13
    cjump sh_BF_4
    .lit S_BE
    return

:sh_BF_4
    dup
    neq 14
    cjump sh_BF_5
    .lit S_BF
    return

:sh_BF_5
    dup
    neq 15
    cjump sh_BF_6
    .lit S_BG
    return

:sh_BF_6
    dup
    neq 16
    cjump sh_BF_7
    .lit S_BH
    return

:sh_BF_7
    dup
    neq 17
    cjump sh_BF_8
    .lit S_BI
    return

:sh_BF_8
    dup
    neq 18
    cjump sh_BF_9
    .lit S_BJ
    return

:sh_BF_9
    dup
    neq 19
    cjump sh_BF_10
    .lit S_BK
    return

:sh_BF_10
    dup
    neq 20
    cjump sh_BF_11
    .lit S_BL
    return

:sh_BF_11
    .lit S_COMPLETE
    return

:state_handler_BG ;-----------
:sh_BG_0
    dup
    neq 6
    cjump sh_BG_1
    .lit S_BB
    return

:sh_BG_1
    dup
    neq 7
    cjump sh_BG_2
    .lit S_BC
    return

:sh_BG_2
    dup
    neq 12
    cjump sh_BG_3
    .lit S_BD
    return

:sh_BG_3
    dup
    neq 13
    cjump sh_BG_4
    .lit S_BE
    return

:sh_BG_4
    dup
    neq 14
    cjump sh_BG_5
    .lit S_BF
    return

:sh_BG_5
    dup
    neq 15
    cjump sh_BG_6
    .lit S_BG
    return

:sh_BG_6
    dup
    neq 16
    cjump sh_BG_7
    .lit S_BH
    return

:sh_BG_7
    dup
    neq 17
    cjump sh_BG_8
    .lit S_BI
    return

:sh_BG_8
    dup
    neq 18
    cjump sh_BG_9
    .lit S_BJ
    return

:sh_BG_9
    dup
    neq 19
    cjump sh_BG_10
    .lit S_BK
    return

:sh_BG_10
    dup
    neq 20
    cjump sh_BG_11
    .lit S_BL
    return

:sh_BG_11
    .lit S_COMPLETE
    return

:state_handler_BH ;-----------
:sh_BH_0
    dup
    neq 6
    cjump sh_BH_1
    .lit S_BB
    return

:sh_BH_1
    dup
    neq 7
    cjump sh_BH_2
    .lit S_BC
    return

:sh_BH_2
    dup
    neq 12
    cjump sh_BH_3
    .lit S_BD
    return

:sh_BH_3
    dup
    neq 13
    cjump sh_BH_4
    .lit S_BE
    return

:sh_BH_4
    dup
    neq 14
    cjump sh_BH_5
    .lit S_BF
    return

:sh_BH_5
    dup
    neq 15
    cjump sh_BH_6
    .lit S_BG
    return

:sh_BH_6
    dup
    neq 16
    cjump sh_BH_7
    .lit S_BH
    return

:sh_BH_7
    dup
    neq 17
    cjump sh_BH_8
    .lit S_BI
    return

:sh_BH_8
    dup
    neq 18
    cjump sh_BH_9
    .lit S_BJ
    return

:sh_BH_9
    dup
    neq 19
    cjump sh_BH_10
    .lit S_BK
    return

:sh_BH_10
    dup
    neq 20
    cjump sh_BH_11
    .lit S_BL
    return

:sh_BH_11
    .lit S_COMPLETE
    return

:state_handler_BI ;-----------
:sh_BI_0
    dup
    neq 6
    cjump sh_BI_1
    .lit S_BB
    return

:sh_BI_1
    dup
    neq 7
    cjump sh_BI_2
    .lit S_BC
    return

:sh_BI_2
    dup
    neq 12
    cjump sh_BI_3
    .lit S_BD
    return

:sh_BI_3
    dup
    neq 13
    cjump sh_BI_4
    .lit S_BE
    return

:sh_BI_4
    dup
    neq 14
    cjump sh_BI_5
    .lit S_BF
    return

:sh_BI_5
    dup
    neq 15
    cjump sh_BI_6
    .lit S_BG
    return

:sh_BI_6
    dup
    neq 16
    cjump sh_BI_7
    .lit S_BH
    return

:sh_BI_7
    dup
    neq 17
    cjump sh_BI_8
    .lit S_BI
    return

:sh_BI_8
    dup
    neq 18
    cjump sh_BI_9
    .lit S_BJ
    return

:sh_BI_9
    dup
    neq 19
    cjump sh_BI_10
    .lit S_BK
    return

:sh_BI_10
    dup
    neq 20
    cjump sh_BI_11
    .lit S_BL
    return

:sh_BI_11
    .lit S_COMPLETE
    return

:state_handler_BJ ;-----------
:sh_BJ_0
    dup
    neq 6
    cjump sh_BJ_1
    .lit S_BB
    return

:sh_BJ_1
    dup
    neq 7
    cjump sh_BJ_2
    .lit S_BC
    return

:sh_BJ_2
    dup
    neq 12
    cjump sh_BJ_3
    .lit S_BD
    return

:sh_BJ_3
    dup
    neq 13
    cjump sh_BJ_4
    .lit S_BE
    return

:sh_BJ_4
    dup
    neq 14
    cjump sh_BJ_5
    .lit S_BF
    return

:sh_BJ_5
    dup
    neq 15
    cjump sh_BJ_6
    .lit S_BG
    return

:sh_BJ_6
    dup
    neq 16
    cjump sh_BJ_7
    .lit S_BH
    return

:sh_BJ_7
    dup
    neq 17
    cjump sh_BJ_8
    .lit S_BI
    return

:sh_BJ_8
    dup
    neq 18
    cjump sh_BJ_9
    .lit S_BJ
    return

:sh_BJ_9
    dup
    neq 19
    cjump sh_BJ_10
    .lit S_BK
    return

:sh_BJ_10
    dup
    neq 20
    cjump sh_BJ_11
    .lit S_BL
    return

:sh_BJ_11
    .lit S_COMPLETE
    return

:state_handler_BK ;-----------
:sh_BK_0
    dup
    neq 6
    cjump sh_BK_1
    .lit S_BB
    return

:sh_BK_1
    dup
    neq 7
    cjump sh_BK_2
    .lit S_BC
    return

:sh_BK_2
    dup
    neq 12
    cjump sh_BK_3
    .lit S_BD
    return

:sh_BK_3
    dup
    neq 13
    cjump sh_BK_4
    .lit S_BE
    return

:sh_BK_4
    dup
    neq 14
    cjump sh_BK_5
    .lit S_BF
    return

:sh_BK_5
    dup
    neq 15
    cjump sh_BK_6
    .lit S_BG
    return

:sh_BK_6
    dup
    neq 16
    cjump sh_BK_7
    .lit S_BH
    return

:sh_BK_7
    dup
    neq 17
    cjump sh_BK_8
    .lit S_BI
    return

:sh_BK_8
    dup
    neq 18
    cjump sh_BK_9
    .lit S_BJ
    return

:sh_BK_9
    dup
    neq 19
    cjump sh_BK_10
    .lit S_BK
    return

:sh_BK_10
    dup
    neq 20
    cjump sh_BK_11
    .lit S_BL
    return

:sh_BK_11
    .lit S_COMPLETE
    return

:state_handler_BL ;-----------
:sh_BL_0
    dup
    neq 6
    cjump sh_BL_1
    .lit S_BB
    return

:sh_BL_1
    dup
    neq 7
    cjump sh_BL_2
    .lit S_BC
    return

:sh_BL_2
    dup
    neq 12
    cjump sh_BL_3
    .lit S_BD
    return

:sh_BL_3
    dup
    neq 13
    cjump sh_BL_4
    .lit S_BE
    return

:sh_BL_4
    dup
    neq 14
    cjump sh_BL_5
    .lit S_BF
    return

:sh_BL_5
    dup
    neq 15
    cjump sh_BL_6
    .lit S_BG
    return

:sh_BL_6
    dup
    neq 16
    cjump sh_BL_7
    .lit S_BH
    return

:sh_BL_7
    dup
    neq 17
    cjump sh_BL_8
    .lit S_BI
    return

:sh_BL_8
    dup
    neq 18
    cjump sh_BL_9
    .lit S_BJ
    return

:sh_BL_9
    dup
    neq 19
    cjump sh_BL_10
    .lit S_BK
    return

:sh_BL_10
    dup
    neq 20
    cjump sh_BL_11
    .lit S_BL
    return

:sh_BL_11
    .lit S_COMPLETE
    return

:state_handler_BM ;-----------
:sh_BM_0
    .lit S_COMPLETE
    return

:state_handler_BN ;-----------
:sh_BN_0
    .lit S_COMPLETE
    return

:state_handler_BO ;-----------
:sh_BO_0
    .lit S_COMPLETE
    return

:state_handler_BP ;-----------
:sh_BP_0
    .lit S_COMPLETE
    return


; === Emitter ==============================================================

; Jump table for emitting.  The accepting state should be on the TOS on input.
; Call this.
:emit_token
    .lit &emit_token_list       ; next_state baseaddr ]
    add                         ; jumpaddr ]
    jump    ; to the right routine for this state.  ; ]
:emit_err
    end     ; TODO handle this better

:emit_token_list

.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_handler_E
.lit &emit_handler_F
.lit &emit_handler_G
.lit &emit_handler_H
.lit &emit_handler_I
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_handler_P
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_handler_AD
.lit &emit_handler_AE
.lit &emit_handler_AF
.lit &emit_handler_AG
.lit &emit_handler_AH
.lit &emit_handler_AI
.lit &emit_handler_AJ
.lit &emit_handler_AK
.lit &emit_handler_AL
.lit &emit_handler_AM
.lit &emit_handler_AN
.lit &emit_handler_AO
.lit &emit_handler_AP
.lit &emit_handler_AQ
.lit &emit_handler_AR
.lit &emit_handler_AS
.lit &emit_handler_AT
.lit &emit_handler_AU
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_err
.lit &emit_handler_AZ
.lit &emit_handler_BA
.lit &emit_handler_BB
.lit &emit_handler_BC
.lit &emit_handler_BD
.lit &emit_handler_BE
.lit &emit_handler_BF
.lit &emit_handler_BG
.lit &emit_handler_BH
.lit &emit_handler_BI
.lit &emit_handler_BJ
.lit &emit_handler_BK
.lit &emit_handler_BL
.lit &emit_handler_BM
.lit &emit_handler_BN
.lit &emit_handler_BO
.lit &emit_handler_BP

; Emit routines


:emit_handler_E
    out T_LT
    return


:emit_handler_F
    out T_ASSIGN
    return


:emit_handler_G
    out T_GT
    return


:emit_handler_H
    out T_NUM   ; TODO also emit the actual numeric value!
    return


:emit_handler_I
    out TODO
    return


:emit_handler_P     ; misc. punctuation represents itself
    dup
    out
    return


:emit_handler_AD
    out T_ARROW
    return


:emit_handler_AE
    out T_TERN2
    return


:emit_handler_AF
    out T_LE
    return


:emit_handler_AG
    out T_NE
    return


:emit_handler_AH
    out T_EQ
    return


:emit_handler_AI
    out T_GE
    return


:emit_handler_AJ
    out T_NUM   ; TODO also emit the actual numeric value!
    return


:emit_handler_AK
    out TODO
    return


:emit_handler_AL
    out TODO
    return


:emit_handler_AM
    out TODO
    return


:emit_handler_AN
    out TODO
    return


:emit_handler_AO
    out TODO
    return


:emit_handler_AP
    out TODO
    return


:emit_handler_AQ
    out TODO
    return


:emit_handler_AR
    out TODO
    return


:emit_handler_AS
    out TODO
    return


:emit_handler_AT
    out TODO
    return


:emit_handler_AU
    out TODO
    return


:emit_handler_AZ
    out TODO
    return


:emit_handler_BA
    out T_SSHIP
    return


:emit_handler_BB
    out TODO
    return


:emit_handler_BC
    out TODO
    return


:emit_handler_BD
    out TODO
    return


:emit_handler_BE
    out TODO
    return


:emit_handler_BF
    out TODO
    return


:emit_handler_BG
    out TODO
    return


:emit_handler_BH
    out TODO
    return


:emit_handler_BI
    out TODO
    return


:emit_handler_BJ
    out TODO
    return


:emit_handler_BK
    out TODO
    return


:emit_handler_BL
    out TODO
    return


:emit_handler_BM
    out TODO
    return


:emit_handler_BN
    out TODO
    return


:emit_handler_BO
    out TODO
    return


:emit_handler_BP
    out TODO
    return


