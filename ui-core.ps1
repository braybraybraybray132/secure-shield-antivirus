# Guardian Shield - screen building blocks, background-task runner, profile, XP and badges.

$script:BC = New-Object System.Windows.Media.BrushConverter
function B([string]$Hex) { return $script:BC.ConvertFromString($Hex) }
function C([string]$Hex) { return [System.Windows.Media.ColorConverter]::ConvertFromString($Hex) }
$script:Bul = [string][char]0x2022

$script:SevColors = @{ CRITICAL = '#FF3B5C'; HIGH = '#FF8A3D'; MEDIUM = '#FFC23D'; LOW = '#00E5FF'; INFO = '#00E5FF'; PASS = '#39FF88'; WARN = '#FFC23D'; FAIL = '#FF3B5C'; UNKNOWN = '#7F8EA8' }
function Get-SevColor([string]$Tag) { $c = $script:SevColors[$Tag.ToUpper()]; if ($c) { return $c } else { return '#7F8EA8' } }

function New-TB {
  param([string]$Text = '', [double]$Size = 14, [string]$Color = '#B8C6DE', [string]$Weight = 'Normal', [string]$Margin = '0', [string]$Font = '')
  $t = New-Object System.Windows.Controls.TextBlock
  $t.Text = $Text; $t.FontSize = $Size; $t.Foreground = B $Color
  $t.FontWeight = [System.Windows.FontWeights]::$Weight
  $t.TextWrapping = 'Wrap'; $t.Margin = $Margin
  if ($Font) { $t.FontFamily = New-Object System.Windows.Media.FontFamily($Font) }
  return $t
}
function New-Card([string]$Border = '#1C2A45', [string]$Bg = '#0E1524', [string]$Margin = '0,0,0,12') {
  $b = New-Object System.Windows.Controls.Border
  $b.Background = B $Bg; $b.BorderBrush = B $Border; $b.BorderThickness = '1'; $b.CornerRadius = '10'; $b.Padding = '18'; $b.Margin = $Margin
  return $b
}
function New-Stack([string]$Orientation = 'Vertical') { $s = New-Object System.Windows.Controls.StackPanel; $s.Orientation = $Orientation; return $s }
function New-Pill([string]$Text, [string]$Color) {
  $b = New-Object System.Windows.Controls.Border
  $b.CornerRadius = '10'; $b.Padding = '9,2'; $b.Margin = '0,0,8,4'; $b.HorizontalAlignment = 'Left'
  $b.Background = B ('#22' + $Color.TrimStart('#')); $b.BorderBrush = B $Color; $b.BorderThickness = '1'
  $b.Child = New-TB $Text 11 $Color 'SemiBold' '0' 'Consolas'
  return $b
}
function New-Bullets($Panel, [string]$Text, [string]$Color = '#B8C6DE') {
  foreach ($p in ($Text -split '\s*\|\|\s*')) { if ($p.Trim()) { [void]$Panel.Children.Add((New-TB ("  " + $script:Bul + "  " + $p.Trim()) 14 $Color 'Normal' '0,3,0,3')) } }
}
function New-Button([string]$Text, [string]$Style = 'Ghost', $Tag = $null) {
  $btn = New-Object System.Windows.Controls.Button
  $btn.Content = $Text; $btn.Style = $script:Window.FindResource($Style); $btn.Tag = $Tag; $btn.HorizontalAlignment = 'Left'
  return $btn
}
function Open-Link([string]$Target) { if ($Target) { try { Start-Process $Target } catch { Show-Toast "Couldn't open: $Target" '#FF3B5C' } } }

