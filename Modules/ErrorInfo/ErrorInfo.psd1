#
# Module manifest for module 'ErrorInfo'
#

@{
    RootModule = './ErrorInfo.psm1'
    ModuleVersion = '0.0.1'
    CompatiblePSEditions = @('Core', 'Desktop')
    GUID = '277fcac0-7d5b-4c82-ac24-ff72378d2e51'
    Author = 'Karl Oswald'
    CompanyName = 'None'
    Copyright = '(c) 2020 Karl Oswald. All rights reserved.'
    Description = 'Provides a PowerShell class intended for sending a minimal set of error information down the (success) pipeline.'
    PowerShellVersion = '5.1.0' # Minimum
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    FileList = @(
        './ErrorInfo.psm1'
    )
}

