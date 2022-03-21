all:
	iverilog and_gate_testbench.v and_gate.v -o and_gate_testbench.vvp
	./and_gate_testbench.vvp
	gtkwave ./and_gate_testbench.vcd
clean:
	rm -f *.vvp *.vcd