# Standard intel card: tag pill, title, how it works, impact, defence bullets
function Add-InfoCard($Panel, $Item) {
  $col = Get-SevColor ([string]$Item.tag)
  $c = New-Card $col; $sp = New-Stack
  $hdr = New-Stack 'Horizontal'
  if ($Item.tag) { [void]$hdr.Children.Add((New-Pill $Item.tag $col)) }
  if ($Item.when) { [void]$hdr.Children.Add((New-Pill $Item.when '#8FA0BC')) }
  [void]$sp.Children.Add($hdr)
  [void]$sp.Children.Add((New-TB $Item.Title 19 '#E6F1FF' 'SemiBold' '0,6,0,8' 'Bahnschrift SemiBold'))
  if ($Item.how)    { [void]$sp.Children.Add((New-TB 'HOW IT WORKS' 12 '#00E5FF' 'Normal' '0,4,0,2' 'Consolas')); [void]$sp.Children.Add((New-TB $Item.how)) }
  if ($Item.impact) { [void]$sp.Children.Add((New-TB 'HOW IT AFFECTS YOU' 12 '#FF2E88' 'Normal' '0,10,0,2' 'Consolas')); [void]$sp.Children.Add((New-TB $Item.impact)) }
  if ($Item.defend) { [void]$sp.Children.Add((New-TB 'HOW TO DEFEND YOURSELF' 12 '#39FF88' 'Normal' '0,10,0,2' 'Consolas')); New-Bullets $sp $Item.defend '#D6E2F5' }
  $c.Child = $sp; [void]$Panel.Children.Add($c)
}

# ---------- Run slow work in the background, then call OnDone on the screen thread ----------
function Start-Background {
  param([scriptblock]$Work, [scriptblock]$OnDone, [object[]]$ArgumentList = @())
  $ps = [PowerShell]::Create()
  [void]$ps.AddScript($Work.ToString())
  foreach ($a in $ArgumentList) { [void]$ps.AddArgument($a) }
  $handle = $ps.BeginInvoke()
  $timer = New-Object System.Windows.Threading.DispatcherTimer
  $timer.Interval = [TimeSpan]::FromMilliseconds(250)
  $timer.Tag = @{ PS = $ps; Handle = $handle; OnDone = $OnDone }
  $timer.Add_Tick({
    param($s, $e)
    $st = $s.Tag
    if (-not $st.Handle.IsCompleted) { return }
    $s.Stop()
    $result = $null; $err = $null
    try { $result = $st.PS.EndInvoke($st.Handle) } catch { $err = $_.Exception.InnerException.Message; if (-not $err) { $err = $_.Exception.Message } }
    if (-not $err -and $st.PS.HadErrors -and (-not $result -or $result.Count -eq 0)) { $err = [string]($st.PS.Streams.Error | Select-Object -First 1) }
    $st.PS.Dispose()
    $out = $null; if ($result -and $result.Count -eq 1) { $out = $result[0] } elseif ($result) { $out = @($result) }
    & $st.OnDone $out $err
  })
  $timer.Start()
}

# ---------- Toast pop-up ----------
$script:ToastTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:ToastTimer.Interval = [TimeSpan]::FromSeconds(4)
$script:ToastTimer.Add_Tick({ $script:UI.Toast.Visibility = 'Collapsed'; $script:ToastTimer.Stop() })
function Show-Toast([string]$Text, [string]$Color = '#00E5FF') {
  $script:UI.ToastText.Text = $Text; $script:UI.ToastText.Foreground = B $Color; $script:UI.Toast.BorderBrush = B $Color
  $fx = New-Object System.Windows.Media.Effects.DropShadowEffect; $fx.Color = C $Color; $fx.BlurRadius = 24; $fx.ShadowDepth = 0; $fx.Opacity = 0.6
  $script:UI.Toast.Effect = $fx; $script:UI.Toast.Visibility = 'Visible'
  $script:ToastTimer.Stop(); $script:ToastTimer.Start()
}

