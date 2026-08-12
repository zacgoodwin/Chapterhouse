# Windows toast notification, zero dependencies (WinRT projection — run with
# windows powershell.exe 5.1, not pwsh). Usage: toast.ps1 -Title t -Body b
param(
  [Parameter(Mandatory = $true)][string]$Title,
  [string]$Body = ''
)

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$template = @"
<toast><visual><binding template="ToastGeneric">
<text>$([System.Security.SecurityElement]::Escape($Title))</text>
<text>$([System.Security.SecurityElement]::Escape($Body))</text>
</binding></visual></toast>
"@

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($template)
$toast = New-Object Windows.UI.Notifications.ToastNotification($xml)
# AppId: PowerShell's own — fine for a personal loop notification.
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(
  '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
).Show($toast)
