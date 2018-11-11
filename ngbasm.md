# ngbasm

ngbasm is a minimalistic assembler for the ngb instruction set. It provides:

* Two passes: assemble, then resolve lables
* Labels
* Basic literals
* Symbolic names for all instructions
* Facilities for inlining simple data
* Directives for setting output filename

ngbasm is intended to be a stepping stone for supporting larger applications.
It wasn't designed to be easy or fun to use, just to provide the essentials
needed to build useful things.

## Instruction Set

Nga has a very small set of instructions. These can be briefly listed in a
short table:

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  ccall     16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

ngb adds:

    27 in
    28 out
    29 cjump

All instructions except for **lit** are one cell long. **lit** takes two: one
for the instruction and one for the value to push to the stack.

## Syntax

ngbasm provides a simple syntax. A short example:

    ; Test.ngb
    .output test.ngb
    :add
      add
      return
    :subtract
      sub
      return
    :increment
      .lit 1
      call &add
      return
    :main
      .lit 100
      .lit 95
      call &subtract
      call &increment
      end

Delving a bit deeper:

* Comment lines begin with a semicolon
* Blank lines are ok and will be stripped out
* One instruction (or assembler directive) per line
* Labels start with a colon
* A **.lit** can be followed by a number or a label name
* References to labels must start with an &

### Assembler Directives

ngbasm provides some directives which can be useful:

**.o**utput is used to set the name of the file that will be created with
the Nga bytecode. If none is set, the filename will be defaulted to
*output.ngb*

Example:

    .output sample.ngb

**.d**ata is used to inline raw data into the generated image.

Example:

    .data 98
    .data 99
    .data 100

**.l**it is used to push a literal onto the stack.  That is, `.lit` is
actually the `lit` instruction.  This is to make the parser simpler.

**.i**include inlines another file as if it had been typed right at
the point of the include.

Example:

    .include foo.nas

**.c**onst defines constants.

Example:

    .const foo 42
    .lit foo    ; equivalent to .lit 42

### Technical Notes

ngbasm has a trivial parser. In deciding how to deal with a line, it will first
strip it to its core elements, then proceed. So given a line like:

    .lit 100 ... push 100 to the stack! ...

ngbasm will take the first token (*.lit*) to identify
the instruction and the second token for the value. The rest is ignored.

For instructions (not labels or directives), any argument will be assembled
into a `lit` instruction (not directive).  For example:

    jump &foo

is actually assembled as:

    .lit &foo
    jump

## The Code

First up, the preamble, and some variables.

| name   | usage                                               |
| ------ | --------------------------------------------------- |
| output_filename | stores the name of the file for the assembled image |
| labels | stores a list of labels and pointers                |
| memory | stores all values                                   |
| i      | pointer to the current memory location              |
| instrs | Dictionary of the ngb instructions and opcodes      |

````
#!/usr/bin/env python3
import sys
import os
import re

output_filename = ''
labels = []
resolve = []
memory = []
i = 0

# Stack of filenames we are processing.  The current file being assembled
# is always filenames[-1].
filenames = []

# Constants we know about
consts = {}

# Instruction -> opcode mapping
instrs = {
    'nop': 0,
    ' lit': 1,  # leading whitespace so it can't be assembled
    'dup': 2,
    'drop': 3,
    'swap': 4,
    'push': 5,
    'pop': 6,
    'jump': 7,
    'call': 8,
    'ccall': 9,
    'return': 10,
    'eq': 11,
    'neq': 12,
    'lt': 13,
    'gt': 14,
    'fetch': 15,
    'store': 16,
    'add': 17,
    'sub': 18,
    'mul': 19,
    'divmod': 20,
    'and': 21,
    'or': 22,
    'xor': 23,
    'shift': 24,
    'zret': 25,
    'end': 26,

    # Not in nga
    'in': 27,
    'out': 28,
    'cjump': 29,
}

````

The next two functions are for adding labels to the dictionary and searching
for them.

````
def define(id):
    global labels
    labels.append((id, i))

def lookup(id):
    for label in labels:
        if label[0] == id:
            return label[1]
    return -1

````

**comma** is used to compile a value into memory.

````
def comma(v):
    global memory, i
    try:
        memory.append(int(v))
    except ValueError:
        memory.append(v)
    i = i + 1

````

This next one maps a symbolic name to its opcode. It requires a two character
string (this is sufficent to identify any of the instructions).

*It may be worth looking into using a simple lookup table instead of this.*

````
def map_to_inst(s):
    return instrs.get(s, -1)

````

This next function saves the memory image to a file.

````
def save(filename):
    import struct
    with open(filename, 'wb') as file:
        j = 0
        while j < i:
            file.write(struct.pack('i', memory[j]))
            j = j + 1

````

An image starts with a jump to the main entry point (the *:main* label).
Since the offset of *:main* isn't known initially, this compiles a jump to
offset 0, which will be patched by a later routine.

````
def preamble():
    comma(instrs[' lit'])
    comma(0)  # value will be patched to point to :main
    comma(instrs['jump'])

````

**patch_entry()** replaces the target of the jump compiled by **preamble()**
with the offset of the *:main* label.

````
def patch_entry():
    main_addr = lookup('main')
    if main_addr == -1:
        print('main not defined - add a :main line')
        exit(1)
    memory[1] = main_addr

````

