<#
.Synopsis
Error handling design pattern demo and test

.Description
Demonstrates various error handling design patterns. Runs tests in order to ensure that the patterns work with different powershell versions.

.Link
https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.errorrecord

.Link
https://powershellexplained.com/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/#psitem

.Link
https://vexx32.github.io/2019/01/31/PowerShell-Error-Handling/

#>
using namespace System.Management.Automation
using Module IntegrationTester
using Module ErrorRemover

$t = [IntegrationTester]::new()

$t.describe( 'DP1: Auto. variable $?')

    $t.it( 'should catch the error' )
    $er = $null
    $e = $null
    $giArgs = @{ Path = './NoSuch.txtxt'
                 ErrorAction = 'SilentlyContinue'
                 ErrorVariable = 'er'}
    Get-Item @giArgs
    if( -Not $? )
    {
        $e = $er[0]
    }
    $t.ignoreError = $true
    $t.AssertEqual(
        $e.Exception.GetType().Name,
        'ItemNotFoundException'
    )

$t.describe( 'DP2: ErrorVariable (EV)')

    $t.it( 'should catch the error' )
    $er = $null
    $e = $null
    $giArgs = @{ Path = './NoSuch.txtxt'
                 ErrorAction = 'SilentlyContinue'
                 ErrorVariable = 'er'}
    Get-Item @giArgs
    if( $null -ne $er )
    {
        $e = $er[0]
    }
    $t.ignoreError = $true
    $t.AssertEqual(
        $e.Exception.GetType().Name,
        'ItemNotFoundException'
    )

$t.describe( 'Design pattern 3: Try/Catch' )

# With this design pattern, note the ErrorAction 'Stop', without which the error may not be caught.

    $t.it( 'should catch the error' )
    $e = $null
    $giArgs = @{ Path = './NoSuch.txtxt'
                 ErrorAction = 'Stop' }

    try { Get-Item @giArgs } 

    catch  [ItemNotFoundException] { # or catch {
        $e = $_
    }
    $t.ignoreError = $true
    $t.AssertEqual(
        $e.Exception.GetType().Name,
        'ItemNotFoundException'
    )

$t.describe( 'DP4: EV, advanced function' )

    $t.it( 'should catch the error' )

    function Get-NoSuchItem
    {
        [CmdletBinding()]
        param( [string] $Path )
        return Get-Item -Path $Path
    }

    $er = $null
    $err = $null
    $GnsiArgs = @{ Path = './NoSuch2.txt'
                ErrorAction = 'SilentlyContinue'
                ErrorVariable = 'er' }
    Get-NoSuchItem @GnsiArgs | Out-Null
    
    if( $null -ne $er )
    {
        $err = $er[0]
    }
    $t.ignoreError = $true
    $t.AssertEqual(
        $err.Exception.GetType().Name,
        'ItemNotFoundException'
    )

$t.describe( 'DP5: $global:Error')

    $t.it( 'should catch the error' )
    $initialCount = [ErrorRemover]::new().RemoveError()
    $e = $null
    $giArgs = @{ Path = '/NoSuch.txtxt'
                 ErrorAction = 'SilentlyContinue' }

    Get-Item @giArgs
    
    if( $global:Error.Count -gt $initialCount )
    {
        $e = $global:Error[0]
    }
    $t.ignoreError = $true
    $t.AssertEqual(
        $e.Exception.GetType().Name,
        'ItemNotFoundException'
    )

$t = $null