#!/bin/bash

# Rescan for available Wi-Fi networks
nmcli d wifi rescan

# Add a delay to allow the rescan to complete
sleep 3

# List available Wi-Fi networks
wifi_networks=$(nmcli -t -f SSID,SECURITY dev wifi list | grep ':WPA\|:WEP' | cut -d: -f1 | uniq)

# List available wired interfaces
wired_interfaces=$(nmcli -t -f DEVICE,TYPE,CONNECTION dev status | grep ethernet | awk -F: '{print $1 ":" $3}')

# Get the active connection
active_connection=$(nmcli -t -f NAME connection show --active | head -n 1)

# Mark active connection with a star
wifi_networks=$(nmcli -t -f SSID dev wifi | grep -v '^$')
wired_connections=$(nmcli -t -f NAME,TYPE connection show | awk -F: '$2 == "ethernet" || $1 == "lo" {print $1}')
marked_wifi_networks=$(echo "$wifi_networks" | awk -v active="$active_connection" '{if ($0 == active) print "★ " $0; else print $0}')
# marked_wired_connections=$(echo "$wired_connections" | awk -v active="$active_connection" '{if ($0 == active) print "★ " $0; else print $0}')
marked_wired_connections=$(echo "$wired_connections" | awk -v active="$active_connection" '{if ($0 == active) print "★ " $0; else print $0}')

# Combine Wi-Fi networks, wired connections, and active connection
# options=$(echo -e "$marked_wifi_networks\n$marked_wired_connections\nDisconnect Active Connection: $active_connection")
options=$(echo -e "Wi-Fi Networks:\n$marked_wifi_networks\n\nWired Connections:\n$marked_wired_connections\n\nDisconnect Active Connection: $active_connection")

# Use rofi to display the list and capture the selected network or interface
selected=$(echo "$options" | rofi -dmenu -p "Select Network/Interface")

# Check if a network or interface was selected
if [ -n "$selected" ]; then
  if [[ "$selected" == "Disconnect Active Connection: $active_connection" ]]; then
    # Deactivate the active connection
    nmcli connection down "$active_connection" || notify-send "Disconnection Failed" "Could not disconnect $active_connection"
  elif echo "$wifi_networks" | grep -q "^$selected$"; then
    # Check if the network requires a password
    security=$(nmcli -t -f SSID,SECURITY dev wifi list | grep "^$selected" | cut -d: -f2 | uniq)
    if [[ "$security" == *"WPA"* || "$security" == *"WEP"* ]]; then
      # Check if a password is already stored for this network
      if nmcli -s -g NAME connection show | grep -Fxq "$selected"; then
        # Attempt to connect to the selected network without prompting for password
        nmcli connection up "$selected" || notify-send "Connection Failed" "Could not connect to $selected"
      else
        # Prompt for the password using rofi
        password=$(rofi -dmenu -password -p "Enter password for $selected")
        # Attempt to connect to the selected network with the provided password
        nmcli dev wifi connect "$selected" password "$password" || notify-send "Connection Failed" "Could not connect to $selected"
      fi
    else
      # Attempt to connect to the selected network without a password
      nmcli dev wifi connect "$selected" || notify-send "Connection Failed" "Could not connect to $selected"
    fi
  elif echo "$wired_interfaces" | grep -q "^$selected$"; then
    # Extract the interface name from the selection
    interface=$(echo "$selected" | cut -d: -f1)
    # Activate the selected wired interface
    nmcli connection up "$interface" || notify-send "Connection Failed" "Could not activate $interface"
  elif [[ "$selected" == *"Disconnect Active Connection"* ]]; then
    notify-send "Debug" "active_connection='$active_connection'"
    # Deactivate the active connection
    nmcli connection down "$active_connection" || notify-send "Disconnection Failed" "Could not disconnect $active_connection"
  fi
else
  notify-send "No Selection" "Please select a network or interface to connect."
fi
