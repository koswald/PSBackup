# Get-BackupFiles test

using namespace System.Collections # Generic.List, Generic.HashSet, Hashtable
using namespace System.IO # FileInfo
using Module IntegrationTester
#Requires -Module Utility
Import-Module Backup -Force

$PSCommandPath |
    Split-Path |
    Set-Location

# remove previous test folders, which if present may give incorrect test results
function Remove-Artifacts
{
    param(
        [parameter( Mandatory = $true )]
        [string[]] $Artifacts,
        [int] $MaxTries = 100,
        [int] $msPause = 250
    )

    $RemoveArgs = @{ Recurse = $true
                     Force = $true
                     ErrorAction = 'SilentlyContinue' }
    $testArgs = @{ ErrorAction = 'SilentlyContinue' }
        
    $i = 0
    foreach( $i in 1..$MaxTries )
    {
        $fail = $false
        $Artifacts | ForEach-Object {
            if( Test-Path $_ @testArgs ) 
            {
                Remove-Item $_ @RemoveArgs
            }
            if( Test-Path $_ @testArgs ) 
            {
                $fail = $true
            }
        }
        if( -Not $fail )
        {
            return $i
        }
        Start-Sleep -m $msPause
    }
    return - $i
}
$artifacts = @(
    './Src'
)
if(( Remove-Artifacts $artifacts ) -lt 0 ) {
    Throw "One or more test artifacts could not be removed. Test script {0} could not be run." -f ( $PSCommandPath | Split-Path -Leaf )
}

# create fixture

# New-Item args
$stop = @{ ErrorAction = 'Stop' }
@(
    @{ Path = './Src'; ItemType = 'Directory' }
    @{ Path = './Src/a'; ItemType = 'Directory' }
    @{ Path = './Src/b'; ItemType = 'Directory' }
    @{ Path = './Src/c'; ItemType = 'Directory' }
    @{ Path = './Src/d'; ItemType = 'Directory' }
    @{ Path = './Src/ReadMe.md'; ItemType = 'File' }
    @{ Path = './Src/.gitignore'; ItemType = 'File' }
    @{ Path = './Src/license.txt'; ItemType = 'File' }
    @{ Path = './Src/Setup.ps1'; ItemType = 'File' }
    @{ Path = './Src/a/alpha.ps1'; ItemType = 'File' }
    @{ Path = './Src/b/bravo.psm1'; ItemType = 'File' }
    @{ Path = './Src/c/charlie.psd1'; ItemType = 'File' }
    @{ Path = './Src/d/delta.cs'; ItemType = 'File' }
) | ForEach-Object { 
    if( -Not ( Test-Path $_.Path @stop )) {
        New-Item @_ | Out-Null
    }
}
 #clear archive bit(s)
@(
#    './Src/p/one.ps1'
) | ForEach-Object {
    Clear-ArchiveBit ( Get-Item $_ ) @Stop
}
function Get-NameString
{
    param( [FileInfo[]] $Files )
    
    # make a list of file names
    $list = [Generic.List[string]]::new()
    foreach( $file in $Files )
    {
        $list.Add( $file.Name )
    }
    
    # sort the list alphabetically
    $list.Sort()
    
    # ToString()
    $str = ''
    foreach( $file in $list )
    {
        $str += "|$($file)"
    }
    if( -Not ( [string]::Empty -eq $str ))
    {
        # remove leading delimiter
        $str = $str.Substring( 1 )
    }
    return $str
}


[Directory]::SetCurrentDirectory( $PWD )
"Current directory: $([Environment]::CurrentDirectory)"

$t = [IntegrationTester]::new()

$t.describe( 'Get-BackupFiles')

# TEST WITH WINDOWS POWERSHELL AND POWERSHELL CORE

$t.it( 'should include and exclude with Subfolders $true' )
$Spec = @{
    Src = "./Src"
    Include = "*.p*", "*.md", "*.txt"
    Exclude = "a*", "c*"
    Subfolders = $true }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    'bravo.psm1|license.txt|ReadMe.md|Setup.ps1'
)
$t.it( 'should include and exclude with Subfolders $false' )
$Spec = @{
    Src = "./Src"
    Include = "*t*", "*.md"
    Exclude = "*p*", "*s*"
    Subfolders = $false }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    '.gitignore|ReadMe.md'
)
$t.it( 'should include and exclude with one item only (Recurse)' )
$Spec = @{
    Src = "./Src"
    Include = "*.p*"
    Exclude = "a*"
    Subfolders = $true }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    'bravo.psm1|charlie.psd1|Setup.ps1'
)
$t.it( 'should include and exclude with one item only (no Recurse)' )
$Spec = @{
    Src = "./Src"
    Include = "*.p*"
    Exclude = "a*"
    Subfolders = $false }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    'Setup.ps1'
)
$t.it( 'should ignore empty include and exclude item (Recurse)' )
$Spec = @{
    Src = "./Src"
    Include = "", "*.p*"
    Exclude = "", "a*"
    Subfolders = $true }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    'bravo.psm1|charlie.psd1|Setup.ps1'
)
$t.it( 'should ignore empty include and exclude item (No Recurse)' )
$Spec = @{
    Src = "./Src"
    Include = "", "*.p*"
    Exclude = "", "a*"
    Subfolders = $false }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    'Setup.ps1'
)
$t.it( 'should not exclude with one empty item (Recurse)')
$Spec = @{
    Src = "./Src"
    Include = "*t*"
    Exclude = ""
    Subfolders = $true }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    '.gitignore|delta.cs|license.txt|Setup.ps1'
)
$t.it( 'should not exclude with one empty item (no Recurse)')
$Spec = @{
    Src = "./Src"
    Include = "*t*"
    Exclude = ""
    Subfolders = $false }
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    '.gitignore|license.txt|Setup.ps1'
)
$t.it( 'should not exc. with missing exc. key in spec (Recurse)')
$Spec = @{
    Src = "./Src"
    Include = "*"
    Dest = "./Dest"
    Subfolders = $true }
Optimize-SpecData $Spec
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    '.gitignore|alpha.ps1|bravo.psm1|charlie.psd1|delta.cs|license.txt|ReadMe.md|Setup.ps1'
)
$t.it( 'should not exc. with missing exc. key in spec (no Recurse)')
$Spec = @{
    Src = "./Src"
    Dest = "./Dest"
    Include = "*"
    Subfolders = $false }
Optimize-SpecData $Spec
$files = Get-BackupFiles $Spec
$t.AssertEqual(
    ( Get-NameString $files ),
    '.gitignore|license.txt|ReadMe.md|Setup.ps1'
)

Remove-Artifacts $artifacts > $null
