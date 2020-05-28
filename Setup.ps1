<#
.Synopsis
Prepares the project for use.

.Description
Makes project modules discoverable to PowerShell scripts and consoles.
Requires a restart of the PowerShell console for changes to take effect.

.Parameter ProfileName
Specifies which profile file to use. The default is CurrentUserAllHosts. Must be one of CurrentUserAllHosts, CurrentUserCurrentHost, AllUsersAllHosts, or AllUsersCurrentHost. Alias: pn.

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
    $ProfileName = 'CurrentUserAllHosts'
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
$PSCommandPath | Split-Path | Set-Location
$ProjectModulePath = "$PWD$($separator)Modules"

# check whether the project module path has already been added

$var = [Environment]::GetEnvironmentVariable( 'PSModulePath' )
$paths = $var -split $delimiter

if( $paths -contains $ProjectModulePath )
{
    "The project's module path has already been added to the PSModulePath variable."
}
else {
    # The project module path has not already been added, so ask to add it.

    $file = $profile.$ProfileName

    "Do you want to add the project path to the $ProfileName profile file ($file)?"

    $key = $host.UI.RawUI.ReadKey()
    if( 'y' -like $key.Character )
    {
        $acArgs = @{
            Path = $file
            Value = "`$env:PSModulePath += '$delimiter$ProjectModulePath'"
        }
        Add-Content @acArgs

        "The path has been added. Restart the console for changes to take effect."
    }
    else { "`nThe new path was not added." }
}