# ---------- Profile (saved in %APPDATA%\GuardianShield\profile.json) ----------
$script:AppDir = Join-Path $env:APPDATA 'GuardianShield'
$script:ProfilePath = Join-Path $script:AppDir 'profile.json'
function Read-GsProfile {
  $p = @{ Name = 'Agent'; XP = 0; Badges = @(); History = @(); Visited = @(); Questions = 0; HibpKey = ''; Joined = (Get-Date).ToString('d MMMM yyyy') }
  if (Test-Path $script:ProfilePath) {
    try {
      $j = Get-Content $script:ProfilePath -Raw | ConvertFrom-Json
      foreach ($k in @('Name', 'XP', 'Questions', 'HibpKey', 'Joined')) { if ($null -ne $j.$k) { $p[$k] = $j.$k } }
      foreach ($k in @('Badges', 'Visited')) { if ($j.$k) { $p[$k] = @($j.$k) } }
      if ($j.History) { $p.History = @($j.History | ForEach-Object { @{ Date = [string]$_.Date; Score = [int]$_.Score } }) }
      $p.XP = [int]$p.XP; $p.Questions = [int]$p.Questions
    } catch {}
  }
  return $p
}
function Save-GsProfile {
  if (-not (Test-Path $script:AppDir)) { New-Item -ItemType Directory -Path $script:AppDir -Force | Out-Null }
  $script:Me | ConvertTo-Json -Depth 5 | Set-Content -Path $script:ProfilePath -Encoding UTF8
}

# ---------- Ranks, XP and badges ----------
$script:Ranks = @(
  @{ N = 'RECRUIT'; X = 0 }, @{ N = 'SCOUT'; X = 150 }, @{ N = 'DEFENDER'; X = 400 }, @{ N = 'SENTINEL'; X = 800 },
  @{ N = 'GUARDIAN'; X = 1500 }, @{ N = 'ELITE GUARDIAN'; X = 2500 }, @{ N = 'LEGEND'; X = 4000 }
)
$script:BadgeDefs = [ordered]@{
  first_scan     = @{ N = 'First Contact';       D = 'Run your first full system scan';           I = [char]0xE9D9 }
  fortress       = @{ N = 'Fortress';            D = 'Reach a Shield Score of 90 or more';        I = [char]0xEA18 }
  av_scan        = @{ N = 'Bug Squasher';        D = 'Run an antivirus scan';                     I = [char]0xEBE8 }
  malware_hunter = @{ N = 'Malware Hunter';      D = 'Check a file in the Malware Checker';       I = [char]0xE721 }
  disk_doctor    = @{ N = 'Disk Doctor';         D = 'Check your hard disk health';               I = [char]0xEDA2 }
  pw_master      = @{ N = 'Password Master';     D = 'Test a password that scores 85+';           I = [char]0xE72E }
  leak_seeker    = @{ N = 'Leak Seeker';         D = 'Check a password or email for leaks';       I = [char]0xE715 }
  phish_buster   = @{ N = 'Phish Buster';        D = 'Analyse a suspicious message';              I = [char]0xE7BA }
  scam_spotter   = @{ N = 'Scam Spotter';        D = 'Study both the Card and Phishing radars';   I = [char]0xE8C7 }
  intel          = @{ N = 'Intel Analyst';       D = 'Download the live threat feed';             I = [char]0xE774 }
  breach_aware   = @{ N = 'Breach Aware';        D = 'Build your breach action plan';             I = [char]0xE716 }
  student        = @{ N = 'Student of the Shield'; D = 'Ask Shield AI 5 questions';               I = [char]0xE99A }
}
function Get-RankInfo([int]$Xp) {
  $i = 0; for ($k = 0; $k -lt $script:Ranks.Count; $k++) { if ($Xp -ge $script:Ranks[$k].X) { $i = $k } }
  $next = $null; if ($i -lt $script:Ranks.Count - 1) { $next = $script:Ranks[$i + 1].X }
  return @{ Index = $i; Name = $script:Ranks[$i].N; Level = $i + 1; Floor = $script:Ranks[$i].X; Next = $next }
}
function Update-RankUI {
  $r = Get-RankInfo $script:Me.XP
  $script:UI.TxtPlayerName.Text = ([string]$script:Me.Name).ToUpper()
  $script:UI.TxtRank.Text = "$($r.Name)  //  LVL $($r.Level)"
  if ($r.Next) { $pct = 100 * ($script:Me.XP - $r.Floor) / ($r.Next - $r.Floor); $txt = "$($script:Me.XP) XP  -  $($r.Next - $script:Me.XP) XP to next rank" }
  else { $pct = 100; $txt = "$($script:Me.XP) XP  -  MAX RANK" }
  $script:UI.XpBar.Value = $pct; $script:UI.TxtXp.Text = $txt
}
function Add-XP([int]$Amount, [string]$Why) {
  $old = (Get-RankInfo $script:Me.XP).Index
  $script:Me.XP = [int]$script:Me.XP + $Amount
  Save-GsProfile; Update-RankUI
  $new = Get-RankInfo $script:Me.XP
  if ($new.Index -gt $old) { Show-Toast "RANK UP!  You are now $($new.Name)" '#FF2E88' } else { Show-Toast "+$Amount XP   $Why" }
}
function Grant-Badge([string]$Id) {
  if (@($script:Me.Badges) -contains $Id) { return }
  $script:Me.Badges = @($script:Me.Badges) + $Id
  Save-GsProfile
  Show-Toast "BADGE UNLOCKED:  $($script:BadgeDefs[$Id].N)" '#FFC23D'
}

