-- and_gate_testbench.vhd

library ieee;
use ieee.std_logic_1164.all;

entity and_gate_testbench is
end and_gate_testbench;

architecture behavior of and_gate_testbench is
    component and_gate is
        port (
            d1  : in  std_logic;
            d2  : in  std_logic;
            q   : out std_logic);
    end component;
    signal input  : std_logic_vector(0 to 1);
    signal output : std_logic;
begin
    uut: and_gate port map (
        d1 => input(0),
        d2 => input(1),
        q  => output
    );

    stim_proc: process
    begin
        input <= "00"; wait for 10 ns; assert output = '0' report "0 and 0 failed";
        input <= "01"; wait for 10 ns; assert output = '0' report "0 and 1 failed";
        input <= "10"; wait for 10 ns; assert output = '0' report "1 and 0 failed";
        input <= "11"; wait for 10 ns; assert output = '1' report "1 and 1 failed";
        report "and gate testbench finished";
        wait;
    end process;
end;
