# Backup module test

using Module IntegrationTester
Import-Module Utility -Force
Import-Module Backup -Force

$PSCommandPath |
    Split-Path |
    Set-Location

# remove previous test folders, which if present may give false positive test results

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
    './Dest2'
    './Dest3'
    './Dest' )
if(( Remove-Artifacts $artifacts ) -lt 0 ) {
    Throw "One or more test artifacts could not be removed. Test script {0} could not be run." -f ( $PSCommandPath | Split-Path -Leaf )
}

# create fixture

# New-Item args
$Stop = @{ ErrorAction = 'Stop' }
@(
    @{ Path = './Src'; ItemType = 'Directory' }
    @{ Path = './Src/p'; ItemType = 'Directory' }
    @{ Path = './Src/p/one.ps1'; ItemType = 'File' }
    @{ Path = './Src/p/two.ps1'; ItemType = 'File' }
    @{ Path = './Src/p/three.ps1'; ItemType = 'File' }
    @{ Path = './Src/p/four.ps1'; ItemType = 'File' }
    @{ Path = './Src/b'; ItemType = 'Directory' }
    @{ Path = './Src/b/one.dll'; ItemType = 'File' }
) | ForEach-Object { 
    if( -Not ( Test-Path $_.Path @stop )) {
        New-Item @_ | Out-Null
    }
 }
 #clear archive bit(s)
@(
    './Src/p/one.ps1'
) | ForEach-Object {
    Clear-ArchiveBit ( Get-Item $_ ) @Stop
}
#backup folder(s)
$specs = @(
    @{ Src = './Src'
       Dest = './Dest'
       Include = '*'
       Subfolders = $true
       VersionsOnSrc = @(@{ Include = 'th*.ps?'; MaxQty = 11 })
       VersionsOnDest = @(@{ Include = 'f???.*' }) }
    @{ Src = './Src'; Dest = './Dest'; Include = '*' }
)

$initialOptimizeCalls = $BackupSpy.OptimizeCalls
$initialRemoveCalls = $BackupSpy.RemoveCalls
$specs | Backup-Updates

#begin tests
$t = [IntegrationTester]::new()

$t.describe( 'Backup-Updates' )

$t.it( 'should get input from the pipeline' )
    $t.AssertEqual(
        ( Test-Path './Dest/b/one.dll' ),
        $true
    )
    
$t.it( 'should copy a file' ) 
    $t.AssertEqual(
        ( Test-Path './Dest/b/one.dll' ),
        $true
    )
    
$t.it( 'should not copy a non-archived file' )
    $t.AssertEqual(
        ( Test-Path './Dest/p/one.ps1' ),
        $false
    )
    
$t.it( 'should reset archive bits' )
    $attr = ( Get-Item './Src/b/one.dll' ).attributes
    $t.AssertEqual(
        ( $attr -band 32 ),
        $false
    )
    
$t.it('should call function Optimize-SpecData')
    $t.AssertEqual(
        $BackupSpy.OptimizeCalls,
        ( $InitialOptimizeCalls + 2 )
    )

$t.describe( 'Optimize-SpecData' )

$t.it( 'should default to @( ) for Exclude' )
    $t.AssertEqual(
        ( $specs[1].Exclude ).Count,
        0
    )
    
$t.it( 'should default to $false for Subfolders' )
    $t.AssertEqual(
        $specs[1].Subfolders,
        $false
    )
    
$t.it( 'should default to $false for Force' )
    $t.AssertEqual(
        $specs[1].Force,
        $false
    )
    
# 'should Include'
# 'should exclude'
# 'should recurse'
# 'should fail to recurse'
# 'should force'
# 'should fail to force'

$t.describe( 'Backup-Version' )

$t.it( 'should backup a file version' )
    $Version = @{ Include = 'tw*.ps?'
        MaxQty = 3
    }
    $vArgs = @{ File = ( Get-Item './Src/p/two.ps1' )
        Version = $Version
    }
    Backup-Version @vArgs
    $GciArgs = @{ Path = './Src/p/versions/tw@.ps#'
        Filter = 'two_????-??-??--??????.ps1'
        File = $true
    }
    $items = Get-ChildItem @GciArgs
    
    # save the name/path
    $oldest = $items[0].FullName
    
    $t.AssertEqual(
        $items.Count,
        1
    )
    
$t.describe( 'Remove-ExcessVersions' )

