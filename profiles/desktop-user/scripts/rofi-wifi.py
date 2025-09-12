#!/usr/bin/env python3
"""
Rofi WiFi Manager
A script to manage WiFi connections through Rofi
"""

import subprocess
import sys
import json
import os
from typing import List, Dict, Optional


class WiFiManager:
    def __init__(self):
        self.known_networks = self.get_known_networks()

    def get_known_networks(self) -> List[str]:
        """Get list of known/saved WiFi networks"""
        try:
            result = subprocess.run(
                ["nmcli", "-t", "-f", "NAME", "connection", "show"],
                capture_output=True,
                text=True,
                check=True,
            )
            return [
                line.strip()
                for line in result.stdout.strip().split("\n")
                if line.strip()
            ]
        except subprocess.CalledProcessError:
            return []

    def scan_networks(self) -> List[Dict[str, str]]:
        """Scan for available WiFi networks"""
        try:
            # Rescan for networks
            subprocess.run(
                ["nmcli", "device", "wifi", "rescan"], capture_output=True, check=False
            )

            # Get available networks
            result = subprocess.run(
                [
                    "nmcli",
                    "-t",
                    "-f",
                    "SSID,SIGNAL,SECURITY,IN-USE",
                    "device",
                    "wifi",
                    "list",
                ],
                capture_output=True,
                text=True,
                check=True,
            )

            networks = []
            seen_ssids = set()

            for line in result.stdout.strip().split("\n"):
                if not line.strip():
                    continue

                parts = line.split(":")
                if len(parts) >= 4:
                    ssid = parts[0].strip()
                    signal = parts[1].strip()
                    security = parts[2].strip()
                    in_use = parts[3].strip()

                    # Skip hidden networks and duplicates
                    if not ssid or ssid in seen_ssids:
                        continue

                    seen_ssids.add(ssid)

                    # Determine security icon
                    if security:
                        sec_icon = "🔒"
                    else:
                        sec_icon = "🔓"

                    # Determine signal strength icon
                    try:
                        signal_int = int(signal)
                        if signal_int >= 75:
                            signal_icon = "📶"
                        elif signal_int >= 50:
                            signal_icon = "📶"
                        elif signal_int >= 25:
                            signal_icon = "📱"
                        else:
                            signal_icon = "📡"
                    except ValueError:
                        signal_icon = "📡"

                    # Check if currently connected
                    status_icon = "✅" if in_use == "*" else ""

                    # Check if it's a known network
                    known_icon = "💾" if ssid in self.known_networks else ""

                    networks.append(
                        {
                            "ssid": ssid,
                            "signal": signal,
                            "security": security,
                            "in_use": in_use == "*",
                            "display": f"{status_icon}{known_icon}{sec_icon}{signal_icon} {ssid} ({signal}%)",
                        }
                    )

            # Sort by signal strength (descending) and connection status
            networks.sort(
                key=lambda x: (
                    not x["in_use"],
                    -int(x["signal"]) if x["signal"].isdigit() else 0,
                )
            )
            return networks

        except subprocess.CalledProcessError as e:
            print(f"Error scanning networks: {e}", file=sys.stderr)
            return []

    def connect_to_network(self, ssid: str) -> bool:
        """Connect to a WiFi network"""
        try:
            # Check if it's a known network first
            if ssid in self.known_networks:
                result = subprocess.run(
                    ["nmcli", "connection", "up", ssid], capture_output=True, text=True
                )
                if result.returncode == 0:
                    self.notify(f"Connected to {ssid}")
                    return True

            # For unknown networks, try to connect (will prompt for password if needed)
            result = subprocess.run(
                ["nmcli", "device", "wifi", "connect", ssid],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                self.notify(f"Connected to {ssid}")
                return True
            else:
                # If connection failed, might need password
                self.prompt_password(ssid)
                return False

        except subprocess.CalledProcessError as e:
            self.notify(f"Failed to connect to {ssid}: {e}")
            return False

    def prompt_password(self, ssid: str):
        """Prompt for WiFi password using Rofi"""
        try:
            result = subprocess.run(
                [
                    "rofi",
                    "-dmenu",
                    "-p",
                    f"Password for {ssid}",
                    "-password",
                    "-theme-str",
                    'inputbar { children: [ "prompt", "entry" ]; } element alternate { background-color: transparent; }',
                ],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0 and result.stdout.strip():
                password = result.stdout.strip()
                connect_result = subprocess.run(
                    ["nmcli", "device", "wifi", "connect", ssid, "password", password],
                    capture_output=True,
                    text=True,
                )

                if connect_result.returncode == 0:
                    self.notify(f"Connected to {ssid}")
                else:
                    self.notify(f"Failed to connect to {ssid}")

        except subprocess.CalledProcessError as e:
            self.notify(f"Error connecting to {ssid}: {e}")

    def disconnect_current(self) -> bool:
        """Disconnect from current WiFi network"""
        try:
            # Get current connection
            result = subprocess.run(
                ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"],
                capture_output=True,
                text=True,
                check=True,
            )

            active_connections = result.stdout.strip().split("\n")
            wifi_connections = [
                conn for conn in active_connections if conn in self.known_networks
            ]

            if wifi_connections:
                for conn in wifi_connections:
                    subprocess.run(
                        ["nmcli", "connection", "down", conn],
                        capture_output=True,
                        check=True,
                    )
                self.notify("Disconnected from WiFi")
                return True
            else:
                self.notify("No active WiFi connection found")
                return False

        except subprocess.CalledProcessError as e:
            self.notify(f"Error disconnecting: {e}")
            return False

    def notify(self, message: str):
        """Send desktop notification"""
        try:
            subprocess.run(
                ["notify-send", "WiFi Manager", message],
                capture_output=True,
                check=False,
            )
        except:
            pass

    def show_menu(self):
        """Show the main Rofi menu"""
        networks = self.scan_networks()

        if not networks:
            self.notify("No WiFi networks found")
            return

        # Prepare menu options
        options = []

        # Add disconnect option if connected
        current_network = None
        for network in networks:
            if network["in_use"]:
                current_network = network["ssid"]
                break

        if current_network:
            options.append("🔌 Disconnect")
            options.append("---")

        # Add rescan option
        options.append("🔄 Rescan Networks")
        options.append("---")

        # Add networks
        for network in networks:
            options.append(network["display"])

        # Show Rofi menu
        rofi_input = "\n".join(options)

        try:
            result = subprocess.run(
                [
                    "rofi",
                    "-dmenu",
                    "-i",
                    "-p",
                    "WiFi Networks",
                    "-format",
                    "s",
                    "-theme-str",
                    "listview { lines: 10; } element alternate { background-color: transparent; }",
                ],
                input=rofi_input,
                text=True,
                capture_output=True,
            )

            if result.returncode == 0:
                selection = result.stdout.strip()
                self.handle_selection(selection, networks)

        except subprocess.CalledProcessError as e:
            self.notify(f"Error showing menu: {e}")

    def handle_selection(self, selection: str, networks: List[Dict[str, str]]):
        """Handle user selection from Rofi menu"""
        if selection == "🔌 Disconnect":
            self.disconnect_current()
        elif selection == "🔄 Rescan Networks":
            self.show_menu()  # Rescan and show menu again
        elif selection and selection != "---":
            # Find the selected network
            for network in networks:
                if network["display"] == selection:
                    self.connect_to_network(network["ssid"])
                    break


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--disconnect":
        wifi_manager = WiFiManager()
        wifi_manager.disconnect_current()
    else:
        wifi_manager = WiFiManager()
        wifi_manager.show_menu()


if __name__ == "__main__":
    main()
