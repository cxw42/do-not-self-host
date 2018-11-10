# Makefile for ngb

all: ngb ngbasm.py

%.py: %.md
	./extract.py $^ $@
	chmod a+x $@

%: %.c
	gcc -o $@ $<

