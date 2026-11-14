# Guardian Shield - Dashboard, PC Scan, Antivirus, Malware Checker and Disk pages.

# ================= SYSTEM SCAN =================
$script:ScanMsgs = @('Checking antivirus engine...', 'Checking virus definitions...', 'Looking for active threats...', 'Testing firewall...',
  'Checking Windows Update...', 'Checking Windows version support...', 'Checking UAC...', 'Checking Secure Boot...', 'Checking drive encryption...',
  'Checking SmartScreen...', 'Checking Remote Desktop...', 'Checking for SMBv1...', 'Checking disk health...')
$script:MsgTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:MsgTimer.Interval = [TimeSpan]::FromMilliseconds(650)
$script:MsgTimer.Add_Tick({ $script:MsgIdx = ($script:MsgIdx + 1) % $script:ScanMsgs.Count; $script:UI.TxtScanStatus.Text = $script:ScanMsgs[$script:MsgIdx] })

function Start-SystemScan {
  if ($script:Scanning) { return }
  $script:Scanning = $true
  $script:UI.BtnRunScan.IsEnabled = $false; $script:UI.BtnRunScan2.IsEnabled = $false
  $script:UI.TxtGrade.Text = 'SCANNING...'; $script:UI.TxtGrade.Foreground = B '#00E5FF'
  $script:UI.TxtScanSummary.Text = 'Scanning... please wait (10-30 seconds).'
  $script:MsgIdx = 0; $script:MsgTimer.Start(); Start-Spinner
  Start-Background -Work $script:ScanWork -OnDone {
    param($res, $err)
    $script:Scanning = $false; $script:MsgTimer.Stop(); Stop-Spinner
    $script:UI.BtnRunScan.IsEnabled = $true; $script:UI.BtnRunScan2.IsEnabled = $true
    if (-not $res) { $script:UI.TxtScanStatus.Text = "The scan could not finish: $err"; $script:UI.TxtGrade.Text = 'SCAN FAILED'; return }
    Show-ScanResult $res
  }
}

