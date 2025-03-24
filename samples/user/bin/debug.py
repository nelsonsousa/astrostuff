#!/usr/bin/env python3
import os
import pty
import time
from datetime import datetime
import threading
import serial
import argparse
import re
import sys
from colorama import Fore, Style, init

# Initialize colorama for coloured terminal output
init()

# Create a lock for thread-safe logging to file
log_lock = threading.Lock()

def forward_virtual_to_real(master_fd, ser_real, logfile):
    """Forward data from the virtual port (Ekos) to the real port (mount)."""
    while True:
        data = os.read(master_fd, 1024)
        if data:
            text = data.decode(errors='replace')
            # Prepend direction indicator and print in blue
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            output = "\n" + now + "\t > \t" + text + "\t< \t"
            print(Fore.BLUE + output + Style.RESET_ALL, end='')
            ser_real.write(data)
            with log_lock:
                logfile.write(output)
                logfile.flush()

def forward_real_to_virtual(master_fd, ser_real, logfile):
    """Forward data from the real port (mount) to the virtual port (Ekos)."""
    while True:
        data = ser_real.readline()
        if data:
            text = data.decode(errors='replace')
            # Prepend direction indicator and print in green
            output = text
            print(Fore.GREEN + output + Style.RESET_ALL, end='')
            os.write(master_fd, data)
            with log_lock:
                logfile.write(output)
                logfile.flush()

def manual_input_loop(ser_real, logfile):
    """Read manual commands from the keyboard and send them to the mount."""
    while True:
        try:
            # Read a line from the terminal (this will block until you hit Enter)
            command = input()
            if command.strip() == "":
                continue
            # Optionally, add a newline if required by your mount's protocol
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            output = "\n" + now + "\t > \t" + command + "\t< \t"
            print(Fore.RED + output + Style.RESET_ALL, end='')
            ser_real.write(command.encode())
            with log_lock:
                logfile.write(output)
                logfile.flush()
        except Exception as e:
            print("Error reading input:", e)

def main():
    parser = argparse.ArgumentParser(
        description="Serial port sniffer for Ekos and mount using a virtual port."
    )
    parser.add_argument("port", help="Real serial port symlink (e.g., /dev/serial/by-id/usb-DEVICE_NAME-if00-port0)")
    parser.add_argument("--baudrate", type=int, default=9600, help="Baudrate (default 9600)")
    args = parser.parse_args()

    # Open the real serial port with the specified baudrate
    ser_real = serial.Serial(args.port, baudrate=args.baudrate, timeout=0.1)

    # Create a pseudo-terminal pair. The slave side is the virtual port for Ekos.
    master_fd, slave_fd = pty.openpty()
    slave_name = os.ttyname(slave_fd)
    print("Configure Ekos to use this virtual port:", slave_name)

    # Extract DEVICE_NAME from the symlink basename
    basename = os.path.basename(args.port)
    match = re.match(r'usb-(.*)-if00-port0', basename)
    if match:
        device_name = match.group(1)
    else:
        device_name = basename  # fallback if pattern doesn't match

    log_dir = os.path.expanduser("~/Logs")
    os.makedirs(log_dir, exist_ok=True)
    ts = datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
    log_filename = os.path.join(log_dir, f"{device_name}_{ts}.log")
    print("Logging communication to file:", log_filename)
    logfile = open(log_filename, "a")
    logfile.write(f"Logging started for {device_name}\n")
    logfile.flush()
    # Start threads to forward data in both directions
    threading.Thread(target=forward_virtual_to_real, args=(master_fd, ser_real, logfile), daemon=True).start()
    threading.Thread(target=forward_real_to_virtual, args=(master_fd, ser_real, logfile), daemon=True).start()

    # Start a thread to allow manual input.
    threading.Thread(target=manual_input_loop, args=(ser_real, logfile), daemon=True).start()

    # Keep the main thread alive.
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nExiting...")
        logfile.write(f"Logging ended.\n")
        logfile.flush()
    finally:
        logfile.close()
        ser_real.close()

if __name__ == "__main__":
    main()
