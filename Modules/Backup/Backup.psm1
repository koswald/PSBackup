using namespace System.Collections # for Hashtable, Generic.List, Generic.HashSet
using namespace System.Management.Automation # ItemNotFoundException, ErrorRecord
using namespace System.IO # for Path, Directory, DirectoryNotFoundException
using Module ErrorInfo
#Requires -Module Utility

function Copy-FSItem
{
    param
    (
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [Hashtable] $SpecSheet
    )
    Process
    {
        $ss = $SpecSheet
        if( ! ( Test-Path $ss.Src )) {
            Write-Error "Can't find $($ss.Src)"
            return
        }
        if( $null -eq $ss.Force )
        {
            $ss.Force = $false
        }
        if( $null -eq $ss.Include )
        {
            $ss.Include = '*'
        }
        if( $null -eq $ss.Subfolders )
        {
            $ss.Subfolders = $false
        }
        New-Folder $ss.Dest -ErrorAction 'Stop'

        $ciArgs = @{ Path = $ss.Src
                     Filter = $ss.Include
                     Destination = $ss.Dest
                     Recurse = $ss.Subfolders
                     Force = $ss.Force
                     ErrorAction = 'Continue' }
        Copy-Item @ciArgs
    }

    <#
    .Synopsis
    Copies a folder

    .Description
    Copies a folder. Suitable for bulk, unattended copy.

    .Parameter BackupSpec
    Hashtable(s) with the following key names
        Src
        Dest
        Include
        Subfolders
        Force
    Src and Dest are required.
    Subfolders and Force are $false by default.
    Include is * by default.

    .Example
    $BackupSpec1 = @{
        Src = "$home\MyData"
        Dest = "$home\OneDrive\Backups\MyData"
        Include = "*.txt"
        Subfolders = $true
    }
    $BackupSpec1 | Copy-FSItem

    .Inputs
    Backup specification hashtable(s)

    .Outputs
    None

    .Notes
    Uses the PowerShell Copy-Item Cmdlet.
    #>
}

function Copy-Here
{
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [alias( 'ss' )] [Hashtable] $SpecSheet
    )
    Process {
        $ss = $SpecSheet
        # relative path => absolute path
        $ss.Src = ( Get-Item $ss.Src ).FullName
        if( $null -eq $ss.Include )
        {
            $ss.Include = '*'
        }
        $prid = "Shell.Application"
        $app = New-Object -ComObject $prid
        New-Folder $ss.Dest > $null
        # relative path => absolute path
        $ss.Dest =
            ( Get-Item $ss.Dest ).FullName
        $folder = $app.Namespace($ss.Dest)
        $src = "{0}\{1}" -f $ss.Src, $ss.Include
        $folder.CopyHere( $src, 0 )
    }
    <#
    .Synopsis
    Copies a folder

    .Description
    Copies a folder based on hashtable specifications.
    Suitable for attended copy.
    If destination files already exist, the user is given an interface comparing source and destination file details and is given the option for individual file or bulk overwrite.

    .Parameter Spec
    Hashtable key names
        Src
        Dest
        Include

    .Example
    $folder1 = @{
        Src = "$env:AppData\MyData"
        Dest = "C:\Backups\AppData\MyData"
        Include = "*"
    }
    $folder1 | Copy-Here

    .Notes
    Uses the Windows-native Shell.Application CopyHere method, which includes a progress bar, requests for elevated privileges as necessary, and has other UI features such as requesting overwrite permission and applying user response to all items, if desired.
    #>
}

function Get-Progress( [Hashtable] $Spec )
{
    <#
    .Synopsis
    Calculate backup progress
    #>

    $x = $Spec.ProgressActual
    $y = $x/$Spec.ProgressExpected * 100
    $Spec.PercentComplete =
        Optimize-Percent( $y )
}

function Optimize-Percent( [Single] $x )
{
    <#
    .Synopsis
    Validate Write-Progress -PercentComplete
    #>

    if( $x -lt 0 )
    {
        return 0
    }
    elseif( $x -gt 100 )
    {
        return 100
    }
    else
    {
        return $x
    }
}

