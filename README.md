# do-not-self-host

A development toolchain from the ground up, starting from assembly.
Don't self-host your next language!  Make it possible for us to build from
source, from scratch, without needing a bootstrap package!

This is a long-term hobby project, so please do not expect regular
updates :) .  However, I certainly welcome others who want to contribute.

Assumes a development environment that provides stdin/stdout and redirection.

## Current status

* ngb: VM (in C)
* ngbasm: assembler (in Python)

## Editor support

ngb assembly files have the extension `.nas`.  A Vim syntax configuration
is available [here](https://github.com/cxw42/ngb-vim).

## I'm not the only one

The Facebook Buck build system also doesn't self-host by default (although
it can).  The Buck [FAQ](https://buckbuild.com/concept/faq.html) says, in part:

> Q: Why is Buck built with Ant instead of Buck?
>
> A: Self-hosting systems can be more difficult to maintain and debug.
If Buck built itself using Buck, then every time a change was made to Buck's source, the commit would have to include a new Buck binary that included that change. It would be easy to forget to include the binary, difficult to verify that it was the correct binary, and wasteful to bloat the Git history of the repository with binaries that could be rebuilt from source. Building Buck using Ant ensures we are always building from source, which is simpler to verify.

## Notes

Based on [crcx/Nga-Bootstrap](https://github.com/crcx/Nga-Bootstrap), which
provides:

* naje - a basic assembler (Python)
* nmfcx -  a Machine Forth Cross Compiler (Retro)

In the pipeline:

* NGA+:
  - Implement NGA VM in x86 assembly (NASM?)
  - Read/write stdin/stdout (port-based, a la retro?  Maybe not - that's
    flexible, but perhaps more than we need).
  - Add support for record blocks A and B - configurable number of fields
    per block; `aload`, `astore`, `bload`, `bstore`, `aread`, `awrite`,
    `bread`, `bwrite`
  - `.const`

* Minimal Infix High-Level Language (Minhi) - `<program>::=<expression>+`, and
  everything else is an expression.
  - Why expressions?  Because infix expressions are easy
  to parse based on a table, as described in
  [_A Retargetable C Compiler: Design and Implementation_](https://sites.google.com/site/lccretargetablecompiler/).
  - Lexer written in NGA+ that takes source and outputs token stream
  - Parser written in NGA+ that takes token stream (block A) and outputs
    AST (block B)
  - Compiler that produces NGA+ assembly
  - Later, a compiler that produces x86 assembly

Future: to be determined... (but possibly a C compiler written in Minhi)

