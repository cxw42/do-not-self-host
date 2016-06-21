# Bootstrapping

**6/21/2016**:

I've been working on Naje. When I'm done it'll be a two pass assembler to
allow for forward references.

Update: finished two pass model during lunch break; Naje is now useful.

Next up: get PL/0 -> Naje working

**6/17/2016**:

When I began work on Retro I started with an assembler written in Toka. Though
a bit more complex now, the metacompiler is a direct descendant of that original
piece of code. I'll be following the same general approach for one of these
experiments.

Added two files:

* nga.c
* ngita.c

Build using:

    cc ngita.c nga.c -o ngita

Added more files:

* retro.c
* retroImage
* library/files.rx

Build using:

    cc retro.c -o retro

Then a cross compiler:

* cross.rx

The cross compiler is a hacked up copy of **meta.rx** from Retro 11.7. The
main changes so far:

* Nga instructions instead of Ngaro ones
* changed these to use Nga instructions / memory layout:

  - main:
  - t:
  - i:
  - cond
  - =if
  - <if
  - >if
  - jump:
  - again

* removed:

  - ;
  - bootNew
  - shrink
  - a bunch of dictionary related bits

* added ;,
* added image saving code from retro.rx Ngaro implementation

So there's now a mostly functional cross compiler / machine forth dialect.

I see an opportunity here to rewrite more of this piece of code now that it's
working. It'd be nice to simplify it further and move it into a Markdown source
like the rest of the Nga source tree.

...

cross.rx is now nmfcx.rx (nga machine forth cross compiler) - I've simplified
it to a good extent and am now happy with it.

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