function Get-BackupFiles
{
    <#
    .Synopsis
    Returns the files to backup.

    .Description
    Returns the files to backup for one hashtable/spec.

    .Parameter Spec
    For hashtable requirements, see Get-Help Backup-Updates -Detailed.

    .Notes
    For internal use. Exported for testing.
    The validation function Optimize-SpecData is called before this one.
    #>
    param( [parameter( Mandatory )]
           [Hashtable] $Spec
           ,
           [switch] $IncludeNonarchived = $false )

    $gciArgs = @{
        Path = $Spec.Src
        Recurse = $Spec.Subfolders
        Filter = "*"
        Include = $Spec.Include
        Exclude = $Spec.Exclude
        Attributes = 'Archive'
        File = $true
        ErrorAction = 'Continue'
        ErrorVariable = 'er' }

    if( $IncludeNonarchived )
    {
        $gciArgs.Remove( 'Attributes' )
    }

    # Case 1: PowerShell Core root folder only.
    # Include and Exclude work only with Recurse of $true and Filter of '*', as with Windows PowerShell. But unlike Windows PowerShell, Depth of 0 prevents actual recurse.

    if( -Not $Spec.Subfolders -And
        $PSVersionTable.PSVersion.Major -ge 6 )
    {
        $gciArgs.Depth = 0
        $gciArgs.Recurse = $true
        $files = Get-ChildItem @gciArgs
    }

    # Case 2: Windows PowerShell root folder only.
    # Fltering must be custom, not by Get-ChildItem. See PowerShell Core note above.

    elseif( -Not $Spec.Subfolders )
    {
        $gciArgs.Remove('Include')
        $gciArgs.Remove('Exclude')
        $gciArgs.Recurse = $false

        # get a list of all archivable files in the root folder
        $list = [Generic.List[FileInfo]]::new()
        foreach( $file in Get-ChildItem @gciArgs )
        {
            $list.Add( $file )
        }

        # exclude
        foreach( $filterOut in $Spec.Exclude )
        {
            [Predicate[FileInfo]] $predicate = {
                param( [FileInfo] $fi )
                $fi.Name -like $filterOut
            }
            $list.RemoveAll( $predicate ) | Out-Null
        }

        # include
        $files = [Generic.HashSet[FileInfo]]::new()
        foreach( $filterIn in $Spec.Include )
        {
            foreach( $file in $list )
            {
                if( $file.Name -like $filterIn )
                {
                    $files.Add( $file ) | Out-Null
                }
            }
        }
    }

    # Case 3: Recurse

    else
    {
        $files = Get-ChildItem @gciArgs
    }

    return $files
}

function Get-CommonBackupPath
{
    <#
    .Description
    Gets the string common to source and destination, minus the trailing \, but including the leading \.

    .Parameter Spec
    The backup spec [Hashtable] $Spec with the source file's [FileInfo] object added as the File value.

    .Example
    # in function Backup-Updates
    $Src = $file.DirectoryName
    $Spec.File = $file
    $Dest = "{0}{1}" -f @(
        $Spec.Dest
        ( Get-CommonBackupPath $Spec )
    )

    .Notes
    Exported for testing only.
    #>

    param( [parameter( Mandatory = $true )]
           [Hashtable] $Spec )

    return $Spec.File.DirectoryName.Substring( $Spec.Src.Length )
}

