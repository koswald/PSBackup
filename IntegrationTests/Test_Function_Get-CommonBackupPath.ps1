# Get-CommonoBackupPath test

using namespace System.IO # FileInfo
using namespace System.Collections # Hashtable
using Module IntegrationTester # IntegrationTester
#Requires -Module Utility
Import-Module Backup -Force

$PSCommandPath |
    Split-Path |
    Set-Location

# remove previous test folders, which if present may give incorrect test results
$artifacts = @(
    '.\9876'
)
if(( Remove-TestArtifact $artifacts ) -lt 0 ) {
    Throw "One or more test artifacts could not be removed. Test script {0} could not be run." -f ( $PSCommandPath | Split-Path -Leaf )
}

$t = [IntegrationTester]::new()

$t.describe( 'Get-CommonBackupPath' )

$t.it( 'should get the path part--empty' )
# note: the unit under test is intended to be called only after expanding and resolving the two paths.
$script = $PsCommandPath
$src = $script | Split-Path
$dest = "$( $src | Split-Path )\Backup"
$file = Get-Item $script
$Spec = @{
    Src = $src
    Dest = $dest
    File = $file }
$t.AssertEqual(
    ( Get-CommonBackupPath $Spec ),
    [String]::Empty
)

$t.it( 'should get the path part--not empty' )
$subFolder = "$($Spec.Src)\9876"
$file = "$subFolder\ReadMe.md"
if( -Not ( Test-Path $subFolder ))
{
    New-Item $subFolder -ItemType 'Directory' | Out-Null
    New-Item $file -ItemType 'File' | Out-Null
}
$Spec.File = Get-Item $file
if( 'Win32NT' -eq [System.Environment]::OSVersion.Platform ){
    $expected = '\9876'
} else {
    $expected = '\9876'
}
$t.AssertEqual(
    ( Get-CommonBackupPath $Spec ),
    $expected
)


Remove-TestArtifact $artifacts > $null
