function Bypass-ExecPolicy {
#.SYNOPSIS
# Educational file displaying how to simply bypass execution policies.
# ARBITRARY VERSION NUMBER:  1.1.2
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Super simple script that is more educational than useful.  It simply shows how easy it is
# to bypass execution policies in PowerShell (i.e., Restricted).
#
# Technically this script won't execute with a Restricted Execution Policy if you try to 
# load it via the script itslef, however it will if you use the one-liner syntax OR load it
# via other methods (e.g., "iex (System.Net.WebClient::new().DownloadString('<url>'))").
#
# Usage against Restricted Execution Policies:
# [+] Pipe this function into 'iex':  Bypass-ExecPolicy My-Script.ps1 | iex
# [+] Use the one-liner Syntax:  iex ([string](Get-Content My-Script.ps1 | % { "$_`n" }))
#
# Parameters:
#    -File        -->    Target file to execute.
#    -Help        -->    Return Get-Help information.
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param (
        [string] $File,
        [switch] $Help
    )


    # Return Get-Help Information
    if ($Help) { return (Get-Help Bypass-ExecPolicy) }


    # Error Correction
    if (!$File) { return (Write-Host 'Input target file.' -ForegroundColor Red) }


    # One-Liner Syntax: 
    # REPLACE 'return' WITH 'iex'

    return ([string](Get-Content $File | % { "$_`n" }))
}