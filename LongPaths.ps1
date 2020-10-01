<#
    .Synopsis
    Enable or disable long paths.

    .Description
    Enable or disable paths longer than 260 characters on Windows systems.

    It is recommended that long paths be disabled, which is the Windows default, while testing experimental features of the https://github.com/koswald/PSBackup project, such as the VersionsOnSrc hashtable key of the Backup-Updates SpecSheet parameter.

    Requires elevated privileges. A warning message will appear if privileges are not elevated.

    Changes take effect immediately for processes that are started after the change is made. But in order to guarantee that changes are in effect for all running processes, a reboot is required.

    .Parameter Enable
    Switch parameter. Use -Enable to enable long paths. You must specify either -Enable or -Disable.

    .Parameter Disable
    Switch parameter. Use -Disable to disable long paths. You must specify either -Enable or -Disable.

    .Link
    https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#maximum-path-length-limitation
    .Link
    https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation
    .Link
    https://superuser.com/questions/14883/what-is-the-longest-file-path-that-windows-can-handle/14887#14887 A comment on this answer points out some potential hazards of using long paths.
    .Link
    https://github.com/koswald/PSBackup/blob/master/ReadMe.md (see Issues)
    .Link
    Get-Help Backup-Updates -Parameter SpecSheet
#>
using namespace System.Security.Principal

param(
    # require either -Enable or -Diable
    [parameter( ParameterSetName = 'Enabling',
                Mandatory = $true,
                Position = 0 )]
    [switch] $Enable = $false
    ,
    [parameter( ParameterSetName = 'Disabling',
                Mandatory = $true,
                Position = 0 )]
    [switch] $Disable = $false
)
$lpeProperty = @{ Name = "LongPathsEnabled"
                  Path = "HKLM:\System\CurrentControlSet\Control\FileSystem" }

# get the current setting

$currentSetting = ( Get-ItemProperty @lpeProperty ).LongPathsEnabled
$enabled = 1
$disabled = 0

# check whether the desired setting is already in effect

if( $Enable -And ( $enabled -eq $currentSetting ))
{
    "Long paths are already enabled."
    Exit
}
elseif( $Disable -And ( $disabled -eq $currentSetting ))
{
    "Long paths are already disabled."
    Exit
}

# check for elevated privileges

$identity  = [WindowsIdentity]::GetCurrent()
$principal = [WindowsPrincipal] $identity
$adminRole = [WindowsBuiltInRole]::Administrator
if( -Not $principal.IsInRole($adminRole) )
{
    # show status and error message, then exit

    if( $disabled -eq $currentSetting )
    {
        "Long paths are disabled."
    }
    elseif( $enabled -eq $currentSetting )
    {
        "Long paths are enabled."
    }
    else
    {
        "The registry value is corrupted. To fix this,"
    }
    "$( $PSCommandPath | Split-Path -Leaf ) must be run with elevated privileges."
    Exit
}

# change the setting

$lpeProperty.Type = "DWord"
if ( $Enable )  { $lpeProperty.Value = 0x00000001 }
if ( $Disable ) { $lpeProperty.Value = 0x00000000 }

Set-ItemProperty @lpeProperty -ErrorAction 'Stop'

"Long paths have been $( if( $Enable ) { 'enabled' } else { 'disabled' } )."
"Reboot for change to take effect."