function Show-ScanResult($Res) {
  $script:LastScan = $Res
  $checks = @($Res.Checks)
  $scored = @($checks | Where-Object { $_.Max -gt 0 -and $_.Status -ne 'Unknown' })
  $pts = 0; $max = 0; foreach ($c in $scored) { $pts += $c.Points; $max += $c.Max }
  $score = 0; if ($max -gt 0) { $score = [int][Math]::Round(100 * $pts / $max) }
  $script:LastScore = $score

  if ($score -ge 90) { $grade = 'FORTRESS - EXCELLENT'; $col = '#39FF88' }
  elseif ($score -ge 75) { $grade = 'PROTECTED'; $col = '#7CFF6B' }
  elseif ($score -ge 60) { $grade = 'SOME RISKS'; $col = '#FFC23D' }
  elseif ($score -ge 40) { $grade = 'AT RISK'; $col = '#FF8A3D' }
  else { $grade = 'DANGER'; $col = '#FF3B5C' }
  Set-RingColor $col; Start-ScoreAnimation $score
  $script:UI.TxtGrade.Text = $grade; $script:UI.TxtGrade.Foreground = B $col
  $fails = @($checks | Where-Object { $_.Status -eq 'Fail' }).Count
  $warns = @($checks | Where-Object { $_.Status -eq 'Warn' }).Count
  $unk = @($checks | Where-Object { $_.Status -eq 'Unknown' }).Count
  $script:UI.TxtScanStatus.Text = "Scan complete at $((Get-Date).ToString('h:mm tt')).  $fails problem(s), $warns warning(s)."
  $sumTxt = "Score $score/100  -  $fails problem(s), $warns warning(s)"
  if ($unk -gt 0) { $sumTxt += ", $unk not checked (needs Administrator)" }
  $script:UI.TxtScanSummary.Text = $sumTxt

  # Tiles
  $av = $checks | Where-Object { $_.Id -eq 'av' } | Select-Object -First 1
  $script:UI.TileAvVal.Text = $(if ($av.Status -eq 'Pass') { 'ACTIVE' } else { 'OFF' }); $script:UI.TileAvVal.Foreground = B (Get-SevColor $av.Status)
  $script:UI.TileAvSub.Text = $Res.AvName
  if (@($Res.Active).Count -gt 0) { $script:UI.TileThreatVal.Text = 'INFECTED'; $script:UI.TileThreatVal.Foreground = B '#FF3B5C'; $script:UI.TileThreatSub.Text = "$(@($Res.Active).Count) active threat(s) - go to Antivirus" }
  elseif (@($Res.Recent).Count -gt 0) { $script:UI.TileThreatVal.Text = 'CLEAN*'; $script:UI.TileThreatVal.Foreground = B '#FFC23D'; $script:UI.TileThreatSub.Text = "$(@($Res.Recent).Count) threat(s) blocked in last 30 days" }
  else { $script:UI.TileThreatVal.Text = 'CLEAN'; $script:UI.TileThreatVal.Foreground = B '#39FF88'; $script:UI.TileThreatSub.Text = 'No threats found' }
  $fw = $checks | Where-Object { $_.Id -eq 'fw' } | Select-Object -First 1
  $script:UI.TileFwVal.Text = $(if ($fw.Status -eq 'Pass') { 'ON' } elseif ($fw.Status -eq 'Warn') { 'PARTIAL' } else { 'OFF' }); $script:UI.TileFwVal.Foreground = B (Get-SevColor $fw.Status)
  $script:UI.TileFwSub.Text = $(if ($Res.Fw3) { 'Third-party firewall active' } else { "$($Res.FwOn) of $($Res.FwTotal) network types protected" })
  $up = $checks | Where-Object { $_.Id -eq 'upd' } | Select-Object -First 1
  $script:UI.TileUpdVal.Text = $(if ($null -ne $Res.UpdDays) { "$($Res.UpdDays) DAYS AGO" } else { 'UNKNOWN' }); $script:UI.TileUpdVal.Foreground = B (Get-SevColor $up.Status)
  $script:UI.TileUpdSub.Text = $(if ($Res.Reboot) { 'Restart needed to finish updates' } else { 'Last successful update install' })

  $adm = $(if ($Res.IsAdmin) { 'Yes' } else { 'No (some checks skipped)' })
  $script:UI.TxtSysInfo.Text = "Computer:      $($Res.Computer)`nWindows:       $($Res.OSLabel)`nProcessor:     $($Res.CPU)`nMemory (RAM):  $($Res.RAM) GB`nAdministrator: $adm"

  # Detailed list - problems first
  $order = @{ Fail = 0; Warn = 1; Unknown = 2; Pass = 3 }
  $script:UI.ScanList.Children.Clear()
  foreach ($c in ($checks | Sort-Object { $order[$_.Status] }, { - $_.Max })) {
    $col = Get-SevColor $c.Status
    $label = @{ Pass = 'PASS'; Warn = 'WARNING'; Fail = 'PROBLEM'; Unknown = "COULDN'T CHECK" }[$c.Status]
    $card = New-Card $col; $sp = New-Stack
    $hdr = New-Stack 'Horizontal'; [void]$hdr.Children.Add((New-Pill $label $col))
    if ($c.Max -gt 0) { [void]$hdr.Children.Add((New-Pill "$($c.Points) / $($c.Max) PTS" '#8FA0BC')) } else { [void]$hdr.Children.Add((New-Pill 'HEALTH INFO' '#8FA0BC')) }
    [void]$sp.Children.Add($hdr)
    [void]$sp.Children.Add((New-TB $c.Title 18 '#E6F1FF' 'SemiBold' '0,6,0,4' 'Bahnschrift SemiBold'))
    [void]$sp.Children.Add((New-TB $c.Detail))
    if ($c.Fix -and $c.Status -ne 'Pass') {
      [void]$sp.Children.Add((New-TB 'HOW TO FIX' 12 '#39FF88' 'Normal' '0,10,0,2' 'Consolas'))
      [void]$sp.Children.Add((New-TB $c.Fix 14 '#D6E2F5'))
    }
    if ($c.Action -and $c.Status -ne 'Pass') {
      $btn = New-Button 'FIX IT  >' 'Neon' $c.Action; $btn.Margin = '0,12,0,0'
      $btn.Add_Click({ param($s, $e) Open-Link $s.Tag })
      [void]$sp.Children.Add($btn)
    }
    $card.Child = $sp; [void]$script:UI.ScanList.Children.Add($card)
  }

  Update-Insights
  # History, XP and badges
  $script:Me.History = @(@{ Date = (Get-Date).ToString('ddd d MMM yyyy  h:mm tt'); Score = $score }) + @($script:Me.History) | Select-Object -First 20
  Save-GsProfile
  Add-XP 50 'System scan complete'
  Grant-Badge 'first_scan'
  if ($score -ge 90) { Grant-Badge 'fortress' }
}

