<#
  =====================================================================
   GUARDIAN SHIELD  v1.0  -  Cyber Defence Console for Windows 10 / 11
  =====================================================================
   Start it by double-clicking "Start Guardian Shield.bat".
   This file is the "main" program. It loads the other .ps1 files in
   this folder (data, logic and screens) and the window design (ui.xaml).
#>
param([switch]$NoElevate)

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- 1. Ask for Administrator rights (needed for some deep checks). If the user says No, we carry on in Limited mode. ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $NoElevate) {
  try {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -WindowStyle Hidden -ErrorAction Stop `
      -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$($MyInvocation.MyCommand.Path)`"", '-NoElevate')
    exit
  } catch { }   # user pressed "No" -> continue without admin
}

# ---- 2. Load the Windows screen libraries ----
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-GsLog([string]$Text) {
  try { $d = Join-Path $env:APPDATA 'GuardianShield'; if (-not (Test-Path $d)) { New-Item -ItemType Directory $d -Force | Out-Null }
    Add-Content -Path (Join-Path $d 'error.log') -Value ("[{0}] {1}" -f (Get-Date), $Text) } catch {}
}

try {
  # ---- 3. Load all the parts of the program ----
  foreach ($part in @('data-scams.ps1', 'data-intel.ps1', 'data-learn.ps1', 'data-adviser.ps1', 'logic.ps1', 'work-scan.ps1', 'work-tools.ps1', 'ui-core.ps1', 'ui-protect.ps1', 'ui-identity.ps1')) {
    $p = Join-Path $here $part
    if (-not (Test-Path $p)) { throw "A program file is missing: $part. Please extract ALL files from the ZIP into one folder." }
    . $p
  }

  # ---- 4. Build the window from ui.xaml ----
  $xamlText = Get-Content -Path (Join-Path $here 'ui.xaml') -Raw -Encoding UTF8
  [xml]$xml = $xamlText
  $reader = New-Object System.Xml.XmlNodeReader $xml
  $script:Window = [Windows.Markup.XamlReader]::Load($reader)
  $script:UI = @{}
  foreach ($m in [regex]::Matches($xamlText, 'x:Name="([^"]+)"')) { $n = $m.Groups[1].Value; $script:UI[$n] = $script:Window.FindName($n) }

  # ---- 5. Load data and profile ----
  $script:CardItems = ConvertFrom-GsData $script:CardData
  $script:PhishItems = ConvertFrom-GsData $script:PhishData
  $script:VulnItems = ConvertFrom-GsData $script:VulnData
  $script:BreachItems = ConvertFrom-GsData $script:BreachData
  $script:TipsItems = ConvertFrom-GsData $script:TipsData
  $script:KbItems = ConvertFrom-GsData $script:AdviserData
  $script:Me = Read-GsProfile
  $script:Scanning = $false; $script:LastScan = $null; $script:LastScore = $null

  # Crash guard: show any unexpected error as a pop-up message instead of closing
  $script:Window.Dispatcher.Add_UnhandledException({
    param($s, $e)
    $e.Handled = $true
    Write-GsLog $e.Exception.ToString()
    Show-Toast ("Oops: " + $e.Exception.Message) '#FF3B5C'
  })

  # ---- 6. Title bar ----
  if ($isAdmin) { $script:UI.TxtAdmin.Text = '[ ADMIN MODE: FULL SCAN POWER ]'; $script:UI.TxtAdmin.Foreground = B '#39FF88' }
  else { $script:UI.TxtAdmin.Text = '[ LIMITED MODE: restart and choose YES for full checks ]'; $script:UI.TxtAdmin.Foreground = B '#FFC23D' }
  $script:UI.BtnClose.Add_Click({ $script:Window.Close() })
  $script:UI.BtnMin.Add_Click({ $script:Window.WindowState = 'Minimized' })
  $script:UI.BtnMax.Add_Click({ if ($script:Window.WindowState -eq 'Maximized') { $script:Window.WindowState = 'Normal' } else { $script:Window.WindowState = 'Maximized' } })
  $script:Window.Add_StateChanged({ if ($script:Window.WindowState -eq 'Maximized') { $script:UI.RootBorder.Margin = '7' } else { $script:UI.RootBorder.Margin = '0' } })

  # ---- 7. Page headers with "Explained simply" lessons ----
  foreach ($k in $script:PageInfo.Keys) {
    $info = $script:PageInfo[$k]; $h = $script:UI["Hdr_$k"]
    if (-not $h) { continue }
    [void]$h.Children.Add((New-TB $info[0] 12 '#FF2E88' 'Normal' '0' 'Consolas'))
    [void]$h.Children.Add((New-TB $info[1] 32 '#E6F1FF' 'SemiBold' '0,2,0,2' 'Bahnschrift SemiBold'))
    [void]$h.Children.Add((New-TB $info[2] 15 '#8FA0BC' 'Normal' '0,0,0,14'))
    $lc = New-Card '#2A3C63' '#0C1628' '0,0,0,18'; $ls = New-Stack
    $lh = New-Stack 'Horizontal'
    [void]$lh.Children.Add((New-TB ([string][char]0xEA80) 16 '#FFC23D' 'Normal' '0,0,8,0' 'Segoe MDL2 Assets'))
    [void]$lh.Children.Add((New-TB 'EXPLAINED SIMPLY' 12 '#FFC23D' 'Normal' '0' 'Consolas'))
    [void]$ls.Children.Add($lh); [void]$ls.Children.Add((New-TB $info[3] 14 '#C8D6EE' 'Normal' '0,6,0,0'))
    $lc.Child = $ls; [void]$h.Children.Add($lc)
  }

  # ---- 8. Navigation ----
  $script:PageKeys = @('Dashboard', 'Scan', 'AV', 'Malware', 'Disk', 'Pass', 'Email', 'Breach', 'Card', 'Phish', 'Vulns', 'AI', 'Tips', 'Member')
  function Show-Page([string]$Key) {
    foreach ($k in $script:PageKeys) { $script:UI["Page_$k"].Visibility = 'Collapsed' }
    $script:UI["Page_$Key"].Visibility = 'Visible'; $script:UI["Page_$Key"].ScrollToTop()
    if (@($script:Me.Visited) -notcontains $Key) {
      $script:Me.Visited = @($script:Me.Visited) + $Key; Save-GsProfile
      if (@('Card', 'Phish', 'Vulns', 'Breach', 'Tips') -contains $Key) { Add-XP 10 'Intel briefing read' }
      if ((@($script:Me.Visited) -contains 'Card') -and (@($script:Me.Visited) -contains 'Phish')) { Grant-Badge 'scam_spotter' }
    }
    if ($Key -eq 'AV' -and -not $script:AvLoaded) { $script:AvLoaded = $true; Update-AvStatus }
    if ($Key -eq 'Disk' -and -not $script:DiskLoaded) { $script:DiskLoaded = $true; Start-DiskCheck }
    if ($Key -eq 'Member') { Update-MemberPage }
  }
  foreach ($k in $script:PageKeys) { $script:UI["Nav_$k"].Add_Checked({ param($s, $e) Show-Page ($s.Name -replace '^Nav_', '') }) }

  # ---- 9. Fill the information pages ----
  foreach ($i in $script:CardItems) { Add-InfoCard $script:UI.CardList $i }
  foreach ($i in $script:PhishItems) { Add-InfoCard $script:UI.PhishList $i }
  foreach ($i in $script:VulnItems) { Add-InfoCard $script:UI.VulnCurated $i }
  Initialize-BreachPage; Initialize-TipsPage; Initialize-AdviserPage; Initialize-XpHowTo
  Update-Insights; Update-RankUI
  $script:UI.BtnDiskScan.Content = "SCAN DRIVE $($env:SystemDrive) FOR ERRORS"

  # ---- 10. Buttons ----
  $script:UI.BtnRunScan.Add_Click({ Start-SystemScan })
  $script:UI.BtnRunScan2.Add_Click({ Start-SystemScan })
  $script:UI.BtnQuickScan.Add_Click({ Start-AvAction 'quick' })
  $script:UI.BtnFullScan.Add_Click({
    $ok = [System.Windows.MessageBox]::Show('A full scan checks every file on your PC and can take an hour or more. You can keep using your PC while it runs. Start now?', 'Guardian Shield', 'YesNo', 'Question')
    if ($ok -eq 'Yes') { Start-AvAction 'full' } })
  $script:UI.BtnUpdateSigs.Add_Click({ Start-AvAction 'update' })
  $script:UI.BtnAvRefresh.Add_Click({ Update-AvStatus })
  $script:UI.BtnOpenSecurity.Add_Click({ Open-Link 'windowsdefender://threat/' })
  $script:UI.BtnPickFile.Add_Click({ Select-FileToCheck })
  $script:UI.BtnCheckFile.Add_Click({ Start-FileCheck })
  $script:UI.BtnVirusTotal.Add_Click({ if ($script:LastHash) { Open-Link ("https://www.virustotal.com/gui/file/" + $script:LastHash) } })
  $script:UI.BtnStartupAudit.Add_Click({ Start-StartupAudit })
  $script:UI.BtnDiskRefresh.Add_Click({ Start-DiskCheck })
  $script:UI.BtnDiskScan.Add_Click({ Start-DiskErrorScan })

  $script:UI.PwdInput.Add_PasswordChanged({ if (-not $script:UI.ChkShowPwd.IsChecked) { Update-PasswordMeter } })
  $script:UI.PwdVisible.Add_TextChanged({ if ($script:UI.ChkShowPwd.IsChecked) { Update-PasswordMeter } })
  $script:UI.ChkShowPwd.Add_Checked({ $script:UI.PwdVisible.Text = $script:UI.PwdInput.Password; $script:UI.PwdInput.Visibility = 'Collapsed'; $script:UI.PwdVisible.Visibility = 'Visible' })
  $script:UI.ChkShowPwd.Add_Unchecked({ $script:UI.PwdInput.Password = $script:UI.PwdVisible.Text; $script:UI.PwdVisible.Visibility = 'Collapsed'; $script:UI.PwdInput.Visibility = 'Visible' })
  $script:UI.BtnPwned.Add_Click({ Start-PwnedCheck })
  $script:UI.SldLen.Add_ValueChanged({ $script:UI.TxtLen.Text = [string][int]$script:UI.SldLen.Value })
  $script:UI.BtnGenerate.Add_Click({
    $pw = New-StrongPassword ([int]$script:UI.SldLen.Value) ([bool]$script:UI.ChkUpper.IsChecked) ([bool]$script:UI.ChkLower.IsChecked) ([bool]$script:UI.ChkDigits.IsChecked) ([bool]$script:UI.ChkSymbols.IsChecked) ([bool]$script:UI.ChkAmbig.IsChecked)
    $script:UI.TxtGenerated.Text = $pw
    $s = Test-PasswordStrength $pw
    $script:UI.TxtGenInfo.Text = "Strength $($s.Score)/100 - would take $($s.Crack) to crack. Made with Windows' cryptographic random generator, so it's truly unpredictable. Save it in a password manager - don't write it on a sticky note on your screen!" })
  $script:UI.BtnPassphrase.Add_Click({
    $pw = New-Passphrase 5; $script:UI.TxtGenerated.Text = $pw
    $s = Test-PasswordStrength $pw
    $script:UI.TxtGenInfo.Text = "Strength $($s.Score)/100. A passphrase is 5 random words joined together - long (so very hard to crack) but easy to picture and remember. Imagine a little story with the words to lock it in your memory." })
  $script:UI.BtnCopyPwd.Add_Click({ if ($script:UI.TxtGenerated.Text) { [System.Windows.Clipboard]::SetText($script:UI.TxtGenerated.Text); Show-Toast 'Copied! Paste it with Ctrl + V.' } })
  $script:UI.BtnTestGen.Add_Click({ if ($script:UI.TxtGenerated.Text) { $script:UI.ChkShowPwd.IsChecked = $false; $script:UI.PwdInput.Password = $script:UI.TxtGenerated.Text; $script:UI.Page_Pass.ScrollToTop() } })

  $script:UI.BtnEmailCheck.Add_Click({ Start-EmailCheck })
  $script:UI.BtnOpenHibp.Add_Click({ if ($script:UI.TxtEmail.Text.Trim()) { [System.Windows.Clipboard]::SetText($script:UI.TxtEmail.Text.Trim()); Show-Toast 'Email copied - paste it on the website with Ctrl + V' }; Open-Link 'https://haveibeenpwned.com/' })
  $script:UI.BtnOpenMozilla.Add_Click({ Open-Link 'https://monitor.mozilla.org/' })
  $script:UI.BtnSaveKey.Add_Click({
    $k = $script:UI.TxtHibpKey.Password.Trim()
    if ($k) { $script:Me.HibpKey = (ConvertTo-SecureString $k -AsPlainText -Force | ConvertFrom-SecureString) } else { $script:Me.HibpKey = '' }
    Save-GsProfile; $script:UI.TxtHibpKey.Password = ''
    Show-Toast $(if ($k) { 'API key saved (encrypted to your Windows account).' } else { 'API key removed.' }) })
  $script:UI.BtnAnalyseEmail.Add_Click({ Start-EmailAnalysis })
  $script:UI.BtnBreachPlan.Add_Click({ Build-BreachPlan })
  $script:UI.BtnLoadKev.Add_Click({ Start-KevLoad })
  $script:UI.BtnSend.Add_Click({ Send-ChatQuestion $script:UI.ChatInput.Text })
  $script:UI.ChatInput.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Return') { Send-ChatQuestion $script:UI.ChatInput.Text } })
  $script:UI.BtnSaveName.Add_Click({
    $n = $script:UI.TxtNameEdit.Text.Trim(); if (-not $n) { $n = 'Agent' }
    $script:Me.Name = $n; Save-GsProfile; Update-RankUI; Update-MemberPage; Show-Toast "Callsign set: $($n.ToUpper())" })

  # ---- 11. Start on the Dashboard and run a scan automatically ----
  $script:UI.Nav_Dashboard.IsChecked = $true
  $script:Window.Add_ContentRendered({ Start-SystemScan })
  [void]$script:Window.ShowDialog()
}
catch {
  Write-GsLog $_.Exception.ToString()
  [System.Windows.MessageBox]::Show("Guardian Shield couldn't start:`n`n$($_.Exception.Message)`n`nA log was saved to: $env:APPDATA\GuardianShield\error.log", 'Guardian Shield', 'OK', 'Error') | Out-Null
}
