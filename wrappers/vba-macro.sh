#!/bin/sh

# Simple wrapper to generate PMA VBA macros from anywhere.
# Arbitrary Version Number: v1.0.0
# Author: Tyler McCann (@tylerdotrar)

# Requirements:
#   PowerShell (/usr/bin/pwsh)

# Examples:
#   Get-VBAMacro <bonus_args>
#   Get-VBAMacro -Help

# Setup:
#   git clone https://github.com/tylerdotrar/PoorMansArmory /usr/share/PoorMansArmory
#   ln -s /usr/share/PoorMansArmory/wrappers/vba-macro.sh /usr/bin/Get-VBAMacro

pma_tool=$(basename $0)
exec pwsh -c ". /usr/share/PoorMansArmory/officemacros/$pma_tool.ps1; $pma_tool $@"
