# Guardian Shield - pure logic (no screen code). Password checks, generators, phishing analysis, data parsing.

# ---------- Read the "== Title / key: value" data format ----------
function ConvertFrom-GsData([string]$Text) {
  $items = New-Object System.Collections.ArrayList
  $cur = $null; $lastKey = $null
  foreach ($raw in ($Text -split "`r?`n")) {
    $line = $raw.TrimEnd()
    if ($line -match '^== (.+)$') { $cur = @{ Title = $Matches[1].Trim() }; [void]$items.Add($cur); $lastKey = $null; continue }
    if ($null -eq $cur) { continue }
    if ($line -match '^\+ (.*)$' -and $lastKey) { $cur[$lastKey] = $cur[$lastKey] + "`n" + $Matches[1]; continue }
    if ($line -match '^([a-z]+): (.*)$') { $lastKey = $Matches[1]; $cur[$lastKey] = $Matches[2] }
  }
  return ,$items.ToArray()
}

# ---------- Password strength ----------
$script:CommonPw = @('password','123456','12345678','qwerty','abc123','111111','iloveyou','admin','welcome','monkey','dragon',
  'football','letmein','sunshine','princess','master','shadow','baseball','superman','trustno1','starwars','whatever','qazwsx',
  'michael','jordan','hunter','killer','pokemon','minecraft','fortnite','roblox','summer','winter','charlie','freedom','batman',
  'computer','internet','hello','secret','login','australia','aussie','footy','cricket','liverpool','chelsea','arsenal','soccer',
  'hockey','ranger','buster','ginger','pepper','cookie','matrix','zaq12wsx','1q2w3e4r','asdfgh','zxcvbn','qwertyuiop','iloveu',
  'lovely','flower','ninja','azerty','loveme','666666','987654321','121212','000000','654321','gamer','gaming','valorant','xbox',
  'playstation','steam','discord','changeme','default','guest','access','mustang','maggie','tigger','robert','daniel','jessica')

function Format-Duration([double]$Seconds) {
  if ($Seconds -lt 1) { return 'instantly' }
  $units = @(@(31536000000000,'million years'),@(31536000000,'thousand years'),@(31536000,'years'),@(86400,'days'),@(3600,'hours'),@(60,'minutes'),@(1,'seconds'))
  if ($Seconds -gt 31536000 * 1e10) { return 'longer than the age of the universe' }
  foreach ($u in $units) { if ($Seconds -ge $u[0]) { return ('about {0:N0} {1}' -f [Math]::Floor($Seconds / $u[0]), $u[1]) } }
  return 'instantly'
}

