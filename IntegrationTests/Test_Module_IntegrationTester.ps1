# IntegrationTester module test

# Expected outcome includes
# 3 fail
# 1 error

using Module IntegrationTester

$t = [IntegrationTester]::new()

$t.describe('IntegrationTester')

$t.it('should pass [int] equality')
$t.AssertEqual(1, 1)

# Expected outcome:
# Result: fail
$t.it('should fail [int] inequality')
$t.AssertEqual(1, 2)

# Expected outcome:
# Result: pass
$t.it('should pass [string] equality')
$t.AssertEqual('aa', 'aa')

# Expected outcome:
# Result: fail
$t.it('should fail [string] inequality')
$t.AssertEqual('aa', 'bb')

# Expected outcome:
# Result: pass
$t.it('should pass [bool] equality' )
$t.AssertEqual($true, $true)

# Expected outcome:
# Result: fail
$t.it('should fail [bool] inequality')
$t.AssertEqual($true, $false)

# Expected outcome:
# Result: pass
$t.it( 'should verify expected error message' )
$null.ToString() # generate error
$t.AssertErrorMessage( '*cannot*call*method*on*null*expr*')

# Expected outcome:
# Result: error
# Err: ~ cannot call method on null-val expression
$t.it( 'should catch unexpected error' )
$null.ToString() # generate error
$t.AssertEqual(
    'actual value',
    'Expected Result: error. Expected Actual: same as Err. Expected Err: You cannot call a method on a null-valued expression. System.Management.Automation.RuntimeException at Test_Module_IntegrationTester.ps1:51.'
)