function Update-Insights {
  $p = $script:UI.DashInsights; $p.Children.Clear()
  if ($script:LastScan) {
    $probs = @($script:LastScan.Checks | Where-Object { $_.Status -eq 'Fail' -or $_.Status -eq 'Warn' } | Sort-Object { if ($_.Status -eq 'Fail') { 0 } else { 1 } }, { - $_.Max } | Select-Object -First 3)
    foreach ($c in $probs) { Add-InsightRow $p $(if ($c.Status -eq 'Fail') { 'FIX FIRST' } else { 'IMPROVE' }) (Get-SevColor $c.Status) ("$($c.Title): $($c.Fix)") }
    if ($probs.Count -eq 0) { Add-InsightRow $p 'ALL CLEAR' '#39FF88' 'Every security check passed. Brilliant work, Agent - keep updates on and run a scan each week.' }
  } else { Add-InsightRow $p 'START HERE' '#00E5FF' 'Press RUN FULL SYSTEM SCAN to get your Shield Score and personalised advice.' }
  foreach ($i in $script:Insights) { Add-InsightRow $p $i.Tag (Get-SevColor $i.Tag) $i.Text }
}
function Add-InsightRow($Panel, [string]$Tag, [string]$Color, [string]$Text) {
  $g = New-Object System.Windows.Controls.Grid; $g.Margin = '0,0,0,10'
  $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = '110'; $c2 = New-Object System.Windows.Controls.ColumnDefinition
  $g.ColumnDefinitions.Add($c1); $g.ColumnDefinitions.Add($c2)
  $pill = New-Pill $Tag $Color; $pill.VerticalAlignment = 'Top'
  $t = New-TB $Text 14 '#D6E2F5'; [System.Windows.Controls.Grid]::SetColumn($t, 1)
  [void]$g.Children.Add($pill); [void]$g.Children.Add($t); [void]$Panel.Children.Add($g)
}