function Test-PasswordStrength([string]$P) {
  $fb = New-Object System.Collections.ArrayList
  if (-not $P) { return @{ Score = 0; Verdict = ''; Color = '#7F8EA8'; Crack = ''; Feedback = @(); Entropy = 0 } }
  $len = $P.Length
  $hasL = $P -cmatch '[a-z]'; $hasU = $P -cmatch '[A-Z]'; $hasD = $P -match '\d'; $hasS = $P -match '[^a-zA-Z0-9]'
  $pool = 0; if ($hasL) { $pool += 26 }; if ($hasU) { $pool += 26 }; if ($hasD) { $pool += 10 }; if ($hasS) { $pool += 33 }
  $ent = $len * [Math]::Log([Math]::Max($pool, 2), 2)
  $lower = $P.ToLower()
  $norm = $lower -replace '@','a' -replace '4','a' -replace '0','o' -replace '1','i' -replace '!','i' -replace '3','e' -replace '\$','s' -replace '5','s' -replace '7','t'
  $penalty = 0
  if (($script:CommonPw -contains $lower) -or ($script:CommonPw -contains $norm) -or ($script:CommonPw -contains ($norm -replace '\d+$',''))) {
    $ent = [Math]::Min($ent, 12)
    [void]$fb.Add('This is one of the most common passwords in the world. Criminals try it in the first second.')
  } else {
    foreach ($w in $script:CommonPw) {
      if ($w.Length -ge 4 -and ($lower.Contains($w) -or $norm.Contains($w))) {
        $penalty += [Math]::Min($ent * 0.4, $w.Length * 3.5)
        [void]$fb.Add("Contains a well-known word ('$w'). Guessing programs try common words first, even with numbers or symbols swapped in.")
        break
      }
    }
  }
  $seqFound = $false
  foreach ($seq in @('abcdefghijklmnopqrstuvwxyz','qwertyuiop','asdfghjkl','zxcvbnm','01234567890','0987654321')) {
    for ($i = 0; $i -le $seq.Length - 4; $i++) { if ($lower.Contains($seq.Substring($i, 4))) { $seqFound = $true; break } }
    if ($seqFound) { break }
  }
  if ($seqFound) { $penalty += 10; [void]$fb.Add('Has a keyboard or alphabet run (like 1234, abcd or qwer). These are the first patterns tried.') }
  if ($P -match '(.)\1{2,}') { $penalty += 6; [void]$fb.Add('Repeats the same character 3+ times (like aaa or 111).') }
  if ($P -match '(19|20)\d{2}') { $penalty += 6; [void]$fb.Add('Contains what looks like a year. Birthdays and years are easy to guess from social media.') }
  if ($P -cmatch '^[A-Z][a-z]+\d+[^a-zA-Z0-9]?$') { $penalty += 10; [void]$fb.Add('Follows the most predictable pattern: Capital + word + numbers + symbol (like Summer2026!).') }
  if ($len -lt 8) { [void]$fb.Add("Only $len characters - far too short. Use at least 14.") }
  elseif ($len -lt 14) { [void]$fb.Add("$len characters is OK but not great. 14-16+ characters makes it MUCH harder to crack.") }
  $missing = @(); if (-not $hasU) { $missing += 'capital letters' }; if (-not $hasL) { $missing += 'small letters' }; if (-not $hasD) { $missing += 'numbers' }; if (-not $hasS) { $missing += 'symbols' }
  if ($missing.Count -gt 0 -and $len -lt 20) { [void]$fb.Add('Adding ' + ($missing -join ', ') + ' would make it stronger.') }
  $ent = [Math]::Max(0, $ent - $penalty)
  $score = [int][Math]::Min(100, [Math]::Round($ent / 90 * 100))
  if ($len -lt 12) { $score = [Math]::Min($score, 60) }   # short passwords are never 'good enough'
  if ($score -lt 25)     { $v = 'VERY WEAK - NOT GOOD ENOUGH'; $c = '#FF3B5C' }
  elseif ($score -lt 45) { $v = 'WEAK - NOT GOOD ENOUGH'; $c = '#FF8A3D' }
  elseif ($score -lt 65) { $v = 'FAIR - STILL NOT GOOD ENOUGH'; $c = '#FFC23D' }
  elseif ($score -lt 85) { $v = 'STRONG - GOOD ENOUGH'; $c = '#7CFF6B' }
  else                   { $v = 'EXCELLENT - UNBREAKABLE'; $c = '#39FF88' }
  if ($fb.Count -eq 0) { [void]$fb.Add('No weak patterns found. Make sure you only use it for ONE account.') }
  $secs = [Math]::Pow(2, $ent) / 2 / 1e10   # a gaming PC rig guessing ~10 billion passwords per second
  return @{ Score = $score; Verdict = $v; Color = $c; Crack = (Format-Duration $secs); Feedback = $fb.ToArray(); Entropy = [Math]::Round($ent) }
}

# ---------- Cryptographically secure random numbers ----------
$script:Rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
function Get-SecureIndex([int]$Max) {
  $bytes = New-Object byte[] 4
  $limit = 4294967296 - (4294967296 % $Max)
  while ($true) {
    $script:Rng.GetBytes($bytes)
    $v = [long][BitConverter]::ToUInt32($bytes, 0)
    if ($v -lt $limit) { return [int]($v % $Max) }
  }
}

