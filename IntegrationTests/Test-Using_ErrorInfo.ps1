using Module ErrorInfo

"If there is a message in white, 'You cannot call a method on a null-valued expression', then the {bug-candidate} is not present."
"If there is an error message in red, 'Unable to find type [SomeType]', then the {bug-candidate} is present or the .psd1 file is invalid."

"Conclusion: Linux PowerShell is more strict in its parsing of the .psd1 files."

$ErrorActionPreference = 'SilentlyContinue'
$null.ToString()
$ErrorActionPreference = 'Continue'

[ErrorInfo]::new( $global:Error[0] )
