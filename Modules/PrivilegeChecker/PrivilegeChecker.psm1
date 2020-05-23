using namespace System.Security.Principal
using namespace System.DirectoryServices.AccountManagement

class PrivilegeChecker
{
    # Gets whether the calling process has elevated privileges.
    static [bool] PrivilegesAreElevated()
    {
        [WindowsIdentity] $identity = [WindowsIdentity]::GetCurrent()
        [WindowsPrincipal] $principal = [WindowsPrincipal]::new( $identity );
        return $principal.IsInRole( [WindowsBuiltInRole]::Administrator )
    }
}