function New-StrongPassword([int]$Length = 20, [bool]$Upper = $true, [bool]$Lower = $true, [bool]$Digits = $true, [bool]$Symbols = $true, [bool]$NoAmbiguous = $false) {
  $sets = @()
  if ($Upper)   { $sets += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' }
  if ($Lower)   { $sets += 'abcdefghijklmnopqrstuvwxyz' }
  if ($Digits)  { $sets += '0123456789' }
  if ($Symbols) { $sets += '!@#$%^&*()-_=+[]{};:,.?/' }
  if ($sets.Count -eq 0) { $sets = @('abcdefghijklmnopqrstuvwxyz') }
  if ($NoAmbiguous) { $sets = @($sets | ForEach-Object { $_ -replace '[Il1O0o]', '' }) }
  $all = -join $sets
  $chars = New-Object System.Collections.ArrayList
  foreach ($s in $sets) { [void]$chars.Add($s[(Get-SecureIndex $s.Length)]) }      # at least one of each type
  while ($chars.Count -lt $Length) { [void]$chars.Add($all[(Get-SecureIndex $all.Length)]) }
  for ($i = $chars.Count - 1; $i -gt 0; $i--) { $j = Get-SecureIndex ($i + 1); $t = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $t }  # shuffle
  return -join $chars
}

$script:WordList = (@'
apple arrow atlas badge bamboo banjo beacon berry bison blaze bloom bolt breeze brick bridge bronze bubble cactus camel candle canyon captain carbon castle cedar cherry chess cinema circus citrus cliff cloud clover cobalt comet copper coral cosmic cotton crane crater crystal cyber dagger delta desert diesel dingo dolphin domino dragonfly dune eagle echo eclipse ember emu engine falcon feather ferry fiesta fjord flame flint forest fossil fox galaxy garden gecko geyser ginger glacier globe goblin granite gravity griffin guitar hammer harbor hawk hazel helmet hero hollow honey horizon hunter igloo indigo iron island ivory jacket jaguar jasper jelly jet jungle kayak kettle kiwi koala lagoon lantern laser lava lemon lily lion lizard llama lotus lunar magnet mango maple marble meadow meteor mint mirror monsoon mosaic mountain nebula needle neon nickel ninja noodle oasis ocean olive omega onyx opal orbit otter oyster paddle panda panther paper parrot pebble pepper phoenix piano pilot pirate pixel planet plasma platypus plum polar pony prism puzzle pyramid quartz quasar quokka rabbit radar rainbow raven reef rhino ribbon river robot rocket ruby saddle salmon sapphire saturn scarlet scooter shadow shark shield silver sketch sky slate snow solar sonic spark sphinx spider spiral sprout squid star storm summit sunset swift taco tango thunder tiger timber titan toast tornado torch tower trail tulip tundra turbo turtle twilight ultra umbrella unicorn valley vapor velvet venom violet viper volcano voyage wafer walrus wander wasabi wave whale whisper wizard wombat yacht yeti yodel zebra zenith zephyr zinc zombie
'@).Trim() -split '\s+'

function New-Passphrase([int]$Words = 5) {
  $picked = for ($i = 0; $i -lt $Words; $i++) { $w = $script:WordList[(Get-SecureIndex $script:WordList.Count)]; $w.Substring(0,1).ToUpper() + $w.Substring(1) }
  $num = Get-SecureIndex 100
  $sym = '!@#$%&*?'[(Get-SecureIndex 8)]
  return (($picked -join '-') + '-' + $num + $sym)
}

function Get-Sha1Hex([string]$Text) {
  $sha = [System.Security.Cryptography.SHA1]::Create()
  $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))
  return (-join ($hash | ForEach-Object { $_.ToString('X2') }))
}

