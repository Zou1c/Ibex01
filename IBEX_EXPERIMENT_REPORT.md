# Ibex RISC-V SoC on AX7015B (Zynq XC7Z015) — Experiment Summary

## 1. Experiment Overview

This experiment implements a minimal RISC-V SoC on the ALINX AX7015B development board (Xilinx Zynq-7000 XC7Z015-2CLG485I) using the lowRISC Ibex CPU core. The SoC runs a bare-metal LED running-light firmware entirely from FPGA programmable logic (PL), demonstrating a working RISC-V processor fetching instructions from BRAM, decoding addresses through a custom bus, and driving GPIO output.

### Hardware Platform

| Item | Detail |
|------|--------|
| Board | ALINX AX7015B |
| SoC Chip | XC7Z015-2CLG485I (Zynq-7000) |
| PL Resources | 74K Logic Cells, 46200 LUTs, 3.3Mb BRAM, 160 DSP |
| PS (unused for logic) | Dual ARM Cortex-A9 @ 766MHz |
| DDR3 | 1GB (2x H5TQ4G63AFR-PBI) |
| PL Clock | 50MHz on-board oscillator (Pin Y14, BANK13) |
| LEDs Used | 4x PL LEDs on baseboard (BANK35, active-low) |

### SoC Architecture

```
                    ┌──────────────────────────────────────┐
  PL 50MHz ──────►  │           ibex_soc_top               │
  Oscillator (Y14)  │                                      │
                    │  ┌───────────┐                       │
                    │  │ Ibex CPU  │  RV32IMC, 50MHz       │
                    │  │           │                       │
                    │  └──┬────┬──┘                       │
                    │ instr│  data│                        │
                    │     │     │                          │
                    │     ▼     ▼                          │
                    │  ┌──────┐ ┌─────────┐               │
                    │  │ BRAM │ │ soc_bus │               │
                    │  │ 16KB │ │ decoder │               │
                    │  └──────┘ └────┬────┘               │
                    │                │                     │
                    │           ┌────▼─────┐              │
                    │           │   GPIO   │──► LED[3:0]  │
                    │           └──────────┘              │
                    │                                      │
                    │  ┌────────────────────┐              │
                    │  │ Zynq PS (idle)     │  DDR/MIO    │
                    │  │ pins connected but  │  not float  │
                    │  │ clock not used      │             │
                    │  └────────────────────┘              │
                    └──────────────────────────────────────┘
```

### Memory Map

| Address Range | Target | Description |
|---------------|--------|-------------|
| 0x0000_0000 ~ 0x0000_3FFF | BRAM 16KB | Instruction + Data (shared) |
| 0x1000_0000 | GPIO Output Register | Directly drives LED pins |
| 0x1000_0004 | GPIO Input Register | Reserved for buttons |

---

## 2. Complete Workflow

### Phase 1: Environment Setup

