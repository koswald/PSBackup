' to be called by the task scheduler
' to invoke Backup.ps1, which will run hidden unless debugging

' for pwsh.exe (PowerShell 6+) use /exe:pwsh
' for powershell.exe, use /exe:powershell
' for debugging, use /debug:True

dbugByDefault = False

' get command-line arguments
Set args = WScript.Arguments.Named
If Len(args("exe")) Then
    exe = args("exe")
Else exe = "pwsh" ' default
End If
If Len(args("debug")) Then
    dbug = args("debug")
Else dbug = dbugByDefault
End If
Set args = Nothing

' other command fragments
common1 = " -ExecutionPolicy Bypass"
dbugMid = " -NoLogo -NoExit"
common2 = " -File ""%MyPsScripts%\ps\Backup\Backup.ps1"" ""%MyPsScripts%\ps\Backup\SpecFile1.ps1"" "
prodEnd = " -DontOpenReport"
dbugEnd = " -ShowSpecs -PassThru -Debug"

If dbug Then
    command = exe & common1 & dbugMid & common2 & dbugEnd
    visibility = visible
Else
    command = exe & common1 & common2 & prodEnd
    visibility = hidden
End If

Set shell = CreateObject( "WScript.Shell" )

If dbug Then

    ' show optout with proposed command

    msg = "Starting task" & vbLf & command
    settings = vbSystemModal
    settings = settings + vbOkCancel
    settings = settings + vbInformation
    title = WScript.ScriptName
    timeout = 59 ' seconds

    If vbCancel = shell.PopUp( _
        msg, timeout, title, settings _
    ) Then
        Set shell = Nothing
        WScript.Quit
    End If
End If

shell.Run command, visibility

Set shell = Nothing
Const hidden = 0
Const visible = 1