# Bootstrapping

**6/16/2016**:

So the core of Nga is done (assuming I don't decide to make more changes to
the instruction set...). The next step is to start building something on it.

I'm a longtime concatenative language user so I'll be working on a couple of
possible implementations, with an eye on eventually supporting a decent subset
of Parable.

This process will be a little tricky: the only assembler so far is a crude
single pass thing, and there's no cross compilers yet. (There is a PL/0 compiler
generating assembly, but this is still incomplete).

Some directions to explore:

- use current Retro+Ngaro with a modified meta.rx to build a minimal Retro/Forth
  environment
- implement a Parable-style interface layer and compiler that uses Nga internally
- continue work on fleshing out the assembler into something more useful
  (it'd be really nice to have a second pass that would allow for resolving any
   future labels to addresses)

Since this is in many ways a fresh start, I'll be documenting my work as I go
along, so it'll hopefully be easier to see how this goes.
