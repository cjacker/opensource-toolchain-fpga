all:
	ghdl -a and_gate.vhd
	ghdl -a and_gate_testbench.vhd
	ghdl -e and_gate_testbench
	./and_gate_testbench --vcd=and_gate_testbench.vcd
	gtkwave ./and_gate_testbench.vcd
clean:
	rm -f *.o *.vcd *.cf and_gate_testbench
