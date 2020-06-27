<#
.Synopsis
Backs up changed files.

.Description
Backup.ps1 backs up new and changed files based on hashtable settings. The hashtable(s) may be kept in a separate .ps1 file or passed in as a parameter.

Multiple backup specifications are stored in an array of hashtables.

Each hashtable specification or "spec" supports the following:
- Source and destination folders,
- multiple wildcard include filters,
- multiple wildcard exclude filters,
- option to force overwrite of read-only files, and
- settings for saving versions of files.

In-console progress bars show per-spec progress and overall progress. The progress bars may not appear in the VS Code Integrated Console.

Run Get-Help Backup-Updates -Detailed for hashtable syntax, features and examples. Run Get-Help ./Backup.ps1 -Full for full help on this script, including parameters.

.Parameter SpecFile
A filespec pointing to a file containing the backup specifications, or "specs." The file consists of an array of hashtables assigned to a variable named $specs. The hashtables contain the specifications for what folders and files will be backed up.

- The file must have the .ps1 extension, and 
- The array of hashtables must be assigned to the variable $specs.

Either this parameter or the Specs parameter must be specified. Run Get-Help Backup-Updates -Detailed for hashtable requirements.

.Parameter Specs
An array of hashtables containing backup specifications. Either this parameter or the SpecFile parameter must be specified. Run Get-Help Backup-Updates -Detailed for hashtable requirements.

.Parameter DontOpenReport
A boolean that determines whether the report file is opened after the backup operation has completed. The default is $false: By default, the report will open if files were copied or if there were errors.

.Parameter ShowSpecs
A boolean that determines whether the hashtable specification(s) are shown on the console. The default is $false.

.Parameter Title
Specifies the title of the output html document and its h1 header contents in the body. Default is Backup report.

.Parameter CssFile
Specifies the .css file for formatting the report. Optional. The default is table.css. The tables may be difficult to read without formatting, but if Setup.ps1 is run, a suitable table.css will be placed in the default log/report folder automatically.

.Parameter Properties
A hashtable containing the type names and corresponding properties to include in the report file. The default looks something like this:

    @{ 
        FileInfo = @(
            'Name'
            'LastWriteTime'
            'Length'
            'DirectoryName'
        )
        ErrorInfo = @(
            'Message'
            'ScriptName'
            'LineNumber'
            'ExceptionFullName'
        )
        ErrorRecord = @(
            'Exception.Message'
            'InvocationInfo.ScriptName'
            'InvocationInfo.ScriptLineNumber'
            'Exception.GetType().FullName'
            'TargetObject'
            'CategoryInfo.Category'
            'ScriptStackTrace'
            'FullyQualifiedErrorId'
            'Exception.GetType().Name'
            'Exception.ToString()'
        )
    }

    If an object in pipeline has a type name that is not specified in the Properties parameter, except for [string], then the top-level properties returned by Get-Member -MemberType Property will be logged. in general, ErrorRecord objects are sent to the error stream and are not logged. ErrorInfo objects are sent to the success stream, and so they are also logged.
    
.Parameter PassThru
Determines whether to resend objects down the pipeline. Default is $false. If $true, objects continue down the pipeline as well as being sent to the html file. If PassThru is $true, the progress bar may flicker. Alias: pt.

.Parameter NoFrills
Simply does the backup. No Html log file is generated. No overall progress is shown. No hashtables are written to the console. Either the SpecFile parameter or else the Specs parameter will be used to input the backup specifications; other parameters will be ignored. Alias: nf.

.Link
Get-Help Out-Html [ -Detailed | -Full ]
.Link
Get-Help about_Backup
.Link
Get-Help about_PSBackup
#>

using namespace System.Collections
using namespace System.Text
using Module ErrorInfo
#Requires -Module Backup

[CmdletBinding( 
  DefaultParameterSetName = 'SpecFile' )]

param(
    [parameter( Position = 0,
        ParameterSetName = 'SpecFile',
        Mandatory = $true )]
    [string] $SpecFile,

    [parameter( Position = 0,
        ParameterSetName = 'Specs',
        Mandatory = $true )]
    [Hashtable[]] $Specs,

    [switch] $DontOpenReport = $false,

    [switch] $ShowSpecs = $false,

    [string] $Title = "Backup report",

    [string] $CssFile = 'table.css',

    [Hashtable] $Properties = @{ 
        FileInfo =@(
            'Name'
            'LastWriteTime'
            'Length'
            'DirectoryName'
        )
        ErrorInfo = @(
            'Message'
            'ScriptName'
            'LineNumber'
            'ExceptionFullName' 
        )
        ErrorRecord = @(
            'Exception.Message'
            'InvocationInfo.ScriptName'
            'InvocationInfo.ScriptLineNumber'
            'Exception.GetType().FullName'
            'TargetObject'
            'CategoryInfo.Category'
            'ScriptStackTrace'
            'FullyQualifiedErrorId'
            'Exception.GetType().Name'
            'Exception.ToString()'
        )
    },

    [alias( 'pt' )]
    [switch] $PassThru = $false,

    [alias( 'nf' )]
    [switch] $NoFrills = $false
)
# check platform

if( 'Win32NT' -eq [Environment]::OSVersion.Platform )
{
    $LogFolder = "$env:AppData\PSBackup\logs"
}
else
{
    $LogFolder = "$home/.local/share/PSBackup/logs"
    "Only Windows is supported at this time."
    Exit
}

# basic definitions

$silent = @{ ErrorAction = 'SilentlyContinue' }
$scriptName = Get-ScriptName

