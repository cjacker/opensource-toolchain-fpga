# OpenSource toolchain for FGPA

**NOTE: the MIT license of this repo means all individual resources made by myself, the content of the tutorial and the example codes is licensed under MIT. All third-party opensource projects, upstream source codes and patches to other opensource projects will/should follow their own LICENSE.**

A **field-programmable gate array (FPGA)** is an integrated circuit designed to be configured by a customer or a designer after manufacturing – hence the term field-programmable.

FPGA is not a CPU, MCU or special-purpose IC whose configuration is set and sealed by a manufacturer and cannot be modified, it's a general purpose IC that can be programmed (configured) after it has been manufactured. FPGA contain adaptive logic modules (ALMs) and logic elements (LEs) connected via programmable interconnects. These blocks create a physical array of logic gates that can be customized to perform specific computing tasks. 

for more information of FPGA, you can refer to https://en.wikipedia.org/wiki/Field-programmable_gate_array.

FPGA programming is not like "software programming" in the usual sense. FPGA programming is "creating hardware architecture to perform specific tasks", And the programming language used with FPGA has little in common with traditional programming languages. to program FPGAs, you use specific hardware description languages (HDL) such as VHDL or Verilog, it describes the structure and behavior of electronic circuits, and most commonly, digital logic circuits. 

A programming language toolchain (such as C programming language) we known before is a 'translator' to translate the source codes to target binaries. the principles would be similar for FPGA, the toolchain of FPGA also works as a 'translator' to translate the source codes of HDL to target binaries (bitstream file), and the compilation process for FPGA consists of 'synthesis' and 'place and route' (P&R), and the final bitstream file will be uploaded to FPGA by a flashing tool.

Until a few years ago, developing for FPGAs required the use of proprietary locked-down tools, but in the last few years, the satuation changed, open-source FPGA tools such as Yosys/Nextpnr have come flooding out. 

There is an article describing the design of Yosys/Nextpnr opensource FPGA toolchain very clearly and briefly, please refer to https://arxiv.org/pdf/1903.10407.pdf. 

By the way, DO NOT CRITICIZE anything about the opensource FPGA toolchain, it's pointless. for beginners, the opensource FPGA toolchain is very easy to get and setup, very friendly to use，very clean to understand the FPGA development flow and good enough to start a project.

# Hardware requirements

* A FPGA development board, which can be well supported by yosys/nextpnr and not too expensive.
  - Lattice iCE40 or ECP5 family. for example, iCE40 ICEBreaker, ICESugar, ICESugar nano board, or ECP5 Colorlight series board.
  - Gowin LittleBee family. for example, Tang nano 1k/4k/9k/20k, Tang primer 20k board.
* Optional, a JTAG adapter.
  - most of FPGA development board already integrated one.

NOTE:
* QuickLogic devices (QLF-K4N8, QLF-K6N10 and EOS-S3) and Xilinx 7 series can be supported by Symbiflow/prjxray/Yosys/VTR, I will extend this tutorial after acquiring a dev board.

# Toolchain overview:
We will follow the FPGA design flow to describe the FPGA toolchain.

* Design and Verification: iVerilog for verilog, GHDL for VHDL, Verilator for verilog, Digital for verilog/VHDL
* Synthesis: yosys and ghdl-yosys-plugin
* Equivalence checking: yosys
* Formal Verification: yosys-smtbmc/sby with yices/z3, etc.
* Place and route: nextpnr with multiple backend(iCE40, ECP5, GOWIN, etc.)
* Program/Flash tool: various different tools for different FPGA family
* Other tools: gtkwave (waveform viewer), digitaljs (simulator), etc.


# Design and Verification

Note, there are some moderm HDL languanges such as Chipsel, SpinalHDL which can be used to generate VHDL/Verilog, After VHDL/Verilog generated, the following process should be same as we start from Verilog/VHDL direcly.

## iVerilog

