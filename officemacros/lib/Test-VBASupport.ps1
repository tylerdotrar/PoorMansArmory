function Test-VBASupport {
#.SYNOPSIS
# Validate System can Generate Macro via the VBA Project Object Model
# ARBITRARY VERSION NUMBER:  3.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# TBA
# 
# Parameters:
#   -Silent  -->  Return test boolean instead of visual output
#   -Help    -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory
 

    Param(
        [switch]$Silent,
        [switch]$Help
    )
    

    # Return Get-Help Information
    if ($Help) { return (Get-Help Test-VBASupport) }
    

    # Initialize Boolean
    $VBAsupport = $FALSE


    # Validate Word Application Exists
    Try { $WordApp = New-Object -ComObject "Word.Application" }
    Catch {
        if ($Silent) { return $VBAsupport }
        else         { return (Write-Host "[-] Unable to find 'Word.Application' object." -ForegroundColor Red) }
    }

    
    # Validate VBA project object model is enabled
    Try {
        if (!$Silent) { Write-Host "[+] Testing if the system supports macro generation..." -ForegroundColor Yellow}

        $Document   = $WordApp.Documents.Add()
        $VBproject  = $Document.VBProject.VBComponents.Item(1)
        $VBAsupport = $TRUE

        if (!$Silent) { Write-Host " o  Macro generation via the VBA project object model is supported." }
    }
    Catch {
        $VBAsupport = $FALSE

        if (!$Silent) {
            Write-Host " o  Macro generation via the VBA project object model is NOT supported."

            Write-host "`n[-] To fix this..." -ForegroundColor Red
            Write-Host " o  Enable   : 'Trust Access to the VBA project object model'"
            Write-Host " o  Location : Word --> Options --> Trust Center --> Macro Settings --> Developer Macro Settings`n"
        }
    }


    # Cleanup
    $Document.Close()
    $WordApp.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WordApp) | Out-Null

    if ($Silent) { return $VBAsupport }
}