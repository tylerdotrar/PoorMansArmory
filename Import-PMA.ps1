<#
  Simple script to import the primary PoorMansArmory scripts into the current session.
  AUTHOR: Tyler McCann (@tylerdotrar)
  ARBITRARY VERSION NUMBER: 1.0.0
  LINK: https://github.com/tylerdotrar/PoorMansArmory
#>


$LoadedScripts = @('Import-PMA.ps1')


# Load Main Reverse Shell Scripts
Write-Output '[+] Importing Reverse Shell Scripts:'
$RevShellScripts = "$PSScriptRoot/revshells"

foreach ($pmaScript in (Get-ChildItem -LiteralPath $RevShellScripts -Filter '*.ps1')) {
    . $pmaScript.Fullname
    $LoadedScripts += $pmaScript.Name
    Write-Host " o  $($pmaScript.Name)"
}


# Load Main Microsoft Office Scripts
Write-Output "`n[+] Importing Microsoft Office Scripts:"
$OfficeScripts = "$PSScriptRoot/officemacros"

foreach ($pmaScript in (Get-ChildItem -LiteralPath $OfficeScripts -Filter '*.ps1')) {
    . $pmaScript.Fullname
    $LoadedScripts += $pmaScript.Name
    Write-Host " o  $($pmaScript.Name)"
}


# Ignore Tertiary Scripts
Write-Output "`n[+] Ignoring the Following Optional Scripts:"

foreach ($pmaScript in (Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -Filter '*.ps1')) {
    if (($LoadedScripts -notcontains $pmaScript.Name) -and ($pmaScript.Fullname -notmatch 'uploads')) { 
        Write-Host " o  $(($pmaScript.FullName).Replace($PSScriptRoot,'.'))"
    }
}