# ================= ANTIVIRUS =================
function Update-AvStatus {
  $script:UI.AvStatus.Children.Clear()
  [void]$script:UI.AvStatus.Children.Add((New-TB 'Reading antivirus status...'))
  Start-Background -Work $script:AvStatusWork -OnDone {
    param($res, $err)
    $p = $script:UI.AvStatus; $p.Children.Clear()
    $mp = $null; if ($res) { $mp = $res.Mp }
    if (-not $mp) { [void]$p.Children.Add((New-TB 'Microsoft Defender is not available. If you use a different antivirus (Norton, McAfee, etc.) please scan with that program instead.' 14 '#FFC23D')); return }
    $rows = @(
      @('Real-time protection', $(if ($mp.RealTimeProtectionEnabled) { 'ON' } else { 'OFF' }), [bool]$mp.RealTimeProtectionEnabled),
      @('Antivirus engine', $(if ($mp.AntivirusEnabled) { "Running ($($mp.AMRunningMode))" } else { 'OFF' }), [bool]$mp.AntivirusEnabled),
      @('Tamper protection', $(if ($mp.IsTamperProtected) { 'ON' } else { 'OFF' }), [bool]$mp.IsTamperProtected),
      @('Virus definitions', "Version $($mp.AntivirusSignatureVersion) - $($mp.AntivirusSignatureAge) day(s) old", ($mp.AntivirusSignatureAge -le 2)),
      @('Last quick scan', $(if ($mp.QuickScanEndTime) { $mp.QuickScanEndTime.ToString('d MMM yyyy h:mm tt') } else { 'Never' }), [bool]$mp.QuickScanEndTime),
      @('Last full scan', $(if ($mp.FullScanEndTime) { $mp.FullScanEndTime.ToString('d MMM yyyy h:mm tt') } else { 'Never' }), [bool]$mp.FullScanEndTime)
    )
    foreach ($r in $rows) {
      $g = New-Object System.Windows.Controls.Grid; $g.Margin = '0,3,0,3'
      $a = New-Object System.Windows.Controls.ColumnDefinition; $a.Width = '220'; $g.ColumnDefinitions.Add($a); $g.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
      $t1 = New-TB $r[0] 14 '#8FA0BC'; $t2 = New-TB $r[1] 14 $(if ($r[2]) { '#39FF88' } else { '#FFC23D' }) 'SemiBold'
      [System.Windows.Controls.Grid]::SetColumn($t2, 1); [void]$g.Children.Add($t1); [void]$g.Children.Add($t2); [void]$p.Children.Add($g)
    }
    $h = $script:UI.AvHistory; $h.Children.Clear()
    $hist = @($res.History)
    if ($hist.Count -eq 0) { [void]$h.Children.Add((New-TB 'Nothing has ever been caught on this PC (or the history was cleared). Clean record!' 14 '#39FF88')) }
    foreach ($t in $hist) {
      $col = $(if ($t.Active) { '#FF3B5C' } else { '#FFC23D' })
      $c = New-Card $col; $sp = New-Stack
      $hs = New-Stack 'Horizontal'; [void]$hs.Children.Add((New-Pill $(if ($t.Active) { 'ACTIVE - NEEDS ACTION' } else { 'BLOCKED / REMOVED' }) $col))
      $sev = @{ 1 = 'LOW'; 2 = 'MODERATE'; 4 = 'HIGH'; 5 = 'SEVERE' }[[int]$t.Severity]; if ($sev) { [void]$hs.Children.Add((New-Pill "SEVERITY: $sev" '#8FA0BC')) }
      [void]$sp.Children.Add($hs)
      [void]$sp.Children.Add((New-TB $t.Name 16 '#E6F1FF' 'SemiBold' '0,6,0,2'))
      [void]$sp.Children.Add((New-TB ("Found: " + $(if ($t.When) { ([datetime]$t.When).ToString('d MMM yyyy h:mm tt') } else { '?' })) 13))
      if ($t.Path) { [void]$sp.Children.Add((New-TB ("Where: " + $t.Path) 12 '#7F8EA8' 'Normal' '0' 'Consolas')) }
      $c.Child = $sp; [void]$h.Children.Add($c)
    }
  }
}

function Start-AvAction([string]$Action) {
  foreach ($b in @('BtnQuickScan', 'BtnFullScan', 'BtnUpdateSigs')) { $script:UI[$b].IsEnabled = $false }
  $script:UI.AvProgress.Visibility = 'Visible'
  $script:UI.TxtAvResult.Foreground = B '#00E5FF'
  $script:UI.TxtAvResult.Text = @{ quick = 'Quick scan running... You can keep using your PC or explore other tabs.'; full = 'FULL scan running... this checks every file and can take an hour or more. Leave Guardian Shield open.'; update = 'Downloading the newest virus definitions...' }[$Action]
  Start-Background -Work $script:AvActionWork -ArgumentList @($Action) -OnDone {
    param($res, $err)
    foreach ($b in @('BtnQuickScan', 'BtnFullScan', 'BtnUpdateSigs')) { $script:UI[$b].IsEnabled = $true }
    $script:UI.AvProgress.Visibility = 'Collapsed'
    if ($err -or -not $res) {
      $script:UI.TxtAvResult.Foreground = B '#FF8A3D'
      $script:UI.TxtAvResult.Text = "Couldn't complete that: $err`nTip: start Guardian Shield as Administrator, or make sure Microsoft Defender is your active antivirus."
      return
    }
    if ($res.Action -eq 'update') { $script:UI.TxtAvResult.Foreground = B '#39FF88'; $script:UI.TxtAvResult.Text = 'Virus definitions updated! Your antivirus now knows the newest threats.'; Add-XP 20 'Definitions updated' }
    elseif ($res.Found -gt 0) { $script:UI.TxtAvResult.Foreground = B '#FF3B5C'; $script:UI.TxtAvResult.Text = "SCAN FINISHED in $($res.Minutes) min - $($res.Found) THREAT(S) FOUND. See the threat history below. Press OPEN WINDOWS SECURITY > Protection history to remove them."; Add-XP 100 'Threat hunted'; Grant-Badge 'av_scan' }
    else { $script:UI.TxtAvResult.Foreground = B '#39FF88'; $script:UI.TxtAvResult.Text = "SCAN FINISHED in $($res.Minutes) min - NO THREATS FOUND. Your PC is clean."; Add-XP $(if ($res.Action -eq 'full') { 150 } else { 75 }) 'Antivirus scan complete'; Grant-Badge 'av_scan' }
    Update-AvStatus
  }
}

