using namespace System.Collections

function Set-ArchiveBit
{
    <#
        .Synopsis
        Sets the archive bit on a file.

        .Description
        Sets the archive bit on a file. The file may be either a relative path [string], a full path [string], or a [System.IO.FileInfo] object returned by the Get-Item cmdlet, as in Get-Item ".\MyFile.txt".
    #>
    param(
        [parameter()]
        [object] $File )

    if ( $null -eq $File.FullName )
    {
        # convert [string] to [FileInfo]
        $File = Get-Item $File
    }
    $File.attributes = $File.attributes -bor 32
}

function Clear-ArchiveBit
{
    <#
        .Synopsis
        Clears the archive bit on a file.
        
        .Description
        Clears the archive bit on a file. The file may be either a relative path [string], a full path [string], or a [System.IO.FileInfo] object returned by the Get-Item cmdlet, as in Get-Item ".\MyFile.txt".
    #>
    param(
        [parameter()] [object] $file )
        
    if ( $null -eq $file.fullName )
    {
        # convert [string] to [FileInfo]
         $file = Get-Item $file
     }
    $file.attributes = $file.attributes -band -bnot 32
}

function New-Folder
{
    <#
        .Synopsis
        Creates a directory.
        
        .Description
        The New-Folder command creates a new folder and, if necessary, the parent folders too.
    #>
    param(
         [parameter( Mandatory = $true )]
         [string] $Path )
         
    if ( -Not ( Test-Path $Path ))
    {
        $NiArgs = @{
            Path = $Path
            ItemType = 'Directory'
            # Force creates parent directories if necessary
            Force = $true
        }
        New-Item @NiArgs  | Out-Null
    }
}

function Test-Match
{
    <#
        .Synopsis
        Tests for a match.

        .Description
        Tests a string for a match against an array of wildcards.

        .Parameter TestString
        A [string] to compare with the wildcard array.

        .Parameter Wildcards
        An array of wildcard strings ( [string[]] ). If the test string is like any of the wildcards, then $true is returned. Otherwise, $false is returned. If Wildcards is not specified, then $false is returned.
    #>
    param(
        [parameter( Mandatory = $true )]
        [string] $TestString,
        
        [parameter( Mandatory = $false )]
        [string[]] $Wildcards )

    if( $null -eq $Wildcards ) {
        return $false
    }
    if( 0 -eq $Wildcards.Count ) {
        return $false
    }
    foreach( $wildcard in $Wildcards )
    {
        if ( $testString -like $wildcard )  {
            return $true
        }
    }
    return $false
}

function Get-Datestamp
{
    <#
        .Synopsis
        Get a datestamp for "now".
        
        .Parameter ForFileName
        Set to $true to get a datestamp suitable for a filename. Default is $false.
    #>
    param(
        [Parameter()]
        [switch] $ForFileName = $false )
        
    if( $ForFileName ) {
        # file-name compatible
        $format = @{ UFormat = "%Y-%m-%d--%H%M%S" }
        
    } else { 
        # human read
        $format = @{ UFormat = "%m-%d-%Y %H:%M:%S" }
    }
    return Get-Date @format
}

function Get-FileName
{
    <#
        .Synopsis
        Gets a filename.
        
        .Description
        The Get-FileName command gets the filename from a path, including the extension.
        
        .Example
        Get-FileName 'C:\file.ext' # file.ext
    #>
    param(
        [parameter( Mandatory = $true )]
        [string] $Path )

    return $Path | Split-Path -Leaf
}

function Get-FileBaseName
{
    <#
        .Synopsis
        Gets a  file's base name.
        
        .Description
        The Get-FileBaseName command gets the filename from a path, excluding the extension.
        
        .Example
        Get-FileBaseName 'C:\file.ext' # file
    #>
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
    <#
        .Description
        Gets the name of the calling script, including the extension.
    #>
    $path = @{ 
        Path = $MyInvocation.ScriptName }
    return Get-FileName @path
}

function Get-ScriptFullName
{
    <#
        .Description
        Gets the full name of the calling script, including the path.
    #>
    return $MyInvocation.ScriptName
}

function Get-ScriptBaseName
{
    <#
        .Description
        Gets the name of the calling script, excluding the extension.
    #>
    $path = @{ Path = $MyInvocation.ScriptName }
    return Get-FileBaseName @path
}

