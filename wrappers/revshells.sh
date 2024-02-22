#!/bin/sh

# Simple wrapper to execute PMA revshell tools from anywhere.
# Arbitrary Version Number: v1.0.0
# Author: Tyler McCann (@tylerdotrar)

# Requirements:
#   PowerShell (/usr/bin/pwsh)

# Examples:
#   Get-RevShell <ip_addr> <port> <bonus_args>
#   Get-RevShell -Help
#   Get-Stager http(s)://<ip_addr>/<revshell_file> <bonus_args>
#   Get-Stager -Help

# Setup:
#   git clone https://github.com/tylerdotrar/PoorMansArmory /usr/share/PoorMansArmory
#   ln -s /usr/share/PoorMansArmory/wrappers/revshells.sh /usr/bin/Get-RevShell
#   ln -s /usr/share/PoorMansArmory/wrappers/revshells.sh /usr/bin/Get-Stager

pma_tool=$(basename $0)
exec pwsh -c ". /usr/share/PoorMansArmory/revshells/$pma_tool.ps1; $pma_tool $@"
