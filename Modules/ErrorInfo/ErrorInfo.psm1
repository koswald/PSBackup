using namespace System.Collections.Specialized # for OrderedDictionary
using namespace System.Management.Automation # for PSCustomObject, ErrorRecord, InvocationInfo
using namespace System.Diagnostics # for Process
using namespace System.IO # for Path

# ErrorInfo class: an object based on ErrorRecord

class ErrorInfo
{
    [string] $Message
    [string] $ScriptName
    [string] $LineNumber
    [string] $ExceptionName
    [string] $ExceptionFullName
    
    # constructor #1
    ErrorInfo( [ErrorRecord] $er )
    {
        $this.Init( $er )
    }
    
    # constructor #2
    ErrorInfo( [ErrorRecord] $er, [String] $message )
    {
        $this.Init( $er, $message )
    }
    
    hidden Init( [ErrorRecord] $er )
    {
        [Exception] $exc = $er.Exception
        
        $this.Message = $exc.Message
        $this.ExceptionName = $exc.GetType().Name
        $this.ExceptionFullName = $exc.GetType().FullName

        [InvocationInfo] $info = $er.InvocationInfo
            
        $this.ScriptName = [Path]::
            GetFileName( $info.ScriptName )
        $this.LineNumber =$info.ScriptLineNumber
    }
    
    hidden Init( [ErrorRecord] $er, [String] $message )
    {
        $this.Init( $er )
        $this.Message = "{0} {1}" -f @(
            $this.Message
            $message
        )
    }
}