function Measure-PipedObjects
{
    <#
        .Synopsis
        Counts pipeline objects.
            
        .Description
        The Measure-PipedObjects command counts pipeline objects. The count is returned via the Count property of the hashtable referenced by the Counter parameter. 
        Another object is returned with the Counter hashtable's CountByType property, showing how many of each object type were sent down the pipeline.

        .Parameter Counter
        A hashtable reference. Required. The Count property returns the object count. The CountByType returns a [PSCustomObject] showing how many of each object type were counted.
        
        .Inputs
        [System.Object]
        
        .Outputs
        [System.Object] Each input object is returned to the pipeline unchanged.
        Two values are returned via the hashtable that was passed in by reference. See the command description.
        
        .Example
        $ht = @{} # an empty hashtable assigned to a variable
        Get-Services | Measure-PipedObjects -Counter $ht
        "Services count: $( $ht.Count )"
    #>
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $false )]
        [Hashtable] $Counter
        ,
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [System.Object] $Object )
        
    Begin
    {
        $Counter.Count = 0 
        $cbt = @{}
    }
    Process
    {
        $Object #return object to the pipeline
        $Counter.Count++
        $type = $Object.GetType().FullName
        if( -Not $cbt.ContainsKey( $type ))
        {
            $cbt.Add( $type, 0 )
        }
        $cbt.$type++
    }
    End
    {
        $Counter.CountByType = [PSCustomObject] $cbt
    }
}

function Convert-AsciiToChar
{
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

    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [int16] $Ascii )
        
    Process { [char] [byte] $Ascii }
}

function Convert-HexToChar
{
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
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )] 
        [string] $Hex )
        
    Process { [char] [byte] "0x$Hex" }
}

function Out-Html
{
    <#
    .Synopsis
    Writes objects to an .html file.

    .Description
    Converts pipeline objects to an html file. Objects continue down the pipeline if and only if the PassThru switch parameter is used. Object properties to include may be selected using the Properties parameter. 

    For information about the parameters, type Get-Help Out-Html -Detailed.

    .Parameter InputObject
    The object(s) input from the pipeline.

    .Parameter Title
    Title of the html output file. 'Pipeline objects report' by default.

    .Parameter Body
    Html to insert after the <body> tag, "<h1> $Title </h1>" by default.

    .Parameter OutFile
    Output file. By default, 'out.htm'.

    .Parameter CssUri
    Uri for the .css file. By default, 'table.css'.

    .Parameter Encoding
    Optional. Default is 'ASCII'. Allowed values include ASCII, BigEndianUnicode, OEM, Unicode, UTF7, UTF8, UTF8BOM, UTF8NoBOM, and UTF32. Beginning in PowerShell 6.2, other values are allowed. For more information, see the documentation for Out-File.

    .Parameter Properties
    A hashtable that controls which properties are written to file. The keys are the object type names. Values are arrays of desired properties to include in the html file. See example below.

    .Parameter PassThru
    Determines whether to resend objects down the pipeline. Default is $false. If $true, objects are sent down the pipeline as well as being sent to the html file. Alias: pt.

    .Inputs
    .NET objects piped to this command are sent to an .html file. For types specified in the Properties parameter, only the specified properties are written to the file.

    .Outputs
    Input objects are not passed to the output unless -PassThru is specified.

    .Example
    Get-ChildItem | Out-Html

    .Example
    Get-ChildItem | Out-Html -Properties @{
        FileInfo = @(
            'Name'
            'Length'
        )
        DirectoryInfo = @(
            'Name'
            'CreationTime'
        )
    }
    #>
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [System.Object] $InputObject
        ,
        [string] $Title ='Pipeline objects report'
        ,
        [string] $Body = "<h1> $Title </h1>"
        ,
        [string] $OutFile = 'out.htm'
        ,
        [string] $CssUri = 'table.css'
        ,
        [string] $Encoding = 'ASCII'
        ,
        [Hashtable] $Properties
        ,
        [alias( 'pt' )]
        [switch] $PassThru = $false
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

        $html = [System.Text.StringBuilder]::new()
        [void] $html.Append('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' )
        [void] $html.Append( '{0}<html xmlns="http://www.w3.org/1999/xhtml">' -f "`n" )
        [void] $html.Append( '{0}<head> {1}<title> {2} </title> {3}<link rel="stylesheet" type="text/css" href="{4}" /> {5}</head>' -f @(
            "`n", "`n", $Title, "`n", $CssUri, "`n"
        ))
        [void] $html.Append( "`n<body>" )
        [void] $html.Append( $Body )

        $tableHasUnclosedTag = $false
        $previousType = [String]::Empty
        $loop = 1
    }
    Process
    {
        if( $PassThru )
        {
            # resend object to the pipeline
            $InputObject
        }
        # get the properties
        $type = $InputObject.GetType().Name
        if( 'String' -eq $type )
        {
            $props = @( 'String' )
        }
        elseif( $null -ne $Properties -And
            $Properties.ContainsKey( $type ))
        {
            # use only the specified properties
            $props = $Properties[$type]
        }
        else 
        {
            # use all available properties
            $props = $InputObject |
                Get-Member -MemberType 'Property' |
                    ForEach-Object { $_.Name }
        }
        if( $type -ne $previousType )
        {
            # this is a new or different type of object, so begin a new table

            if( $tableHasUnclosedTag )
            {
                # close the previous table
                [void] $html.Append( "`n</table>" )
            }
            # heading for the new table
            [void] $html.Append( "{0} {1} object(s): {2}" -f @(
                "<h2>", $type, "</h2>"
            ))

            # start to write the table
            [void] $html.Append( "`n<table>" )
            # start to write the header row
            [void] $html.Append( "`n<tr>" )

            foreach( $prop in $props )
            {
                # write a table header cell
                [void] $html.Append( '<th> {0} </th>' -f $prop )
            }
            # close the table header row
            [void] $html.Append( '</tr>' )
        }
       
        # write a table row for the current object
        
        # start the new row
        [void] $html.Append( "`n<tr>" )

        foreach( $prop in $props )
        {
           # write a single cell in the row
           
            if( 'String' -eq $type )
            {
                 [void] $html.Append( '<td> {0} </td>' -f $InputObject )
            }
            elseif( $prop.IndexOf( "." ) -gt 0 )
            {
                # multiple / nested properties
                
                $index = $prop.IndexOf( '.' )
                $prop1 = $prop.Substring( 0, $index )
                $prop2 = $prop.Substring( $index + 1, $prop.Length - $index - 1 )
                
                if( $prop2.IndexOf( '.' ) -gt 0 )
                {
                    # three levels of properties
                    
                    $index = $prop2.IndexOf( '.' )
                    $prop2a = $prop2.Substring( 0, $index )
                    $prop2b = $prop2.Substring(
                        $index + 1, $prop2.Length - $index - 1
                    )
                    if( 'GetType()' -like $prop2a )
                    {
                        [void] $html.Append( 
                            '<td> {0} </td>' -f $InputObject.$prop1.GetType().$prop2b
                         )
                    }
                    else
                    {
                        [void] $html.Append(
                            '<td> {0} </td>' -f $InputObject.$prop1.$prop2a.$prop2b
                        )
                    }
                }
                # two levels of properties
                
                elseif( 'ToString()' -like $prop2 )
                {
                    [void] $html.Append(
                        '<td> {0} </td>' -f $InputObject.$prop1.ToString()
                     )
                }
                elseif( 'GetType()' -like $prop2 )
                {
                    [void] $html.Append(
                        '<td> {0} </td>' -f $InputObject.$prop1.GetType()
                     )
                }
                else
                {
                    [void] $html.Append(
                        '<td> {0} </td>' -f $InputObject.$prop1.$prop2
                     )
                }
            }
           # end multiple-level properties
            else
            {
               [void] $html.Append( '<td> {0} </td>' -f $InputObject.$prop )
            }
            # continue to the next cell/property
        } # end foreach property
        # finish the row
        [void] $html.Append( '</tr>' )
        
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
            [void] $html.Append( "`n</table>" )
        }
        # close html
        [void] $html.Append( "`n</body>`n</html>" )

        $html.ToString() | Out-File @outArgs
    }
}

