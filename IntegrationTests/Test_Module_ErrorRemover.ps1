# ErrorRemover module test

# The purpose of the ErrorRemover is to remove an error from the $global:Error ArrayList, if necessary, in order to reliably use its Count property to determine whether an error occurred. If the ArrayList is at capacity, and an error occurs, then the count will not change.

# This test fills the $global:Error System.Collections.ArrayList to capacity and then tests whether the ErrorRemover can be used to "catch" an error using $global:Error.Count.

using Module ErrorRemover
using Module IntegrationTester

$t = [IntegrationTester]::new()
$remover = [ErrorRemover]::new()

$t.describe('ErrorRemover')

$t.it( 'should remove an error' )
if( $global:MaximumErrorCount ) {
    $max =$global:MaximumErrorCount
} else {
    $max = 256 #the default
}

# fill $global:Error with errors
foreach( $k in 1..$max )
{
    $null.ToString()
}
# call the method under test
$remover.RemoveError() | Out-Null
$remover = $null
# check results
$t.ignoreError = $true
$t.AssertEqual(
    $global:Error.Count,
    ( $max - 1 )
)