1. Install Vivado 2024.2 (Windows)
2. Clone Ibex repository: `git clone https://github.com/lowRISC/ibex.git`
3. Install RISC-V toolchain: xpack-riscv-none-elf-gcc v15.2.0
4. Add toolchain `bin/` directory to Windows system PATH
5. **Reopen CMD** after modifying PATH (changes don't apply to existing terminals)

### Phase 2: Compile Firmware

```bat
cd firmware
riscv-none-elf-as -march=rv32imc_zicsr -mabi=ilp32 -o blink.o blink.S
riscv-none-elf-ld -T link.ld -o blink.elf blink.o
riscv-none-elf-objcopy -O binary blink.elf blink.bin
python bin2hex.py blink.bin firmware.hex
```

The firmware (blink.S) implements a running-light pattern on 4 active-low LEDs:
- Reset vector at 0x00 jumps to 0x80
- Main code at 0x80: init stack, set mtvec, load GPIO address
- Main loop: write LED pattern to GPIO, delay ~0.5s, rotate pattern
- Total size: 224 bytes (56 x 32-bit words)

### Phase 3: Create Vivado Project

1. New RTL Project, target device: `xc7z015clg485-2`
2. Create Block Design `zynq_ps_bd` with Zynq PS IP
3. Configure Zynq PS:
   - Input clock: 33.333MHz
   - FCLK_CLK0: 50MHz
   - DDR3: MT41J256M16 RE-125, 32-bit, 533MHz
   - Bank 1 (BANK501): LVCMOS 1.8V
   - Peripherals: QSPI Flash + UART0 only
4. Make External: DDR, FIXED_IO, FCLK_CLK0, FCLK_RESET0_N
5. Validate → Generate Output Products → Create HDL Wrapper

### Phase 4: Add RTL Sources

Custom SoC files:
- `ibex_soc_top.sv` — Top-level module
- `bram_mem.sv` — Dual-port BRAM with firmware initialization
- `soc_bus.sv` — Address decoder (BRAM vs GPIO)
- `simple_gpio.sv` — GPIO peripheral for LED output

Ibex RTL files (from cloned repo):
- `ibex/rtl/` — All .sv files
- `ibex/vendor/lowrisc_ip/ip/prim/rtl/` — Primitive modules
- `ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/` — Generic primitives

### Phase 5: Add Constraints

Pin assignments (pins.xdc):
- PL clock: Y14 (50MHz oscillator, BANK13)
- LED[0]: A5, LED[1]: A7, LED[2]: A6, LED[3]: B8 (all LVCMOS33)

### Phase 6: Synthesize, Implement, Program

1. Run Synthesis
2. Run Implementation
3. Generate Bitstream
4. Open Hardware Manager → Program Device via JTAG

---

## 3. Problems Encountered and Solutions

### Problem 1: build.bat Chinese Encoding Error

**Symptom**: Running `build.bat` on Windows CMD produced garbled characters treated as commands.

**Cause**: Chinese comments in the .bat file were saved in UTF-8, but Windows CMD defaults to GBK encoding.

**Solution**: Rewrote build.bat using ASCII-only content (English comments).

**Lesson**: Always use English-only content in .bat files, or explicitly set `chcp 65001` at the beginning.

---

### Problem 2: RISC-V Toolchain Not Found

**Symptom**: `[ERROR] Cannot find riscv-none-elf-as`

**Cause**: Modified system PATH but used the same CMD window.

**Solution**: Close and reopen a new CMD window after modifying environment variables.

**Lesson**: Windows environment variable changes only take effect in newly opened processes.

---

### Problem 3: Unrecognized Opcode `csrw`

**Symptom**: `Error: unrecognized opcode 'csrw mtvec,t0', extension 'zicsr' required`

**Cause**: New versions of the RISC-V toolchain require explicit ISA extension declarations for CSR instructions.

**Solution**: Changed `-march=rv32imc` to `-march=rv32imc_zicsr`.

**Lesson**: The RISC-V ISA modularization means CSR instructions are no longer implicitly included in the base ISA for newer toolchains.

---

### Problem 4: Zynq PS Wrapper Port Name Mismatch

**Symptom**: `named port connection 'FCLK_CLK0' does not exist`

**Cause**: Vivado's "Make External" appends `_0` suffix to port names. The actual ports were `FCLK_CLK0_0` and `FCLK_RESET0_N_0`.

**Solution**: Opened the auto-generated `zynq_ps_bd_wrapper.v` to check exact port names, updated `ibex_soc_top.sv` accordingly.

**Lesson**: Always verify auto-generated wrapper port names — never assume they match the IP block's internal signal names.

---

### Problem 5: Ibex Version Parameter Mismatch

**Symptom**: `parameter 'BranchPrediction' does not exist` and `port 'ram_cfg_i' does not exist`

**Cause**: Different Ibex versions have different parameters and ports. The wrapper was written for an older version.

**Solution**: Removed `BranchPrediction` parameter and `ram_cfg_i` port connection from the instantiation.

**Lesson**: When using third-party IP, always check the actual module interface in your downloaded version. Don't rely on documentation for a different version.

---

### Problem 6: `$readmemh` Cannot Find firmware.hex

**Symptom**: `[Synth 8-4445] could not open $readmem data file 'firmware.hex'` (Critical Warning)

**Cause**: Vivado's synthesis working directory is NOT the project root — it can be in `AppData/Roaming/Xilinx/Vivado/` or `project.runs/synth_1/`.

**Solution**: Used absolute path in the RTL: `"E:/vivadoprojects/ibex_soc/firmware.hex"`

**Lesson**: Always use absolute paths (with forward slashes) for `$readmemh` file parameters in Vivado. Relative paths are unreliable because the working directory varies.

---

### Problem 7: UART Ports Missing Pin Constraints

**Symptom**: `DRC NSTD-1: Unspecified I/O Standard` and `DRC UCIO-1: Unconstrained Logical Port` for UART pins.

**Cause**: UART0 on Zynq goes through PS MIO pins (automatically routed), but the Block Design exported them as PL-side top-level ports that needed XDC constraints.

**Solution**: Removed UART from top-level ports. Tied `UART_0_0_rxd` to `1'b1` (idle) and left `UART_0_0_txd` unconnected inside the wrapper instantiation.

**Lesson**: On Zynq, PS peripherals (UART, ETH, USB, etc.) route through MIO pins automatically. They should NOT be exposed as PL top-level ports unless using EMIO.

---

### Problem 8: LEDs All ON, Not Blinking (The Big One!)

**Symptom**: All 4 LEDs constantly lit after programming. No blinking.

**Root Cause**: **JTAG-only programming does not initialize the Zynq PS.** The PS remains in reset state, so `FCLK_CLK0` never outputs a clock signal. Without a clock, no logic runs — the GPIO register stays at its reset value (0x00000000), and since LEDs are active-low, all 4 LEDs light up.

**Diagnosis Method**: Added a hardware heartbeat counter (pure combinational/sequential logic) to LED[3] that blinks at 1Hz independently of the CPU. When LED[3] didn't blink either, it confirmed the clock was dead.

**Solution**: Switched from PS `FCLK_CLK0` to the **PL-side 50MHz oscillator** (pin Y14, always running). Added a power-on-reset counter instead of relying on PS `FCLK_RESET0_N`.

**Lesson**: This is one of the most common Zynq pitfalls:
- JTAG programming only configures PL fabric
- PS must be separately initialized (via FSBL or Vitis) to enable FCLK outputs
- For PL-only designs, always use an external oscillator connected to PL pins
- The Zynq PS block must still be instantiated to prevent DDR/MIO pins from floating, but its clock/reset outputs cannot be trusted without PS initialization

---

## 4. Final File List

| File | Purpose |
|------|---------|
| `ibex_soc_top.sv` | Top-level SoC: PL clock, reset, Ibex + BRAM + bus + GPIO |
| `bram_mem.sv` | Dual-port BRAM, loaded via `$readmemh` with absolute path |
| `soc_bus.sv` | Address decoder: bit[28]=0 → BRAM, bit[28]=1 → GPIO |
| `simple_gpio.sv` | GPIO register: write = LED output, read = button input |
| `pins.xdc` | Pin constraints: PL clock (Y14), 4 LEDs (A5/A7/A6/B8) |
| `blink.S` | RISC-V assembly firmware: running light on active-low LEDs |
| `link.ld` | Linker script: 16KB RAM at 0x0, code entry at 0x80 |
| `build.bat` | Windows build script for firmware compilation |
| `bin2hex.py` | Binary to Verilog hex format converter |
| `zynq_ps_bd` | Vivado Block Design: Zynq PS (DDR3 + QSPI + UART0) |

---

## 5. Experiment Results

After programming the FPGA via JTAG:

- **LED[3] (PL_LED4, pin B8)**: Blinks at 1Hz — hardware heartbeat, confirms PL clock is running
- **LED[2:0] (PL_LED1~3, pins A5/A7/A6)**: Running light pattern, each LED lights up for ~0.5 seconds in sequence

This confirms:
1. The **Ibex RISC-V CPU** is running at 50MHz on the XC7Z015 FPGA
2. The CPU successfully **fetches instructions from BRAM** (56 words of firmware)
3. The **bus decoder** correctly routes data writes to the GPIO peripheral
4. The **GPIO register** drives the LED pins through proper IOSTANDARD (LVCMOS33)
5. The **active-low LED logic** in firmware produces the correct visual pattern

### Resource Utilization (approximate)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUT | ~4,000 | 46,200 | ~9% |
| FF | ~2,500 | 92,400 | ~3% |
| BRAM | ~8 | 95 | ~8% |
| DSP | 4 | 160 | 2.5% |

The Ibex core is very lightweight, leaving abundant resources for future expansion.

---

## 6. Key Takeaways

1. **Zynq ≠ pure FPGA**: The PS must be explicitly initialized for FCLK to work. PL-only designs should use external oscillators.

2. **Ibex is excellent for small FPGAs**: At ~4000 LUTs, it fits comfortably even on the smallest Zynq devices with room to spare.

3. **Version compatibility matters**: Always check the actual RTL interface of third-party IP against your instantiation. Parameters and ports change between versions.

4. **Vivado file paths are tricky**: Use absolute paths with forward slashes for `$readmemh`. The synthesis working directory is unpredictable.

5. **Incremental debugging saves time**: The heartbeat LED technique (testing clock independently of CPU) immediately isolated the root cause when all LEDs were stuck.

6. **Active-low LEDs need inverted logic**: On the AX7015B baseboard, GPIO=0 means LED ON. Firmware must account for this.

---

## 7. Suggested Next Steps

| Step | Description | Skills Gained |
|------|-------------|---------------|
| 1 | Write firmware in C with startup code | C runtime, cross-compilation |
| 2 | Add UART peripheral to SoC | Bus integration, serial protocol |
| 3 | Add Timer + interrupt controller | RISC-V interrupt/exception model |
| 4 | Initialize PS via Vitis, use FCLK | Zynq PS-PL co-design |
| 5 | ARM + RISC-V communication via AXI | Heterogeneous multi-core systems |