function Optimize-SpecData
{
    <#
    .Synopsis
    Validate, expand, count, initialize

    .Notes
    Exported for testing only.
    #>

    param(
        [parameter( Mandatory = $true )]
        [Hashtable] $SpecSheet )

    $ss = $SpecSheet
    $ss.OptimizeError = $false
    if( $null -eq $ss.SpecFile )
    {
        $specFile = [string]::Empty
    }
    else
    {
        $specFile = "{0} '{1}'." -f @(
            " Spec file:"
            (Get-Item $ss.SpecFile).FullName )
    }

    # set default values

    if( $null -eq $ss.Name )
    {
        $ss.Name = 'Name not specified'
    }
    if( -Not ( $null -eq $ss.Filter ))
    {
        # throw error
        $ss.OptimizeError = $true
        $contextMessage = "The Filter key is not used. Use the Include key instead, which supports an array of wildcard filters. Remove the Filter key from '{0}'." -f $ss.Name
        $exc = [System.ArgumentException]::new()
        $localizedMessage = $exc.Message
        $message = "{0} {1}{2}" -f @(
            $localizedMessage, $contextMessage, $specFile )
        $errorRecord = [ErrorRecord]::new(
            [ArgumentException]::new( $message ),
            "FilterIsInvalidBackupSpecKeyUseInclude",
            [ErrorCategory]::InvalidArgument,
            $ss.Filter )
        $PSCmdlet.WriteError( $errorRecord )
        [ErrorInfo]::new( $errorRecord )
    }
    if( $null -eq $ss.Subfolders )
    {
        $ss.Subfolders = $false
    }
    if( $null -eq $ss.Include )
    {
        # throw error
        $ss.OptimizeError = $true
        $contextMessage = "The Include key is required. It accepts one or more wildcard expressions that are used to specify what files will be backed up for '{0}'." -f $ss.Name
        $exc = [ArgumentException]::new()
        $localizedMessage = $exc.Message
        $message = "{0} {1}{2}" -f @(
            $localizedMessage, $contextMessage, $specFile )
        $errorRecord = [ErrorRecord]::new(
            [ArgumentException]::new( $message ),
            "MissingBackupHashtableKeyInclude",
            [ErrorCategory]::InvalidArgument,
            $ss )
        $PSCmdlet.WriteError( $errorRecord )
        [ErrorInfo]::new( $errorRecord )
    }
    if( $null -eq $ss.Exclude )
    {
        $ss.Exclude = @()
    }
    if( $null -eq $ss.Force )
    {
        $ss.Force = $false
    }
    if( $null -eq $ss.VersionsOnSrc )
    {
        $ss.VersionsOnSrc = @()
    }
    else
    {
        foreach( $version in $ss.VersionsOnSrc )
        {
            if( $null -eq $version.MaxQty )
            {
                $version.MaxQty = $DefaultMaxVersionQty
            }
        }
    }
    if( $null -eq $ss.VersionsOnDest )
    {
       $ss.VersionsOnDest = @()
    }
    else
    {
        foreach( $version in $ss.VersionsOnDest )
        {
            if( $null -eq $version.MaxQty )
            {
                $version.MaxQty = $DefaultMaxVersionQty
            }
        }
    }
    if( $null -eq $ss.Src -or $null -eq $ss.Dest )
    {
        # throw error
        $ss.OptimizeError = $true
        $contextMessage = "The Src and Dest hashtable keys specify the root source folder and root target folder for backup spec '{0}'. Both of these keys are required. The source folder must exist." -f $ss.Name
        $exc = [ArgumentException]::new()
        $localizedMessage = $exc.Message()
        $message = "{0} {1}{2}" -f @(
            $localizedMessage, $contextMessage, $specFile )
        $errorRecord = [ErrorRecord]::new(
            [ArgumentException]::new( $message ),
            "MissingRequiredBackupSpecKey",
            [ErrorCategory]::InvalidArgument,
            $ss )
        $PSCmdlet.WriteError( $errorRecord )
        [ErrorInfo]::new( $errorRecord )
    }

    [Directory]::SetCurrentDirectory( $PWD )
    $ss.Src = [Path]::GetFullPath( $ss.Src )
    $ss.Dest = [Path]::GetFullPath( $ss.Dest )

    if ( -Not ( Test-Path $ss.Src ))
    {
        # signal the calling function
        # to skip this backup spec
        $ss.OptimizeError = $true

        # throw
        $contextMessage = "{0} '{1}'. {2}{3}" -f @(
            'Skipping backup spec'
            $ss.Name
            'Check source folder spelling.'
            $specFile
        )
        $exc = [DirectoryNotFoundException]::new()
        $message = "{0} {1}" -f @(
            $exc.Message # localized message
            $contextMessage )
        $errorRecord = [ErrorRecord]::new(
            [DirectoryNotFoundException]::new( $message ),
            "InvalidOrMissingBackupSourceFolder",
            [ErrorCategory]::ObjectNotFound,
            $ss.Src
        )
        $PSCmdlet.WriteError( $errorRecord )
        [ErrorInfo]::new( $errorRecord, $message )
    }
    $BackupSpy.OptimizeCalls++
}

