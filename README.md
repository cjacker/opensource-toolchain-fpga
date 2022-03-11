# OpenSource toolchain for FGPA

A **field-programmable gate array (FPGA)** is an integrated circuit designed to be configured by a customer or a designer after manufacturing – hence the term field-programmable.

FPGA is not a CPU or MCU or special-purpose IC whose configuration is set and sealed by a manufacturer and cannot be modified, it's a general purpose IC that can be programmed (configured) for specific use after it has been manufactured. FPGA contain adaptive logic modules (ALMs) and logic elements (LEs) connected via programmable interconnects. These blocks create a physical array of logic gates that can be customized to perform specific computing tasks. 

FPGA programming is not like "programming" in the usual sense, such as C programming. FPGA programming is "creating hardware architecture to perform specific tasks". that's to say, by FPGA programming, you can config FPGA working as a CPU or as a hardware accelerator of specific algorithm.

And the programming language used with FPGA is far different from various programming languages we are already similar with. to program FPGAs, you use specific hardware description languages such as VHDL or Verilog, it describes the structure and behavior of electronic circuits, and most commonly, digital logic circuits. 

for more information of FPGA, you can refer to https://en.wikipedia.org/wiki/Field-programmable_gate_array.

A programming language toolchain (such as C programming language) we known before is a 'translator' to translate the source codes to target binaries. the principles would be similar for FPGA, the toolchain of FPGA also works as a 'translator' to translate the source codes of hardware description languages (such as verilog) to target binaries (it called as 'bitstream file'), and the compilation process for FPGA consists of 'synthesis' and 'place and route' (P&R), and the final bitstream file will be uploaded to FPGA by a flashing tool.

Until a few years ago, developing for FPGAs required the use of proprietary locked-down tools, but in the last few years, the satuation changed, open-source FPGA tools such as Yosys nextpnr have come flooding out. 

There is a good and not too long article describing the design of Yosys/Nextpnr opensource FPGA toolchain very clearly and briefly, please refer to https://arxiv.org/pdf/1903.10407.pdf. 

This tutorial will focus on this opensource toolchain of FPGA. there are also some opensource FPGA toolchains based on yosys/nextpnr, 


