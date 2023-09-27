function Get-WifiCredentials {
#.SYNOPSIS
# Simple tool to return Wi-Fi credentials saved on the local system.
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Script that utilizes 'netsh' to export WLAN profiles in cleartext, search for
# any passwords, then aggregates all relevant data in an organized list.
#
# Parameters:
#   -Help   -->   Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/Tiny-Tools
    
    Param( [switch]$Help )

    # Return Get-Help Information
    if ($Help) { return Get-Help Get-WifiCredentials }

    # Export Wireless Data in Cleartext
    netsh wlan export profile key=clear | Out-Null

    # Find Passwords and Clean-Up
    $Data = Select-String -Path "Wi-Fi*.xml" -Pattern "keyMaterial"
    Remove-Item -Path "./Wi-Fi*.xml"

    # Create List of all known SSID's with Correlated Passwords
    $WifiCreds = @()
    foreach ($Line in $Data) {

        $SSID        = (($Line -split '.xml')[0] -split 'Wi-Fi-')[-1]
        $Password    = (($Line -split '<keyMaterial>')[-1] -split '</keyMaterial>')[0]

        $Credentials = [pscustomobject]@{SSID = "$SSID"; Password = "$Password"}
        $WifiCreds   += $Credentials
    }

    return $WifiCreds
}