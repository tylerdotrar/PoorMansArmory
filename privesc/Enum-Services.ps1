function Enum-Services {
#.SYNOPSIS
# Enumerate, Audit, and Parse Windows Services
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# Enumeration script developed to easily parse the Access Control Lists (ACLs) and other parameters
# of Windows Services, such as the service owner, start mode, and whether the service path is vulnerable
# to an unquoted service path attack.  Unquoted service paths are able to be audited for writeability
# via the '-Audit' parameter.
#
# By default the script will return an object containing sorted service binary ACLs.
# 
# Parameters:
#   -StartMode      -->  Services with specified start modes (e.g., 'Auto','Disabled','Manual')
#   -UnquotedPaths  -->  Services containing spaces in their paths but not wrapped in quotations
#   -Audit          -->  Test if vulnerable portions of the unquoted path are writeable for the current user
#   -Owner          -->  Services belonging to specified Owner (e.g., 'SYSTEM')
#   -FullControl    -->  Services with FullControl access rights for specified group (e.g., 'Administrators')
#   -OnlyPath       -->  Return full service paths instead of ACL's
#   -Help           -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory


    Param(
        [string]$StartMode,
        [switch]$UnquotedPaths,
        [switch]$Audit,
        [string]$Owner,
        [string]$FullControl, # Partially broken; needs refined logic.
        [switch]$OnlyPath,
        [switch]$Help
    )


    # Return Get-Help Information
    if ($Help) { return (Get-Help Enum-Services) }

    
    # Error Correction
    if ($StartMode) {
        $StartOptions = @('Auto','Manual','Disabled')
        if ($StartOptions -notcontains $StartMode) { return (Write-Host '[-] Invalid start mode.' -ForegroundColor Red) }
    }
    if ($Audit -and !$UnquotedPaths) { return (Write-Host '[-] Auditing only supports unquoted service paths.' -ForegroundColor Red) }
    

    # Internal Function(s)
    function Perform-PathAudit ($ServicePaths) {
        
        # Audit unquoted service paths for writeability
        foreach ($UnquotedPath in $ServicePaths) {
            Write-Output "[+] Auditing unquoted service path writeability..."
            Write-Host " o  Target Service : '$UnquotedPath'"


            # Remove all path data after the last space
            $LastSegment = ($UnquotedPath).Split(' ')[-1]
            $PreSpace    = ($UnquotedPath).Replace($LastSegment,'')


            # Check every preceding directory for spaces, ignoring the drive letter
            $VulnerablePaths = @()
            $PathSegments = ($PreSpace.Split('\')).Split('/')


            # If directory segment contains a space, service path is vulnerable here.
            for ($i=1; $i -lt $PathSegments.Length;$i++) {

                $Reconstructed = $PathSegments[0..$i] -join '\'
                if ($PathSegments[$i] -like "* *") { $VulnerablePaths += $Reconstructed }
            }
            

            # Audit each vulnerable portion of the path
            foreach ($VulnerablePath in $VulnerablePaths) {
                
                # Remove all path data after the last '\'
                $LastVSegment = $VulnerablePath.Split('\')[-1]
                $RootVPath    = $VulnerablePath.Replace($LastVSegment,'')

                Write-Host " o  Auditing Path  : '$RootVPath'"


                # Randomly generate a filename to avoid conflictions
                $AuditFile = $NULL
                for ($i=0; $i -lt 6; $i++) {
                    $AuditFile += Get-Random -InputObject ([char[]](([char]'a')..([char]'z')))
                    $AuditFile += Get-Random -InputObject ([char[]](([char]'A')..([char]'Z')))
                }
                $AuditFile += '.exe'


                # Full audit file path
                $AuditFilePath = Join-Path -Path $RootVPath -ChildPath $AuditFile
                #Write-Host " o  Audit File     : '$AuditFilePath'"


                # Begin Audit
                Try {
                    New-Item -Path $AuditFilePath -ErrorAction Stop -Force | Out-Null
                    Remove-Item -Path $AuditFilePath -ErrorAction SilentlyContinue -Force | Out-Null
                    $isWriteable = $TRUE
                }
                Catch { $isWriteable = $FALSE}

                
                # Return Results
                Write-Host " o  Path Writeable : " -NoNewline
                if ($isWriteable) { Write-Host "$isWriteable" -ForegroundColor Green }
                else              { Write-Host "$isWriteable" -ForegroundColor Red  }
            }
            Write-Host ''
        }
    }


    # Cleanup pathnames
    $CleanServices = @()
    foreach ($Service in (Get-CimInstance -ClassName win32_service)) {

        # Only Collect Services with Specified Start Modes
        if ($StartMode) { $Service = $Service | ? { $_.StartMode -eq "$StartMode" } }
        
        $Service = $Service.Pathname

        # Remove options after the executable
        $Service = ($Service -split ' -')[0]
        $Service = ($Service -split ' /')[0]
        $Service = ($Service -split ' \\')[0]


        # Contains a Space but not Quotation Marks
        if ($UnquotedPaths) { $Service = ($Service | ? { ($_ -like '* *') -and ($_ -notlike '*"*') }) }


        # Remove quotations from path (should be implied when passed to Get-Acl)
        else {
            $Service = $Service.Replace('"','')
            $Service = $Service.Replace("'",'')
        }


        # If path is not empty, add to list
        if ($Service -ne "") { $CleanServices += $Service }
    }


    # Get the ACL of each unique, cleaned service path
    $ACLlist = @()
    foreach ( $Service in ($CleanServices | Sort-Object -Unique) ) {
        
        $ACL = Get-Acl -LiteralPath $Service 2>$NULL

        if ($Owner)       { $ACL = $ACL | ? { $_.Owner -like "*$Owner*" } }
        if ($FullControl) { $ACL = $ACL | ? { ($_.Access.FileSystemRights -eq "FullControl") -and ($_.Access.IdentityReference -like "*$FullControl*") } }
        
        # Return absolute path instead of ACL
        if (($OnlyPath -or $Audit) -and $ACL.path) { $ACL = ($ACL.Path).Replace('Microsoft.PowerShell.Core\FileSystem::','') }

        $ACLlist += $ACL
    }

    # Check if any services match input parameters
    if ($ACLlist.Length -eq 0) { return '[-] No services that match the query were found.' }

    
    # Return
    if ($UnquotedPaths -and $Audit) { return Perform-PathAudit -ServicePaths $ACLlist }
    else                            { return $ACLlist                                 }
}