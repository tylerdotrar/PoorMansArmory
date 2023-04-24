function WebClient ([string]$URL) {
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 1.1.1

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
        # Check if bypass already exists in current shell
        if (([System.Net.ServicePointManager]::ServerCertificateValidationCallback).Method.DeclaringType.Name -ne 'SelfSignedCerts') {
            Add-Type $CertBypass;
            [SelfSignedCerts]::Bypass();
        }
    }

    # Target File
    $File = $PWD.path + '/' + ($URL -split '/')[-1]

    # Download String / Raw Text
    if ($URL -like "*/r/*") { $Response = [System.Net.WebClient]::new().DownloadString($URL) }

    # Download File
    if ($URL -like "*/d/*") {
        Try {
            [System.Net.WebClient]::new().DownloadFile("$URL","$File")
            if (Test-Path -LiteralPath $File) { $Response = 'SUCCESSFUL DOWNLOAD' }
        }
        Catch { $Response = 'UNSUCCESSFUL DOWNLOAD' }
    }

    # Upload File
    if ($URL -like "*/u/*") {
        if (!(Test-Path -LiteralPath $File)) { $Response = 'FILE NOT IN PWD' }
        else {
            $ByteArray = [System.Net.Webclient]::new().UploadFile($URL,$File)
            $Response  = [System.text.Encoding]::Ascii.GetString($ByteArray)
        }
    }

    return $Response
}