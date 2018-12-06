# mtok.nas Makefile

DEPS = state-machine.geninc ../ngbasm.py ../minhi-constants.nas

all: mtok.ngb mtok2.ngb

%.ngb: %.nas
	-rm $@
	../ngbasm.py $< $@

mtok.ngb: mtok.nas $(DEPS)

mtok2.ngb: mtok2.nas $(DEPS)

state-machine.geninc: mtok-generated.csv state-machine.py
	./state-machine.py $< > $@

mtok-generated.csv: make-mtok-csv.pl
	./make-mtok-csv.pl > $@

