using namespace System.Collections

function Set-ArchiveBit
{
    param(
        [parameter()]
        [object] $file )

        if ( -Not $file.fullName )
        # convert relative path [string]
        # to [System.IO.FileInfo]
        { $file = Get-Item $file }

    $file.attributes = $file.attributes -bor 32

    <#
    .Synopsis
    Sets the archive bit on a file
    .Description
    Sets the archive bit on a file. The file may be either a relative path [string], a full path [string], or a [System.IO.FileInfo] object returned by the Get-Item cmdlet, as in Get-Item "./MyFile.txt".
    #>
}

function Clear-ArchiveBit
{
    param(
        [parameter()] [object] $file )
        
    if ( -Not ( $file.fullName ))
        # convert relative path [string]
        # to [System.IO.FileInfo]
        { $file = Get-Item $file }
        
    $file.attributes =
        $file.attributes -band -bnot 32

    <#
    .Synopsis
    Clears the archive bit on a file
    .Description
    Clears the archive bit on a file. The file may be either a relative path [string], a full path [string], or a [System.IO.FileInfo] object returned by the Get-Item cmdlet, as in Get-Item "./MyFile.txt".
    #>
}

function New-Folder
{
    param(
         [parameter( Mandatory = $true )]
         [string] $Path )
         
    if ( -Not ( Test-Path $Path ))
    {
        $NiArgs = @{
            Path = $Path
            ItemType = 'Directory' }
        New-Item @NiArgs  | Out-Null
    }
}

function Test-Match
{
    param(
        [parameter( Mandatory = $true )]
        [string] $TestString,
        [parameter( Mandatory = $false )]
        [string[]] $Wildcards )

    if( $null -eq $Wildcards )
        { return $false }
    if( 0 -eq $Wildcards.Count )
        { return $false }

    foreach( $wildcard in $Wildcards )
    {
        if ( $testString -like $wildcard ) 
            { return $true }
    }
    return $false
}

function Get-Datestamp
{
    param(
        [Parameter()]
        [switch] $ForFileName = $false )
        
    if( $ForFileName )
        { $format = @{ UFormat =
            "%Y-%m-%d--%H%M%S" }}
            
    else { $format = @{ UFormat =
            "%m-%d-%Y %H:%M:%S" }}

    return Get-Date @format
}

function Get-FileName
{
    param(
        [parameter( Mandatory = $true )]
        [string] $Path )

    return $Path | Split-Path -Leaf
}

function Get-FileBaseName
{
    param(
        [parameter( Mandatory = $true )]
        [string] $Path )

    $ver = $PSVersionTable.
        PSVersion.Major
    if( $ver -ge 6 ) {
        return $Path | Split-Path -LeafBase
    } else {
        return [System.IO.path]::
          GetFileNameWithoutExtension( 
              $Path )
    }
}

function Get-ScriptName
{
    $path = @{ 
        Path = $MyInvocation.ScriptName }
    return Get-FileName @path
}

function Get-ScriptFullName
{
    return $MyInvocation.ScriptName
}

function Get-ScriptBaseName
{
    $path = @{ 
        Path = $MyInvocation.ScriptName }
    return Get-FileBaseName @path
}

function Measure-PipedObjects
{
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $false )]
        [Hashtable] $Counter,
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [System.Object] $Object )
        
    Begin
    {
        # "`$MyInvocation.PipelineLength: $($MyInvocation.PipelineLength)"
        $Counter.Count = 0 
        $cbt = @{}
    }
    Process
    {
        $Object #return object to the pipeline
        $Counter.Count++
        $type = $Object.GetType().Name
        if( -Not $cbt.ContainsKey( $type ))
        {
            $cbt.Add( $type, 0 )
        }
        $cbt.$type++
    }
    End
    {
        $Counter.Add(
            'CountByType',
            [PSCustomObject] $cbt )
    }
<#
.Synopsis
Counts pipeline objects
    
.Description
Counts pipeline objects. The count is returned via the Count property of the hashtable referenced by the Counter parameter.
Another object is returned with the Counter hashtable's CountByType property, showing how many of each object type were sent down the pipeline.

.Parameter Counter
 A hashtable reference. Required. The Count property returns the object count.
 
 .Inputs
 [System.Object]
 
 .Outputs
 [System.Object] Each input object is returned to the pipeline unchanged.
Two values are returned via the hashtable that was passed in by reference. See the command description.
 
.Example
$aho = @{} # a hashtable object
Get-Services |
    Measure-PipedObjects -Counter $aho
"Services count: $( $aho.Count )"
#>
}

function Convert-AsciiToChar
{
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [int16] $Ascii )
        
    Process { [char] [byte] $Ascii }
    
<#
.Synopsis
Converts Ascii values to characters

.Inputs
[int] Ascii value(s), base 10

.Outputs
[char] character(s)

.Example
@( 42, 43 ) | Convert-AsciiToChar
Output:
*
+
#>
}

function Convert-HexToChar
{
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )] 
        [string] $Hex )
        
    Process { [char] [byte] "0x$Hex" }
    
<#
.Synopsis
Converts Hex byte to char

.Parameter Hex
A two-character string corresponding to an Ascii char. Can also be used as pipeline input.

.Inputs
Hex string(s)/byte(s) to be converted. See Parameter Hex.

.Outputs
char(s)

.Example
@( '2A', '2B' ) | Convert-HexToChar
Output:
*
+
#>
}

