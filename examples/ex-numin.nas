; Numin example

:main
    numin
    iseof
    cjump &done

    ; The way to see this run is by watching the trace.  Look for the `dup`s.
    ; Alternatively, look at the stack print at the end of execution.
    dup
    jump &main

:done
    end

