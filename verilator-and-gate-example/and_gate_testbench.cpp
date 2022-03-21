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

