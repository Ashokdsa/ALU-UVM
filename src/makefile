QUESTA := /home/share/questa.csh
SHELL := /bin/csh

#.IGNORE:
	#make clean
	#make view

.ONESHELL:

all:
	source $(QUESTA) 
	make clean 
	make compile 
	make simulate

main:
	source $(QUESTA)
	make clean
	rm -rf covReport alu_coverage.ucdb
	vlog -sv +acc +cover +fcover -l alu.log alu_top.sv
	vsim -vopt work.top -voptargs=+acc=npr -assertdebug -l simulation.log -coverage -c -do "coverage save -onexit -assert -directive -cvg -codeAll alu_coverage.ucdb; run -all; exit"  
	vcover report -html alu_coverage.ucdb -htmldir cov_report -details

view:
	firefox ./covReport/index.html

compile:
	vlog -sv alu_top.sv

simulate:
	vsim -c top +UVM_VERBOSITY=UVM_MEDIUM -do "run -all;exit" 

clean:
	rm -rf transcript work/
	rm alu.log
	rm wave.vcd
	rm simulation.log
	clear
	clear
	clear

#+UVM_OBJECTION_TRACE
