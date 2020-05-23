# Ensure that the project root is the current working directory

$PSCommandPath | Split-Path | Set-Location

# build the project Module path

if( 'Win32NT' -eq [Environment]::OSVersion.Platform ) {
    $delimiter = ';'
    $separator = '\'
} else {
    $delimiter = ':'
    $separator = '/'
}

$ProjectModulePath = "$PWD$($separator)Modules"

# check whether project module path has already been added

$var = [Environment]::GetEnvironmentVariable( 'PSModulePath' )
$paths = $var -split $delimiter

$cuProfile = 'CurrentUserAllHosts'

if( $paths -contains $ProjectModulePath )
{
    "`$env:PSModulePath already contains the project module path"
}
else 
{
    # The project module path has not already been added,
    # so ask to add it.

    $file = $profile.$cuProfile

    "Do you want to add the project path to the $cuProfile profile ($file)?"

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
