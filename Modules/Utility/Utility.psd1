#
# Module manifest for module 'Utility'
#
@{
    RootModule = './Utility.psm1'
    ModuleVersion = '0.0.1'
    GUID = '97f37765-4f86-43f6-8c5d-210ce958e292'
    Author = 'Karl Oswald'
    CompanyName = 'None'
    Copyright = '(c) 2019 Karl Oswald. All rights reserved.'
    Description = 'Utilities create new folder (New-Folder).'
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
        'Remove-Error'
        'Out-Html'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
}