# ---------- Score ring ----------
function Set-Ring([double]$Pct) {
  if ($Pct -le 0) { $script:UI.RingArc.Data = $null; return }
  $inv = [Globalization.CultureInfo]::InvariantCulture
  $r = 102; $cx = 120; $cy = 120
  $angle = [Math]::Min($Pct, 99.99) / 100 * 360
  $rad = ($angle - 90) * [Math]::PI / 180
  $x = $cx + $r * [Math]::Cos($rad); $y = $cy + $r * [Math]::Sin($rad)
  $large = 0; if ($angle -gt 180) { $large = 1 }
  $data = 'M {0},{1} A {2},{2} 0 {3} 1 {4},{5}' -f $cx.ToString($inv), ($cy - $r).ToString($inv), $r.ToString($inv), $large, $x.ToString('0.###', $inv), $y.ToString('0.###', $inv)
  $script:UI.RingArc.Data = [System.Windows.Media.Geometry]::Parse($data)
}
function Set-RingColor([string]$Hex) {
  $script:UI.RingArc.Stroke = B $Hex
  $fx = New-Object System.Windows.Media.Effects.DropShadowEffect; $fx.Color = C $Hex; $fx.BlurRadius = 22; $fx.ShadowDepth = 0; $fx.Opacity = 0.85
  $script:UI.RingArc.Effect = $fx
}
function Start-ScoreAnimation([int]$Target) {
  $script:AnimCur = 0; $script:AnimTarget = $Target
  if ($script:AnimTimer) { $script:AnimTimer.Stop() }
  $script:AnimTimer = New-Object System.Windows.Threading.DispatcherTimer
  $script:AnimTimer.Interval = [TimeSpan]::FromMilliseconds(16)
  $script:AnimTimer.Add_Tick({
    $step = [Math]::Max(1, [int](($script:AnimTarget - $script:AnimCur) / 8))
    $script:AnimCur = [Math]::Min($script:AnimTarget, $script:AnimCur + $step)
    Set-Ring $script:AnimCur; $script:UI.TxtScore.Text = [string]$script:AnimCur
    if ($script:AnimCur -ge $script:AnimTarget) { $script:AnimTimer.Stop() }
  })
  $script:AnimTimer.Start()
}
function Start-Spinner {
  $script:UI.ScanSpinner.Opacity = 0.9
  $rt = New-Object System.Windows.Media.RotateTransform; $script:UI.ScanSpinner.RenderTransform = $rt
  $anim = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 360, (New-Object System.Windows.Duration([TimeSpan]::FromSeconds(1.4))))
  $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
  $rt.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $anim)
}
function Stop-Spinner { $script:UI.ScanSpinner.Opacity = 0; $script:UI.ScanSpinner.RenderTransform = $null }