# ================= MALWARE CHECKER =================
function Select-FileToCheck {
  $dlg = New-Object Microsoft.Win32.OpenFileDialog
  $dlg.Title = 'Choose a file to check for malware'
  $dl = Join-Path $env:USERPROFILE 'Downloads'; if (Test-Path $dl) { $dlg.InitialDirectory = $dl }
  if ($dlg.ShowDialog()) { $script:UI.TxtFilePath.Text = $dlg.FileName; $script:CheckPath = $dlg.FileName; $script:UI.MalResult.Children.Clear(); $script:UI.BtnVirusTotal.Visibility = 'Collapsed' }
}

function Start-FileCheck {
  if (-not $script:CheckPath -or -not (Test-Path -LiteralPath $script:CheckPath)) { Show-Toast 'Press BROWSE... and pick a file first.' '#FFC23D'; return }
  $script:UI.BtnCheckFile.IsEnabled = $false; $script:UI.MalProgress.Visibility = 'Visible'
  $script:UI.MalResult.Children.Clear(); [void]$script:UI.MalResult.Children.Add((New-TB 'Scanning the file with 6 tests...'))
  Start-Background -Work $script:FileCheckWork -ArgumentList @($script:CheckPath) -OnDone {
    param($r, $err)
    $script:UI.BtnCheckFile.IsEnabled = $true; $script:UI.MalProgress.Visibility = 'Collapsed'
    $p = $script:UI.MalResult; $p.Children.Clear()
    if (-not $r) { [void]$p.Children.Add((New-TB "Couldn't check that file: $err" 14 '#FF8A3D')); return }
    $risk = 0; $tests = New-Object System.Collections.ArrayList
    function T([string]$Name, [string]$Status, [string]$Text) { [void]$tests.Add(@($Name, $Status, $Text)) }
    # 1 Antivirus
    if ($r.ScanDone -and $r.ThreatsFound -gt 0) { $risk += 100; T 'Antivirus scan' 'Fail' 'MICROSOFT DEFENDER SAYS THIS FILE IS MALICIOUS. Do NOT open it. Delete it, or let Windows Security quarantine it.' }
    elseif ($r.ScanDone) { T 'Antivirus scan' 'Pass' 'Microsoft Defender found no known threats in this file.' }
    else { $risk += 10; T 'Antivirus scan' 'Unknown' 'The Defender scan could not run (another antivirus may be active). Scan it with your antivirus too.' }
    # 2 Type
    $ext = [IO.Path]::GetExtension($r.Name).ToLower()
    $runnable = @('.exe', '.scr', '.bat', '.cmd', '.com', '.pif', '.js', '.jse', '.vbs', '.vbe', '.wsf', '.ps1', '.hta', '.msi', '.jar', '.lnk', '.iso', '.img', '.vhd', '.reg', '.dll', '.cpl', '.msc')
    if ($runnable -contains $ext) { $risk += 15; T 'File type' 'Warn' "This is a '$ext' file, which can RUN programs on your PC. Only open it if you trust exactly where it came from." }
    elseif (@('.zip', '.rar', '.7z') -contains $ext) { $risk += 5; T 'File type' 'Warn' "This is a compressed archive ($ext). Check the files inside it before opening them." }
    elseif (@('.docm', '.xlsm', '.pptm') -contains $ext) { $risk += 15; T 'File type' 'Warn' 'This Office file can contain MACROS (mini programs). Never click "Enable content" on a file from an email.' }
    else { T 'File type' 'Pass' "'$ext' files can't run programs by themselves." }
    # 3 Double extension
    if ($r.Name -match '\.(pdf|docx?|xlsx?|jpe?g|png|gif|mp4|mp3|txt)\s*\.(exe|scr|bat|cmd|js|vbs|com|pif|lnk|hta)$') { $risk += 60; T 'Disguise trick' 'Fail' "The name '$($r.Name)' pretends to be a document or picture, but is really a program. This is a classic malware trick. DO NOT OPEN." }
    else { T 'Disguise trick' 'Pass' 'No fake "double extension" in the file name.' }
    # 4 Signature
    if ($r.SigStatus -eq 'Valid') { $risk -= 10; T 'Digital signature' 'Pass' "Signed by: $($r.Signer). The signature is valid, so the file hasn't been changed since that company made it." }
    elseif ($r.SigStatus -eq 'NotSigned' -and $runnable -contains $ext) { $risk += 20; T 'Digital signature' 'Warn' 'This program is NOT digitally signed - we can''t confirm who made it. Most legitimate software is signed.' }
    elseif ($r.SigStatus -eq 'HashMismatch') { $risk += 50; T 'Digital signature' 'Fail' 'The signature is BROKEN - the file was changed after it was signed. Treat it as dangerous.' }
    elseif ($r.SigStatus -eq 'NotSigned') { T 'Digital signature' 'Pass' 'Not signed (normal for documents, pictures and media).' }
    else { $risk += 10; T 'Digital signature' 'Warn' "Signature status: $($r.SigStatus)." }
    # 5 Origin
    if ($r.ZoneId -ge 3) { $src = $(if ($r.HostUrl) { " from $($r.HostUrl)" } else { '' }); T 'Where it came from' 'Warn' "Downloaded from the internet$src. Make sure that is a site you trust." }
    else { T 'Where it came from' 'Pass' 'No "downloaded from the internet" label found.' }
    if ($r.Path -match '(?i)\\AppData\\Local\\Temp\\') { $risk += 10; T 'Location' 'Warn' 'This file is in a Temp folder - malware often hides there.' }
    # 6 Fingerprint
    T 'Fingerprint (SHA-256)' 'Info' "$($r.Sha256)`nPress LOOK UP ON VIRUSTOTAL to compare this fingerprint against 70+ antivirus engines (your file is NOT uploaded)."

    $risk = [Math]::Max(0, [Math]::Min(100, $risk))
    if ($risk -ge 60) { $v = 'DANGEROUS - DO NOT OPEN'; $vc = '#FF3B5C' } elseif ($risk -ge 25) { $v = 'SUSPICIOUS - BE CAREFUL'; $vc = '#FF8A3D' } elseif ($risk -ge 10) { $v = 'PROBABLY SAFE - SOME CAUTION'; $vc = '#FFC23D' } else { $v = 'LOOKS SAFE'; $vc = '#39FF88' }
    [void]$p.Children.Add((New-TB "RISK $risk/100  -  $v" 22 $vc 'Bold' '0,0,0,4' 'Bahnschrift SemiBold'))
    [void]$p.Children.Add((New-TB ("{0}  ({1:N0} KB)" -f $r.Name, ($r.Size / 1KB)) 13 '#7F8EA8' 'Normal' '0,0,0,10'))
    foreach ($t in $tests) {
      $col = $(if ($t[1] -eq 'Info') { '#00E5FF' } else { Get-SevColor $t[1] })
      $row = New-Stack; $row.Margin = '0,0,0,10'
      $h = New-Stack 'Horizontal'; [void]$h.Children.Add((New-Pill $t[1].ToUpper() $col)); [void]$h.Children.Add((New-TB $t[0] 15 '#E6F1FF' 'SemiBold'))
      [void]$row.Children.Add($h); [void]$row.Children.Add((New-TB $t[2] 14 '#B8C6DE' 'Normal' '0,2,0,0')); [void]$p.Children.Add($row)
    }
    $script:LastHash = $r.Sha256; $script:UI.BtnVirusTotal.Visibility = 'Visible'
    Add-XP 30 'File analysed'; Grant-Badge 'malware_hunter'
  }
}