# ---------- Phishing analysis ----------
$script:Brands = [ordered]@{
  'microsoft' = @('microsoft.com','live.com','outlook.com','office.com','microsoftonline.com','office365.com')
  'mygov' = @('my.gov.au','gov.au'); 'ato' = @('ato.gov.au','gov.au'); 'centrelink' = @('servicesaustralia.gov.au','gov.au'); 'medicare' = @('servicesaustralia.gov.au','gov.au')
  'australia post' = @('auspost.com.au'); 'auspost' = @('auspost.com.au'); 'linkt' = @('linkt.com.au')
  'commbank' = @('commbank.com.au','cba.com.au'); 'westpac' = @('westpac.com.au'); 'anz' = @('anz.com','anz.com.au'); 'nab' = @('nab.com.au')
  'paypal' = @('paypal.com'); 'netflix' = @('netflix.com'); 'apple' = @('apple.com','icloud.com'); 'amazon' = @('amazon.com','amazon.com.au')
  'telstra' = @('telstra.com','telstra.com.au'); 'optus' = @('optus.com.au'); 'steam' = @('steampowered.com','steamcommunity.com')
  'discord' = @('discord.com','discord.gg'); 'dhl' = @('dhl.com','dhl.com.au'); 'origin' = @('originenergy.com.au'); 'qantas' = @('qantas.com','qantas.com.au')
}
$script:Freemail = @('gmail.com','outlook.com','hotmail.com','yahoo.com','icloud.com','live.com','bigpond.com','proton.me','protonmail.com','aol.com')

function Get-HostOf([string]$Url) {
  if ($Url -notmatch '^[a-z]+://') { $Url = 'http://' + $Url }
  try { return ([uri]$Url).Host.ToLower() } catch { return '' }
}
function Test-DomainIn([string]$HostName, [string[]]$Domains) {
  foreach ($d in $Domains) { if ($HostName -eq $d -or $HostName.EndsWith('.' + $d)) { return $true } }
  return $false
}

