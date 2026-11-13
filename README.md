# AXI3 VIP Verification using SystemVerilog and UVM

## 📌 Project Overview

This project focuses on developing a reusable and scalable **AXI3 Verification IP (VIP)** using SystemVerilog and UVM. The verification environment is designed to verify the functionality of the AXI3 protocol, including read and write transactions, burst transfers, handshaking mechanisms, and outstanding transactions.

The project aims to validate protocol behavior through constrained-random testing, directed testing, assertions, and functional coverage.

## 🛠️ Tools and Technologies

- **Verification Language:** SystemVerilog
- **Verification Methodology:** UVM
- **Simulator:** Siemens QuestaSim , VCS 
- **Lint Tool:** VC SpyGlass
- **Concepts:** OOP, Constrained Randomization, Assertions, Functional Coverage

## 🏗️ UVM Testbench Architecture

The AXI3 VIP follows a layered UVM architecture consisting of the following components:

1. **Sequence Item:** Defines AXI3 transaction fields.
2. **Sequence:** Generates directed and constrained-random transactions.
3. **Sequencer:** Controls the flow of transactions.
4. **Driver:** Drives AXI3 signals to the DUT.
5. **Monitor:** Observes AXI3 interface signals and collects transactions.
6. **Agent:** Encapsulates the driver, sequencer, and monitor.
7. **Scoreboard:** Compares expected and actual transactions.
8. **Reference Model:** Predicts expected behavior.
9. **Environment:** Integrates the agent, scoreboard, and reference model.
10. **Test:** Configures and executes different verification scenarios.

## 🔄 AXI3 Protocol Features Verified

- Read and Write Channel Verification
- VALID and READY Handshake Mechanism
- FIXED Burst Transactions
- INCR Burst Transactions
- WRAP Burst Transactions
- Unaligned Transfers
- Outstanding Transactions
- Address and Data Channel Verification
- Burst Length and Burst Size Verification
- Semaphore-Based Synchronization for channel control

## 🧪 Verification Methodology

The following verification techniques are used:

- Directed Testing
- Constrained-Random Testing
- Functional Coverage
- SystemVerilog Assertions (SVA)
- Self-Checking Testbench
- Scoreboard-Based Data Comparison
- Simulation and Debugging

## 📊 Functional Coverage

Functional coverage is implemented to measure the verification completeness of different AXI3 protocol scenarios.

**Achieved Functional Coverage: 100%**

Coverage is collected for important protocol features, including:
- Burst types (FIXED, INCR, WRAP)
- Burst lengths
- Transfer sizes
- Read and write transactions
- VALID/READY handshake scenarios
- Outstanding transactions