function Start-StartupAudit {
  $script:UI.BtnStartupAudit.IsEnabled = $false
  $script:UI.StartupList.Children.Clear(); [void]$script:UI.StartupList.Children.Add((New-TB 'Checking startup programs...'))
  Start-Background -Work $script:StartupWork -OnDone {
    param($res, $err)
    $script:UI.BtnStartupAudit.IsEnabled = $true
    $p = $script:UI.StartupList; $p.Children.Clear()
    $items = @($res | Where-Object { $_ })
    [void]$p.Children.Add((New-TB "$($items.Count) program(s) start automatically with Windows. Too many slow your PC down. Turn off ones you don't need in Task Manager (Ctrl+Shift+Esc) > Startup apps." 14 '#B8C6DE' 'Normal' '0,0,0,10'))
    foreach ($i in $items) {
      if ($i.Odd) { $st = 'FAIL'; $why = 'SUSPICIOUS: it runs from a Temp/Downloads folder or uses a hidden script command. Search its name online, and consider removing it.' }
      elseif ($i.Status -eq 'Valid') { $st = 'PASS'; $why = "Signed by $($i.Signer)." }
      elseif ($i.Status -eq 'NotFound') { $st = 'WARN'; $why = 'The program file could not be found - it may be a leftover from something uninstalled.' }
      else { $st = 'WARN'; $why = 'NOT digitally signed - we can''t confirm who made it. If you don''t recognise the name, search it online.' }
      $c = New-Card (Get-SevColor $st); $sp = New-Stack
      $h = New-Stack 'Horizontal'; [void]$h.Children.Add((New-Pill $st (Get-SevColor $st))); [void]$h.Children.Add((New-TB $i.Name 15 '#E6F1FF' 'SemiBold'))
      [void]$sp.Children.Add($h); [void]$sp.Children.Add((New-TB $why 13 '#B8C6DE' 'Normal' '0,4,0,2'))
      [void]$sp.Children.Add((New-TB $i.Command 11 '#5C6C88' 'Normal' '0' 'Consolas')); $c.Child = $sp; [void]$p.Children.Add($c)
    }
    Add-XP 20 'Startup audit done'
  }
}