Icarus Verilog is a opensource Verilog simulation and synthesis tool. It operates as a compiler, compiling source code written in Verilog (IEEE-1364) into some target format. For batch simulation, the compiler can generate an intermediate form called vvp assembly. This intermediate form is executed by the `vvp` command. For synthesis, the compiler generates netlists in the desired format. 

For more information, refer to http://iverilog.icarus.com/. 

Up to this tutorial written, the latest version of iverilog is '11.0', most modern dist already shipped iverilog in their repos, you can install it via yum/apt, and it's not neccesary to build iverilog yourself.

Here is a brief intro of iVerilog usage. 

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

**Compile and run**

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

Usally, we also write corresponding testbench codes for verification:

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

GHDL is an open-source simulator for VHDL language. GHDL allows you to compile and execute your VHDL code directly in your PC.

GHDL fully supports the 1987, 1993, 2002 versions of the IEEE 1076 VHDL standard, and partially the latest 2008 revision (well enough to support fixed_generic_pkg or float_generic_pkg).

For more information, please refer to http://ghdl.free.fr/

Up to this tutorial written, the latest version of ghdl is '2.0.0', most modern dist already shipped ghdl with multiple backends(llvm/gcc/mcode) in their repos, you can install it via your package management tool, and it's not neccesary to build it yourself.

Here is a brief intro of ghdl usage.

**Demo codes**

Here we still use and gate as example, save below codes to 'and_gate.vhd':

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

To build the simulation executable, we need to run Verilator again to regenerate the .mk files to include the C++ testbench, this is done using `--exe and_gate_testbench.cpp`:

```
verilator -Wall --trace -cc and_gate.v --exe and_gate_testbench.cpp
```

and build it:

```
make -C obj_dir -f Vand_gate.mk Vand_gate
```

Once built, simply run the 'Vand_gate' binary to run the simulation:

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

You can simulate it directly or export to VHDL or Verilog, after VHDL/Verilog generated, please refer to above sections.

# Synthesis

Synthesis is the process of converting input HDL source files into a netlist, netlist is a "list of nets", which describes the connections between different block available on the desired FPGA chip. However, it is worth to notice that these are only logical connections. So the synthesized model is only a draft of the final design, made with the use of available resources.

## Yosys basic usage

**Yosys (Yosys Open SYnthesis Suite)** is a opensource framework for RTL synthesis tools. It currently has extensive Verilog-2005 support and provides a basic set of synthesis algorithms for various application domains.

Yosys take HDL source codes as input and generate netlist using JSON format.

A lot of modern dist maybe already packaged Yosys. since it's probability an outdated version, I do not suggest using it directly. if the version is too old, you should consider building it yourself.

Building yosys is very simple, but you need install some requirments package such as make/bison/flex/g++/python3/abc and readline/tcl/libffi development packages, then download a release source tarball (up to this tutorial written, the latest Yosys version is 0.15) or clone the git repo from https://github.com/YosysHQ/yosys, and build it:

```
make config-gcc
make PREFIX=/usr ABCEXTERNAL=/usr/bin/abc PRETTY=0 all
make PREFIX=/usr ABCEXTERNAL=/usr/bin/abc install
```

The 'yosys' command will be installed to standard dir '/usr/bin'. If the 'PREFIX' is not set to standard dir, please add the path to PATH env after installtion according to your 'PREFIX' setting.

After build and installation successfully, try it with 'and_gate.v':

```
// and_gate.v -- and gate
module and_gate(
    input d1,
    input d2,
    output q
);
    assign q = d1 & d2;
endmodule
```

Yosys has REPL mode support, you can use it interactively or use batch script mode.

**REPL mode:**

```
$ yosys
yosys> read_verilog and_gate.v
1. Executing Verilog-2005 frontend: and_gate.v
Parsing Verilog input from `and_gate.v' to AST representation.
Generating RTLIL representation for module `\and_gate'.
Successfully finished Verilog frontend.

yosys> show
2. Generating Graphviz representation of design.
Writing dot description to `.yosys_show.dot'.
Dumping module and_gate to page 1.
Exec: { test -f '.yosys_show.dot.pid' && fuser -s '.yosys_show.dot.pid' 2> /dev/null; } || ( echo $$ >&3; exec xdot '.yosys_show.dot'; ) 3> '.yosys_show.dot.pid' &

