-- and_gate.vhd

library ieee;
use ieee.std_logic_1164.all;

entity and_gate is
  port(d1,d2:in std_logic;
       q:out std_logic);
end and_gate;

architecture behavior of and_gate is
begin
  q <= d1 and d2;
end behavior;

