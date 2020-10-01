# Backup module test

using Module IntegrationTester
#Requires -Module Backup
#Requires -Module Utility

Import-Module Utility -Force
Import-Module Backup -Force

$PSScriptRoot | Set-Location

# remove previous test folders, which if present may give false positive test results

$artifacts = @(
    '.\Src'
    '.\Dest2'
    '.\Dest3'
    '.\Dest'
)
if(( Remove-TestArtifact $artifacts ) -lt 0 ) {
    Throw "One or more test artifacts could not be removed. Test script {0} could not be run." -f ( $PSCommandPath | Split-Path -Leaf )
}

# create fixture

# New-Item args
$Stop = @{ ErrorAction = 'Stop' }
@(
    @{ Path = '.\Src'; ItemType = 'Directory' }
    @{ Path = '.\Src\p'; ItemType = 'Directory' }
    @{ Path = '.\Src\p\one.ps1'; ItemType = 'File' }
    @{ Path = '.\Src\p\two.ps1'; ItemType = 'File' }
    @{ Path = '.\Src\p\three.ps1'; ItemType = 'File' }
    @{ Path = '.\Src\p\four.ps1'; ItemType = 'File' }
    @{ Path = '.\Src\b'; ItemType = 'Directory' }
    @{ Path = '.\Src\b\one.dll'; ItemType = 'File' }

) | ForEach-Object {
    if( -Not ( Test-Path $_.Path @stop )) {
        New-Item @_ | Out-Null
    }
 }
#clear archive bit(s)
@(
    '.\Src\p\one.ps1'
) | ForEach-Object {
    Clear-ArchiveBit ( Get-Item $_ ) @Stop
}
#backup folder(s)
$specs = @(
    @{ Src = '.\Src'
       Dest = '.\Dest'
       Include = '*'
       Subfolders = $true
       VersionsOnSrc = @(@{ Include = 'th*.ps?'; MaxQty = 11 })
       VersionsOnDest = @(@{ Include = 'f???.*' }) }
    @{ Src = '.\Src'; Dest = '.\Dest'; Include = '*' }
)

$specs | Backup-Updates | Out-Null

#begin tests
$t = [IntegrationTester]::new()

$t.describe( 'Backup-Updates' )

    $Version = @{ Include = 'tw*.ps?'
        MaxQty = 3
    }
    $vArgs = @{ File = ( Get-Item '.\Src\p\two.ps1' )
        Version = $Version
    }
    Backup-Version @vArgs

# create newer version files, in number greater or equal to $Version.MaxQty
    @(
        @{ Path = '.\Src\p\versions\tw@.ps#\two_YYYY-MM-DD--HHMM01.ps1'; ItemType = 'File' }
        @{ Path = '.\Src\p\versions\tw@.ps#\two_YYYY-MM-DD--HHMM02.ps1'; ItemType = 'File' }
        @{ Path = '.\Src\p\versions\tw@.ps#\two_YYYY-MM-DD--HHMM03.ps1'; ItemType = 'File' }
        @{ Path = '.\Src\p\versions\tw@.ps#\two_YYYY-MM-DD--HHMM04.ps1'; ItemType = 'File' }

    ) | ForEach-Object {

        New-Item @_ > $null
    }


$t.describe( 'Backup-Updates'  )

$t.it( 'should not save a version of a version' )
# set archive bit
$file = Get-Item '.\Src\p\three.ps1'
$file.Attributes = $file.Attributes -bor 32
# run the item under test
$specs | Backup-Updates | Out-Null
# set archive bit, again
$file = Get-Item '.\Src\p\three.ps1'
$file.Attributes = $file.Attributes -bor 32
# run the item under test, again
$specs | Backup-Updates | Out-Null
# check for the presence of the versions
# folder where it is not desirable
$folder = '.\Src\p\versions\th@.ps#\versions'
$t.AssertEqual(
    ( Test-Path $folder ),
    $false
)

Remove-TestArtifact $artifacts > $null

$t = $null