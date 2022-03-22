-- blink.vhdl
-- blink LED of iCESugar nano board every 1s.

library ieee;
use ieee.std_logic_1164.all;

entity blink is
port(
  clk: in std_logic;
  led: out std_logic
);
end blink;

architecture behavior of blink is
begin
  p1: process(clk)
-- the default freq of icesugar nano is 12Mhz
  variable count: integer range 0 to 12000000 := 0;
  variable ledstatus: std_logic;
  begin
    if clk'event and clk = '1' then
      if count < (4800000-1) then
        count := count + 1;
      else
        count := 0;
        ledstatus := not ledstatus;
      end if;
    end if;
    led <= ledstatus;
  end process;
end behavior;
