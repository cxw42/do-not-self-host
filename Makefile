# Makefile for ngb

all: ngb ngbasm.py

%.py: %.md
	./extract.py $^ $@
	chmod a+x $@

# Default rule for %: %.c
