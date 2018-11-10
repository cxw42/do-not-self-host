; ex1.nas: a simple test of ngb.  By cxw42, 2018.  MIT.
:main

  ; Put something on the stack, just so we'll see it when ngb exits.
  lit 42

  ; Print "A" so we know we're alive.
  lit 65
  out

  ; Loop echoing character+1 until space bar is pressed
:loop
  in

  ; Is it a space?
  dup
  lit 32
  eq

  ; If so, we're done.
  lit &done
  cjump

  ; Otherwise, bump it, print it, and loop around.
  lit 1
  add
  out
  lit &loop
  jump

:done
  ; Remove the leftover copy of the character that we didn't `out`
  drop
  end
