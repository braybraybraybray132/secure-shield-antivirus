# Guardian Shield - Password Lab, Email Guard, Breaches, Intel pages, AI Adviser, Tips and Membership.

# ================= PASSWORD LAB =================
function Get-TypedPassword { if ($script:UI.ChkShowPwd.IsChecked) { return $script:UI.PwdVisible.Text } else { return $script:UI.PwdInput.Password } }
function Update-PasswordMeter {
  $pw = Get-TypedPassword
  $r = Test-PasswordStrength $pw
  $script:UI.PwdMeter.Value = $r.Score; $script:UI.PwdMeter.Foreground = B $r.Color
  $script:UI.TxtPwdScore.Text = "$($r.Score)/100"; $script:UI.TxtPwdScore.Foreground = B $r.Color
  $script:UI.TxtPwdVerdict.Text = $r.Verdict; $script:UI.TxtPwdVerdict.Foreground = B $r.Color
  $script:UI.TxtCrackTime.Text = $(if ($pw) { "Time for a criminal's computer to crack it: $($r.Crack)   (strength: $($r.Entropy) bits)" } else { '' })
  $script:UI.PwdFeedback.Children.Clear()
  foreach ($f in $r.Feedback) { [void]$script:UI.PwdFeedback.Children.Add((New-TB ("  " + $script:Bul + "  " + $f) 14 '#D6E2F5' 'Normal' '0,2,0,2')) }
  $script:UI.TxtPwnedResult.Text = ''
  if ($r.Score -ge 85 -and -not $script:PwBadgeGiven) { $script:PwBadgeGiven = $true; Grant-Badge 'pw_master'; Add-XP 15 'Strong password tested' }
}
function Start-PwnedCheck {
  $pw = Get-TypedPassword
  if (-not $pw) { Show-Toast 'Type a password first.' '#FFC23D'; return }
  $hash = Get-Sha1Hex $pw
  $script:UI.BtnPwned.IsEnabled = $false
  $script:UI.TxtPwnedResult.Foreground = B '#00E5FF'
  $script:UI.TxtPwnedResult.Text = "Checking... (only the first 5 characters of the scrambled code are sent: $($hash.Substring(0,5))...)"
  Start-Background -Work $script:PwnedWork -ArgumentList @($hash.Substring(0, 5), $hash.Substring(5)) -OnDone {
    param($count, $err)
    $script:UI.BtnPwned.IsEnabled = $true
    if ($err) { $script:UI.TxtPwnedResult.Foreground = B '#FF8A3D'; $script:UI.TxtPwnedResult.Text = "Couldn't reach the leak database (are you online?): $err"; return }
    if ([int]$count -gt 0) { $script:UI.TxtPwnedResult.Foreground = B '#FF3B5C'; $script:UI.TxtPwnedResult.Text = ("LEAKED! This password has appeared {0:N0} times in data breaches. Criminals have it on their lists. STOP using it everywhere and change it now." -f [int]$count) }
    else { $script:UI.TxtPwnedResult.Foreground = B '#39FF88'; $script:UI.TxtPwnedResult.Text = 'Good news: this password was NOT found in any known data breach (out of billions of leaked passwords).' }
    Add-XP 20 'Leak check'; Grant-Badge 'leak_seeker'
  }
}