A source file consists of a series of lines, with one instruction (or label)
per line. While minimalistic, ngbasm does allow for blank lines and indention.
This function strips out the leading and trailing whitespace as well as blank
lines so that the rest of the assembler doesn't need to deal with it.
It also strips from a semicolon to the end of the line so you can put
comments on the same line as operations.

````
def clean_source(raw):
    cleaned = []
    for line in raw:    # permit comments to EOL
        cleaned.append(re.sub(r';.*$','',line).strip())
    final = []
    for line in cleaned:
        if line != '':
            final.append(line)
    return final


def load_source(filename):
    with open(filename, 'r') as f:
        raw = f.readlines()
    return clean_source(raw)

````

We now have a couple of routines that are intended to make future maintenance
easier by keeping the source more readable. It should be pretty obvious what
these do.

````
def is_label(token):
    if token[0] == ':':
        return True
    else:
        return False

def is_directive(token):
    if token[0] == '.':
        return True
    else:
        return False

def is_inst(token):
    if map_to_inst(token) == -1:
        return False
    else:
        return True

````

We also permit various forms of operand: literal number, ASCII character,
label, or constant.  This routine maps non-number forms to numbers.  It does
not call `int()` on the result, however, since the result might be a label
string such as `&main`.

````
def operand_value(token):
    if token[0] == "'":     # ASCII character
        return ord(token[1])
    else:
        return consts.get(token,token)

````

Ok, now for a somewhat messier bit. The **LIT** instruction is two part: the
first is the actual opcode (1), the second (stored in the following cell) is
the value to push to the stack. A source line is setup like:

    .lit 100
    .lit &increment

In the first case, we want to compile the number 100 in the following cell.
But in the second, we need to lookup the *:increment* label and compile a
pointer to it.

````
def handle_lit(parts):
    comma(instrs[' lit'])
    val = operand_value(parts[1])
    try:
        a = int(val)
        comma(a)
    except:
        xt = str(val)
        comma(xt)

````

We can also define constants.

````
def handle_const(parts):
    if len(parts) < 3:
        print('.const <name> <value> missing arguments @', i)
        exit(1)
    consts[parts[1]] = operand_value(parts[2])

````

We can also include files, e.g., to share constants.

````
def handle_include(parts):
    filename = parts[1]
    # Look for include file relative to the file we are currently processing
    this_file_path = os.path.normpath(os.path.join(
            os.path.dirname(os.path.realpath(os.path.abspath(filenames[-1]))),
            filename
    ))
    print('Including ', this_file_path, ' @', i)

    filenames.append(this_file_path)
    src = load_source(this_file_path)
    for (lineno, line) in enumerate(src):
        assemble(lineno, line)
    filenames.pop()

````

For assembler directives we have a single handler. There are currently two
directives; one for setting the **output** filename and one for inlining data.

````
def handle_directive(parts):
    global output_filename
    token = parts[0]
    if token[0:2] == '.o': output_filename = parts[1]
    elif token[0:2] == '.d':    # data: Raw cell value.  Can't use &label.
        val = operand_value(parts[1])
        comma(int(val))
    elif token[0:2] == '.l': handle_lit(parts)
    elif token[0:2] == '.i': handle_include(parts)
    elif token[0:2] == '.c': handle_const(parts)

````

Now for the meat of the assembler. This takes a single line of input, checks
to see if it's a label or instruction, and lays down the appropriate code,
calling whatever helper functions are needed (**handle_lit()** being notable).

Note that `assemble()` assumes that `clean_source()` has already been called
on the input line.

````
def assemble(lineno, line):
    parts = line.split()
    token = parts[0]

    if token[0] == ';':     # Comment
        pass
    elif is_label(token):
        labels.append((line[1:], i))
        print('label = ', line, '@', i)
    elif is_directive(token):
        handle_directive(parts)
    elif is_inst(token):
        op = map_to_inst(token)
        if op == -1:
            print('Unknown instruction ', token)
            exit(1)

        if len(parts) > 1:
            handle_lit(('.lit ', parts[1]))

        comma(op)
    else:
        print('Line was not something I know how to handle.')
        print(lineno, ': ', line)
        exit()

````

**resolve_labels()** is the second pass; it converts any labels into addresses.

````
def resolve_labels():
    global memory
    results = []
    for cell in memory:
        value = 0
        try:
            value = int(cell)
        except ValueError:
            value = lookup(cell[1:])  # Ignore the '&' at the start of the label
            if value == -1:
                print('Label ', cell, ' not found!')
                exit()
        results.append(value)
    memory = results

````

And finally we can tie everything together into a coherent package.

````
if __name__ == '__main__':
    if len(sys.argv) < 3:
        raw = []
        # Dummy filename based on current dir
        filenames.append(os.path.join(os.getcwd(),'standard-input'))
        for line in sys.stdin:
            raw.append(line)
        src = clean_source(raw)
    else:
        filenames.append(sys.argv[1])
        src = load_source(sys.argv[1])

    preamble()
    for (lineno, line) in enumerate(src):
        assemble(lineno, line)
    assemble(-1, 'end') # Always at the end, just to be safe
    resolve_labels()
    patch_entry()

    if len(sys.argv) < 3:
        if output_filename == '':
            save('output.ngb')
        else:
            save(output_filename)
    else:
        save(sys.argv[2])

    # print(src)  # Useful for debugging
    print(labels)
    print(memory)

````
