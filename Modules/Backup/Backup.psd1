﻿#
# Module manifest for module 'Backup'
#
@{
    RootModule = '.\Backup.psm1'
    ModuleVersion = '0.0.1'
    CompatiblePSEditions = @('Core', 'Desktop')
    GUID = '9b892472-477d-4311-a7cf-f99510c5483c'
    Author = 'Karl Oswald'
    Copyright = '(c) 2020 Karl Oswald. All rights reserved.'
    Description = 'Provides backup features.'
    PowerShellVersion = '5.1.0' # Minimum
    RequiredModules = @(
        'Utility'
        'ErrorInfo'
    )
    FunctionsToExport = @(
        'Copy-FSItem'
        'Copy-Here'
        'Backup-Updates'
        'Optimize-Percent'
        'Optimize-SpecData'
        'Backup-Version'
        'Remove-ExcessVersions'
        'Get-BackupFiles'
        'Get-CommonBackupPath'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    FileList = @(
        '.\Backup.psm1'
    )
}
