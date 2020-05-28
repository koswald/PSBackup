# Utility module test
using namespace System.IO
using Module IntegrationTester
Import-Module Utility -Force

$t = [IntegrationTester]::new()
$PSScriptRoot | Set-Location

# remove previous test folders, which if present may give false positive test results
function Remove-Artifacts
{
    param(
        [parameter( Mandatory = $true )]
        [string[]] $Artifacts,
        [int] $MaxTries = 100,
        [int] $msPause = 250 )

    $RemoveArgs = @{
        Recurse = $true
        Force = $true
        ErrorAction = 'SilentlyContinue' }
    $testArgs = @{
        ErrorAction = 'SilentlyContinue' }
        
    $i = 0
    foreach( $i in 1..$MaxTries ) {
        $fail = $false
        $Artifacts | ForEach-Object {
            if( Test-Path $_ @testArgs ) 
               { Remove-Item $_ @RemoveArgs }
            if( Test-Path $_ @testArgs )
               { $fail = $true }
        }
        if( -Not $fail ) { return $i }
        Start-Sleep -m $msPause
    }
    return - $i
}
$artifacts = @(
    './2560'
)
if(( Remove-Artifacts $artifacts ) -lt 0 ) {
    Throw "One or more test artifacts could not be removed. Test script {0} could not be run." -f ( $PSCommandPath | Split-Path -Leaf )
}

$t.describe( 'New-Folder' )

$t.it( 'should create a new folder' )
#ensure test folder does not exist
if( Test-Path './2560' )
    { Remove-Item -Path './2560' -Force -Recurse }
if( Test-Path './2560' )
    { throw 'Couldn''t delete folder ./2560' }
#create folder 2 deep
New-Folder './2560/2560a'
$t.AssertEqual(
    ( Test-Path './2560/2560a' ),
    $true
)

$t.it( 'should create parent folders' )
New-Folder '.2560/2560/2560/2560/2560'
$t.AssertEqual(
    ( Test-Path '.2560/2560/2560/2560/2560' ),
    $true
)
$t.describe( 'Test-Match' )

$t.it( 'shd ret. $false on null $wildcards' )
$isMatch = Test-Match `
    -Wildcards $null `
    -TestString 'test.txt'
$t.AssertEqual( $isMatch, $false )

$t.it( 'should return $true on match' )
$isMatch = Test-Match `
    -Wildcards @( '*.dll', '*.exe' ) `
    -TestString 'test.dll'
$t.AssertEqual( $isMatch, $true )

$t.it( 'should return $false on no match' )
$isMatch = Test-Match `
    -Wildcards @( '*.dll', '*.exe' ) `
    -TestString 'test.txt'
$t.AssertEqual( $isMatch, $false )

$t.describe( 'Get-FileName' )

$t.it( 'should get the file name' )
   $args = @{ Path = $PSCommandPath }
   $t.AssertEqual(
        ( Get-FileName @args ),
        'Test_Module_Utility.ps1'
    )

$t.describe( 'Get-FileBaseName' )

$t.it( 'should get a file''s base name' )
    $args = @{ Path = $PSCommandPath }
    $t.AssertEqual(
        ( Get-FileBaseName @args ),
        'Test_Module_Utility'
    )

$t.describe( 'Get-ScriptName' )

$t.it( 'should get the script name' )
   $t.AssertEqual(
       ( Get-ScriptName ),
       ( $PSCommandPath | 
            Split-Path -Leaf )
   )

$t.describe( 'Get-ScriptBaseName' )
$t.it( 'should get the script base name' )
   $t.AssertEqual(
       ( Get-ScriptBaseName ),
       ( [Path]::
           GetFileNameWithoutExtension(
               $PSCommandPath
           ))
   )

$t.describe( 'Convert-AsciiToChar' )

$t.it( 'should convert ascii to char')
    $chars = 191, 32 | Convert-AsciiToChar
    $t.AssertEqual(
        ( -join $chars ),
        "$([char][byte]'0191') "
    )
    
$t.describe( 'Convert-HexToChar' )

$t.it( 'should convert hex to char')
    $chars = 'BF', '20' | Convert-HexToChar
    $t.AssertEqual(
        ( -join $chars ),
        "$([char][byte]'0191') "
    )

if( 'Unix' -eq [Environment]::OSVersion.Platform )
{
    "Linux attributes section is under construction."
}

$t.describe( 'Clear-ArchiveBit' )

$t.it( 'should clear A bit (rel. path)' )
New-Item ./2560/2560a/new.txt | Out-Null
$file = Get-Item ./2560/2560a/new.txt
$attributes = $file.attributes
if( 32 -ne ($attributes -band 32 )) {
    $t = $null
    throw "Expected archive bit to be set"
}
Clear-ArchiveBit './2560/2560a/new.txt'
$file = Get-Item ./2560/2560a/new.txt
$attributes = $file.attributes
$t.AssertEqual(
    ( $attributes -band 32 ),
    0
)

$t.it( 'should clear A bit [IO.FileInfo]' )
if ( !( Test-Path ./2560/2560a/new.txt )) {
    New-Item ./2560/2560a/new.txt | Out-Null 
}
#set archive bit
Set-ItemProperty `
    -Path './2560/2560a/new.txt' `
    -Name attributes `
    -Value ( $attributes -bor 32 )
$attributes = ( Get-ItemProperty `
    ./2560/2560a/new.txt ).attributes
if(32 -ne ($attributes -band 32) ) {
    $t = $null
    throw "Expected archive bit to be set"
}
#get IO.FileInfo object
$item = Get-Item -Path './2560/2560a/new.txt'
Clear-ArchiveBit($item)
$attributes = (Get-ItemProperty `
    ./2560/2560a/new.txt).attributes
$t.AssertEqual(
    ( $attributes -band 32 ),
    0
)

$t.describe( 'Set-ArchiveBit' )

$t.it( 'should set A bit (rel. path)' )
if ( !( Test-Path ./2560/2560a/new.txt )) {
    New-Item ./2560/2560a/new.txt | 
        Out-Null
}
#clear archive bit
$attributes = ( Get-ItemProperty `
    ./2560/2560a/new.txt ).attributes
Set-ItemProperty `
    -Path './2560/2560a/new.txt' `
    -Name attributes `
    -Value ( $attributes -band -33 )
    # -33 = -bnot 32
Set-ArchiveBit './2560/2560a/new.txt'
$attributes = ( Get-ItemProperty `
    ./2560/2560a/new.txt ).attributes
$t.AssertEqual(
    ( $attributes -band 32 ),
    32
)

$t.it( 'should set A bit [IO.FileInfo]' )
#clear archive bit
Set-ItemProperty `
    -Path './2560/2560a/new.txt' `
    -Name attributes `
    -Value ( $attributes -band -33 )
    # -33 = -bnot -33
$attributes = ( Get-ItemProperty `
    ./2560/2560a/new.txt ).attributes
if( 0 -ne ( $attributes -band 32 ) ) {
    $t = $null
    throw "Expected archive bit to be clear"
}
#get IO.FileInfo object
$item = Get-Item -Path './2560/2560a/new.txt'
Set-ArchiveBit $item
$attributes = ( Get-ItemProperty `
    ./2560/2560a/new.txt ).attributes
$t.AssertEqual(
    ( $attributes -band 32 ),
    32
)
Remove-Artifacts $artifacts > $null
$t = $null