# ================= EMAIL GUARD =================
function Get-HibpKey {
  if (-not $script:Me.HibpKey) { return '' }
  try {
    $ss = ConvertTo-SecureString $script:Me.HibpKey -ErrorAction Stop
    $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
  } catch { return '' }
}
function Start-EmailCheck {
  $email = $script:UI.TxtEmail.Text.Trim()
  if ($email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { Show-Toast 'Please type a full email address, like name@example.com' '#FFC23D'; return }
  $key = Get-HibpKey
  $script:UI.EmailBreaches.Children.Clear()
  if (-not $key) {
    [System.Windows.Clipboard]::SetText($email)
    $script:UI.TxtEmailResult.Foreground = B '#00E5FF'
    $script:UI.TxtEmailResult.Text = "Your email has been COPIED. Have I Been Pwned is opening in your browser now:`n  1. Click in the search box on that page.`n  2. Press Ctrl + V to paste your email.`n  3. Press the 'Check' button.`nIf it says 'Oh no - pwned!', it lists each breach. Change your password on those sites, and anywhere you used the same password. Then come back to the Aussie Breaches tab for an action plan."
    Open-Link 'https://haveibeenpwned.com/'
    Add-XP 25 'Email breach check'; Grant-Badge 'leak_seeker'; return
  }
  $script:UI.EmailProgress.Visibility = 'Visible'; $script:UI.BtnEmailCheck.IsEnabled = $false
  $script:UI.TxtEmailResult.Text = 'Checking billions of breached records...'
  Start-Background -Work $script:HibpWork -ArgumentList @($email, $key) -OnDone {
    param($r, $err)
    $script:UI.EmailProgress.Visibility = 'Collapsed'; $script:UI.BtnEmailCheck.IsEnabled = $true
    if (-not $r) { $script:UI.TxtEmailResult.Text = "Error: $err"; return }
    switch ($r.Status) {
      'none'   { $script:UI.TxtEmailResult.Foreground = B '#39FF88'; $script:UI.TxtEmailResult.Text = 'GOOD NEWS: this email was not found in any known data breach.' }
      'badkey' { $script:UI.TxtEmailResult.Foreground = B '#FF8A3D'; $script:UI.TxtEmailResult.Text = 'Your API key was rejected. Check it and save it again (Advanced section below).' }
      'rate'   { $script:UI.TxtEmailResult.Foreground = B '#FFC23D'; $script:UI.TxtEmailResult.Text = 'Too many checks too quickly - wait a minute and try again.' }
      'error'  { $script:UI.TxtEmailResult.Foreground = B '#FF8A3D'; $script:UI.TxtEmailResult.Text = "Couldn't check right now: $($r.Msg)" }
      'found'  {
        $list = @($r.Data | Sort-Object { [datetime]$_.BreachDate } -Descending)
        $script:UI.TxtEmailResult.Foreground = B '#FF3B5C'
        $script:UI.TxtEmailResult.Text = "PWNED: this email appears in $($list.Count) data breach(es). For each one below: change that site's password, and change it anywhere else you reused it. Turn on two-factor."
        foreach ($b in $list) {
          $c = New-Card '#FF3B5C'; $sp = New-Stack
          [void]$sp.Children.Add((New-TB $b.Title 17 '#E6F1FF' 'SemiBold' '0,0,0,4' 'Bahnschrift SemiBold'))
          [void]$sp.Children.Add((New-TB ("Breach date: {0}   |   Accounts affected: {1:N0}" -f $b.BreachDate, [long]$b.PwnCount) 13 '#8FA0BC'))
          [void]$sp.Children.Add((New-TB ('Stolen: ' + (@($b.DataClasses) -join ', ')) 14 '#FFC23D' 'Normal' '0,6,0,0'))
          $c.Child = $sp; [void]$script:UI.EmailBreaches.Children.Add($c)
        }
      }
    }
    Add-XP 25 'Email breach check'; Grant-Badge 'leak_seeker'
  }
}
function Start-EmailAnalysis {
  $body = $script:UI.TxtEmailBody.Text; $sender = $script:UI.TxtSender.Text
  if (-not $body.Trim()) { Show-Toast 'Paste a message into the big box first.' '#FFC23D'; return }
  $r = Test-PhishingMessage $sender $body
  $p = $script:UI.EmailVerdict; $p.Children.Clear()
  $c = New-Card $r.Color '#0E1524' '0,14,0,0'; $sp = New-Stack
  [void]$sp.Children.Add((New-TB "SCAM RISK: $($r.Risk)/100" 26 $r.Color 'Bold' '0' 'Bahnschrift SemiBold'))
  [void]$sp.Children.Add((New-TB $r.Verdict 16 $r.Color 'SemiBold' '0,2,0,10'))
  if ($r.Flags.Count -gt 0) {
    [void]$sp.Children.Add((New-TB "RED FLAGS FOUND ($($r.Flags.Count))" 12 '#FF2E88' 'Normal' '0,0,0,4' 'Consolas'))
    foreach ($f in ($r.Flags | Sort-Object { - $_.W })) { [void]$sp.Children.Add((New-TB ("  " + $script:Bul + "  " + $f.T) 14 '#D6E2F5' 'Normal' '0,2,0,2')) }
  }
  if (@($r.Links).Count -gt 0) { [void]$sp.Children.Add((New-TB ('Links in the message go to: ' + (@($r.Links) -join ', ')) 13 '#8FA0BC' 'Normal' '0,10,0,0')) }
  $adv = $(if ($r.Risk -ge 25) { 'WHAT TO DO: Don''t click any links, don''t reply, and don''t call numbers in the message. If it claims to be a company, open their official app or type their website yourself. Report it at scamwatch.gov.au, then delete it.' } else { 'Even with no red flags, never enter passwords or card details from a link in a message. When in doubt, go to the official app or website yourself.' })
  [void]$sp.Children.Add((New-TB $adv 14 '#39FF88' 'Normal' '0,12,0,0'))
  $c.Child = $sp; [void]$p.Children.Add($c)
  Add-XP 25 'Message analysed'; Grant-Badge 'phish_buster'
}

# ================= BREACHES =================
function Initialize-BreachPage {
  $script:BreachChecks = @()
  foreach ($b in $script:BreachItems) {
    $c = New-Card '#2A3C63'; $sp = New-Stack
    $cb = New-Object System.Windows.Controls.CheckBox; $cb.Margin = '0'; $cb.Tag = $b
    $cb.Content = New-TB $b.Title 18 '#E6F1FF' 'SemiBold' '0' 'Bahnschrift SemiBold'
    [void]$sp.Children.Add($cb)
    $h = New-Stack 'Horizontal'; $h.Margin = '0,8,0,4'
    [void]$h.Children.Add((New-Pill $b.when '#8FA0BC')); [void]$h.Children.Add((New-Pill $b.size '#FF8A3D')); [void]$sp.Children.Add($h)
    [void]$sp.Children.Add((New-TB ('What was stolen: ' + $b.data) 14 '#FFC23D'))
    if ($b.how) { [void]$sp.Children.Add((New-TB $b.how 13 '#8FA0BC' 'Normal' '0,4,0,0')) }
    $c.Child = $sp; [void]$script:UI.BreachList.Children.Add($c); $script:BreachChecks += $cb
  }
  foreach ($l in $script:HelpLinks) {
    $row = New-Stack; $row.Margin = '0,0,0,10'
    $btn = New-Button $l.N 'Ghost' $l.U; $btn.Margin = '0,0,0,2'; $btn.Add_Click({ param($s, $e) Open-Link $s.Tag })
    [void]$row.Children.Add($btn); [void]$row.Children.Add((New-TB $l.D 13 '#8FA0BC')); [void]$script:UI.HelpList.Children.Add($row)
  }
}
function Build-BreachPlan {
  $sel = @($script:BreachChecks | Where-Object { $_.IsChecked } | ForEach-Object { $_.Tag })
  $p = $script:UI.BreachPlan; $p.Children.Clear()
  $c = New-Card '#00E5FF'; $sp = New-Stack
  [void]$sp.Children.Add((New-TB 'YOUR PERSONAL ACTION PLAN' 13 '#00E5FF' 'Normal' '0,0,0,8' 'Consolas'))
  if ($sel.Count -eq 0) { [void]$sp.Children.Add((New-TB 'You didn''t tick any breaches - great! Still do the "Everyone" steps below, because many breaches are never noticed.' 15 '#39FF88')) }
  else {
    $risk = 'MEDIUM'; $all = ($sel | ForEach-Object { $_.data }) -join ' '
    if ($all -match 'licence|passport|card|bank') { $risk = 'HIGH' }
    [void]$sp.Children.Add((New-TB "You may have been in $($sel.Count) breach(es). Identity risk: $risk" 18 (Get-SevColor $risk) 'SemiBold' '0,0,0,10' 'Bahnschrift SemiBold'))
    foreach ($b in $sel) {
      [void]$sp.Children.Add((New-TB $b.Title.ToUpper() 13 '#FF2E88' 'Normal' '0,8,0,2' 'Consolas'))
      New-Bullets $sp $b.do '#D6E2F5'
    }
  }
  [void]$sp.Children.Add((New-TB 'EVERYONE SHOULD ALSO:' 13 '#39FF88' 'Normal' '0,14,0,2' 'Consolas'))
  New-Bullets $sp 'Check your email at Have I Been Pwned (Email Guard tab). || Use a different password for every site - a password manager makes this easy. || Turn on two-factor authentication for email, banking and myGov. || Treat calls and texts that know your details with suspicion - leaked data makes scams more convincing. || If you think your ID is being misused, call IDCARE free on 1800 595 160.' '#D6E2F5'
  $c.Child = $sp; [void]$p.Children.Add($c)
  Add-XP 30 'Breach plan built'; Grant-Badge 'breach_aware'
}

# ================= LIVE THREAT FEED =================
function Start-KevLoad {
  $script:UI.BtnLoadKev.IsEnabled = $false; $script:UI.KevProgress.Visibility = 'Visible'
  $script:UI.TxtKevStatus.Text = 'Downloading the official list from CISA...'
  Start-Background -Work $script:KevWork -OnDone {
    param($res, $err)
    $script:UI.BtnLoadKev.IsEnabled = $true; $script:UI.KevProgress.Visibility = 'Collapsed'
    $p = $script:UI.VulnLive; $p.Children.Clear()
    if (-not $res) { $script:UI.TxtKevStatus.Text = "Couldn't download the feed (are you online?): $err"; return }
    $items = @($res.Items)
    $script:UI.TxtKevStatus.Text = "Feed updated $($res.Released). $($items.Count) new actively-exploited hole(s) added in the last 30 days (out of $($res.Total) on the list in total). Microsoft ones affect your PC directly."
    foreach ($v in $items) {
      $isMs = ("$($v.vendorProject)" -match 'Microsoft')
      $col = $(if ($isMs) { '#FF3B5C' } else { '#FF8A3D' })
      $c = New-Card $col; $sp = New-Stack
      $h = New-Stack 'Horizontal'
      [void]$h.Children.Add((New-Pill $v.cveID $col)); [void]$h.Children.Add((New-Pill ("Added " + $v.dateAdded) '#8FA0BC'))
      if ($v.knownRansomwareCampaignUse -eq 'Known') { [void]$h.Children.Add((New-Pill 'USED BY RANSOMWARE' '#FF2E88')) }
      if ($isMs) { [void]$h.Children.Add((New-Pill 'AFFECTS WINDOWS USERS' '#FF3B5C')) }
      [void]$sp.Children.Add($h)
      [void]$sp.Children.Add((New-TB $v.vulnerabilityName 16 '#E6F1FF' 'SemiBold' '0,6,0,4'))
      [void]$sp.Children.Add((New-TB ("Product: $($v.vendorProject) $($v.product)") 13 '#8FA0BC'))
      [void]$sp.Children.Add((New-TB $v.shortDescription 14 '#B8C6DE' 'Normal' '0,6,0,0'))
      [void]$sp.Children.Add((New-TB 'WHAT IT MEANS FOR YOU' 12 '#39FF88' 'Normal' '0,10,0,2' 'Consolas'))
      [void]$sp.Children.Add((New-TB (Get-KevImpact $v) 14 '#D6E2F5'))
      $c.Child = $sp; [void]$p.Children.Add($c)
    }
    Add-XP 25 'Threat intel downloaded'; Grant-Badge 'intel'
  }
}

# ================= SHIELD AI ADVISER =================
function Add-ChatBubble([string]$Who, [string]$Text) {
  $b = New-Object System.Windows.Controls.Border
  $b.CornerRadius = '12'; $b.Padding = '14,10'; $b.Margin = '0,0,0,10'; $b.MaxWidth = 680; $b.BorderThickness = '1'
  $sp = New-Stack
  if ($Who -eq 'user') { $b.HorizontalAlignment = 'Right'; $b.Background = B '#0F2A40'; $b.BorderBrush = B '#00A8C0'; [void]$sp.Children.Add((New-TB ([string]$script:Me.Name).ToUpper() 11 '#00E5FF' 'Normal' '0,0,0,4' 'Consolas')) }
  else { $b.HorizontalAlignment = 'Left'; $b.Background = B '#18122A'; $b.BorderBrush = B '#FF2E88'; [void]$sp.Children.Add((New-TB 'SHIELD AI' 11 '#FF2E88' 'Normal' '0,0,0,4' 'Consolas')) }
  [void]$sp.Children.Add((New-TB $Text 14 '#E6F1FF'))
  $b.Child = $sp; [void]$script:UI.ChatPanel.Children.Add($b); $script:UI.ChatScroll.ScrollToEnd()
  return $b
}
function Get-ScanAdvice {
  if (-not $script:LastScan) { return "I haven't seen a scan yet. Go to the Dashboard and press RUN FULL SYSTEM SCAN - then ask me again and I'll explain every problem." }
  $probs = @($script:LastScan.Checks | Where-Object { $_.Status -eq 'Fail' -or $_.Status -eq 'Warn' } | Sort-Object { if ($_.Status -eq 'Fail') { 0 } else { 1 } }, { - $_.Max })
  if ($probs.Count -eq 0) { return "Your latest Shield Score is $($script:LastScore)/100 and every check passed. Your PC is in excellent shape! Keep it that way: let updates install, restart weekly, and scan once a week." }
  $lines = @("Your Shield Score is $($script:LastScore)/100. Here is what's pulling it down, most important first:")
  $n = 1; foreach ($c in $probs) { $lines += ''; $lines += "$n. $($c.Title.ToUpper()) - $($c.Detail)"; $lines += "   How to fix: $($c.Fix)"; $n++ }
  $lines += ''; $lines += 'Tip: the PC Scan tab has a FIX IT button next to most of these that opens the right Windows setting for you.'
  return ($lines -join "`n")
}
function Send-ChatQuestion([string]$Q) {
  if (-not $Q.Trim()) { return }
  Add-ChatBubble 'user' $Q | Out-Null
  $script:UI.ChatInput.Text = ''
  $low = $Q.ToLower()
  if ($low -match 'score|what.?s wrong|scan result|is my (pc|computer|laptop) (safe|ok|secure|protected|vulnerable)|my (pc|computer|laptop) (safe|ok|secure|vulnerable)') { $ans = Get-ScanAdvice }
  else {
    $ans = Find-AdviserAnswer $Q $script:KbItems
    if (-not $ans) { $ans = "I'm not sure about that one yet. I know about: viruses, scams, phishing, passwords, two-factor, data breaches, card fraud, Windows updates, ransomware, gaming safety, kids' safety, Wi-Fi, disks and reporting a scam.`nTry asking it a different way - for example 'What should I do if I clicked a link?'" }
  }
  $thinking = Add-ChatBubble 'ai' 'thinking...'
  $t = New-Object System.Windows.Threading.DispatcherTimer; $t.Interval = [TimeSpan]::FromMilliseconds(550)
  $t.Tag = @{ Bubble = $thinking; Answer = $ans }
  $t.Add_Tick({ param($s, $e) $s.Stop(); $script:UI.ChatPanel.Children.Remove($s.Tag.Bubble); Add-ChatBubble 'ai' $s.Tag.Answer | Out-Null })
  $t.Start()
  $script:Me.Questions = [int]$script:Me.Questions + 1; Save-GsProfile
  Add-XP 5 'Question asked'
  if ($script:Me.Questions -ge 5) { Grant-Badge 'student' }
}
function Initialize-AdviserPage {
  $chips = @("Why is my score low?", "I think I have a virus", "I clicked a phishing link", "Someone used my credit card", "I was in the Optus breach",
    "How do I make a strong password?", "Is Windows Defender enough?", "Are game cheats safe to download?", "What is a zero-day?", "How do I report a scam?")
  foreach ($q in $chips) {
    $btn = New-Button $q 'Ghost' $q; $btn.Padding = '10,5'; $btn.Margin = '0,0,8,8'; $btn.FontSize = 12
    $btn.Add_Click({ param($s, $e) Send-ChatQuestion $s.Tag }); [void]$script:UI.ChatChips.Children.Add($btn)
  }
  Add-ChatBubble 'ai' "G'day, $($script:Me.Name)! I'm Shield AI, your personal security adviser. I work offline, so nothing you type leaves this PC.`nAsk me anything - or tap a question below." | Out-Null
}

# ================= TIPS =================
function Initialize-TipsPage {
  foreach ($t in $script:TipsItems) {
    $c = New-Card; $sp = New-Stack
    $h = New-Stack 'Horizontal'
    $ic = New-TB ([string][char][Convert]::ToInt32($t.icon, 16)) 22 '#00E5FF' 'Normal' '0,0,12,0' 'Segoe MDL2 Assets'
    [void]$h.Children.Add($ic); [void]$h.Children.Add((New-TB $t.Title 19 '#E6F1FF' 'SemiBold' '0' 'Bahnschrift SemiBold')); [void]$sp.Children.Add($h)
    $inner = New-Stack; $inner.Margin = '0,8,0,0'; New-Bullets $inner $t.tips '#D6E2F5'; [void]$sp.Children.Add($inner)
    $c.Child = $sp; [void]$script:UI.TipsList.Children.Add($c)
  }
}

# ================= MEMBERSHIP =================
function Update-MemberPage {
  $r = Get-RankInfo $script:Me.XP
  $script:UI.MemName.Text = ([string]$script:Me.Name).ToUpper()
  $script:UI.MemRank.Text = "RANK: $($r.Name)   //   LEVEL $($r.Level)"
  if ($r.Next) { $script:UI.MemXpBar.Value = 100 * ($script:Me.XP - $r.Floor) / ($r.Next - $r.Floor); $script:UI.MemXpText.Text = "$($script:Me.XP) XP   -   $($r.Next - $script:Me.XP) XP until $($script:Ranks[$r.Index + 1].N)" }
  else { $script:UI.MemXpBar.Value = 100; $script:UI.MemXpText.Text = "$($script:Me.XP) XP   -   MAXIMUM RANK REACHED" }
  $script:UI.MemSince.Text = "Member since $($script:Me.Joined)   |   Badges: $(@($script:Me.Badges).Count) of $($script:BadgeDefs.Count)"
  $script:UI.TxtNameEdit.Text = $script:Me.Name

  $bp = $script:UI.BadgePanel; $bp.Children.Clear()
  foreach ($id in $script:BadgeDefs.Keys) {
    $d = $script:BadgeDefs[$id]; $got = (@($script:Me.Badges) -contains $id)
    $col = $(if ($got) { '#FFC23D' } else { '#2A3550' })
    $b = New-Object System.Windows.Controls.Border; $b.Width = 170; $b.Height = 150; $b.Margin = '0,0,12,12'; $b.CornerRadius = '12'; $b.Padding = '10'
    $b.BorderThickness = '1'; $b.BorderBrush = B $col; $b.Background = B $(if ($got) { '#1F1A10' } else { '#0B111D' })
    $sp = New-Stack
    $ic = New-TB ([string]$d.I) 34 $col 'Normal' '0,4,0,6' 'Segoe MDL2 Assets'; $ic.HorizontalAlignment = 'Center'
    $nm = New-TB $d.N 14 $(if ($got) { '#E6F1FF' } else { '#5C6C88' }) 'SemiBold'; $nm.TextAlignment = 'Center'
    $ds = New-TB $(if ($got) { 'UNLOCKED' } else { $d.D }) 11 $(if ($got) { '#FFC23D' } else { '#5C6C88' }); $ds.TextAlignment = 'Center'; $ds.Margin = '0,4,0,0'
    [void]$sp.Children.Add($ic); [void]$sp.Children.Add($nm); [void]$sp.Children.Add($ds); $b.Child = $sp; [void]$bp.Children.Add($b)
  }
  $rl = $script:UI.RankLadder; $rl.Children.Clear()
  for ($i = 0; $i -lt $script:Ranks.Count; $i++) {
    $rk = $script:Ranks[$i]
    $col = $(if ($i -lt $r.Index) { '#39FF88' } elseif ($i -eq $r.Index) { '#FF2E88' } else { '#5C6C88' })
    $mark = $(if ($i -lt $r.Index) { 'DONE   ' } elseif ($i -eq $r.Index) { 'YOU >  ' } else { '       ' })
    [void]$rl.Children.Add((New-TB ("{0} LVL {1}  {2,-16} {3,6} XP" -f $mark, ($i + 1), $rk.N, $rk.X) 14 $col 'Normal' '0,2,0,2' 'Consolas'))
  }
  $hl = $script:UI.HistoryList; $hl.Children.Clear()
  $hist = @($script:Me.History)
  if ($hist.Count -eq 0) { [void]$hl.Children.Add((New-TB 'No scans yet. Run one from the Dashboard!')) }
  foreach ($h in $hist) {
    $sc = [int]$h.Score; $col = $(if ($sc -ge 75) { '#39FF88' } elseif ($sc -ge 60) { '#FFC23D' } else { '#FF3B5C' })
    [void]$hl.Children.Add((New-TB ("{0,-30}  SCORE {1,3}/100" -f $h.Date, $sc) 14 $col 'Normal' '0,2,0,2' 'Consolas'))
  }
}
function Initialize-XpHowTo {
  $rows = @('Full system scan ............ +50 XP', 'Antivirus quick scan ........ +75 XP', 'Antivirus full scan ......... +150 XP', 'Update virus definitions .... +20 XP',
    'Check a file for malware .... +30 XP', 'Startup programs audit ...... +20 XP', 'Disk health check ........... +30 XP', 'Password leak check ......... +20 XP',
    'Email breach check .......... +25 XP', 'Analyse a scam message ...... +25 XP', 'Build breach action plan .... +30 XP', 'Download live threat feed ... +25 XP',
    'Read an intel briefing ...... +10 XP (first time)', 'Ask Shield AI a question .... +5 XP')
  foreach ($r in $rows) { [void]$script:UI.XpHowTo.Children.Add((New-TB $r 14 '#B8C6DE' 'Normal' '0,2,0,2' 'Consolas')) }
}
