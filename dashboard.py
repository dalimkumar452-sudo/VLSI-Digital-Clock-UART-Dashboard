import serial
import threading
import tkinter as tk
from tkinter import font
import time  # <-- Notun add kora hoyeche timer er jonno

# --- Configuration (Change 'COM3' to your FPGA's actual COM Port) ---
SERIAL_PORT = 'COM3' 
BAUD_RATE = 115200

# --- Setup Main Dashboard Window ---
root = tk.Tk()
root.title("VLSI Advanced Clock Dashboard")
root.geometry("600x300")
root.configure(bg='#0F172A') # Dark slate modern background

# Custom Font setup
digital_font = font.Font(family="Courier New", size=80, weight="bold")

# Time Display Label
time_label = tk.Label(root, text="--:--:--", font=digital_font, fg="#06B6D4", bg='#0F172A')
time_label.pack(expand=True)

# Status Label
status_label = tk.Label(root, text="Initializing...", fg="#94A3B8", bg='#0F172A', font=("Arial", 12))
status_label.pack(side="bottom", pady=10)

# --- Serial Reading Function (Runs in Background with Auto-Reconnect) ---
def read_from_fpga():
    while True:
        try:
            # 1. TAR LAGANO THAKLE (Hardware Connected)
            ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
            status_label.config(text=f"Connected to VLSI Clock on {SERIAL_PORT} \u25CF", fg="#22C55E") # Green text
            time_label.config(fg="#06B6D4") # Normal cyan color for time
            
            # Continuously read data while connected
            while True:
                if ser.in_waiting > 0:
                    data = ser.readline().decode('utf-8').strip()
                    
                    if len(data) == 8 and ":" in data:
                        time_label.config(text=data)
                        
        except (serial.SerialException, OSError):
            # 2. TAR KETE GELE BA KHULE FELLE (Hardware Disconnected)
            status_label.config(text="HARDWARE DISCONNECTED. Auto-reconnecting...", fg="#EF4444") # Red text
            time_label.config(fg="#EF4444") # Time turns red
            
            # Wait for 2 seconds before trying to reconnect again
            time.sleep(2)

# --- Start Background Thread ---
thread = threading.Thread(target=read_from_fpga, daemon=True)
thread.start()

# --- Run Application ---
root.mainloop()