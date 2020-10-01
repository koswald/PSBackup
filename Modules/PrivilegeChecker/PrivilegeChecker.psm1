using namespace System.Security.Principal

class PrivilegeChecker
{
    # Gets whether the calling process has elevated privileges.
    static [bool] PrivilegesAreElevated()
    {
        $identity = [WindowsIdentity]::GetCurrent()
        $principal = [WindowsPrincipal]::new( $identity )
        return $principal.IsInRole( [WindowsBuiltInRole]::Administrator )
    }
}
