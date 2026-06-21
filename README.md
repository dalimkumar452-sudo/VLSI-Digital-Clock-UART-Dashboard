🕒 VLSI Advanced Digital Clock with UART & Python Dashboard

![Verilog](https://img.shields.io/badge/Language-Verilog_IEEE_1364--2001-blue.svg)
![Python](https://img.shields.io/badge/Language-Python_3.x-yellow.svg)
![Simulation](https://img.shields.io/badge/Simulation-Icarus_Verilog-brightgreen.svg)
![Status](https://img.shields.io/badge/Status-Completed-success.svg)

## 📌 Project Overview

This project presents a complete hardware-software co-design of an advanced digital clock system. Designed at the Register-Transfer Level (RTL) using **Verilog**, the hardware maintains accurate timekeeping, manages an alarm Finite State Machine (FSM), and handles mechanical button debouncing. 

To bridge the gap between pure hardware and modern user interfaces, a custom **UART Transmitter** was implemented on the FPGA to stream real-time data to a PC. A robust, multi-threaded **Python GUI Dashboard** receives this data, providing a dynamic, auto-reconnecting visual interface.

## ✨ Key Features

### 💻 Hardware Features (FPGA / RTL)
* **Accurate Timekeeping:** Cascaded Modulo-60 (Seconds/Minutes) and Modulo-24 (Hours) counters.
* **Synchronous Clock Dividers:** Derives 1Hz (time) and 1kHz (multiplexing/debouncing) enables from a 50MHz system clock to prevent clock skew.
* **Hardware Debouncing:** Shift-register-based debouncers to ensure clean, single-cycle pulses from noisy mechanical switches.
* **Alarm FSM:** Continuous time comparator with an integrated Snooze function (+5 minutes logic).
* **7-Segment Multiplexing:** Time-multiplexed controller driving 4-digit displays at 1kHz.
* **Custom UART TX:** 115200 Baud, 8-N-1 protocol transmitter to serialize and send time data (`HH:MM:SS\n`).

### 🖥️ Software Features (Python Dashboard)
* **Multi-threaded Architecture:** Background daemon thread handles serial reading (`pyserial`) without freezing the Tkinter main loop.
* **Hot-Plugging / Auto-Reconnect:** The dashboard automatically detects hardware disconnections, displays a warning, and seamlessly reconnects when the hardware is plugged back in.
* **Modern UI:** Dark-themed, dynamic user interface built with `Tkinter`.

## 🛠️ Tech Stack & Tools
* **Hardware Description:** Verilog (RTL)
* **Simulation & Verification:** Icarus Verilog, GTKWave, EDA Playground
* **Software Dashboard:** Python 3, Tkinter, PySerial
* **Target Architecture:** Parameterized for standard FPGA boards (e.g., Xilinx Artix-7, Altera Cyclone IV)

## 🗂️ Repository Structure

```text
VLSI-Digital-Clock-Alarm/
│
├── rtl/
│   └── digital_clock_top.v      # Top-level Verilog module (Clock, FSM, UART)
├── tb/
│   └── tb_digital_clock.v       # Self-checking testbench for RTL simulation
├── software/
│   ├── dashboard.py             # Python UART receiver & GUI
│   └── requirements.txt         # Python dependencies
├── screenshots/                 # Simulation waveforms and UI screenshots
├── .gitignore
└── README.md
🚀 Getting Started
1. Hardware RTL Simulation (No Board Required)
You can simulate the hardware logic using EDA Playground or your local simulator (ModelSim/Vivado).

Copy the contents of rtl/digital_clock_top.v and tb/tb_digital_clock.v.

Use Icarus Verilog and enable EPWave (or VCD dumping).

Run the simulation to observe the time counting, switch debouncing, and UART bit-banging waveforms.

2. Running the Python Dashboard
Ensure you have Python installed on your system.

Navigate to the software/ directory.

Install the required dependency:

Bash
pip install -r requirements.txt
(Optional) If you have the FPGA programmed and connected, update the SERIAL_PORT variable in dashboard.py (e.g., 'COM3' for Windows or '/dev/ttyUSB0' for Linux).

Run the application:

Bash
python dashboard.py
📸 Screenshots
RTL Simulation (Waveform Verification)
(Insert EPWave / GTKWave Screenshot Here)

Demonstrating the 1Hz clock enable, alarm comparator asserting the buzzer, and UART TX line state changes.

Software GUI Dashboard
(Insert Python Dashboard Screenshot Here)

The real-time Tkinter interface displaying data received from the Verilog hardware over serial.

🎓 Learning Outcomes
This project acts as a bridge between pure ASIC/FPGA digital logic and Embedded Systems. It demonstrates a practical understanding of synchronous design principles, handling asynchronous inputs (debouncing), state machine design, and hardware-to-PC communication protocols.

Designed & Developed for VLSI Portfolio Showcasing.