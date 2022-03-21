all:
	verilator -cc and_gate.v
	cp and_gate_testbench.cpp obj_dir
	verilator -Wall --trace -cc and_gate.v --exe and_gate_testbench.cpp
	make -C obj_dir -f Vand_gate.mk Vand_gate
	./obj_dir/Vand_gate
	gtkwave ./and_gate_testbench.vcd 
clean:
	rm -rf *.vcd obj_dir
