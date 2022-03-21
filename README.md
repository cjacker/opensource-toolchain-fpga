# OpenSource toolchain for FGPA

A **field-programmable gate array (FPGA)** is an integrated circuit designed to be configured by a customer or a designer after manufacturing – hence the term field-programmable.

FPGA is not a CPU or MCU or special-purpose IC whose configuration is set and sealed by a manufacturer and cannot be modified, it's a general purpose IC that can be programmed (configured) for specific use after it has been manufactured. FPGA contain adaptive logic modules (ALMs) and logic elements (LEs) connected via programmable interconnects. These blocks create a physical array of logic gates that can be customized to perform specific computing tasks. 

for more information of FPGA, you can refer to https://en.wikipedia.org/wiki/Field-programmable_gate_array.

FPGA programming is not like "programming" in the usual sense. FPGA programming is "creating hardware architecture to perform specific tasks",  And the programming language used with FPGA has little in common with traditional programming languages. to program FPGAs, you use specific hardware description languages (HDL) such as VHDL or Verilog, it describes the structure and behavior of electronic circuits, and most commonly, digital logic circuits. 

A programming language toolchain (such as C programming language) we known before is a 'translator' to translate the source codes to target binaries. the principles would be similar for FPGA, the toolchain of FPGA also works as a 'translator' to translate the source codes of HDL to target binaries (called as 'bitstream file'), and the compilation process for FPGA consists of 'synthesis' and 'place and route' (P&R), and the final bitstream file will be uploaded to FPGA by a flashing tool.

Until a few years ago, developing for FPGAs required the use of proprietary locked-down tools, but in the last few years, the satuation changed, open-source FPGA tools such as Yosys/Nextpnr have come flooding out. 

There is an article describing the design of Yosys/Nextpnr opensource FPGA toolchain very clearly and briefly, please refer to https://arxiv.org/pdf/1903.10407.pdf. 

This tutorial will focus on this opensource toolchain. there are also some other opensource FPGA toolchains or frameworks, most of them are based on yosys/nextpnr, you do not need to care about them at this time.

# Hardware requirements

* A FPGA development board, which can be well supported by yosys/nextpnr.
  - Lattice iCE40 or ECP5 family. for example, iCE40 ICEBreaker, ICESugar, ICESugar nano board, or ECP5 Colorlight series board.
  - Gowin LittleBee family. for example, Tang nano 1k/4k/9k board.
* Optional, a JTAG adapter.
  - most of FPGA development board already integrated it.


# Toolchain overview:

* HDL Coding and Verification: iverilog for verilog, ghdl for VHDL.
* Synthesis: yosys and ghdl-yosys-plugin
* Place and route: nextpnr with multiple backend(iCE40, ECP5, GOWIN, etc.)
* Flashing tool: various different tools for different FPGA family
* Other tools: gtkwave (waveform viewer), digitaljs (simulator), etc.