yosys>
```

**Try to run 'help' in REPL mode to find the usage of yosys REPL commands.**

You should have 'graphviz' and 'xdot' installed first, yosys will generate the graphviz representation of design looks like:

<img src="https://user-images.githubusercontent.com/1625340/159398408-31e5a22d-b873-424f-8943-014debc3a210.png" width="60%">

**Batch mode**

You can create a batch script, for example, named "show.ys":

```
# show.ys -- batch script file for yosys
read_verilog and_gate.v
show
```

And involk yosys with it:

```
yosys show.ys
```

or use `-p` argument:

```
yosys -p "read_verilog and_gate.v; show"
```

**Synthesis**

Yosys support below synthesis command:

```
    synth                generic synthesis script
    synth_achronix       synthesis for Acrhonix Speedster22i FPGAs.
    synth_anlogic        synthesis for Anlogic FPGAs
    synth_coolrunner2    synthesis for Xilinx Coolrunner-II CPLDs
    synth_easic          synthesis for eASIC platform
    synth_ecp5           synthesis for ECP5 FPGAs
    synth_efinix         synthesis for Efinix FPGAs
    synth_gatemate       synthesis for Cologne Chip GateMate FPGAs
    synth_gowin          synthesis for Gowin FPGAs
    synth_greenpak4      synthesis for GreenPAK4 FPGAs
    synth_ice40          synthesis for iCE40 FPGAs
    synth_intel          synthesis for Intel (Altera) FPGAs.
    synth_intel_alm      synthesis for ALM-based Intel (Altera) FPGAs.
    synth_machxo2        synthesis for MachXO2 FPGAs. This work is experimental.
    synth_nexus          synthesis for Lattice Nexus FPGAs
    synth_quicklogic     Synthesis for QuickLogic FPGAs
    synth_sf2            synthesis for SmartFusion2 and IGLOO2 FPGAs
    synth_xilinx         synthesis for Xilinx FPGAs
