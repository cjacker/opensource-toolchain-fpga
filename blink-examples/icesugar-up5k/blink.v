/*
blink.v -- blink the RGB led on iCESugar board.

  LED_B LED_G LED_R 
  1     1     1    black   (all off)
  1     1     0    red
  1     0     1    green
  1     0     0    yellow  (red + green)
  0     1     1    blue
  0     1     0    magenta (red + blue)
  0     0     1    cyan    (green + blue)
  0     0     0    white

The default clock of iCESugar is 12Mhz.
LED blink every (2**24-1)/12M ~= 1.398s
*/

module blink(
    input clk, 
    output LED_R, 
    output LED_G, 
    output LED_B
);
    reg [23:0] counter;
    
    initial begin
        counter = 24'd0;
    end
    
    always @(posedge clk) begin
        counter <= counter + 1;
    end
    
    assign LED_R = ~counter[23];
    assign LED_G = ~counter[23];
    assign LED_B = ~counter[23];
endmodule
