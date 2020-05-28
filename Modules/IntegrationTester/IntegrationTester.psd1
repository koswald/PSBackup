#
# Module manifest for module 'IntegrationTester'
#
@{
    RootModule = './IntegrationTester.psm1'
    ModuleVersion = '0.0.1'
    CompatiblePSEditions = @('Core', 'Desktop')
    GUID = 'ab0997c7-4da8-46e7-89c9-5953a358c07d'
    Author = 'Karl Oswald'
    CompanyName = 'None'
    Copyright = '(c) 2020 Karl Oswald. All rights reserved.'
    Description = 'Provides testing features.'
    PowerShellVersion = '5.1.0' # Minimum
    RequiredModules = @( 
        'ErrorRemover'
    )
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    FileList = @(
        './IntegrationTester.psm1' 
    )
}

