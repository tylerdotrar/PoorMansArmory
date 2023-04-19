function WebClient ([switch]$GET,[switch]$POST,[string]$URL) {
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 1.0.0

    if ($URL -notlike "http*") { return 'INVALID URL' }

    # Bypass Self-Signed Certificate Restriction
    if ($URL -like "https*") {

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
        Add-Type $CertBypass;
        [SelfSignedCerts]::Bypass();
    }


    # Target File
    $File = $PWD.path + '/' + ($URL -split '/')[-1]


    # Download/Raw Text
    if ($GET) {
        if ($URL -like "*/raw/*") { $Response = [System.Net.WebClient]::new().DownloadString($URL) }
        else {
            Try {
                [System.Net.WebClient]::new().DownloadFile("$URL","$File")
                if (Test-Path -LiteralPath $File) { $Respone = 'SUCCESSFUL DOWNLOAD' }
            }
            Catch { $Response = 'UNSUCCESSFUL DOWNLOAD' }
        }
    }


    # Upload
    elseif ($POST) {
        if (!(Test-Path -LiteralPath $File)) { $Response = 'FILE NOT IN PWD' }
        $ByteArray = [System.Net.Webclient]::new().UploadFile($URL,$File)
        $Response  = [System.text.Encoding]::Ascii.GetString($ByteArray)
    }


    # Disable Self-Signed Certificate Bypass
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $NULL
    return $Response
}