function Backup-Updates
{
    param(
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [Hashtable] $SpecSheet
        ,
        [switch] $NoPassThru = $false
        ,
        [switch] $IncludeNonarchived = $false
    )
    Begin
    {
        $shh = @{ ErrorAction = 'SilentlyContinue' }
    }
    Process
    {
        $Spec = $SpecSheet
        # validate
        Optimize-SpecData $Spec @shh
        if( $Spec.OptimizeError )
        {
            return
        }

        $activity = "Backing up $($Spec.Name)"
        $status = "Counting files"
        $progressArgs = @{
            Activity = $activity
            Status = $status
            id = 1
            PercentComplete = 0 }
        Write-Progress @progressArgs

        # get child items
        $er = $null
        $gbfArgs = @{ Spec = $Spec
                      IncludeNonarchived = $IncludeNonarchived
                      ErrorAction = 'SilentlyContinue'
                      ErrorVariable = $er }
        $files = Get-BackupFiles @gbfArgs

        if ( -Not ( $null -eq $er ))
        {
            # ErrorRecord obj => error stream
            $PSCmdlet.WriteError( $er[0] )

            # ErrorInfo obj => success stream
            $message = "{0} {1}, {2}" -f @(
                "Failed to get child items."
                "Skipping folder '$($Spec.Dest)'"
                "backup spec '$($Spec.Name)'" )
            [ErrorInfo]::new( $er[0], $message )
            return
        }

        $Spec.ProgressExpected = $files.Count
        $Spec.progressActual = 0
        $status = "Searching for and copying archived files"

        foreach( $file in $files )
        {
            $Spec.ProgressActual++
            Get-Progress $Spec
            $progressArgs = @{ id = 1
                Activity = $activity
                Status = $status
                PercentComplete = $Spec.PercentComplete }
            Write-Progress @progressArgs

            $Src = $file.DirectoryName
            $Spec.File = $file
            $Dest = "{0}{1}" -f @(
                $Spec.Dest
                ( Get-CommonBackupPath $Spec )
            )

            $unforseenError = $null
            New-Folder $Dest
            $CopyArgs = @{ Path = $file.fullName
                           Destination = $Dest
                           Force = $Spec.Force
                           ErrorAction = 'Stop' }

            try { Copy-Item @CopyArgs }
            
            catch [UnauthorizedAccessException]
            {
                # Check that the cause of the UnauthorizedAccessException was that the target was read-only and Force was $false.
                $destFile = Get-Item ('{0}\{1}' -f @(
                    $Dest, $file.Name ))
                $destFileIsRO = [bool] ( $destFile.Attributes -band 1 )

                if( $destFileIsRO -and -not $Spec.Force )
                {
                    # throw
                    $exc = [UnauthorizedAccessException]::new()
                    $localMessage = $exc.Message
                    $action = "Could not overwrite the target file '{0}' because it is read-only. Either clear the read-only attribute on the source and target files, or else set Force to `$true for the backup spec named '{1}'." -f $destFile.FullName, $Spec.Name
                    $message = '{0} {1}' -f $localMessage, $action
                    $uaErrorRecord = [ErrorRecord]::new(
                        [UnauthorizedAccessException]::new( $message ),
                        'BackupTargetFileIsReadOnly',
                        [ErrorCategory]::PermissionDenied,
                        $destFile )
                    $PSCmdlet.WriteError( $uaErrorRecord )
                    [ErrorInfo]::new( $uaErrorRecord  )

                    continue # to the next file
                }
                else
                {
                    # an UnauthorizedAccessException occurred not caused by combination of read-only target and Force = $false
                    $unforseenError = $_
                }
            }
            catch
            {
                # some other exception occurred
                $unforseenError = $_
            }

            if( $null -ne $unforseenError)
            {
                # rethrow unforseenError
                $PSCmdlet.WriteError( $unforseenError )
                $context = '{0} {1} {2} {3} {4}' -f @(
                    "Copy error context:"
                    "Spec name: '$($Spec.Name)';"
                    "Source folder: '$Src';"
                    "Destination folder: '$Dest';"
                    "File: '$($file.Name)'." )
                [ErrorInfo]::new( $unforseenError, $context )

                continue # to the next file
            }

            if( $Spec.VersionsOnSrc.Count )
            {
                $TvArgs = @{ File = $file
                        Versions = $Spec.VersionsOnSrc }
                Test-Versions @TvArgs
            }
            if( $Spec.VersionsOnDest.Count )
            {
                $dFile ='{0}\{1}' -f $Dest, $file.Name
                $TvArgs = @{ File = Get-Item $dFile
                    Versions = $Spec.VersionsOnDest }
                $Spec.FileInfo = $TvArgs.File
                Test-Versions @TvArgs
            }
            if( $null -eq $Spec.DontResetArchiveBit -or
                $Spec.DontResetArchiveBit -eq $false )
            {
                Clear-ArchiveBit $file
            }
            # output object to the pipeline
            if( -Not ( $NoPassThru ))
            {
                $file
            }

        } # end foreach( $file ... )

    } # end Process

<#
    .Synopsis
    Backs up a folder

    .Description
    The Backup-Updates module backs up a folder's changed files based on hashtable settings.

    .Parameter SpecSheet
    [System.Collections.Hashtable[]] intended to be input from the pipeline or as a parameter.
    Required hashtable keys
        Src [string]
        Dest [string]
        Include [string]
    Recommended key
        Name [string]
    Optional keys
        Exclude [string[]]
        Subfolders [boolean]
        Force [boolean]
        VersionsOnSrc [Hashtable[]] (Experimental may cause unexpected recursion)
        VersionsOnDest [Hashtable[]]
        DontResetArchiveBit [boolean] (Experimental: may cause saved versions to be overwritten with identical versions)

    Src and Dest may be relative paths. Src and Dest correspond to the source and destination folders. The destination folder need not exist.

    Include is a single wildcard expression or an array of wildcard expressions specifying which files to backup.

    Exclude is an array of wildcard expressions specifying files to exclude, @() by default.

    Force is boolean, $false by default. It controls whether to overwrite read-only files.

    VersionsOnSrc (experimental - see project ReadMe.md/Issues) and VersionsOnDest are arrays of hashtables, for saving date-stamped versions of specified files. The key Include is required and accepts a single wildcard expression. The maximum number of version files kept is 5 by default. The default can be changed with the global variable $DefaultMaxVersionQty, and/or customized with the hashtable key MaxQty (see example). The default version folder name is 'versions' and can be changed with the global variable $VersionsFolderName. The subfolder name is autogenerated, and indicates which wildcard expression was used.

    DontResetArchiveBit (experimental - see project ReadMe.md/Issues) controls whether a source file's archive bit is cleared/reset after the copy operation. Default is $false/$null: the archive bit is cleared by default. Set to $true to retain the source file's archive bit in its set state after copying.

    .Example
    $SpecSheets = @(
        @{
            Name = "PowerShell Scripts"
            Src = "$home\MyPSScripts"
            Dest = "$home\OneDrive\Backups\MyPSScripts"
            Subfolders = $true
            Include = "*.ps*", "*.md", ".gitignore", "*.cs"
            Exclude = @( "*.dll", "*.exe" )
            VersionsOnDest = @(
                @{ Include = '*.txt' }, @{ Include = '*.ps1'}
                @{ Include = '*.psm1'; MaxQty = 20 }
            )
        }
        @{
            Name = "My ProgramData"
            Src = "$home\MyProg"
            Dest = "$home\Backups\MyProgData"
            Include = "*"
            Exclude = @("*.dll", "*.exe")
            Subfolders = $true
        }
    )
    $SpecSheets | Backup-Updates

    .Inputs
    System.Collections.Hashtable object(s).

    .Outputs
    System.IO.FileInfo object(s) for the source file for each file copied.
    [ErrorInfo] objects may be sent to the success pipeline.

    .Notes
    Calls the Update-Folder function for each hashtable.
#>
}