```

What we used in this tutorial is 'synth_ice40'/'synth_ecp5'/'synth_nexus'/'synth_gowin'.

For example, we can generate the json format netlist for Lattice ICE40 device as:

```
yosys -ql blink-yosys.log -p "read_verilog and_gate.v; synth_ice40 -json top.json"
```

A 'top.json' netlist for iCE40 will be generated. The synthesis process is platform related, for Lattice ECP5, you should use 'synth_ecp5' command, and for GOWIN (tang nano board), use 'synth_gowin' command. 


## DigitalJS as circuit viewer and simulator after synthesis

[DigitalJS](https://github.com/tilk/digitaljs) is a digital circuit simulator implemented in Javascript. It is designed to simulate circuits synthesized by hardware design tools like Yosys.

Refer to https://github.com/tilk/digitaljs for more information and how to install it.

Here I suggest 2 way to use DigitalJS:

**Online mode**

Open https://digitaljs.tilk.eu/ and upload 'and_gate.v', press "Synthesize and Simulate!" button:

<img src="https://user-images.githubusercontent.com/1625340/159402821-2a3c02c2-6ff2-4c92-a514-e6de77b56205.png" width="50%"/>

**Vscode extentions**

I never suggest which editor should be used before, but Vscode with Verilog and digitalJS extensions is really a good solution to write Verilog codes, you can simulate/verify the verilog codes within vscode with digitalJS, it looks like:

<img src="https://user-images.githubusercontent.com/1625340/159403295-b87b2180-df69-4927-b19e-43da430b0160.png" width="50%"/>

## ghdl-yosys-plugin as VHDL frontend for yosys

By default, Yosys support Verilog 2005 as its input. with 'ghdl-yosys-plugin', Yosys can use VHDL as its input.

Installation:

```
git clone https://github.com/ghdl/ghdl-yosys-plugin.git
make
mkdir -p /usr/share/yosys/plugins
sudo install -m0755 ghdl.so /usr/share/yosys/plugins/
```

If you install yosys to another PREFIX, change it to 'PREFIX/share/yosys/plugins' dir.

Basic usage (use and_gate.vhd from above example):

```
yosys -m ghdl -p 'ghdl and_gate.vhd -e and_gate; show'
yosys -m ghdl -p 'ghdl and_gate.vhd -e and_gate; synth_ice40 -json top.json'
```

# Formal verification

FV is a difficult topic for beginners, you can ignore this section now.

`yosys-smtbmc` is a tool focus on verification of safety properties using BMC and k-induction, using SMT2 circuit descriptions generated by Yosys. and `sby` (SymbiYosys) is a unified front-end for many Yosys-based formal verification flows.

Here is some tutorials for you reference:

http://www.testandverification.com/wp-content/uploads/2017/Formal_Verification/Clifford_Wolf.pdf

https://www.yumpu.com/en/document/read/57038912/formal-verification-with-yosys-smtbmc-clifford-wolf

https://zipcpu.com/tutorial/

https://zipcpu.com/blog/2017/10/19/formal-intro.html

https://zipcpu.com/tutorial/formal.html

https://readthedocs.org/projects/symbiyosys/downloads/pdf/latest/

## Equivalence Checking

Equivalence checking is a portion of a larger discipline called formal verification. This technology uses mathematical modeling techniques to prove that two representations of design exhibit the same behavior. it is useful when we change the codes but want to make sure it has the same behavior as before.

Consider below two Verilog source files:

and1.v
```
module and_gate(
  input d1,
  input d2,
  output q
);
  assign q = d1 & d2;
endmodule
```

and2.v
```
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
```

After reading the codes, we know they have exact same behaviors, 'equivalence checking' is used to prove it. 

Write a batch script 'eqv_check.yosys' as:

```
read_verilog and1.v
prep -flatten -top and_gate
splitnets -ports;;
design -stash gold

read_verilog and2.v
prep -flatten -top and_gate
splitnets -ports;;
design -stash gate

design -copy-from gold -as gold and_gate
design -copy-from gate -as gate and_gate

equiv_make gold gate merged
prep -flatten -top merged

opt_clean -purge
show -prefix equiv-prep -colors 1 -stretch

## method 1
opt -full
equiv_simple -seq 5
equiv_induct -seq 5
equiv_status -assert

## method 2
#equiv_struct -icells t:$adff t:$equiv
#equiv_simple -seq 5
#equiv_induct -seq 5
#equiv_status -assert

## method 3
#techmap -map +/adff2dff.v
#equiv_simple -seq 5
#equiv_induct -seq 5
#equiv_status -assert

## method 4
#clk2fflogic
#equiv_simple -seq 10
#equiv_induct -seq 10
#equiv_status -assert
```

And run:

```
yosys eqv_check.yosys
```

The output looks like:

```
14. Executing EQUIV_STATUS pass.
Found 1 $equiv cells in merged:
  Of those cells 1 are proven and 0 are unproven.
  Equivalence successfully proven!Supports PICkit2 and PICkit3 programmers
