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

* Design and Verification: iVerilog for verilog, GHDL for VHDL, Verilator for verilog, Digital for verilog
* Synthesis: yosys and ghdl-yosys-plugin
* Equivalence checking: yosys
* Place and route: nextpnr with multiple backend(iCE40, ECP5, GOWIN, etc.)
* Flashing tool: various different tools for different FPGA family
* Other tools: gtkwave (waveform viewer), digitaljs (simulator), etc.


# Design and Verification

NOTE:
- all codes used in this chapter are provided within this repo.
- Chipsel/SpinalHDL can be used to generate VHDL/Verilog files, it's another topic and will not include in this tutorial.

## iVerilog

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


## GHDL

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

## Verilator
Verilator is a tool that compiles Verilog and SystemVerilog sources to highly optimized (and optionally multithreaded) cycle-accurate C++ or SystemC code. The converted modules can be instantiated and used in a C++ or a SystemC testbench, for verification and/or modelling purposes.

More information can be found at [the official Verilator website](https://www.veripool.org/verilator/) and [the official manual](https://verilator.org/guide/latest/).

Up to this tutorial written, the latest version of verilator is '4.220', most modern dist already shipped verilator in their repos, you can install it via the package management tool, and it's not neccesary to build it yourself.

Here we use 'and_gate.v' as example:

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

Verilator requires a C++ testbench gets compiled into a native system binary. first it need to use Verilator to convert the SystemVerilog code into C++, or “Verilate” it, which in it’s most basic form is done as follows:

```
verilator --cc and_gate.v
```

The `--cc` parameter here tells Verilator to convert to C++. Verilator also supports conversion to SystemC, which can be done by using `--sc`, but we will not be using this functionality for now.

Running the above command generates a new folder named `obj_dir`  with lot of files in current working directory:

```
$ ls obj_dir
Vand_gate_classes.mk  Vand_gate.h   Vand_gate__Slow.cpp  Vand_gate__Syms.h  Vand_gate__verFiles.dat
Vand_gate.cpp         Vand_gate.mk  Vand_gate__Syms.cpp  Vand_gate__ver.d
```

The generated `.mk` files will be used with Make to build our simulation executable, while the .h and .cpp files contain our C++ headers and implementation sources, resulting from the verilog conversion.

Then create `and_gate_testbench.cpp` under `obj_dir` with below codes:

```
#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vand_gate.h"

#define SIM_TIME 40

vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {

    Vand_gate *ag = new Vand_gate;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;

    ag->trace(m_trace, 5);

    m_trace->open("and_gate_testbench.vcd");

    while (sim_time <= SIM_TIME) {
        if(sim_time < 10) {
          ag->d1 = 0;
          ag->d2 = 0;
        } else if(sim_time < 20) {
          ag->d1 = 0;
          ag->d2 = 1;
        } else if(sim_time < 30) {
          ag->d1 = 1;
          ag->d2 = 0;
        } else {
          ag->d1 = 1;
          ag->d2 = 1;
        }
        ag->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();

    delete ag;
    exit(EXIT_SUCCESS);
}
```

To build the simulation executable, we need to run Verilator again to regenerate the .mk files to include the C++ testbench - this is done using `--exe and_gate_testbench.cpp`:

```
verilator -Wall --trace -cc and_gate.v --exe and_gate_testbench.cpp
```

and build it:

```
make -C obj_dir -f Vand_gate.mk Vand_gate
```

Once built, simply run the Valu binary to run the simulation:

```
$./obj_dir/Vand_gate
```

Running the simulation resulted in a waveform file named `and_gate_testbench.vcd` being generated in current working directory.
```
gtkwave ./and_gate_testbench.vcd
```

## Digital
[Digital](https://github.com/hneemann/Digital) is an easy-to-use digital logic designer and circuit simulator designed for educational purposes, and it can be exported to VHDL or Verilog

There is no installation required, just download and unpack the [Digital.zip](https://github.com/hneemann/Digital/releases/download/v0.29/Digital.zip) file and run:

```
java -jar Digital.jar
```

And the 'and_gate' example in digital looks like:

<img src="https://user-images.githubusercontent.com/1625340/159297256-73d3724a-51f1-40ed-b2ec-8e14676d4ad6.png" width="80%"/>

You can simulate it directly or export to VHDL or Verilog.


# Synthesis

Synthesis is the process of converting input HDL source files into a netlist, netlist is a "list of nets", which describes the connections between different block available on the desired FPGA chip. However, it is worth to notice that these are only logical connections. So the synthesized model is only a draft of the final design, made with the use of available resources.

**Yosys (Yosys Open SYnthesis Suite)** is a opensource framework for RTL synthesis tools. It currently has extensive Verilog-2005 support and provides a basic set of synthesis algorithms for various application domains.

Yosys take HDL source codes as input and generate netlist using JSON format.

A lot of modern dist maybe already packaged yosys. since it's probability an outdated versionbut, I do not suggest use it directly. if the version is too old, you should consider building it yourself.

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