function Test-Versions
{
    <#
    .Synopsis
    Test a file and possibly save a version.

    .Notes
    Not for export
    #>
    param(
        [parameter( Mandatory = $true )]
        [Hashtable[]] $Versions
        ,
        [parameter( Mandatory = $true )]
        [System.IO.FileInfo] $File
    )
    foreach( $version in $Versions ) {

        if( $File.Name -Like $version.Include ) {
            $versionArgs = @{ Version = $version
                              File = $File
                              ErrorAction = 'Stop' }
            Backup-Version @versionArgs
            Remove-ExcessVersions @versionArgs
        }
    }
}

function Get-VersionsFolder
{
    param(
        [parameter( Mandatory = $true )]
        [Hashtable] $Version,

        [parameter( Mandatory = $true )]
        [System.IO.FileInfo] $File
    )
    $root = $File.DirectoryName

    if( $root -like "*\$VersionsFolderName\*" )
    {
        # don't save a version of a version
        return [String]::Empty
    }
    $name = $Version.Include.
        Replace( '*', '@' ).
        Replace( '?', '#' )

    $folder = "$root\$VersionsFolderName\$name"
    New-Folder $folder
    return $folder
}

function Backup-Version
{
    param(
        [parameter( Mandatory = $true )]
        [Hashtable] $Version
        ,
        [parameter( Mandatory = $true,
            ValueFromPipeline = $true )]
        [System.IO.FileInfo] $File
    )
    Process
    {
        $gvfArgs = @{ File = $File
                      Version = $Version }
        $targetFolder = Get-VersionsFolder @gvfArgs

        if( [String]::Empty -eq $targetFolder )
        {
            return # don't save a version of a version

        }
        $targetFile = "{0}\{1}_{2}{3}" -f @(
            $targetFolder
            $File.BaseName
            ( Get-Datestamp -ForFileName )
            $File.Extension
        )
        $BackupSpy.Version = $targetFile

        $ciArgs = @{ Path = $File.FullName
                     Destination = $targetFile
                     ErrorAction = 'Stop' }
        Copy-Item @ciArgs
    }
}