```

There are 4 eqv checking method in this batch script, you can try them as you like.


# Place and route

After synthesis, we need to map the netlist generated by Yosys to actual resources in our FPGA. This process is known as **place and route** and it actually consists of a few different steps.

Nextpnr is the opensource FPGA place and route tool we use in this tutorial. The place and route process is a little bit complex, there is an article ["A Complete Open Source Design Flow for
Gowin FPGAs"](https://ris.utwente.nl/ws/portalfiles/portal/249654527/DeVos2020complete.pdf) described how to implement GOWIN FPGA support in Yosys/Nextpnr, you can take it as reference to understand the detail process.

Generally, you can think it as 'Nextpnr process **the output of Yosys (the netlist with json format)** and **the physical constraints file** supplied by developer or EVB vendors (for example, to inform the software what physical pins on the FPGA should used to control a LED, different vendors use different forms for their constraint files), with some hardware related configuration options, and finally generate the target bitstream file which can be program to FPGA device'.

Currently nextpnr supports:

* Lattice iCE40 devices supported by Project IceStorm
* Lattice ECP5 devices supported by Project Trellis
* Lattice Nexus devices supported by Project Oxide
* Gowin LittleBee devices supported by Project Apicula
* (experimental) Cyclone V devices supported by Mistral
* (experimental) Lattice MachXO2 devices supported by Project Trellis
* (experimental) a "generic" back-end for user-defined architectures

We will introduce the usage of nextpnr for iCE40, ECP5 and Gowin LittleBee, since there are many low-cost boards with these FPGAs for beginners.

## Installation

The installation of nextpnr with different backends is not very easy, If your dist provide the latest version, you can use it directly. if you want to build it yourself, usally you should follow below steps: 1) build and install the bitstream generating tool according to FPGA you use, 2) build the nextpnr with correct backend. 

**Build and install the bitstream generating tool**

For **iCE40**, you should build and install 'icestorm' first:
```
git clone https://github.com/YosysHQ/icestorm.git
make PREFIX=/usr CHIPDB_SUBDIR="icestorm"
make install
```
For **ECP5**, you should build and install 'trellis' and for **GOWIN LittleBee**, it is 'apicula'.

**Build and install nextpnr with different backends**

Up to this tutorial written, the latest release of nextpnr is '0.7', you can download a tarball release or use git codes from 'https://github.com/YosysHQ/nextpnr'. Here I enable Lattice Nexus/ECP5/iCE40 and GOWIN LittleBee support. Up to now, the iCE40 series, ECP5 series and GOWIN LittleBee series have the best support from Nextpnr.

**Update 2024-11-22**: 'nextpnr-himbaechel' had better Gowin 2A family support than 'nextpnr-gowin', please use 'nextpnr-himbaechel' instead of 'nextpnr-gowin'.

```
cmake . -DARCH="generic;ice40;nexus;ecp5;gowin;himbaechel" -DHIMBAECHEL_GOWIN_DEVICES="all" -DICEBOX_DATADIR=/usr/share/icestorm -DTRELLIS_LIBDIR=/usr/lib/trellis
make
make install 
```

After installation finished, there should have 'nextpnr-nexus'/'nextpnr-ecp5'/'nextpnr-ice40'/'nextpnr-gowin'/'nextpnr-himbaechel' installed in /usr/bin.

## Usage demo for Lattice iCE40 (iCESugar and iCESugar nano)

Here we use iCESugar development board with Lattice iCE40-UP5K, it has a RGB LED on board. 

save below codes to 'blink.v':

```
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
```

and below codes to 'io.pcf' (Your board vendor should provide you with a master constraint file, you may still need to comment out pins you not use and rename pins to match your verilog codes)

```
# all io pin used in blink.v
set_io LED_G 41
set_io LED_R 40
set_io LED_B 39
set_io clk   35
```

and Run:

```
$ yosys -ql blink-yosys.log -p "read_verilog blink.v; synth_ice40 -json top.json"
$ nextpnr-ice40  -ql blink-nextpnr.log --up5k --package sg48 --json top.json --pcf io.pcf --asc top.asc
$ icepack top.asc blink.bin
```

The 'blink.bin' is the final bitstream file can be programmed to iCE40 FPGA.

NOTE the parameters `--up5k` and `--package sg48` used with 'nextpnr-ice40' command, you should use the correct parameters according to your hardware.

There is various blink examples and a Makefile template provided for ECP5/iCE40-UP5k/iCE40-LP1K and GOWIN LittleBee within this repo. you can take it as reference.

Depend on the development status of various backends, some of them have more features, for example, the icetime program provided by icestorm is an iCE40 timing analysis tool. It reads designs in IceStorm ASCII format and writes times timing netlists that can be used in external timing analysers. It also includes a simple topological timing analyser that can be used to create timing reports.

If you have a iCESugar nano board, the 'blink.v' should be:

```
// blink.v
// the default clk of icesugar nano is 12Mhz,
// and can be adjusted by icesprog.
//
// $ icesprog -c 1
// CLK -> [ 8MHz]
// CLK-SELECT:
//         [1]:  8MHz
//         [2]: 12MHz
//         [3]: 36MHz
//         [4]: 72MHz
// done

