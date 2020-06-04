# mtok Makefile

.PHONY: all clean

DEPS = state-machine.geninc ../ngbasm.py ../minhi-constants.nas make-mtok-csv.pl ../lib/mtok/lexergen.pm

PROGRAMS = mtok.ngb mtok2.ngb

all: $(PROGRAMS)

%.ngb: %.nas
	-rm $@
	../ngbasm.py $< $@

mtok.ngb: mtok.nas $(DEPS)

mtok2.ngb: mtok2.nas $(DEPS)

state-machine.geninc: mtok-generated.csv state-machine.py
	./state-machine.py $< > $@

mtok-generated.csv: make-mtok-csv.pl
	perl -I../lib $< > $@
	-dot -Tpng mtok-generated.dot > mtok-generated.png

clean:
	-rm -f $(PROGRAMS) state-machine.geninc mtok-generated.csv
