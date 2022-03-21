module and_gate(
  input d1,
  input d2,
  output q
);
  reg r;
  initial begin
  if(d1 == 0 && d2 == 0)
    r <= 0;
  else if(d1 == 0 && d2 == 1)
    r <= 0;
  else if(d1 == 1 && d2 == 0)
    r <= 0;
  else
    r <= 1;
  end
  assign q = r;
endmodule
