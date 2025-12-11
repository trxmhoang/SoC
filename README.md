# Lab Folder Structure

This lab project is organized into three main subfolder:

```text
 lab/
 ├── rtl/   # RTL source code
 ├── sim/   # Simulation scripts
 └── tb/    # Testbench files
```

## 1. RTL Source Code

The `rtl` folder contains all the Verilog modules that implement the actual logic of the design in each Lab. These are files that the testbenches will reference and simulate.

## 2. Testbench Files

The `tb` folder stores all testbenches files used to verify the RTL design. Each testbench corresponds to a module in the `rtl` folder. These files typically include stimulus generation, monitors, checkers and waveform dump commands.

## 3. Simulation Scripts

The `sim` folder  contains scripts to run the testbenches. It contains `sim.do`, a DO script commonly used with simulation tools such as QuestaSim or ModelSim. The script typically:

- Compiles the RTL and testbench files
- Runs the simulation
- Opens the waveform viewer
- Adds signal to the wave window
  
Most tools allow running the script directly via a TCL-like interface or command console. For example, in QuestaSim/ModelSim, run this command:

``` bash
do sim.do
```
