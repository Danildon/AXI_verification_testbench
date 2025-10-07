This repository provides a SystemVerilog testbench for functional verification of AXI-based IP cores. It offers a scalable framework for verifying IP cores with AXI4, AXI4-Lite, and AXI4-Stream interfaces using dedicated VIP handlers.

Key Features

1. Parser-Based Stimulus Management

- Reads transaction stimuli from a configurable input file (Current_Stimuli.txt) via the Parser module.
- Supports flexible verification scenarios without modifying the testbench code.
- Automatically maps stimuli to AXI transactions for all interface types.

2. Automated Reporting

- Logs verification results through the report_producer module.
- Generates structured, timestamped reports for post-simulation analysis.
- Integrated with parser_pkg::ReportFile for standardized output.

3. AXI VIP Integration

- Utilizes Xilinx-style VIP components to model AXI4, AXI4-Lite, and AXI4-Stream master/slave behaviors.
- Provides protocol-compliant driving, monitoring, and response checking.
- Clock & Reset control:
  - Start VIP clocks using start_clock().
  - Assert and deassert resets using assert_reset() and deassert_reset().

4. Modular Handler Objects

- Dedicated handlers for each AXI interface:
- Axi4lite_handler → AXI4-Lite transactions
- Axi4stream_handler → AXI4-Stream sequences
- Axi4Full_handler → Full AXI4 transactions
- Handlers are initialized and started automatically.
- Each handler manages transaction generation, signal driving, and response monitoring.

5. Clock and Reset Sequencing

- VIP clocks are started at simulation initialization.
- Reset sequences ensure all VIPs and DUT submodules start in a known state.
- Easily adaptable to multiple clock domains.

6. Memory & Peripheral Mapping

- Defined in the tb_pkg package with base addresses for peripherals and memory regions.
- Supports realistic address spaces for:
  - DDR, RAM, BRAM
  - APB modules, FIFO blocks, DMA channels
  - Interlaken, PHY interfaces, NoC MACs
  - Enables realistic verification of memory-mapped AXI transactions.

7. Scalable & Extensible Architecture

- Modular handlers and VIPs allow integration of additional AXI interfaces or custom peripherals without modifying the top-level testbench.
- Parser and report modules are generic, supporting future extensions to new transaction types.

8. Simulation Utilities

- Configures simulation time format using:
- $timeformat(-9, 3, " ns", 13);

This testbench provides a robust, flexible, and modular framework for verifying complex AXI-based IP cores with file-driven stimulus, automated reporting, and protocol-compliant VIP integration.
