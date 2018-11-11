; ex1.nas: a simple test of ngb.  By cxw42, 2018.  MIT.
:main

  ; Put something on the stack, just so we'll see it when ngb exits.
  .lit 42

  ; Print "A" so we know we're alive.
  out 65

  ; Loop echoing character+1 until space bar is pressed
:loop
  in

  ; Is it a space?
  dup
  eq 32

  ; If so, we're done.
  cjump &done

  ; Otherwise, bump it, print it, and loop around.
  add 1
  out
  jump &loop

:done
  ; Remove the leftover copy of the character that we didn't `out`
  drop
  end