As mentioned above, the article "[Yosys+nextpnr: an Open Source Framework from
Verilog to Bitstream for Commercial FPGAs](https://arxiv.org/pdf/1903.10407.pdf)" describes Yosys/Nextpnr framework very clearly and briefly, I suggest you must read it first before continuing, then you should be able to understand the architechture of the toolchain and the input/output of every step.

# HDL Coding and Verification

## Verilog

Icarus Verilog is a opensource Verilog simulation and synthesis tool. It operates as a compiler, compiling source code written in Verilog (IEEE-1364) into some target format. For batch simulation, the compiler can generate an intermediate form called vvp assembly. This intermediate form is executed by the `vvp` command. For synthesis, the compiler generates netlists in the desired format. 

For more information, refer to http://iverilog.icarus.com/. 

Up to this tutorial written, the latest version of iverilog is '11.0', most modern dist already shipped iverilog in their repos, you can install it via yum/apt, and it's not neccesary to build iverilog yourself.

Here is a brief intro of iverilog usage. 

**Demo codes**

Save below codes to 'and_gate.v':

```
//and_gate.v -- and gate
module and_gate(
    input d1,
    input d2,
    output q
);
    assign q = d1 & d2;
endmodule
```

**Compile and Run/Simulate**

compile:
```
iverilog -o and_gate.vvp and_gate.v
```

run and simulate:
```
./and_gate.vvp 
# or
vvp ./and_gate.vvp
```

**Verification**

Usally, we also write corresponding test codes for verification:

```
//and_gate_testbench.v

`timescale 1ns/10ps

module and_gate_testbench;
    reg d1i;
    reg d2i;
    wire qo;
    and_gate ag0(.d1(d1i), .d2(d2i), .q(qo));
    initial begin
        d1i <= 0; d2i <= 0;
    #5  $display("input: 0x%0h 0x%0h, output: 0x%0h", d1i, d2i, qo);
    #5  d1i <= 0; d2i <= 1;
    #5  $display("input: 0x%0h 0x%0h, output: 0x%0h", d1i, d2i, qo);
    #5  d1i <= 1; d2i <= 0;
    #5  $display("input: 0x%0h 0x%0h, output: 0x%0h", d1i, d2i, qo);
    #5  d1i <= 1; d2i <= 1;
    #5  $display("input: 0x%0h 0x%0h, output: 0x%0h", d1i, d2i, qo);
    end
endmodule
```

compile and run:
```
iverilog -o and_gate_testbench.vvp and_gate_testbench.v and_gate.v
vvp ./and_gate_testbench.vvp
```

The output looks like:
```
input: 0x0 0x0, output: 0x0
input: 0x0 0x1, output: 0x0
input: 0x1 0x0, output: 0x0
input: 0x1 0x1, output: 0x1
```

**View waveform**

Dump the waveform (use $dumpfile and $dumpvars):

```
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
```

compile and run again:
```
iverilog -o and_gate_testbench.vvp and_gate_testbench.v gate.v
vvp ./and_gate_testbench.vvp
```

It will generate `and_gate_testbench.vcd` which will contain the waveform data. launch GTKWave with the filename as argument:

```
gtkwave and_gate_testbench.vcd
```

On the left panel select signals while holding Shift/Ctrl and click 'Append' button on the bottom. Use ctrl-shift-r to reload the VCD file without reconfiguring GTKWave signal selection:

<img src="https://user-images.githubusercontent.com/1625340/159230111-fff0d786-baad-4a1b-b8dc-928d3127fcc7.png" width="90%"/>


## VHDL

GHDL is an open-source simulator for the VHDL language. GHDL allows you to compile and execute your VHDL code directly in your PC.

GHDL fully supports the 1987, 1993, 2002 versions of the IEEE 1076 VHDL standard, and partially the latest 2008 revision (well enough to support fixed_generic_pkg or float_generic_pkg).

For more information, please refer to http://ghdl.free.fr/

Up to this tutorial written, the latest version of ghdl is '2.0.0', most modern dist already shipped ghdl with multiple backend in their repos, you can install it via your package management tool, and it's not neccesary to build it yourself.

Here is a brief intro of ghdl usage.

**Demo codes**

Here still use and gate as example, save below codes to 'and_gate.vhd':

```
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
```

and below codes to 'and_gate_testbench.vhd'

```
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
```

**Build and run**

```
ghdl -a and_gate.vhd
ghdl -a and_gate_testbench.vhd
ghdl -e and_gate_testbench
./and_gate_testbench
```

The output looks like:

```
and_gate_testbench.vhd:29:9:@40ns:(report note): and gate testbench finished
```

**View waveform**

```
./and_gate_testbench --vcd=and_gate_testbench.vcd
```

The wave form `and_gate_testbench.vcd` will be generated and contains the waveform data. launch GTKWave with the filename as argument:

```
gtkwave and_gate_testbench.vcd
```

# Yosys

Synthesis is the process of converting input Verilog file into a netlist, netlist is a "list of nets", which describes the connections between different block available on the desired FPGA chip. However, it is worth to notice that these are only logical connections. So the synthesized model is only a draft of the final design, made with the use of available resources.

**Yosys (Yosys Open SYnthesis Suite)** is a opensource framework for RTL synthesis tools. It currently has extensive Verilog-2005 support and provides a basic set of synthesis algorithms for various application domains.

Yosys take verilog source codes as input and generate netlist using JSON format.

A lot of dist. maybe already packaged yosys, but I do not suggest use it directly, it's probability an outdated version. if the version is too old, you should consider building it yourself.

Building yosys is very simple, but you need install some build requirments such as make/bison/flex/g++/python3/abc and readline/tcl/libffi development packages, then download a release source tarball (up to this tutorial written, the latest yosys version is 0.15) or clone the git repo from https://github.com/YosysHQ/yosys, and build it:

```
make config-gcc
make PREFIX=/usr ABCEXTERNAL=/usr/bin/abc PRETTY=0 all
make PREFIX=/usr ABCEXTERNAL=/usr/bin/abc install
```

The 'yosys' command will be installed to standard dir '/usr/bin'.

After build and installation successfully, try it with 'blink.v' (a demo verilog source file):

```
```

# Nextpnr
Input: netlist json file generated by yosys and specific phisical constraints file, Output: bitstream file

# Flashing






