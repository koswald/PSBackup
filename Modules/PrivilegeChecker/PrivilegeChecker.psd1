#
# Module manifest for module 'PrivilegeChecker'
#
@{
    RootModule = '.\PrivilegeChecker.psm1'
    ModuleVersion = '0.0.1'
    CompatiblePSEditions = @('Core', 'Desktop')
    GUID = '278196bd-52d5-46b4-be76-c86818172508'
    Author = 'Karl Oswald'
    CompanyName = 'None'
    Copyright = '(c) 2020 Karl Oswald. All rights reserved.'
    Description = 'In Windows, provides a method that checks whether privileges are elevated.'
    PowerShellVersion = '5.1.0' # Minimum
    # RequiredAssemblies = @(
    #     'System.Security.Principal.Windows.dll'
    #     'System.DirectoryServices.AccountManagement.dll'
    #     'System.Security.Claims.dll'
    #     'System.Security.Principal.dll'
    # )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    FileList = @(
        '.\PrivilegeChecker.psm1'
    )
}