function Test-PhishingMessage([string]$Sender, [string]$Body) {
  $flags = New-Object System.Collections.ArrayList
  function Flag([int]$W, [string]$T) { [void]$flags.Add(@{ W = $W; T = $T }) }
  $all = ($Sender + ' ' + $Body)
  $low = $all.ToLower()
  $rules = @(
    @(15, 'urgent|immediately|within 24 hours|within 48 hours|final notice|act now|last chance|expires today|right away', 'Creates URGENCY ("act now", "final notice"). Scammers rush you so you don''t stop and think.'),
    @(15, 'suspended|locked|deactivated|will be closed|unusual activity|unauthori[sz]ed|restricted', 'Threatens that your account is suspended or locked - a classic scare tactic.'),
    @(20, 'verify your|confirm your|update your (details|information|payment)|re-?enter|validate your|log ?in to (avoid|restore)', 'Asks you to VERIFY or CONFIRM your details - real companies rarely ask this by message.'),
    @(25, 'one-?time (code|password)|verification code|read (me|out) the code|send me the code|share the code', 'Asks for a ONE-TIME CODE. Never give a code to anyone - it lets them into your account.'),
    @(20, 'gift ?card|itunes card|google play card|steam card|bitcoin|crypto|usdt|wire transfer|western union', 'Wants payment by gift cards, crypto or wire transfer - real organisations never ask for these.'),
    @(20, 'bank details have changed|new bank details|updated bank account|change of bank', 'Says BANK DETAILS HAVE CHANGED - a top invoice scam. Phone them on a known number before paying.'),
    @(15, 'you have won|winner|prize|claim your|reward|congratulations|selected|lucky', 'Promises a PRIZE or reward you didn''t enter for.'),
    @(12, 'refund|rebate|overpaid|owed money|compensation|unclaimed', 'Offers a REFUND or compensation - often a trick to get your card details.'),
    @(8,  'dear (customer|user|client|member|account holder|sir|madam)|valued customer', 'Uses a GENERIC greeting ("Dear customer") instead of your name.'),
    @(25, 'anydesk|teamviewer|quick ?assist|remote access|ultraviewer|screen ?connect', 'Asks you to install REMOTE-ACCESS software - this lets them control your PC and bank.'),
    @(15, 'do not tell|keep this (secret|confidential|between us)|don''t tell', 'Asks you to keep it SECRET - scammers isolate their victims.'),
    @(15, 'arrest|warrant|police will|legal action|court|fine of', 'Threatens ARREST, fines or legal action - government agencies don''t do this by text or email.'),
    @(12, 'press windows|win\s*\+\s*r|paste (it|this|the command)|powershell|ctrl\s*\+\s*v', 'Tells you to press Windows+R or paste a command - the "ClickFix" malware trick.'),
    @(10, 'password', 'Mentions your PASSWORD. Never type a password into a page you reached from a message.'),
    @(8,  'hi mum|hi mom|hi dad|new number|lost my phone|dropped my phone', 'The "Hi Mum, I have a new number" scam pattern.')
  )
  foreach ($r in $rules) { if ($low -match $r[1]) { Flag $r[0] $r[2] } }

  # Attachments
  if ($low -match '\.(exe|scr|zip|rar|7z|iso|img|html?|js|vbs|lnk|hta|msi|bat|cmd|one)\b') { Flag 15 'Mentions a risky file type (zip, iso, html, exe...). These attachments are used to deliver malware.' }

  # Links
  $urls = @([regex]::Matches($Body, '(?i)\b(?:https?://|www\.)[^\s<>"'')\]]+') | ForEach-Object { $_.Value.TrimEnd('.', ',', ';') })
  $hosts = @($urls | ForEach-Object { Get-HostOf $_ } | Where-Object { $_ } | Select-Object -Unique)
  foreach ($h in $hosts) {
    if ($h -match '^\d{1,3}(\.\d{1,3}){3}$') { Flag 20 "Link goes to a raw number address ($h) instead of a name - almost never legitimate." }
    if ($h -match 'xn--') { Flag 20 "Link uses a disguised international domain ($h) that can imitate real brand names." }
    if (Test-DomainIn $h @('bit.ly','tinyurl.com','t.ly','is.gd','rb.gy','cutt.ly','shorturl.at','tiny.cc','ow.ly','s.id')) { Flag 15 "Uses a link shortener ($h) to hide the real destination." }
    if ($h -match '\.(top|xyz|icu|click|cfd|sbs|live|buzz|rest|cyou|monster|lol|quest|zip|mov|vip|shop)$') { Flag 12 "Link ends in an unusual domain type ($h) popular with scammers." }
    if (($h.Split('-').Count - 1) -ge 3) { Flag 8 "Link has lots of hyphens ($h) - a common sign of a fake website." }
    if ($h -match 'paypa1|micros0ft|rnicrosoft|amaz0n|app1e|netf1ix|g00gle|c0mmbank|steamcommunlty|stearn|disc0rd|dlscord') { Flag 25 "LOOKALIKE domain ($h) - letters swapped for similar-looking numbers or characters." }
  }

  # Sender
  $senderHost = ''
  if ($Sender -match '@([A-Za-z0-9.-]+\.[A-Za-z]{2,})') { $senderHost = $Matches[1].ToLower() }

  # Brand mismatch
  foreach ($b in $script:Brands.Keys) {
    $pat = if ($b.Length -le 4) { '\b' + [regex]::Escape($b) + '\b' } else { [regex]::Escape($b) }
    if ($low -match $pat) {
      $legit = $script:Brands[$b]
      if ($senderHost -and ($script:Freemail -contains $senderHost)) { Flag 25 "Claims to be $($b.ToUpper()) but was sent from a free personal email ($senderHost)."; break }
      if ($senderHost -and -not (Test-DomainIn $senderHost $legit)) { Flag 20 "Mentions $($b.ToUpper()) but the sender's domain ($senderHost) is not an official $($b.ToUpper()) domain."; break }
      $bad = @($hosts | Where-Object { -not (Test-DomainIn $_ $legit) })
      if ($bad.Count -gt 0) { Flag 20 ("Mentions $($b.ToUpper()) but its link goes somewhere else: " + ($bad -join ', ')); break }
    }
  }
  if ($Sender -match '^\+?\d[\d\s]{6,}$' -and $hosts.Count -gt 0) { Flag 6 'A text from a mobile number that contains a link - real companies usually text from a name, not a random number.' }

  $total = 0; foreach ($f in $flags) { $total += $f.W }
  $risk = [Math]::Min(100, $total)
  if ($risk -ge 50) { $verdict = 'LIKELY A SCAM - DO NOT CLICK, REPLY OR PAY'; $color = '#FF3B5C' }
  elseif ($risk -ge 25) { $verdict = 'SUSPICIOUS - TREAT WITH GREAT CAUTION'; $color = '#FF8A3D' }
  elseif ($risk -gt 0) { $verdict = 'LOW RISK - BUT STAY ALERT'; $color = '#FFC23D' }
  else { $verdict = 'NO OBVIOUS RED FLAGS FOUND'; $color = '#39FF88' }
  return @{ Risk = $risk; Verdict = $verdict; Color = $color; Flags = $flags.ToArray(); Links = $hosts }
}