function Remove-ExcessVersions
{
    param(
        [parameter( Mandatory = $true )]
        [Hashtable] $Version,

        [parameter( Mandatory = $true )]
        [System.IO.FileInfo] $File
    )
    $gvfArgs = @{ File = $File; Version = $Version }
    $targetFolder = Get-VersionsFolder @gvfArgs
    if( [String]::Empty -eq $targetFolder )
    {
        return
    }
    $filter = "{0}_????-??-??--??????{1}" -f @(
        $File.BaseName
        $File.Extension )
    $path = "{0}\{1}"  -f $targetFolder, $filter

    $GetChildItemsArgs = @{ Path = $path
                            Filter = $filter
                            File = $true
                            ErrorAction = 'Stop' }
    $soArgs = @{ Property = 'LastWriteTime'
                 Descending = $true }
    $i = 0

    Get-ChildItem @GetChildItemsArgs |
        Sort-Object @soArgs |
        ForEach-Object {
            $i++
            if( $i -gt $Version.MaxQty )
            {
                $file = $_
                try
                {
                    $file.Delete()
                }
                catch [System.UnauthorizedAccessException]
                {
                    # Clear read-only bit and try again
                    $file.Attributes = $file.Attributes -band -bnot 1
                    $file.Delete()
                }
            }
        }
    $BackupSpy.RemoveCalls++
}

$BackupSpy = @{
    OptimizeCalls = 0
    RemoveCalls = 0
    Version = $null
}
$DefaultMaxVersionQty = 5
$VersionsFolderName = 'versions'

$ExportArgs = @{
    Function = @(
        'Copy-FSItem',
        'Copy-Here',
        'Backup-Updates',
        'Optimize-Percent',
        'Optimize-SpecData',
        'Backup-Version',
        'Remove-ExcessVersions'
        'Get-BackupFiles'
        'Get-CommonBackupPath'
    )
    Variable = @(
        'BackupSpy',
        'DefaultMaxVersionQty'
        'VersionsFolderName'
    )
}
Export-ModuleMember @ExportArgs