// LED blink every (2**24-1)/12M ~= 1.398s.

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
```

and 'io.pcf' for icesugar nano board should be:
```
set_io led B6
set_io clk D1
```

and Run:
```
$ yosys -ql blink-yosys.log -p "read_verilog blink.v; synth_ice40 -json top.json"
$ nextpnr-ice40  -ql blink-nextpnr.log --lp1k --package cm36 --json top.json --pcf io.pcf --asc top.asc
$ icetime -d lp1k -mtr blink.rpt top.asc
// Reading input .asc file..
// Reading 1k chipdb file..
// Creating timing netlist..
// Timing estimate: 7.48 ns (133.68 MHz)
$ icepack top.asc blink.bin
```

## Usage demo for ECP5 (ColorLight-i9 board)

Please refer to 'https://github.com/cjacker/opensource-toolchain-fpga/tree/main/blink-examples/colorlight-i9-ecp5'.

The building process as:
```
$ yosys -ql blink-yosys.log -p "read_verilog blink.v; synth_ecp5 -json top.json" blink.v
$ nextpnr-ecp5  -ql blink-nextpnr.log --45k --package CABGA381 --speed 6 --json top.json --textcfg top.config --lpf io.lpf
$ ecppack --bit blink.bit top.config
```

Note:
* The format of physical constraints 'LPF' file is different with iCE40 'PCF' file.
* the parameters of nextpnr-ecp5 is different with nextpnr-ice40, set them up according to your hardware.

## Usage demo for GOWIN LittleBee (Tangnano 9k board)

Please refer to https://github.com/cjacker/opensource-toolchain-fpga/tree/main/blink-examples/tang-nano-9k

The building process for Tang nano 9k is:

```
yosys -ql blink-yosys.log -p "read_verilog blink.v; synth_gowin -json top.json" blink.v
nextpnr-himbaechel -ql blink-nextpnr.log \
    --json top.json \
    --write pnrtop.json \
    --device GW1NR-LV9QN88PC6/I5 \
    --vopt family=GW1N-9C \
    --vopt cst=tangnano9k.cst
gowin_pack -d GW1N-9C -o blink.fs pnrtop.json
```

**nextpnr-gowin is deprecated**

If you use 'nextpnr-gowin', the building process is:
```
$ yosys -ql blink-yosys.log -p "read_verilog blink.v; synth_gowin -json top.json" blink.v
$ nextpnr-gowin  -ql blink-nextpnr.log \
        --json top.json \
        --write pnrtop.json \
        --device GW1NR-LV9QN88PC6/I5 \
        --cst tangnano9k.cst
