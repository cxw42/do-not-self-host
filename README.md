# do-not-self-host

A development toolchain from the ground up, starting from assembly.
Don't self-host your next language!  Make it possible for us to build from
source, from scratch, without needing a bootstrap package!

Assumes a development environment that provides stdin/stdout and redirection.

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
  - Lexer written in NGA+ that outputs token stream
  - Parser written in NGA+ that takes token stream (block A) and outputs
    AST (block B)
  - Compiler that produces NGA+ assembly
  - Later, a compiler that produces x86 assembly

Future: to be determined...