if( 'SpecFile' -eq $PSCmdlet.ParameterSetName )
{
    # check for missing spec file

    if( -Not ( Test-Path $SpecFile @silent ))
    {
        "`$PWD = $PWD"
        throw "{0} `"{1}`". {2} {3}." -f @(
            "Can't find the specifications file"
            $SpecFile
            $scriptName
            "cannot continue"
        )
    }
    # load backup specifications from file

    . ( Get-Item $SpecFile ).FullName
}

$stopOnErr = @{ ErrorAction = 'Stop' }

if ( $NoFrills )
{
    $specs |  Backup-Updates @stopOnErr
    exit
}

# prepare the report file

$scriptBaseName = Get-ScriptBaseName
$friendlyDatestamp = Get-Datestamp
$datestamp = Get-Datestamp -ForFileName
$fileName = "$scriptBaseName-$datestamp.htm"
$outfile = "$LogFolder/$fileName"
New-Folder $LogFolder
if( -Not ( Test-Path $LogFolder/$CssFile ))
{
    Copy-Item -Path $PSScriptRoot/$CssFile -Destination $LogFolder
}
$reportFileArgs = @{
    OutFile = $outfile
    Title = $title
    Body = "{0}`n{1}" -f @(
       "<h1> $title </h1>"
       "<h4> $friendlyDatestamp </h4>"
    )
    CssUri = $CssFile
    Properties = $Properties
    PassThru = $PassThru
}
$oc = @{ Count = 0; CountByType = @{} } # object/file count
    
function Convert-SpecToString( $spec, $keys, $sb ) {
    $sb.Append( "`n@{" ) > $null
    foreach( $key in $keys ) {
        if( $null -eq $spec.$key ) 
        {
            continue # to next $key
        }
        if( 'Object[]' -eq $spec.$key.GetType().Name )
        {
            # this value is an array: of strings or of hashtables
            $sb.Append(( Convert-ArrayToString $key $spec.$key $sb )) > $null
        }
        else
        {
            $sb.Append(("`n    {0} = `"{1}`"" -f $key, $spec.$key )) > $null
        }
    }
    $sb.Append( " `n}" ) > $null
}
function Convert-ArrayToString( $name, $objects, $sb )
{
    $sb.Append(( "`n    $name = @( " )) > $null
    $i = 1
    foreach( $object in $objects )
    {
        if( 'string' -like $object.GetType() )
        {
            # object is a string

            $sb.Append( "`"$object`"" ) > $null
            if( $i -eq $objects.Count )
                { $sb.Append( ' ' ) > $null }
            else { $sb.Append( ', ' ) > $null }
        }
        else # object is assumed to be a hashtable
        {
            $sb.Append( "@{ " ) > $null
            $j = 1
            foreach( $key in $object.keys )
            {
                $sb.Append(( "{0} = `"{1}`"" -f $key, $object.$key )) > $null
                if( $j -eq $object.keys.Count )
                     { $sb.Append( ' ' ) > $null }
                else { $sb.Append( '; ' ) > $null }
                $j++
            }
            if( $i -eq $objects.Count )
                 { $sb.Append( '} ' ) > $null }
            else { $sb.Append( '}, ' ) > $null }
        }
        $i++
    }
    $sb.Append( ")" ) > $null
}
if( $ShowSpecs )
{
    # display specsheet hashtables with keys listed in this order:

    $keys = @( 'Name', 'Src', 'Dest'
               'Include', 'Exclude'
               'Subfolders', 'Force'
               'VersionsOnSrc', 'VersionsOnDest' )
    $sb = [System.Text.StringBuilder]::new()
    foreach( $spec in $specs )
    {
        Convert-SpecToString $spec $keys $sb
    }
    $sb.ToString()
}

$specs | ForEach-Object -Begin {
    $i = 1
} -Process {
    $progressArgs = @{
        Activity = "Overall backup progress"
        Status = "Specsheet $i of $($specs.Count)"
        PercentComplete = Optimize-Percent (
            ($i - 1)/$($specs.Count)*100
        )
    }
    Write-Progress @progressArgs
    
    if( 'SpecFile' -eq $PSCmdlet.ParameterSetName )
    {
        # pass specfile to module for possible error message
        $_.SpecFile = $SpecFile
    }

    # Save spec info for the error message, because after error, $_ will represent the [ErrorRecord].
    $spec = $_ 

    try { Backup-Updates $_ @stopOnErr }

    catch
    {
        [ErrorInfo]::new( $_ )
        "Error context: Spec name: '$($spec.Name)'; Spec source folder: '$($spec.Src)'."
        "Script stack trace: $($_.ScriptStackTrace)"
        if( -Not ( $null -eq $spec.FileInfo ))
        {
            "File: $($spec.FileInfo.FullName)"
        }
    }
    $i++

} -End {
    $progressArgs = @{
        Activity = "Overall backup progress"
        Status = "Complete"
        PercentComplete = 100 }
    Write-Progress @progressArgs
    Start-Sleep -Seconds 3

} | Measure-PipedObjects -Counter $oc |
    Out-Html @reportFileArgs

if ( 0 -eq $oc.Count ) {

    "$(Get-ScriptName): No files were backed up and no errors occurred."
    # remove the header-only report file
    $silent = @{ ErrorAction = 'SilentlyContinue' }
    Remove-Item $outfile @silent

} elseif( -Not $DontOpenReport ) {

    "`nObjects counted by type:"
    $oc.CountByType
    # open the report file
    Invoke-Item $outfile
}