# ================= DISK =================
function Start-DiskCheck {
  $script:UI.DiskProgress.Visibility = 'Visible'; $script:UI.BtnDiskRefresh.IsEnabled = $false
  Start-Background -Work $script:DiskWork -OnDone {
    param($res, $err)
    $script:UI.DiskProgress.Visibility = 'Collapsed'; $script:UI.BtnDiskRefresh.IsEnabled = $true
    $p = $script:UI.DiskList; $p.Children.Clear()
    if (-not $res) { [void]$p.Children.Add((New-TB "Couldn't read disk information: $err" 14 '#FF8A3D')); return }
    if ($res.Predict -gt 0) { $w = New-Card '#FF3B5C'; $w.Child = New-TB 'WARNING: A drive''s own sensors (S.M.A.R.T.) PREDICT IT WILL FAIL. Back up all your files TODAY and replace the drive.' 16 '#FF3B5C' 'Bold'; [void]$p.Children.Add($w) }
    [void]$p.Children.Add((New-TB 'PHYSICAL DRIVES' 13 '#00E5FF' 'Normal' '0,4,0,8' 'Consolas'))
    foreach ($d in @($res.Disks)) {
      $st = $(if ($d.Health -eq 'Healthy') { 'PASS' } elseif ($d.Health -eq 'Warning') { 'WARN' } else { 'FAIL' })
      $c = New-Card (Get-SevColor $st); $sp = New-Stack
      $h = New-Stack 'Horizontal'; [void]$h.Children.Add((New-Pill $d.Health.ToUpper() (Get-SevColor $st)))
      $kind = $(if ($d.Media -eq 'SSD') { 'SSD (solid state - fast, no moving parts)' } elseif ($d.Media -eq 'HDD') { 'HDD (spinning disk)' } else { $d.Media })
      [void]$h.Children.Add((New-Pill $kind '#8FA0BC')); [void]$sp.Children.Add($h)
      [void]$sp.Children.Add((New-TB "$($d.Name)  -  $($d.SizeGB) GB" 17 '#E6F1FF' 'SemiBold' '0,6,0,4' 'Bahnschrift SemiBold'))
      $extra = @()
      if ($null -ne $d.Temp -and $d.Temp -gt 0) { $extra += "Temperature: $($d.Temp) C" + $(if ($d.Temp -gt 60) { ' (HOT - check cooling)' } else { ' (OK)' }) }
      if ($null -ne $d.Wear) { $extra += "Wear: $($d.Wear)% used of its life" }
      if ($null -ne $d.Hours) { $extra += "Powered on: $($d.Hours) hours" }
      if ($d.ReadErr -gt 0) { $extra += "Uncorrected read errors: $($d.ReadErr) (BAD - back up now)" }
      if (-not $res.IsAdmin) { $extra += 'Run as Administrator to see temperature, wear and error counts.' }
      [void]$sp.Children.Add((New-TB ("Status: $($d.Status)  |  Connection: $($d.Bus)`n" + ($extra -join "`n"))))
      if ($st -ne 'PASS') { [void]$sp.Children.Add((New-TB 'This drive is reporting a problem. BACK UP YOUR FILES NOW (OneDrive, Google Drive or an external drive), then get the drive checked or replaced.' 14 '#FF8A3D' 'SemiBold' '0,8,0,0')) }
      $c.Child = $sp; [void]$p.Children.Add($c)
    }
    [void]$p.Children.Add((New-TB 'DRIVE SPACE' 13 '#00E5FF' 'Normal' '0,8,0,8' 'Consolas'))
    foreach ($v in @($res.Volumes)) {
      $col = $(if ($v.UsedPct -ge 90) { '#FF3B5C' } elseif ($v.UsedPct -ge 80) { '#FFC23D' } else { '#39FF88' })
      $c = New-Card; $sp = New-Stack
      $name = "Drive $($v.Letter):" + $(if ($v.Label) { "  ($($v.Label))" } else { '' })
      [void]$sp.Children.Add((New-TB $name 16 '#E6F1FF' 'SemiBold'))
      $bar = New-Object System.Windows.Controls.ProgressBar; $bar.Height = 12; $bar.Maximum = 100; $bar.Value = $v.UsedPct; $bar.Foreground = B $col; $bar.Margin = '0,8,0,6'
      [void]$sp.Children.Add($bar)
      $msg = "$($v.FreeGB) GB free of $($v.SizeGB) GB  ($($v.UsedPct)% used)  -  $($v.FS)"
      if ($v.UsedPct -ge 90) { $msg += "`nALMOST FULL: Windows will be slow and updates may fail. Free up space: Settings > System > Storage > Cleanup recommendations." }
      [void]$sp.Children.Add((New-TB $msg 13)); $c.Child = $sp; [void]$p.Children.Add($c)
    }
    Add-XP 30 'Disk health checked'; Grant-Badge 'disk_doctor'
  }
}

