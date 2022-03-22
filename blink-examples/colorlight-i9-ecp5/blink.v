/*
blink.v

The default clk of colorlight-i9/i7/i5 is 25Mhz,

LED blink every (2**25-1)/25M ~= 1.341s
*/

module blink(
   input clk,
   output led
);
   reg [24:0] counter;

   initial begin
      counter = 0;
   end

   always @(posedge clk ) begin
      counter <= counter + 1;
   end

  assign led = counter[24];
endmodule
