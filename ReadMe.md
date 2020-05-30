# Contents

[Requirements]( #requirements )

[Features]( #project-features)  
- [Backup script]( #backup-script )  
- [Backup-Updates command]( #backup-updates-command )  
- [Out-Html command]( #out-html-command )
- [Backup module]( #backup-module )  
- [Utility module]( #utility-module )  
- [PrivilegeChecker module]( #privilegechecker-module )  
- [Integration tests]( #integration-tests )  

[Setup]( #setup )  
[Notes]( #notes )  
[See also]( #see-also )  
[Links]( #links )  
[References]( #references )  

# Requirements

- PowerShell 5 or higher  
- Windows &trade;

The PSBackup project was tested with Windows PowerShell 5.1 and PowerShell Core 6 and 7.

# Project features

## Backup script

Backs up new and changed files. Any objects sent down the pipeline including files copied, message strings, and ErrorInfo objects are logged to an html file by default. The object properties that are logged are customizable.

For help on this script, type

```PowerShell
Get-Help ./Backup/Backup.ps1 -Full
```

## Backup-Updates command

Backs up changed files based on archive bit state. Backup specifications are grouped in hashtables. Multiple hashtables can be piped to the command. Supports versions and provides a console progress bar. This is the function that [Backup.ps1]( ./Backup/Backup.ps1 ) is based on.

For help on this command, type

``` PowerShell
Get-Help Backup-Updates -Full
```

## Out-Html command

The Out-Html command converts pipeline objects to an html file. Objects continue down the pipeline if and only if the PassThru switch parameter is used. Object properties to include may be selected using the Properties parameter. For information about the parameters, type

```PowerShell
Get-Help Out-Html -Detailed
```

## Backup module

To get a list of other commands in the Backup module, type

```PowerShell
Get-Command -Module Backup
```

## Utility module

The utility module provides a number of useful commands including the [Out-Html]( #out-html-command) command. To see a list of the commands, type

```PowerShell
Get-Command -Module Utility
```

To get help on a particular command, type

```PowerShell
Get-Help <command> -Detailed
```

## PrivilegeChecker module

The PrivilegeChecker module provides a PrivilegeChecker class that has a static method `PrivilegesAreElevated` that returns a boolean according to whether the calling PowerShell session has elevated privileges:

```PowerShell
# using statements must be at the very top of a file or below the initial comments.
using Module PrivilegeChecker 

$pc = [PrivilegeChecker]::new()
$elevated = $pc::PrivilegesAreElevated()
```

The PrivilegeChecker module is an example of a module with localizable module-level help:

```PowerShell
Get-Help about_PrivilegeChecker
```
See [Writing Help for PowerShell Modules].

## Integration tests

The tests can be run as a whole by running `suite.ps1` in the `IntegrationTests` folder. The ultra-light testing framework consists of a [ class ]( Modules/IntegrationTester/IntegrationTester.psm1 ) written in PowerShell.

# Setup

`Setup.ps1` adds the project path to a profile file.

```PowerShell
./Setup.ps1
```

By default, the CurrentUserAllHosts profile file is used, typically `$home\Documents\WindowsPowerShell\profile.ps1` for version 5, and `$home\Documents\PowerShell\profile.ps1` for versions 6 and higher. The file and path will be created if they do not exist. In order to use another profile, type

``` PowerShell
.\Setup.ps1 -ProfileName  # with a space after -ProfileName
```

and press Tab to get the desired profile. If you want to use one of the AllUsers... profiles, you must use a console with elevated privileges. Use `-Confirm` to if you want to require confirmation, and restart the console window for changes to take effect. 

# Notes

## Refresh a module

Changes made to a module need to be refreshed in memory before they take effect. To refresh the module named Utility, for example, use

```PowerShell
Import-Module Utility -Force
```

# See also

Get-Help Backup-Updates [ -Detailed | -Full ]  
Get-Help ./Backup/Backup.ps1 [ -Detailed | -Full ]  
Get-Help about_PSBackup  
Get-Help about_Backup  
./Backup/[BackupTask.md]  

# Links

[PowerShell Scripting]  
[About Hashtables]  
[About Using]  
[Writing Help for PowerShell Modules]  
[About Comment Based Help]  
[Writing Help for PowerShell Cmdlets (Guidelines)]  
[Creating and Throwing Exceptions (C# Programming Guide)]  
[Use PowerShell to Persist Environment Variables]  
[Everything You Ever Wanted to Know About Exceptions]

# References

For the hidden Init pattern used in the ErrorInfo class to simulate one constructor calling another constructor, credit goes to https://stackoverflow.com/questions/44413206/constructor-chaining-in-powershell-call-other-constructors-in-the-same-class.

---

[BackupTask.md]: ./Backup/BackupTask.md

[PowerShell Scripting]: https://docs.microsoft.com/en-us/powershell/scripting/PowerShell-Scripting "https://docs.microsoft.com"

[About Hashtables]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables "https://docs.microsoft.com"

[About Using]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_using "https://docs.microsoft.com" 

[Creating and Throwing Exceptions (C# Programming Guide)]: https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/exceptions/creating-and-throwing-exceptions "https://docs.microsoft.com"
[Writing Help for PowerShell Modules]: https://docs.microsoft.com/en-us/powershell/scripting/developer/module/writing-help-for-windows-powershell-modules "https://docs.microsoft.com"

[About Comment Based Help]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-6 "https://docs.microsoft.com"

[Writing Help for PowerShell Cmdlets (Guidelines)]: https://docs.microsoft.com/en-us/powershell/scripting/developer/help/writing-help-for-windows-powershell-cmdlets "https://docs.microsoft.com"

[Use PowerShell to Persist Environment Variables]: https://trevorsullivan.net/2016/07/25/powershell-environment-variables/ "https://trevorsullivan.net"

[Everything You Ever Wanted to Know About Exceptions]: https://powershellexplained.com/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/#psitem "https://powershellexplained.com"

