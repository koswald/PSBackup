# ErrorRemover module test

# The purpose of the ErrorRemover is to remove an error from the $global:Error ArrayList, if necessary, in order to reliably use its Count property to determine whether an error occurred. If the ArrayList is at capacity, and an error occurs, then the count will not change.

using Module ErrorRemover
using Module IntegrationTester

$t = [IntegrationTester]::new()

$t.describe('ErrorRemover')

$t.it( 'should remove an error' )
if( $global:MaximumErrorCount )
    { $max =$global:MaximumErrorCount }
else { $max = 256 } #the default

# fill $global:Error with errors
foreach( $k in 1..$max )
{
    $null.ToString()
}
# call the function under test
$remover = [ErrorRemover]::new()
$remover.RemoveError() | Out-Null
$remover = $null
# check results
$t.ignoreError = $true
$t.AssertEqual(
    $global:Error.Count,
    ( $max - 1 )
)
