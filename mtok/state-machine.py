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

if len(sys.argv)<2:
    print('state-machine.py <inputfile.csv>')
    exit(1)

states = []     # in order, so we can make a jump table

with open(sys.argv[1], newline='') as csvfile:
    reader = csv.reader(csvfile)
    going = False
    for row in reader:
        # Skip past header and any rows above it
        if row[0]=='NFA STATE':
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

# Generate the state table
print('''
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
''')

for state in states:
    print('.lit &state_handler_'+state['name'])
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
        # Generate the test for this transition.  The .lit+store
        print('''\
:sh_{}_{}
    dup
    neq {}
    cjump sh_{}_{}
    .lit S_{}
    return
'''.format(state['name'], transition_num, input_id,
               state['name'], transition_num + 1, next_state))
        transition_num = transition_num + 1
    # next transition

    # Unrecognized input: If it's an accepting state, we're done with this
    # token.  Otherwise, abort.  TODO handle this better.
    print('''\
:sh_{}_{}
    {}
'''.format(state['name'], transition_num,
        '''.lit S_COMPLETE
    return''' if state['accepting'] else 'end'))
# next state

# Generate the skeleton of the emit_token table
print('''
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
''')

for state in states:
    if state['accepting']:
        print('.lit &emit_handler_'+state['name'])
    else:
        print('.lit &emit_err')

print('''
; Emit routines
''')

for state in states:
    if not state['accepting']: continue
    print('''
:emit_handler_{}
    out TODO
    return'''.format(state['name']))
# next state

# For convenience, generate a state table
print('''
; STATE TABLE - TODO move this up
; zero-based so they can be used in a jump table
''')

for idx, state in enumerate(states):
    print('.const S_{} {}'.format(state['name'], idx))

