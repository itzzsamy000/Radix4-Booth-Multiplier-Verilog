# Radix-4 Booth Multiplier

This Vivado project contains two implementations of a signed 8-bit by signed 8-bit Radix-4 Booth multiplier. Both produce a signed 16-bit product. The included testbenches compare each implementation against Verilog multiplication for every possible operand pair.

## Implementations

- `booth8_baseline` recodes the multiplier into four Radix-4 partial products and adds them with a conventional sum expression.
- `booth8_optimized` uses the same recoding, then compresses the partial products with a carry-save adder tree before one final carry-propagate addition.

Both modules use signed two's-complement inputs in the range -128 through 127.

## Project Contents

- `Radix 4 Booth_multi.xpr`: Vivado project.
- `Radix 4 Booth_multi.srcs/sources_1/new/`: baseline and optimized Verilog modules.
- `Radix 4 Booth_multi.srcs/sim_1/new/`: exhaustive testbenches for both modules.
- `Radix 4 Booth_multi.srcs/sources_1/bd/booth8_hardware/`: block design, IP configuration, and UI metadata. The design includes the optimized multiplier module reference, a Zynq UltraScale+ processing system, and VIO.
- `Radix 4 Booth_multi.srcs/constrs_1/new/multiplier_timing.xdc`: virtual-clock timing constraints for the multiplier inputs and output.
- `booth8_hardware_wrapper.xsa`: exported hardware platform.

The project targets the AMD/Xilinx ZCU104 board and the `xczu7ev-ffvc1156-2-e` device. It was created with Vivado 2026.1; open the `.xpr` file in Vivado and allow Vivado to regenerate any generated IP products as needed.

## Run the Exhaustive Tests

With Icarus Verilog installed, run these commands from PowerShell at the repository root. The test executables are written to the system temporary directory.

Baseline:

```powershell
iverilog -g2012 -s tb_booth8_baseline -o "$env:TEMP/booth8_baseline.vvp" "Radix 4 Booth_multi.srcs/sources_1/new/booth8_baseline.v" "Radix 4 Booth_multi.srcs/sim_1/new/tb_booth8_baseline.v"
vvp "$env:TEMP/booth8_baseline.vvp"
```

Optimized:

```powershell
iverilog -g2012 -s tb_booth8_optimized -o "$env:TEMP/booth8_optimized.vvp" "Radix 4 Booth_multi.srcs/sources_1/new/booth8_optimized.v" "Radix 4 Booth_multi.srcs/sim_1/new/tb_booth8_optimized.v"
vvp "$env:TEMP/booth8_optimized.vvp"
```

Each test checks all 65,536 combinations of signed 8-bit operands. A successful run prints `PASS: All 65,536 signed input combinations matched.`
