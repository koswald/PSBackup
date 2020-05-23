using Module PrivilegeChecker
using Module IntegrationTester
using namespace System.Security.Principal

if( $IsLinux -or $IsMacOS )
{
    exit
}

$identity = [WindowsIdentity]::GetCurrent()
$principal = [WindowsPrincipal]::new( $identity )
$adminRole = [WindowsBuiltInRole]::Administrator
$privileged = $principal.IsInRole($adminRole)

$t = [IntegrationTester]::new()

$t.describe( 'PrivilegeChecker' )

$t.it( 'should get whether privileges are elevated' )
$pc = [PrivilegeChecker]::new()
$t.AssertEqual(
    ( $pc::PrivilegesAreElevated() ),
    $privileged
)
