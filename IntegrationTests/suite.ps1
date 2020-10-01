# run test suite
#Requires -Module Utility

param( [string] $Filter = 'Test_*' )

# get all files in the folder where this file is

$PSScriptRoot | Set-Location
$gciArgs = @{ Path = '.'
              Filter = '*'
              Recurse = $false
              File = $true }
$files = Get-ChildItem @gciArgs

# list and count the test files

"Test files found:"
$i = 0
foreach( $file in $files )
{
    if( $file.Name -like $Filter )
    {
        "$($file.Name)"
        $i++
    }
}
"Test file count: $i"

# run the tests

$global:s = $null
foreach( $file in $files )
{
    if( $file.Name -like $Filter )
    {
        # run each test and add the output objects to a global variable

        $global:s += . .\$($file.Name)
    }
}

# show fails and errors (saved to global $e)

$global:e = $global:s | Where-Object {
    'error' -eq $_.Result -or
    'fail' -eq $_.Result
}
$global:e | Format-List

# show complete results (saved to global $s)

$global:s | Format-Table
