# Main backup spec sheets for Backup.ps1
$copies = "$home/OneDrive/Backups"

$specs = @(
    @{
        Name = 'PowerShell scripts'
        Src = "$env:MyPSScripts"
        Dest = "$copies/MyPSScripts"
        Include = '*'
        Exclude = @(
            '*_????-??-??--??????.htm'
        )
        Subfolders = $true
        VersionsOnSrc = @( 
            @{ Include = '*'; MaxQty = 5 }
        )
    }
)