# mtok.nas Makefile

mtok.ngb: mtok.nas state-machine.geninc ../ngbasm.py
	-rm $@
	../ngbasm.py $< $@

state-machine.geninc: mtok.csv state-machine.py
	./state-machine.py $< > $@