function Remove-TestArtifact
{
<#
    .Synopsis
    Removes test items.

    .Description
    Intended for removing test artifacts, such as files and folders created during a previous integration test, whose presence may invalidate a test.

    The return value is an integer that specifies the number of tries/passes/attempts/loops performed for each artifact. The value is positive if removal of all artifacts was successful, otherwise it is negative.

    .Parameter Artifacts
    [System.String[]]. Mandatory. One or more relative or absolute paths that specify the item(s) to be removed.

    .Parameter MaxTries
    [System.Int32]. Optional. Specifies the number of loops. For large and/or complex test fixtures, this number might need to be raised from the default, which is 10.

    .Parameter msPause
    [System.Int32]. Optional. Milliseconds pause after each loop. Default is 250.

    .Notes
    The developer's research indicates that the System.IO.FileInfo Delete() method is asynchronous, which is the reason for the loop pause.

    The Remove-Item cmdlet is not used. See issues/9246 link below.

    .Link
    https://github.com/PowerShell/PowerShell/issues/9246
#>
    param(
        [parameter( Mandatory = $true )]
        [string[]] $Artifacts
        ,
        [int] $MaxTries = 10
        ,
        [int] $msPause = 250
    )

    $testArgs = @{ ErrorAction = 'SilentlyContinue' }
    $k = 0
    foreach( $k in 1..$MaxTries )
    {
        $fail = $false
        foreach( $artifact in $Artifacts ) {
            if( Test-Path $artifact @testArgs ) 
            {
                Get-ChildItem $artifact -Recurse | ForEach-Object {
                    try { $_.Delete() }
                    catch { # Write-Host $_.Exception.Message -ForegroundColor Green
                    }
                }
                try { (Get-Item $artifact).Delete() }
                catch { # Write-Host $_.Exception.Message -ForegroundColor Magenta 
                }
            }
            if( Test-Path $artifact @testArgs ) 
            {
                $fail = $true
            }
        }
        if( -Not $fail )
        {
            return $k
        }
        Start-Sleep -Milliseconds $msPause
    }
    return - $k
}
