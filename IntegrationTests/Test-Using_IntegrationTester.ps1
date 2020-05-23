using Module IntegrationTester

"If there is an error message in red, 'Unable to find type [SomeType]', then the {bug-candidate} is present or the .psd1 file is invalid, or the test failed for another reason"

$t = [IntegrationTester]::new()
