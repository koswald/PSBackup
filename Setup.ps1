<#
.Synopsis
Prepares the project for use.

.Description
Makes project modules discoverable to PowerShell scripts and consoles.
Requires a restart of the PowerShell console for changes to take effect.

.Parameter ProfileName
Specifies which profile file to use. The default is CurrentUserAllHosts. Must be one of CurrentUserAllHosts, CurrentUserCurrentHost, AllUsersAllHosts, or AllUsersCurrentHost. Alias: pn.

.Parameter Confirm
If -Confirm is specified, then a prompt appears for verification before the profile file is created or changed. Default is to not confirm.

.Notes
Appends a line to the default or specified profile file to add the project path to the PSModulePath environment variable.
#>

param(
    [parameter( Mandatory = $false )]
    [ValidateSet( 
        'CurrentUserAllHosts', 
        'CurrentUserCurrentHost', 
        'AllUsersAllHosts', 
        'AllUsersCurrentHost' )]
    [alias( 'pn' )]
    [string]
    $ProfileName = 'CurrentUserAllHosts', 

    [switch] $Confirm
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
}
else  # The project module path has not been added yet.
{
    $file = $profile.$ProfileName
    $lineToAdd = "`$env:PSModulePath += '$delimiter$ProjectModulePath'"

    if( $Confirm )
    {
        "Do you want to add the line `n`n$lineToAdd `n`nto the $ProfileName profile file '$file'?"
        $key = $host.UI.RawUI.ReadKey(); "`n"
        if( -Not ( 'y' -like $key.Character ))
        {
            "The profile has not been modified."
            Exit
        }
    }
    $acArgs = @{
        Path = $file
        Value = $lineToAdd
        Force = $true
        ErrorAction = 'Stop'
    }
    try {
        if( -Not ( Test-Path $file ))
        {
            New-Item $file -Force | Out-Null
        }
        Add-Content @acArgs 
    }
    catch {
        $_
        "The profile has not been modified."
        Exit
    }
    "The path has been added. Restart the console for changes to take effect."
}

