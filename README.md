# Radix-4 Booth Multiplier — FPGA Implementation on ZCU104

<div align="center">

![Verilog](https://img.shields.io/badge/Language-Verilog-blue?style=for-the-badge)
![Vivado](https://img.shields.io/badge/Tool-Vivado%202026.1-orange?style=for-the-badge)
![Board](https://img.shields.io/badge/Board-ZCU104%20xczu7ev-green?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-65%2C536%20PASS-brightgreen?style=for-the-badge)

**A fully-verified, hardware-implemented signed 8×8-bit Radix-4 Booth Multiplier with CSA optimization, deployed on the Xilinx ZCU104 UltraScale+ FPGA.**

</div>

---

## Table of Contents

- [Overview](#overview)
- [Architecture & Flow Diagram](#architecture--flow-diagram)
- [Features](#features)
- [Project Structure](#project-structure)
- [Implementations](#implementations)
- [Hardware Platform](#hardware-platform)
- [Implementation Results](#implementation-results)
- [Getting Started](#getting-started)
- [Screenshots](#screenshots)
- [Technologies Used](#technologies-used)

---

## Overview

This Vivado project implements and compares **two signed 8×8-bit Radix-4 Booth Multipliers** targeting the AMD/Xilinx **ZCU104** evaluation board (`xczu7ev-ffvc1156-2-e`). Both modules:

- Accept two **signed 8-bit** two's-complement operands (`−128` to `+127`)
- Produce a **signed 16-bit** two's-complement product
- Use **Radix-4 Booth recoding** to reduce partial products from 8 down to 4

The exhaustive testbenches verify all **65,536** unique signed 8-bit operand pairs against Verilog's native `*` operator.

---

## Architecture & Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│              Radix-4 Booth Multiplier — Data Flow             │
└──────────────────────────────────────────────────────────────┘

  Inputs
  ┌──────┐    ┌──────┐
  │  a   │    │  b   │          8-bit signed operands
  │[7:0] │    │[7:0] │
  └──┬───┘    └──┬───┘
     │           │
     │     ┌─────▼─────────────────────────────┐
     │     │   Booth Bit Extension              │
     │     │  booth_bits = {b, 1'b0}  [8:0]    │
     │     └─────┬─────────────────────────────┘
     │           │
     │    ┌──────▼────────────────────────────────────────┐
     │    │        Radix-4 Booth Recoding                  │
     │    │  Overlapping 3-bit windows of booth_bits:      │
     │    │  [2:0], [4:2], [6:4], [8:6] → 4 Booth codes   │
     │    └──────┬────────────────────────────────────────┘
     │           │
     └─────┬─────┘
           │
    ┌──────▼────────────────────────────────────────────────┐
    │          Partial Product Generation  (×4)              │
    │                                                        │
    │  code → 0 / +a / +2a / −a / −2a  (sign-ext 16-bit)   │
    │                                                        │
    │   pp0 = booth_pp(a, [2:0])            weight  2^0     │
    │   pp1 = booth_pp(a, [4:2]) <<< 2      weight  2^2     │
    │   pp2 = booth_pp(a, [6:4]) <<< 4      weight  2^4     │
    │   pp3 = booth_pp(a, [8:6]) <<< 6      weight  2^6     │
    └──────┬────────────────────────────────────────────────┘
           │
     ┌─────┴────────────────────────────────────────────────┐
     │       BASELINE path          OPTIMIZED path           │
     │                                                       │
     │  pp0+pp1+pp2+pp3         CSA Stage 1  (3→2):         │
     │  (3 carry-propagate      sum1  = pp0^pp1^pp2          │
     │   additions)             carry1= maj(pp0,pp1,pp2)<<1  │
     │                                                       │
     │                          CSA Stage 2  (3→2):          │
     │                          sum2  = sum1^carry1^pp3       │
     │                          carry2= maj(s1,c1,pp3)<<1    │
     │                                                       │
     │                          Final CPA (single adder):    │
     │                          product = sum2 + carry2      │
     └──────────────────────────┬────────────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │   product [15:0]      │
                    │  Signed 16-bit result │
                    └──────────────────────┘
```

### Radix-4 Booth Encoding Table

| Code `[i+1 : i-1]` | Partial Product |
|:-------------------:|:---------------:|
| `000` / `111`       | `0`             |
| `001` / `010`       | `+a`            |
| `011`               | `+2a`           |
| `100`               | `−2a`           |
| `101` / `110`       | `−a`            |

---

## Features

- ✅ **Signed 8×8 multiplication** — full two's-complement range (−128 to +127)
- ✅ **Radix-4 Booth recoding** — only 4 partial products instead of 8
- ✅ **Two design variants** — Baseline vs CSA-optimized for direct comparison
- ✅ **Carry-Save Adder (CSA) tree** — reduces critical path to a single CPA
- ✅ **Exhaustive verification** — all 65,536 input combinations pass simulation
- ✅ **Block Design integration** — VIO + Zynq UltraScale+ PS for live hardware testing
- ✅ **Timing constraints met** — WNS = 8.064 ns, all user constraints satisfied
- ✅ **Hardware export** — `.xsa` platform ready for Vitis / PetaLinux

---

## Project Structure

```
Radix 4 Booth_multi/
├── Radix 4 Booth_multi.xpr               # Vivado project file
├── booth8_hardware_wrapper.xsa           # Exported hardware platform (.xsa)
├── .gitignore                            # Vivado-specific ignores
├── README.md                             # This file
│
├── Radix 4 Booth_multi.srcs/
│   ├── sources_1/
│   │   ├── new/
│   │   │   ├── booth8_baseline.v         # Baseline Booth multiplier (RTL)
│   │   │   └── booth8_optimized.v        # CSA-optimized Booth multiplier (RTL)
│   │   └── bd/booth8_hardware/
│   │       ├── booth8_hardware.bd        # Block design (Zynq + VIO + multiplier)
│   │       ├── booth8_hardware.bda       # Block design archive
│   │       ├── ip/                       # IP configuration files
│   │       └── ui/                       # UI metadata
│   ├── sim_1/new/
│   │   ├── tb_booth8_baseline.v          # Exhaustive testbench — baseline
│   │   └── tb_booth8_optimized.v         # Exhaustive testbench — optimized
│   ├── constrs_1/new/
│   │   └── multiplier_timing.xdc         # Virtual-clock timing constraints
│   └── utils_1/imports/synth_1/
│       └── booth8_baseline.dcp           # Synthesized design checkpoint
│
└── Screenshot/
    ├── Screenshot 2026-10-17 145554.png  # Block design diagram
    ├── Screenshot 2026-10-17 145203.png  # Device floorplan view
    ├── Screenshot 2026-10-17 145226.png  # Timing summary
    └── Screenshot 2026-10-17 145215.png  # Power analysis report
```

---

## Implementations

### 1. Baseline Implementation

**File:** `Radix 4 Booth_multi.srcs/sources_1/new/booth8_baseline.v`

Performs Radix-4 Booth recoding and sums all four partial products using **three conventional carry-propagate additions** in a single `assign` expression.

```verilog
module booth8_baseline (
    input  signed [7:0]  a,
    input  signed [7:0]  b,
    output signed [15:0] product
);
    // ... Booth recoding + 4 partial products ...
    assign product = pp0 + pp1 + pp2 + pp3;
endmodule
```

### 2. Optimized CSA Implementation

**File:** `Radix 4 Booth_multi.srcs/sources_1/new/booth8_optimized.v`

Compresses four partial products through **two CSA stages**, leaving only a single final carry-propagate adder — minimising the critical path.

```verilog
module booth8_optimized (
    input  signed [7:0]  a,
    input  signed [7:0]  b,
    output signed [15:0] product
);
    // CSA Stage 1: 3 partial products → 2 vectors
    wire [15:0] sum1   = pp0 ^ pp1 ^ pp2;
    wire [15:0] carry1 = ((pp0 & pp1) | (pp0 & pp2) | (pp1 & pp2)) << 1;

    // CSA Stage 2: 3 vectors → 2 vectors
    wire [15:0] sum2   = sum1 ^ carry1 ^ pp3;
    wire [15:0] carry2 = ((sum1 & carry1) | (sum1 & pp3) | (carry1 & pp3)) << 1;

    // Single final carry-propagating addition
    assign product = sum2 + carry2;
endmodule
```

---

## Hardware Platform

The Vivado Block Design (`booth8_hardware.bd`) integrates:

| IP Block | Version | Role |
|----------|---------|------|
| `booth8_optimized` | v1.0 | RTL multiplier under test |
| `vio_0` (Virtual I/O) | 3.0 | Live input/output probing via JTAG |
| `zynq_ultra_ps_e_0` | 3.5 | Zynq UltraScale+ Processing System |

The VIO exposes `probe_in0[15:0]` (product) and `probe_out0/1[7:0]` (operands) for **real-time hardware verification** without custom software.

**Target:** AMD/Xilinx ZCU104 — `xczu7ev-ffvc1156-2-e`
**Tool:** Vivado 2026.1

---

## Implementation Results

### ✅ Timing Summary

| Metric | Value |
|--------|-------|
| Worst Negative Slack (WNS) | **8.064 ns** ✅ |
| Total Negative Slack (TNS) | 0.000 ns |
| Worst Hold Slack (WHS) | 0.007 ns |
| Failing Endpoints (Setup) | **0** |
| Failing Endpoints (Hold) | **0** |
| Total Endpoints | 2,202 |

> **All user-specified timing constraints are met.**

### ⚡ Power Analysis

| Category | Power |
|----------|-------|
| Total On-Chip Power | 3.378 W |
| Dynamic Power | 2.687 W (80%) |
| Static Power | 0.692 W (20%) |
| Junction Temperature | 28.3°C |
| Thermal Margin | 71.7°C |

---

## Getting Started

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Vivado](https://www.xilinx.com/support/download.html) | 2026.1 | Open, simulate, implement |
| [Icarus Verilog](http://iverilog.icarus.com/) | Any | Command-line simulation |
| ZCU104 Board | — | Hardware deployment |

### Open in Vivado

1. Clone this repository:
   ```powershell
   git clone https://github.com/itzzsamy000/radix4-booth-multiplier.git
   cd radix4-booth-multiplier
   ```

2. Open **Vivado 2026.1** → **Open Project** → select `Radix 4 Booth_multi.xpr`.

3. Allow Vivado to **regenerate generated IP products** when prompted.

4. Open `booth8_hardware.bd` from the Sources panel to view the block design.

### Run Simulation (Icarus Verilog)

**Baseline** — verifies all 65,536 combinations:

```powershell
iverilog -g2012 -s tb_booth8_baseline `
  -o "$env:TEMP/booth8_baseline.vvp" `
  "Radix 4 Booth_multi.srcs/sources_1/new/booth8_baseline.v" `
  "Radix 4 Booth_multi.srcs/sim_1/new/tb_booth8_baseline.v"

vvp "$env:TEMP/booth8_baseline.vvp"
```

**Optimized** — verifies all 65,536 combinations:

```powershell
iverilog -g2012 -s tb_booth8_optimized `
  -o "$env:TEMP/booth8_optimized.vvp" `
  "Radix 4 Booth_multi.srcs/sources_1/new/booth8_optimized.v" `
  "Radix 4 Booth_multi.srcs/sim_1/new/tb_booth8_optimized.v"

vvp "$env:TEMP/booth8_optimized.vvp"
```

**Expected output:**
```
PASS: All 65,536 signed input combinations matched.
```

---

## Screenshots

> All screenshots captured in **Vivado 2026.1** after successful implementation on the ZCU104.

### 1 — Block Design Diagram

The IP Integrator view showing `booth8_optimized` connected to the VIO debug core and Zynq UltraScale+ Processing System.

![Block Design](Screenshot/Screenshot%202026-10-17%20145554.png)

---

### 2 — Device Floorplan

The implemented design placed and routed on the `xczu7ev-ffvc1156-2-e`. The multiplier logic is placed in tile region X3Y3.

![Device Floorplan](Screenshot/Screenshot%202026-10-17%20145203.png)

---

### 3 — Design Timing Summary

Post-implementation timing report confirming **all constraints are met** — WNS = 8.064 ns, 0 failing endpoints.

![Timing Summary](Screenshot/Screenshot%202026-10-17%20145226.png)

---

### 4 — Power Analysis Report

On-chip power analysis: **3.378 W** total, junction temperature **28.3°C**, thermal margin **71.7°C**.

![Power Analysis](Screenshot/Screenshot%202026-10-17%20145215.png)

---

## Technologies Used

| Technology | Details |
|------------|---------|
| **HDL** | Verilog (IEEE 1364-2005 / SystemVerilog-2012) |
| **EDA Tool** | AMD/Xilinx Vivado 2026.1 |
| **Simulation** | Icarus Verilog + `vvp` runtime |
| **Target Device** | Xilinx ZCU104 — `xczu7ev-ffvc1156-2-e` |
| **IP Blocks** | VIO 3.0, Zynq UltraScale+ MPSoC 3.5 |
| **Arithmetic** | Two's-complement signed arithmetic |
| **Algorithm** | Radix-4 Modified Booth Encoding + CSA tree |

---

<div align="center">

Made with ❤️ using Vivado & Verilog | Target: AMD ZCU104 UltraScale+

</div>
