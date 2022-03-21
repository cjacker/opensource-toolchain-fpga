//and_gate.v -- and gate
module and_gate(
    input d1,
    input d2,
    output q
);
    assign q = d1 & d2;
endmodule
