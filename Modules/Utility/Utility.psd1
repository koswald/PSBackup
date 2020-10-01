#
# Module manifest for module 'Utility'
#
@{
    RootModule = '.\Utility.psm1'
    ModuleVersion = '0.0.1'
    CompatiblePSEditions = @('Core', 'Desktop')
    GUID = '97f37765-4f86-43f6-8c5d-210ce958e292'
    Author = 'Karl Oswald'
    CompanyName = 'None'
    Copyright = '(c) 2020 Karl Oswald. All rights reserved.'
    Description = 'Utilities such as create new folder (New-Folder).'
    PowerShellVersion = '5.1.0' # Minimum
    RequiredAssemblies = @()
    FunctionsToExport = @(
        'Set-ArchiveBit'
        'Clear-ArchiveBit'
        'New-Folder'
        'Test-Match'
        'Get-Datestamp'
        'Get-FileName'
        'Get-FileBaseName'
        'Get-ScriptName'
        'Get-ScriptBaseName'
        'Get-ScriptFullName'
        'Measure-PipedObjects'
        'Convert-AsciiToChar'
        'Convert-HexToChar'
        'Out-Html'
        'Remove-TestArtifact'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    FileList = @(
        '.\Utility.psm1'
    )

}

