# Makefile for ngb

ngb_all: ngb ngbasm.py

%.py: %.md
	./extract.py $^ $@
	chmod a+x $@

# Use the default rule for %: %.c
