# Test Backup.ps1

using Module IntegrationTester
$t = [IntegrationTester]::new()
$PSScriptRoot | Set-Location

$t.describe( 'Backup.ps1' )

$t.it( 'should test')

$t.AssertEqual( 1, 2 )