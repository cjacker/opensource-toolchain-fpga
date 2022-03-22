/*
blink.v

The default clk of icesugar nano is 12Mhz,
and can be adjusted with 'icesprog'.

$ icesprog -c 1
CLK -> [ 8MHz]
CLK-SELECT:
        [1]:  8MHz
        [2]: 12MHz
        [3]: 36MHz
        [4]: 72MHz
done

LED blink every (2**24-1)/12M ~= 1.398s
*/

module blink(
   input clk,
   output led
);
   reg [23:0] counter;

   initial begin
      counter = 0;
   end

   always @(posedge clk ) begin
      counter <= counter + 1;
   end

  assign led = counter[23];
endmodule
