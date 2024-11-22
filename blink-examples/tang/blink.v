/*
blink.v

The default clock is 27Mhz for tang nano 9k
LED blink every (2**25-1)/27000000 ~= 1.24s
*/

module blink(
	input clk,
	output [5:0] led
);

  reg [24:0] counter;

  initial begin
    counter = 0;
  end

  always @(posedge clk)
  begin
    counter <= counter + 1;
  end
  
  assign led[5] = counter[24];
  assign led[4] = counter[24];
  assign led[3] = counter[24];
  assign led[2] = counter[24];
  assign led[1] = counter[24];
  assign led[0] = counter[24];

endmodule