function Start-DiskErrorScan {
  $letter = $env:SystemDrive.Substring(0, 1)
  $script:UI.BtnDiskScan.IsEnabled = $false; $script:UI.DiskProgress.Visibility = 'Visible'
  $script:UI.TxtDiskScan.Foreground = B '#00E5FF'; $script:UI.TxtDiskScan.Text = "Scanning drive $letter`: for file system errors (read-only, nothing is changed). This can take a few minutes..."
  Start-Background -Work $script:DiskScanWork -ArgumentList @($letter) -OnDone {
    param($res, $err)
    $script:UI.BtnDiskScan.IsEnabled = $true; $script:UI.DiskProgress.Visibility = 'Collapsed'
    if ($err) { $script:UI.TxtDiskScan.Foreground = B '#FF8A3D'; $script:UI.TxtDiskScan.Text = "Couldn't scan: $err`nThis needs Administrator rights - restart Guardian Shield and choose YES when Windows asks."; return }
    if ($res -match 'NoErrorsFound') { $script:UI.TxtDiskScan.Foreground = B '#39FF88'; $script:UI.TxtDiskScan.Text = 'RESULT: No errors found. Your drive''s file system is healthy.' }
    else { $script:UI.TxtDiskScan.Foreground = B '#FFC23D'; $script:UI.TxtDiskScan.Text = "RESULT: $res`nErrors were found. To repair them: open Command Prompt as Administrator, type   chkdsk /f   and restart." }
    Add-XP 25 'Drive error scan'
  }
}
