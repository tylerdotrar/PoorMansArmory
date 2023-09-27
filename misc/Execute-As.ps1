function Execute-As {
#.SYNOPSIS
# Create scheduled tasks to execute as NT AUTHORITY\SYSTEM, LOCAL SERVICE, or NETWORK SERVICE.
# ARBITRARY VERSION NUMBER:  1.0.0
# AUTHOR:  Tyler McCann (@tylerdotrar)
#
#.DESCRIPTION
# This script creates scheduled tasks to execute specified commands as the desired elevated user.
# The scheduled task is set to execute three seconds after being set, and promptly removes itself
# one second after execution.
#
# Must run with elevated privileges (i.e., Administrator).
#
# Parameters:
#   -SYSTEM           -->  Execute input command as 'NT AUTHORITY\SYSTEM'
#   -LocalService     -->  Execute input command as 'NT AUTHORITY\LOCAL SERVICE'
#   -NetworkService   -->  Execute input command as 'NT AUTHORITY\NETWORK SERVICE'
#   -Command          -->  Command to execute (passed into PowerShell)
#   -Help             -->  Return Get-Help information
#
#.LINK
# https://github.com/tylerdotrar/PoorMansArmory
    

    Param(
        [switch]$SYSTEM,
        [switch]$LocalService,
        [switch]$NetworkService,
        [string]$Command,
        [switch]$Help
    )


    # Return Help Information
    if ($Help) { return (Get-Help Execute-As) }

    
    # Exit if session doesn't have elevated privileges
    $User = [Security.Principal.WindowsIdentity]::GetCurrent();
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (!$isAdmin) { return (Write-Host '[-]  This script requires elevated privileges.' -ForegroundColor Red) }


    # Select what elevation to run command.
    if ($SYSTEM)           { $User = 'SYSTEM'                       }
    if ($NetworkService)   { $User = 'NT AUTHORITY\NETWORK SERVICE' }
    if ($LocalService)     { $User = 'NT AUTHORITY\LOCAL SERVICE'   }
    if (!$User)            { return (Write-Host '[-]  No user specified.' -ForegroundColor Red)    }
    if (!$Command)         { return (Write-Host '[-]  No command specified.' -ForegroundColor Red) }


    Write-Host "[+] Executing command as '$User' in three seconds..."


    # Create a Scheduled Task to run as an elevated user, then permanently remove itself.
    $PS = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"$Command`""
    $Time = New-ScheduledTaskTrigger -At (Get-Date).AddSeconds(3) -Once
    $Time.EndBoundary = (Get-Date).AddSeconds(6).ToString('s')
    $Remove = New-ScheduledTaskSettingsSet -DeleteExpiredTaskAfter 00:00:01
    Register-ScheduledTask -TaskName 'Executed Command' -Action $PS -Trigger $Time -Settings $Remove -User $User -Force | Out-Null


    Start-Sleep -Seconds 3
    Write-Host '[+] Command executed.'
}