# ---------- What does a vulnerability mean for a home user? ----------
function Get-KevImpact($V) {
  $vend = ("" + $V.vendorProject + ' ' + $V.product).ToLower()
  if ($vend -match 'microsoft') {
    if ($vend -match 'office|outlook|word|excel|powerpoint') { return 'Affects you if you use Microsoft Office. Fix: open Word > File > Account > Update Options > Update Now.' }
    return 'Affects Windows PCs like yours. Fix: Settings > Windows Update > Check for updates, install everything, then restart.'
  }
  if ($vend -match 'chrom') { return 'Affects Google Chrome, and usually Edge, Brave and Opera too (they are built on Chromium). Fix: browser menu > Help > About - it updates itself - then click Relaunch.' }
  if ($vend -match 'apple|ios|macos|safari|webkit') { return 'Affects iPhones, iPads or Macs. Fix: Settings > General > Software Update.' }
  if ($vend -match 'android|samsung|qualcomm|pixel|mediatek|arm ') { return 'Affects Android phones. Fix: Settings > System (or Software) update, and Google Play system update.' }
  if ($vend -match 'mozilla|firefox|thunderbird') { return 'Affects Firefox / Thunderbird. Fix: menu > Help > About Firefox.' }
  if ($vend -match 'adobe|acrobat|reader') { return 'Affects Adobe Reader / Acrobat. Fix: Help > Check for Updates.' }
  if ($vend -match 'tp-link|d-link|netgear|zyxel|asus|linksys|draytek|router|tenda|ubiquiti') { return 'Affects some home or small-office routers. Log in to your router (or its app) and install the latest firmware. Replace routers that no longer get updates.' }
  if ($vend -match 'zoom|whatsapp|telegram|7-zip|winrar|vmware|java|nvidia|amd|intel|steam|discord|vlc|notepad\+\+') { return "Affects $($V.product) if it is installed on your PC. Update it from inside the app or from the official website." }
  return 'Mostly used by businesses and organisations - home PCs usually aren''t directly affected. But companies that hold YOUR data might be, which is how breaches happen.'
}

# ---------- Offline adviser lookup ----------
function Find-AdviserAnswer([string]$Question, $Kb) {
  $q = ' ' + $Question.ToLower() + ' '
  $best = $null; $bestScore = 0
  foreach ($e in $Kb) {
    $s = 0
    foreach ($k in ($e.kw -split ',')) { $kw = $k.Trim(); if ($k -match '^ | $') { $kw = $k } ; if ($kw -and $q.Contains($kw)) { $s += $kw.Trim().Length } }
    if ($s -gt $bestScore) { $bestScore = $s; $best = $e }
  }
  if ($best) { return $best.a }
  return $null
}