$t.it( 'should remove excess versions' )
# create newer version files, in number greater or equal to $Version.MaxQty
    @(
        @{ Path = './Src/p/versions/tw@.ps#/two_YYYY-MM-DD--HHMM01.ps1'; ItemType = 'File' }
        @{ Path = './Src/p/versions/tw@.ps#/two_YYYY-MM-DD--HHMM02.ps1'; ItemType = 'File' }
        @{ Path = './Src/p/versions/tw@.ps#/two_YYYY-MM-DD--HHMM03.ps1'; ItemType = 'File' }
        @{ Path = './Src/p/versions/tw@.ps#/two_YYYY-MM-DD--HHMM04.ps1'; ItemType = 'File' }
    ) | ForEach-Object {
        New-Item @_ > $null
    }
    Remove-ExcessVersions @vArgs
    $items = Get-ChildItem @GciArgs
    $t.AssertEqual(
        $items.Count,
        $Version.MaxQty
    )
    
$t.it( 'should remove the oldest version(s)' )
    $t.AssertEqual(
        ( Test-Path $oldest ),
        $false
    )

$t.describe( 'Backup-Updates' )

$t.it( 'should err on wrong source' )
    $e = @{ Name = 'Should err on wrong source!'
             Src = './NonExistent'
             Include = '*'
             Dest = './Dest'
    } | Backup-Updates
    $t.AssertErrorMessage( '*not*on*disk*skipping*' )

$t.it( 'should err on overwrite read-only' )
    # set RO bit on target file
    $file  = Get-Item './Dest/b/one.dll'
    $file.Attributes = $file.Attributes -bor 1
    # set A bit on source file
    $file = Get-Item './Src/b/one.dll'
    $file.Attributes = $file.Attributes -bor 32
#    $t.ignoreError = $true
    $e = @{ Name = 'Should err on overwrite...'
            Src = './Src/b'
            Dest = './Dest/b'
            Include = '*.dll'
            Subfolders = $true
    } | Backup-Updates -EA 'SilentlyContinue'
    $t.AssertErrorMessage( "*unauthorized*either*clear*or*else*" )

$t.it( 'should save version on source' )
    $items = Get-ChildItem `
        -Path './Src/p/versions/th@.ps#' `
        -Filter 'three_????-??-??--??????.ps1' `
        -File
    $t.AssertEqual(
        $items.Count,
        1
    )

$t.it( 'should save version on destination' )
    $items = Get-ChildItem `
        -Path './Dest/p/versions/f###.@' `
        -Filter 'four_????-??-??--??????.ps1' `
        -File
    $t.AssertEqual(
        $items.Count,
        1
    )
    
$t.it( 'should call remove for each save call' )
    $t.AssertEqual(
        ( $BackupSpy.RemoveCalls - $initialRemoveCalls ),
        3
    )
    
# clear RO bit on target file
$file  = Get-Item './Dest/b/one.dll'
$file.Attributes = $file.Attributes -band -bnot 1

$t.it( 'should not save a version of a version' )
# set archive bit
$file = Get-Item './Src/p/three.ps1'
$file.Attributes = $file.Attributes -bor 32
# run the item under test
$specs | Backup-Updates | Out-Null
# check for the presence of the versions
# folder where it is not desirable
$folder = './Src/p/versions/th@.ps#/versions'
$t.AssertEqual(
    ( Test-Path $folder ),
    $false
)

$t.it( 'should set a default MaxQty' )
$default = $specs[0].VersionsOnDest[0].MaxQty
$t.AssertEqual(
    $default,
    5
)

$t.describe( 'Copy-FSItem' )
$t.it( 'should copy' )
$spec2 = @{
     Src = './Src'
     Dest = './Dest2'
     Subfolders = $true }
$spec2 | Copy-FSItem
$gciArgs = @{
    Path = './Dest2'
    File = $true
    Recurse = $true }
$items = Get-ChildItem @gciArgs
$t.AssertEqual(
    ( $items.Count -ge 9 ),
    $true
)

<#
$t.describe( 'Copy-Here' )
$t.it( 'should copy' )
$spec3 = @{
     Src = './Src'
     Dest = './Dest3'
     Subfolders = $true }
$spec3 | Copy-Here
$gciArgs = @{
    Path = './Dest3'
    File = $true
    Recurse = $true }
$items = Get-ChildItem @gciArgs
$t.AssertEqual(
    ( $items.Count -ge 9 ),
    $true
)
#>

Remove-Artifacts $artifacts > $null

$t = $null