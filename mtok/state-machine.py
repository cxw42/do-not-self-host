#!python3
# state-machine.py: Convert a state machine from
# https://cyberzhg.github.io/toolbox/nfa2dfa, saved as a CSV, into ngb asm.
# Copyright (c) 2018 cxw42.  Licensed MIT.
#
# Workflow (Google Chrome):
#   - Create the regex and state machine in nfa2dfa
#   - Right-click the table and choose "Inspect".
#   - Right-click the <table> and choose "Copy | Copy outerHTML".
#   - Paste the table into an empty Excel spreadsheet
#   - Insert a column between cols. B and C.  Label it "Accepting".
#   - Put a non-empty entry in the new column C for any state that is
#     accepting.  This apparently needs to be done manually, which stinks.
#   - Save the table as CSV
#   - Run this
# There must be a better way, but I don't know it right now.
#
# To find the accepting states:
#   - Right-click the chart and Inspect
#   - Right-click the SVG, Copy | Copy outerHTML
#   - paste into mtok.svg
#   - :%s/</^M</g
#   - grep --color=never -E '^</?(svg|ellipse|tspan|g)' mtok.svg > mtok.txt
#   - set hlsearch
#   - /\/ellipse.*\_s<ellipse
#   - Note the letter that appears after each ellipse pair

import sys
import csv
import datetime

if len(sys.argv)<2:
    print('''\
Usage: state-machine.py <inputfile.csv> [which]'
Output is to stdout.
Optional "which" is "table", "machine", or "emitter" (default all three).
''')
    exit(1)

print('; state machine generated ',
        datetime.datetime.now().strftime('%c'))
### Read ################################################################

states = []     # in order, so we can make a jump table
emits = {}

with open(sys.argv[1], newline='') as csvfile:
    reader = csv.reader(csvfile)
    going = False
    for row in reader:

        # EMIT table entries
        if row[0].upper() =='EMIT':
            emits[row[1]] = row[2]
            continue

        # TODO character class table

        # Otherwise, skip past header and any rows above it
        if row[0].upper()=='NFA STATE':
            going = True
            continue
        elif not going:
            continue

        # Add this row to the state table
        st = {'name':row[1], 'accepting': row[2] != '', 'transitions':{}}
        states.append(st)

        for col in range(3, len(row)):
            if row[col] != '':
                st['transitions'][col-3] = row[col]
        # next col
    # next row
# end reader

### Emit table ##########################################################
print('''
; Emit table
''')
for (k,v) in emits.items():
    print('.const E_{} {}'.format(k,v))
# next emits

### Table ###############################################################

if len(sys.argv)<3 or sys.argv[2] == 'table':
    print('''
; State table
; zero-based so they can be used in a jump table
''')

    for idx, state in enumerate(states):
        print('.const S_{} {}'.format(state['name'], idx))
# endif generating the state table

### Machine #############################################################
# Generate the state machine

if len(sys.argv)<3 or sys.argv[2] == 'machine':
    print('''
; === State machine ========================================================

.const S_COMPLETE 65534     ; a token is complete
.const S_ERROR 65535        ; error: the current char is not a valid transition
                            ; from the current state.

; Jump table for state routines.  Call this.
; Inputs are:
;   TOS: The current state
;   NOS: The next character class
; Outputs are:
;   - On failure, abort
;   - On success, leave the next state at TOS, above the next cclass.

:get_next_state
    lit &state_handler_list     ; cclass state baseaddr ]
    add                         ; cclass; addr of the pointer ]
    fetch                       ; cclass; addr of the routine ]
    jump    ; to the right routine for this state.  ; cclass ]
:state_handler_list
''')

    for state in states:
        print('.data &state_handler_'+state['name'])
    # next state

    print('''
; Handler routines.
; Input: the current input type on the top of the stack
; Output: the new state on top of the stack, if any.
;         Aborts the program if no match.
''')

    for state in states:
        print(':state_handler_{} ;-----------'.format(state['name']))
        transition_num = 0
        for input_id, next_state in state['transitions'].items():
            # Generate the test for this transition.  The lit+store
            print('''\
:sh_{}_{}           ; cclass ]
    dup             ; cclass cclass ]
    neq {}          ; cclass flag ]
    cjump &sh_{}_{} ; cclass ]
    drop            ; ]
    lit S_{}        ; new state ]
    return
'''.format(state['name'], transition_num, input_id,
               state['name'], transition_num + 1, next_state))
            transition_num = transition_num + 1
        # next transition

        # Unrecognized input: If it's an accepting state, we're done with this
        # token.  Otherwise, report error.
        print('''\
:sh_{}_{}
    drop
    lit S_{}
    return
'''.format(state['name'], transition_num,
    'COMPLETE' if state['accepting'] else 'ERROR'))

    # next state
#endif generating the state machine

### Emitter #############################################################
# Generate the dispatcher to emit tokens matching the states

if len(sys.argv)<3 or sys.argv[2] == 'emitter':
    # Generate the skeleton of the emit_token table
    print('''
; === Emitter ==============================================================

.const EMIT_CHAR -42    ; An easy value to spot in debug output

; Jump table for emitting.  Call this.
; Input: TOS: The accepting state
;        NOS: The character that got us to this state
; Both are popped off the stack.
:emit_token                     ; char; accepting_state
    lit &emit_token_list        ; char; accepting_state baseaddr ]
    add                         ; char; addr of the pointer ]
    fetch                       ; char; addr of the routine ]
    jump    ; to the right routine for this state.  ; char ]
:emit_err
    end     ; TODO handle this better

:emit_self  ; emit the last character   ; char ]
    out                                 ; ]
    return

:emit_token_list
''')

    for state in states:
        if state['accepting']:
            print('.data &emit_handler_'+state['name'])
        else:
            print('.data &emit_err')
    # next state

    print('''
; Emit routines
''')

    for state in states:
        if not state['accepting']: continue
        # The actual things to emit are defined in the caller's program so
        # the don't get blown away when this is re-run
        print('''
:emit_handler_{0}           ; char ]
    lit E_{0}               ; char tok ]
    eq EMIT_CHAR            ; char flag ]
    cjump &emit_self        ; char ]
    out E_{0}               ; char ]
    drop                    ; ]
    return'''.format(state['name']))
    # next state
# endif generating the emitter

# Always
print("\n; vi" + ": set ft=ngbasm:")    # split it up so it's not a modeline
