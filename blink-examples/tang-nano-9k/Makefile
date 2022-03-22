# for openFPGALoader:
# board name: https://trabucayre.github.io/openFPGALoader/compatibility/board.html
# cabel name: https://trabucayre.github.io/openFPGALoader/compatibility/cable.html
# fpga: https://trabucayre.github.io/openFPGALoader/compatibility/fpga.html


# define project name, and used as result bitstream filename.
PROJECT = blink

# available devices: nexus/ecp5/ice40/gowin. machxo2 had limited support for 1200, not enabled now.
DEVICE = gowin 

# source list. for multiple source files, TOP should be first one in list.
SOURCES = blink.v

############################################
#          options per ARCH                #
############################################

# for Lattice Nexus devices
ifeq ($(strip  $(DEVICE)), nexus)
  NEXUS_DEVICE = LIFCL-40-8SG72C 
  FREQUENCY = 65
# physical constraints file
  PC_FILE = io.pdc
  OBJECT = $(PROJECT).bit
endif

# for Lattice ECP5 devices
ifeq ($(strip  $(DEVICE)), ecp5)
  # for colorlight-i9
  FPGA_TYPE = 45k
  FPGA_PACKAGE = CABGA381
# FREQUENCY of Colorlight-i9 
  FREQUENCY = 25 
  SPEED = 6
  
  # for colorlight-i5
  #FPGA_TYPE = 25k
  #FPGA_PACKAGE = CABGA381
  #FREQUENCY = 25
  #SPEED = 6
  
  # for 5a-75b-v7.0/i7 
  #FPGA_TYPE = 25k
  #FPGA_PACKAGE = CABGA256
  #FREQUENCY = 25
  #SPEED = 6
  
  PC_FILE = io.lpf
  OBJECT = $(PROJECT).bit
endif

# for Lattice iCE40 devices
ifeq ($(strip  $(DEVICE)), ice40)
# for icesugar-nano-lp1k
  #FPGA_TYPE = lp1k
  #FPGA_PACKAGE = cm36
# the default freq is 12Mhz and can be changed with 'icesprog'
  #FREQUENCY = 12
  
# for icesugar-up5k
  FPGA_TYPE = up5k
  FPGA_PACKAGE = sg48
# FREQUENCY of icesugar is 12Mhz and can not be changed.
  FREQUENCY = 12 
  
  PC_FILE = io.pcf
  OBJECT = $(PROJECT).rpt $(PROJECT).bin
endif
# for Gowin LittleBee devices
ifeq ($(strip  $(DEVICE)), gowin)
# tang nano
  #GOWIN_DEVICE = GW1N-LV1QN48C6/I5
  #GOWIN_PACK_DEVICE = GW1N-1
  #PC_FILE = tangnano.cst
# tang nano 1k
  #GOWIN_DEVICE = GW1NZ-LV1QN48C6/I5
  #GOWIN_PACK_DEVICE = GW1NZ-1
  #PC_FILE = tangnano1k.cst
# tang nano 4k
  #GOWIN_DEVICE = GW1NSR-LV4CQN48PC7/I6
  #GOWIN_PACK_DEVICE = GW1NS-4
  #PC_FILE = tangnano4k.cst
# tang nano 9k
  GOWIN_DEVICE = GW1NR-LV9QN88PC6/I5
  GOWIN_PACK_DEVICE = GW1N-9C
  PC_FILE = tangnano9k.cst

  OBJECT = $(PROJECT).fs
endif

all: $(OBJECT)

############################################
#              Synthesis                   #
############################################

top.json: $(SOURCES)
	yosys -ql ${PROJECT}-yosys.log -p "read_verilog $<; synth_$(strip  $(DEVICE)) -json $@" $(SOURCES)


############################################
#          place and route and pack        #
############################################

# for Lattice Nexus devices
ifeq ($(strip  $(DEVICE)), nexus)
top.fasm: top.json $(PC_FILE)
	nextpnr-$(DEVICE) -ql ${PROJECT}-nextpnr.log --device ${NEXUS_DEVICE} --json $< --pdc ${PC_FILE} --freq ${FREQUENCY} --fasm $@ 

$(PROJECT).bit: top.fasm
	prjoxide pack top.fasm $@
endif

# for Lattice ECP5 devices
ifeq ($(strip  $(DEVICE)), ecp5)
top.config: top.json $(PC_FILE)
	nextpnr-$(DEVICE) -ql ${PROJECT}-nextpnr.log --${FPGA_TYPE} --package ${FPGA_PACKAGE} --speed ${SPEED} --json $< --textcfg $@ --lpf ${PC_FILE} --freq ${FREQUENCY}

$(PROJECT).bit: top.config
	ecppack --bit $@ $<
endif

# for Lattice iCE40 devices
ifeq ($(strip  $(DEVICE)), ice40)
top.asc: top.json $(PC_FILE)
	nextpnr-$(DEVICE) -ql ${PROJECT}-nextpnr.log --${FPGA_TYPE} --package ${FPGA_PACKAGE} --json top.json --pcf ${PC_FILE} --asc $@ --freq ${FREQUENCY}

$(PROJECT).rpt: top.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

$(PROJECT).bin: top.asc
	icepack top.asc $@
endif

# for Gowin LittleBee devices
ifeq ($(strip  $(DEVICE)), gowin)
pnrtop.json: top.json $(PC_FILE)
	nextpnr-$(DEVICE) -ql ${PROJECT}-nextpnr.log \
		--json top.json \
		--write pnrtop.json \
		--device ${GOWIN_DEVICE} \
		--cst ${PC_FILE}

$(PROJECT).fs: pnrtop.json
	gowin_pack -d ${GOWIN_PACK_DEVICE} -o ${PROJECT}.fs pnrtop.json
endif

############################################
#                 prog                     #
############################################
# depend on your board design: 

# for Lattice ECP5 devices
ifeq ($(strip  $(DEVICE)), ecp5)
# flash to ram using openocd
# sudo openocd -f ./cmsisdap.cfg -c "init;scan_chain;exit;"  #probe
# sudo openocd -f ./cmsisdap.cfg -c "init;scan_chain;svf -tap ecp5.tap -quiet -progress ${PROJECT}.svf;exit;" # flash to sram
# erase flash
# ecpdap probes && ecpdap scan && ecpdap flash scan && ecpdap flash unprotect && ecpdap flash erase
prog: all
	# program to sram
	ecpdap probes && ecpdap scan && ecpdap program --freq 5000 ${PROJECT}.bit
progflash: all
  # program to flash
	ecpdap probes && ecpdap scan && ecpdap flash scan && ecpdap flash unprotect && ecpdap flash --freq 5000 write ${PROJECT}.bit && ecpdap flash protect
endif

# for Lattice iCE40 devices
# for icesugar, use 'icesprog'
# for jtag, use 'iceprog'
ifeq ($(strip  $(DEVICE)), ice40)
prog: all
	icesprog ${PROJECT}.bin	
endif

# for Gowin LittleBee devices
ifeq ($(strip  $(DEVICE)), gowin)
prog: all
	openFPGALoader -b tangnano9k ${PROJECT}.fs
endif

############################################
#                 clean                    #
############################################

clean:
	rm -f top.json pnrtop.json top.asc top.fasm top.config
	rm -f ${PROJECT}-yosys.log ${PROJECT}-nextpnr.log 
	rm -f ${PROJECT}.fs ${PROJECT}.bin ${PROJECT}.bit ${PROJECT}.svf ${PROJECT}.rpt