function Remove-Error
{
    if( $global:MaximumErrorCount )
        { $max =
            $global:MaximumErrorCount }
    else { $max = 256 } #the default
        
    while ( $global:Error.Count -ge $max ) {
        $global:Error.RemoveAt( 
            $global:Error.Count - 1 
         )
     }
     return $global:Error.Count
     
<#
.Synopsis
Makes room for another error.

.Description
Ensures that $global:Error.Count can be used to determine whether there was an error, by removing the oldest error when necessary.
Returns $global:Error.Count
#>
}

function Out-Html
{
<#
.Synopsis
Converts pipeline objects to an html report file.

.Description
Converts pipeline objects to an html file.

.Parameter PassThru
Determines whether to resend objects down the pipeline. Default is $false. If $tru, objects are sent down the pipeline as well as being sent to the html file. Alias: pt.

.Example
Get-ChildItem | Out-Html

.Example
Get-ChildItem | Out-Html -Properties @{
    FileInfo = @(
        'Name'
        'Length' )
    DirectoryInfo = @(
        'Name'
        'CreationTime' )}
#>
    param(
        [string] $Title =
            'Pipeline objects report',
        [string] $Body = 
            '<h1> Pipeline objects </h1>',
        [string] $OutFile = 'out.htm',
        [string] $CssUri = 'table.css',
        [string] $Encoding = 'ASCII',
        [Hashtable] $Properties,
        [alias( 'pt' )]
        [switch] $PassThru = $false,
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [System.Object] $Obj
    )
    Begin 
    {
        $outArgs = @{ 
            FilePath = $OutFile
            Append = $true
            Encoding = $Encoding }
        
        If ( Test-Path $outFile )
        {
            Clear-Content $outFile
        }

        # begin composing the HTML file

        $html = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
        $html += '{0}<html xmlns="http://www.w3.org/1999/xhtml">' -f "`n"
        $html += '{0}<head>{1}<title>{2}</title>{3}<link rel="stylesheet" type="text/css" href={4} />{5}</head>' -f @(
            "`n", "`n", $Title, "`n", $CssUri, "`n"
        )
        $html += "`n<body>"
        $html += $Body

        $tableHasUnclosedTag = $false
        $previousType = [String]::Empty
        $loop = 1
    }
    Process
    {
        if( $PassThru )
        {
            $Obj # resend input to the pipeline
        }
        $type = $obj.GetType().Name

        if( 'String' -eq $type )
        {
            $props = @( 'String' )
        }
        elseif( -Not $null -eq $Properties -and
            $Properties.ContainsKey( $type ))
        {
            $props = $Properties[$type]
        }
        else 
        {
            $props = $Obj |
                Get-Member -MemberType 'Property' |
                    ForEach-Object { $_.Name }
        }
        
        if( $type -ne $previousType )
        {

            if( $tableHasUnclosedTag )
            {
                # close previous table
                $html += "`n</table>"
            }

            $html +="{0} {1} object(s): {2}" -f @(
              "<h2>", $type, "</h2>"
            )
            
            # this is a new/different type of
            # object, so begin a new table
            
            # start to write the table
            $html += "`n<table>"
            # start to write the header row
            $html += "`n<tr>"

            foreach( $prop in $props )
            {
                # write a table header cell
                $html +='<th>{0}</th>' -f $prop
            }
            # close the table header row
            $html += '</tr>'
        }
       
        # write a table row for the current 
        # object
        
        # start the new row
        $html += "`n<tr>"

        foreach( $prop in $props )
        {
           # write a single cell in the row
           
            if( 'String' -eq $type )
            {
                 $html +='<td>{0}</td>' -f $Obj
            }
            elseif( $prop.IndexOf(".") -gt 0 )
            {
                $index = $prop.IndexOf('.')
                $prop1 = $prop.Substring(0, $index)
                $prop2 = $prop.Substring($index + 1, $prop.Length - $index - 1)
                
                if( $prop2.IndexOf('.') -gt 0 )
                {
                    # a property of a property of a property was specified
                    $index = $prop2.IndexOf('.')
                    $prop2a = $prop2.Substring(0, $index)
                    $prop2b = $prop2.Substring(
                            $index + 1, $prop2.Length - $index - 1)
                    if( 'GetType()' -like $prop2a )
                    {
                        $html += '<td>{0}</td>' -f $Obj.$prop1.GetType().$prop2b
                    }
                    else
                    {
                        $html += '<td>{0}</td>' -f $Obj.$prop1.$prop2a.$prop2b
                    }
                }
                elseif( 'ToString()' -like $prop2 )
                {
                    $html += '<td>{0}</td>' -f $Obj.$prop1.ToString()
                }
                elseif( 'GetType()' -like $prop2 )
                {
                    $html += '<td>{0}</td>' -f $Obj.$prop1.GetType()
                }
                else
                {
                    # a property of a property was specified
                    $html += '<td>{0}</td>' -f $Obj.$prop1.$prop2
                }
            }
            else
            {
               $html += '<td>{0}</td>' -f $obj.$prop
            }
            # finished writing one cell
            # continue to the next cell, if any
        }
        # finish the row
        $html += '</tr>'
        
        $tableHasUnclosedTag = $true
        $previousType = $type
        $loop++
    }
    End
    {
        # close previous table if applicable
        if( $tableHasUnclosedTag )
        {
            # close previous table
            $html += "`n</table>"
        }
        # close html
        $html += "`n</body>`n</html>"

        $html | Out-File @outArgs
    }
}