$ gowin_pack -d GW1N-9C -o blink.fs pnrtop.json
```

Note:
* The format of physical constraints 'CST' file is different.
* you need supply the device family and model according to your device to setup the parameters of nextpnr-gowin and gowin_pack.

## Usage demo of VHDL for iCESugar nano

All above blink examples are Verilog codes, Here is a VHDL blink example for iCE40-LP1K (iCESugar nano dev board).

```
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
```

and Run below commands to generate the final bitstream:

```
$ yosys -m ghdl -ql blink-yosys.log -p "ghdl blink.vhdl -e blink; synth_ice40 -json top.json"
$ nextpnr-ice40  -ql blink-nextpnr.log --lp1k --package cm36 --json top.json --pcf io.pcf --asc top.asc --freq 12
$ icetime -d lp1k -mtr blink.rpt top.asc
// Reading input .asc file..
// Reading 1k chipdb file..
// Creating timing netlist..
// Timing estimate: 10.76 ns (92.96 MHz)
$ icepack top.asc blink.bin
```

You may noticed that only the Yosys command is different with Verilog example.

# Flashing

Congratulation, when you reach the 'flashing' section, you should already have the bitstream file generated for your FPGA hardware, it's really not an easy task. the last step we will do is to upload it to the real FPGA hardware. 

There are various tools we can use, such as openocd, openFPGALoader or some board related tool. actually it depends on not only the FPGA chip but also the development board. for example, 'iceprog' provided by icestorm is a programming tool specially for **FTDI-based** Lattice iCE programmers.

The most common used opensource FPGA flashing tool is openFPGALoader, it has a compatibility list about [FPGA chip](https://trabucayre.github.io/openFPGALoader/compatibility/fpga.html), [development board](https://trabucayre.github.io/openFPGALoader/compatibility/board.html), [cables and adapters](https://trabucayre.github.io/openFPGALoader/compatibility/cable.html), you can take it as reference.

For development boards mentioned in this tutorial,

**iCEBreaker:**

iCEBreaker had on-board FTDI FT2232H integrated, you can directly use 'iceprog' to flashing:
```
iceprog <bitstream file>
```

**iCESugar and iCESugar nano:**

There are 2 way to flash iCESugar board.

* USB storage

iCESugar can be mounted as USB storage device, and you can DND the bitstream file to it.

* icesprog

The designer of iCESugar also develop a flashing tool named ['icesprog'](https://github.com/wuxx/icesugar/tree/master/tools
) (NOTE, it's ice**s**prog, not iceprog)

```
icesprog <bistream file>
```

**Colorlight series with Lattice ECP5:**



You can use openocd to flash the ColorLight ECP5 series board, but it not the best choice.

```
$ sudo openocd -f ./cmsisdap.cfg -c "init;scan_chain; exit;"  #probe
$ sudo openocd -f ./cmsisdap.cfg -c "init;scan_chain; svf -tap ecp5.tap -quiet -progress bistream.svf; exit;" # flash to sram
```

By default, the flash of colorlight series board is write-protected. There is [ecpdap](https://github.com/adamgreig/ecpdap/) which allows you to program ECP5 FPGAs and attached SPI flash using CMSIS-DAP probes in JTAG mode. it had some special features, for example, unlock the protected flash of colorlight board

```
# program to sram:
ecpdap probes && ecpdap scan && ecpdap program --freq 5000 bistream.bit

# erase flash:
ecpdap probes && ecpdap scan && ecpdap flash scan && ecpdap flash unprotect && ecpdap flash erase

# program to flash: 
ecpdap probes && ecpdap scan && ecpdap flash scan && ecpdap flash unprotect && ecpdap flash --freq 5000 write bitstream.bit && ecpdap flash protect
```

[ecpprog](https://github.com/gregdavill/ecpprog) is a another programmer for the Lattice ECP5 series, making use of **FTDI based** JTAG adaptors. 


**Tang nano series board with GOWIN FPGA:**

openFPGALoader has Tang nano serires board support.  for tangnano 9k board:

```
openFPGALoader -b tangnano9k bitstream.fs
```

# Project and Makefile template

I already made a [Makefile template](https://github.com/cjacker/opensource-toolchain-fpga/blob/main/Makefile.template) which include everything in this tutorial, you can use it to start a project very quickly.

When you start a new project, you need modify the 'PROJECT'/'DEVICE'/'SOURCES' vars in Makefile, and also need to check the options defined per arch according to your hardware.

for physical constraints file per development board, you can take a look into 'blink-examples', the complete physical constraints file for iCESugar and Tang nano/1k/4k/9k already provided in corresponding folder of 'blink-examples'. you can also write it manually according to the board's circuit schematic.
