# for OrderedDictionary
using namespace System.Collections.Specialized
# for PSCustomObject, ErrorRecord, InvocationInfo
using namespace System.Management.Automation
# for Process
using namespace System.Diagnostics
# for Path
using namespace System.IO
using Module ErrorRemover

class IntegrationTester
{
    [OrderedDictionary] $result
    [ErrorRemover] $remover
    [int] $erCount
    [bool] $ignoreError

    # constructor
    IntegrationTester()
    {
        $this.remover = [ErrorRemover]::new()

        # initialize the test-result object

        $this.result = [OrderedDictionary]::new()
        $this.result.Add( 'Result', '' )
        $this.result.Add( 'Unit', '' )
        $this.result.Add( 'Spec', '' )
        $this.result.Add( 'Actual', '' )
        $this.result.Add( 'Expected', '' )
        $this.result.Add( 'Err', '' )

        # get the name and version of the PowerShell host

        [process] $proc = Get-Process -pid $global:pid
        $this.result.Add( 'Host', $proc.Name )

        $psvt = $global:PSVersionTable
        $this.result.Add( 'Version', $psvt.PSVersion.ToString() )
    }

    [void] ResetResult( [boolean] $full )
    {
         $this.result[ 'Result' ] = ''
         if( $full ) { $this.result[ 'Unit' ] = '' }
         $this.result[ 'Spec' ] = ''
         $this.result[ 'Actual' ] = ''
         $this.result[ 'Expected' ] = ''
         $this.result[ 'Err' ] = ''
    }
    [void] describe( [string] $unit )
    {
        $this.ResetResult( $true )
        $this.result.Unit = $unit
    }
    [void] it( [string] $spec )
    {
        $this.result.Spec = $spec
        $this.erCount = $this.remover.RemoveError()
        $this.ignoreError = $false
        $global:ErrorActionPreference = 'SilentlyContinue'
    }
    [PSCustomObject] AssertEqual( [object] $actual, [object] $expected )
    {
        $global:ErrorActionPreference = 'Continue'
        $this.result.Actual = $actual
        $this.result.Expected = $expected

        $newErCount = $global:Error.Count

        if($newErCount -gt $this.erCount -and
            -not $this.ignoreError )
        {
            $this.result.Result = 'error'
            [string] $msg = $this.GetErrMsg($global:Error[0])
            $this.result.Err = $msg
            $this.result.actual = $msg
        }
        elseif( $actual -eq $expected )
        {
            $this.result.Result = 'pass'
        }
        else
        {
            $this.result.Result = 'fail'
        }
        $return = [PSCustomObject] $this.result
        $this.ResetResult( $false )
        return $return
    }

    [PSCustomObject] AssertErrorMessage( [string] $filter )
    {
        $global:ErrorActionPreference = 'Continue'
        $newErCount = $global:Error.Count
        $this.result.Expected = $filter

        if( $newErCount -gt $this.erCount )
        {
            $err = $global:Error[0]
            $message = $err.Exception.Message
            $this.result.Actual = $message

            if( $message -like $filter )
            {
                $this.result.Result = 'pass'
            }
            else
            {
                $this.result.Result = 'fail'
            }
        }
        else
        {
            $this.result.Result = 'fail'
            $this.result.Actual = 'No error'
        }
        $return = [PSCustomObject] $this.result
        $this.ResetResult( $false )
        return $return
    }

    [string] GetErrMsg ( [ErrorRecord] $er )
    {
        return '{0} {1} at {2}:{3}.' -f @(
            $er.ToString()
            $er.Exception.GetType().FullName
            ( $er.InvocationInfo.ScriptName | Split-Path -Leaf )
            $er.InvocationInfo.ScriptLineNumber
         )
    }
}
