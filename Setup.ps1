<#
    .Synopsis
    Prepares the project for use.

    .Description
    Makes the PSBackup project modules discoverable to PowerShell console hosts and scripts.
    Requires a restart of the PowerShell console for changes to take effect.

    .Parameter ProfileName
    Specifies which profile file to use. The default is CurrentUserAllHosts. Must be one of CurrentUserAllHosts, CurrentUserCurrentHost, AllUsersAllHosts, or AllUsersCurrentHost. If one of the AllUsers profiles is chosen, then privileges must be elevated.

    .Parameter Confirm
    If -Confirm is specified, then a prompt appears for verification before the profile file is created or changed. Default is to not confirm.

    .Notes
    Appends a line to the default or specified profile file to add the project path to the PSModulePath environment variable.
#>

[CmdletBinding( SupportsShouldProcess )]

param(
    [ValidateSet( 'CurrentUserAllHosts',
                  'CurrentUserCurrentHost',
                  'AllUsersAllHosts',
                  'AllUsersCurrentHost' )]
    [string] $ProfileName = 'CurrentUserAllHosts'
)
# build the project Module path

if( 'Win32NT' -eq [Environment]::OSVersion.Platform ) {
    $delimiter = ';'
    $separator = '\'
} else {
    "This platform is not currently supported."
    Exit
    $delimiter = ':'
    $separator = '/'
}
$ProjectModulePath = "$PSScriptRoot$($separator)Modules"

# check whether the project module path has already been added

$var = [Environment]::GetEnvironmentVariable( 'PSModulePath' )
$paths = $var -split $delimiter

if( $paths -contains $ProjectModulePath )
{
    "The project's module path has already been added to the PSModulePath variable."
    Exit
}

$file = $profile.$ProfileName
$lineToAdd = "`n`$env:PSModulePath += '$delimiter$ProjectModulePath'"

$addContentArgs = @{ Path = $file
                     Value = $lineToAdd
                     Force = $true
                     ErrorAction = 'Stop' }

$newItemArgs = @{ Force = $true
                  ErrorAction = 'Stop' }

$verb = "add the line $lineToAdd"
$noun = "$ProfileName profile file '$file'"
if( $PSCmdlet.ShouldProcess( $noun, $verb ))
{
        if( -Not ( Test-Path $file ))
        {
            try { New-Item $file @newItemArgs | Out-Null }

            catch [System.UnauthorizedAccessException] {
                "`nElevated privileges are required with AllUsers profiles."
                Exit
            }
            catch { $_.Exception.GetType().FullName
                    $_.Exception.Message
                    Exit
            }
        }
        try { Add-Content @addContentArgs }

        catch [System.UnauthorizedAccessException] {
            "`nElevated privileges are required with AllUsers profiles."
            Exit
        }
        catch {
            $_.Exception.GetType().FullName
            $_.Exception.Message
            Exit
        }
        "The path has been added. Restart the console for changes to take effect."
    }
else
{
    "The profile has not been modified."
    Exit
}

