function pma-server {
#.SYNOPSIS
# Lazy PowerShell wrapper to execute 'pma_server.py' from anywhere.
# Arbitrary Version Number: v1.0.0
# Author: Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Python Flask based file hosting server, supporting both file uploads and downloads (either via
# explicit URLs or via custom request headers).  SSL is supported via self signed certificates (-SSL),
# and PoorMansArmory web exploitation payloads output to 'xss_*.txt' files.
#
# PMA Server Python Requirements:
# -> flask
# -> markdown
# -> pyopenssl
#
# Usage:
#   -Directory <DIRECTORY>    Target file directory                             (default: $PWD)
#   -Port <PORT>              Server port to listen on                          (default: 80)
#   -SSL                      Enable HTTPS support via self-signed certificates (default: false)
#   -Debug                    Toggle Flask debug mode                           (default: false)
#   -Help                     Show help message and exit                        (default: false)
#   -PmaPath                  Path to 'pma_server.py'                           (default: $PSScriptRoot/../pma_server.py)
#
# Example Usage:
#   # Host current directory over HTTP on port 80 
#   PS> pma-server
#   # Host current directory over HTTPS on port 443
#   PS> pma-server -SSL
#   # Host the Temp directory over HTTP on port 8080
#   PS> pma-server -Port 8080 -Directory C:\Windows\Temp
#
# Example $PROFILE Setup:
#   PS> git clone https://github.com/tylerdotrar/PoorMansArmory $env:APPDATA/PoorMansArmory
#   PS> pip install -r $env:APPDATA/PoorMansArmory/requirements.txt
#   PS> if (!(Test-Path $PROFILE 2>$NULL)) { New-Item $PROFILE -Force }
#   PS> echo "`n# Load PMA Server into PowerShell.`n. `$env:APPDATA/PoorMansArmory/wrappers/pma-server.ps1" >> $PROFILE 
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory

  Param(
      [string]$Directory = $PWD,
      [int]   $Port,
      [switch]$SSL,
      [switch]$Debug,
      [switch]$Help,

      [string]$PmaPath = "$PSScriptRoot/../pma_server.py"
  )
  

  # Return Get-Help Information
  if ($Help) { return (Get-Help pma-server) }
  

  # Minor Error Correction
  if (!(Test-Path -LiteralPath $PmaPath 2>$NULL)) { return (Write-Host "[-] Unable to find 'pma_server.py'. Try manually setting the `$PmaPath variable." -ForegroundColor Red) }


  # Build Argument List 
  $Execution = @()
  $Execution += $PMAPath
  $Execution += @('--directory', $Directory)
  if ($Port)  { $Execution += @('--port', $Port) } # Defaults to port 80
  if ($SSL)   { $Execution += '--ssl'            } # If enabled, defaults to port 443
  if ($Debug) { $Execution += '--debug'          }
  

  # Execute PMA server w/ params
  python $Execution
}
