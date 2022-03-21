//and_gate_testbench.v

`timescale 1ns/10ps

module and_gate_testbench;
    reg d1i;
    reg d2i;
    wire qo;
    and_gate ag0(.d1(d1i), .d2(d2i), .q(qo));
    initial begin
        $dumpfile("and_gate_testbench.vcd");
        $dumpvars(0, and_gate_testbench);
        d1i <= 0; d2i <= 0;
    #10 d1i <= 0; d2i <= 1;
    #10 d1i <= 1; d2i <= 0;
    #10 d1i <= 1; d2i <= 1;
    #10 $finish;
    end
endmodule
