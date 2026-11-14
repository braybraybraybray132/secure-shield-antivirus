# Guardian Shield - background jobs for the antivirus, malware checker, disk check and online lookups.

$script:AvStatusWork = {
  $ErrorActionPreference = 'SilentlyContinue'
  $mp = Get-MpComputerStatus
  $threats = @(Get-MpThreat); $names = @{}; foreach ($t in $threats) { $names[[string]$t.ThreatID] = $t }
  $hist = @(Get-MpThreatDetection | Sort-Object InitialDetectionTime -Descending | Select-Object -First 25 | ForEach-Object {
    $t = $names[[string]$_.ThreatID]
    [pscustomobject]@{ Name = $(if ($t) { $t.ThreatName } else { 'Unknown threat' }); When = $_.InitialDetectionTime; Active = $(if ($t) { [bool]$t.IsActive } else { $false })
      Severity = $(if ($t) { [int]$t.SeverityID } else { 0 }); Path = (@($_.Resources) -join '; ') -replace '^file:_', ''; Action = [int]$_.ThreatStatusID }
  })
  [pscustomobject]@{ Mp = $mp; History = $hist }
}

$script:AvActionWork = {
  param($Action)
  $ErrorActionPreference = 'Stop'
  $start = Get-Date
  switch ($Action) {
    'quick'  { Start-MpScan -ScanType QuickScan }
    'full'   { Start-MpScan -ScanType FullScan }
    'update' { Update-MpSignature }
  }
  $found = @(Get-MpThreatDetection -ErrorAction SilentlyContinue | Where-Object { $_.InitialDetectionTime -ge $start })
  [pscustomobject]@{ Action = $Action; Minutes = [Math]::Round(((Get-Date) - $start).TotalMinutes, 1); Found = $found.Count }
}

$script:FileCheckWork = {
  param([string]$Path)
  $ErrorActionPreference = 'SilentlyContinue'
  $fi = Get-Item -LiteralPath $Path
  $r = [ordered]@{ Path = $Path; Name = $fi.Name; Size = $fi.Length; Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
  $sig = Get-AuthenticodeSignature -LiteralPath $Path
  $r.SigStatus = [string]$sig.Status
  $r.Signer = $(if ($sig.SignerCertificate) { ($sig.SignerCertificate.Subject -replace '^CN=("?)([^,"]+).*$', '$2') } else { '' })
  $zone = Get-Content -LiteralPath $Path -Stream Zone.Identifier
  $zline = @($zone | Where-Object { $_ -like 'ZoneId=*' }) | Select-Object -First 1
  $r.ZoneId = $(if ($zline) { [int](($zline -replace '^ZoneId=', '').Trim()) } else { -1 })
  $r.HostUrl = (($zone | Where-Object { $_ -like 'HostUrl=*' }) -replace '^HostUrl=', '') | Select-Object -First 1
  $mpcmd = Join-Path $env:ProgramFiles 'Windows Defender\MpCmdRun.exe'
  $r.ScanDone = $false; $r.ThreatsFound = 0; $r.ScanText = ''
  if (Test-Path $mpcmd) {
    $out = & $mpcmd -Scan -ScanType 3 -File $Path -DisableRemediation 2>&1 | Out-String
    $r.ScanText = $out.Trim()
    if ($out -match 'found no threats') { $r.ScanDone = $true; $r.ThreatsFound = 0 }
    elseif ($out -match 'found (\d+) threat') { $r.ScanDone = $true; $r.ThreatsFound = [int]$Matches[1] }
    elseif ($LASTEXITCODE -eq 2) { $r.ScanDone = $true; $r.ThreatsFound = 1 }
  }
  [pscustomobject]$r
}

$script:StartupWork = {
  $ErrorActionPreference = 'SilentlyContinue'
  $items = @(Get-CimInstance Win32_StartupCommand)
  foreach ($i in $items) {
    $cmd = [Environment]::ExpandEnvironmentVariables([string]$i.Command)
    $exe = ''
    if ($cmd -match '^\s*"([^"]+)"') { $exe = $Matches[1] }
    elseif ($cmd -match '^\s*(.+?\.(exe|com|bat|cmd|vbs|js|ps1|lnk))\b') { $exe = $Matches[1] }
    else { $exe = ($cmd -split '\s+')[0] }
    $signer = ''; $status = 'NotFound'
    if ($exe -and (Test-Path -LiteralPath $exe)) {
      $s = Get-AuthenticodeSignature -LiteralPath $exe; $status = [string]$s.Status
      if ($s.SignerCertificate) { $signer = ($s.SignerCertificate.Subject -replace '^CN=("?)([^,"]+).*$', '$2') }
    }
    $odd = ($cmd -match '(?i)\\temp\\|\\downloads\\|-enc|-encodedcommand|mshta|wscript|cscript|regsvr32|rundll32.+http|powershell.+(http|iex|downloadstring)')
    [pscustomobject]@{ Name = $i.Name; Command = $cmd; Location = $i.Location; Signer = $signer; Status = $status; Odd = $odd }
  }
}

$script:DiskWork = {
  $ErrorActionPreference = 'SilentlyContinue'
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  $disks = foreach ($pd in @(Get-PhysicalDisk)) {
    $rel = $null; if ($isAdmin) { $rel = Get-StorageReliabilityCounter -PhysicalDisk $pd }
    [pscustomobject]@{ Name = $pd.FriendlyName; Media = [string]$pd.MediaType; Bus = [string]$pd.BusType; Health = [string]$pd.HealthStatus
      Status = (@($pd.OperationalStatus) -join ', '); SizeGB = [Math]::Round($pd.Size / 1GB)
      Temp = $(if ($rel) { $rel.Temperature } else { $null }); Wear = $(if ($rel) { $rel.Wear } else { $null })
      Hours = $(if ($rel) { $rel.PowerOnHours } else { $null }); ReadErr = $(if ($rel) { $rel.ReadErrorsUncorrected } else { $null }) }
  }
  $predict = @(); if ($isAdmin) { $predict = @(Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus | Where-Object { $_.PredictFailure }) }
  $vols = @(Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 } | Sort-Object DriveLetter | ForEach-Object {
    [pscustomobject]@{ Letter = [string]$_.DriveLetter; Label = $_.FileSystemLabel; FS = $_.FileSystem; SizeGB = [Math]::Round($_.Size / 1GB, 1)
      FreeGB = [Math]::Round($_.SizeRemaining / 1GB, 1); UsedPct = [int](100 - 100 * $_.SizeRemaining / $_.Size); Health = [string]$_.HealthStatus; Type = [string]$_.DriveType }
  })
  [pscustomobject]@{ Disks = @($disks); Volumes = $vols; Predict = $predict.Count; IsAdmin = $isAdmin }
}

$script:DiskScanWork = {
  param($Letter)
  $r = Repair-Volume -DriveLetter $Letter -Scan -ErrorAction Stop
  [string]$r
}

$script:PwnedWork = {
  param($Prefix, $Suffix)
  $ErrorActionPreference = 'Stop'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $resp = Invoke-WebRequest -Uri ("https://api.pwnedpasswords.com/range/" + $Prefix) -UseBasicParsing -Headers @{ 'Add-Padding' = 'true' } -TimeoutSec 20
  $count = 0
  foreach ($line in ($resp.Content -split "`r?`n")) { $p = $line.Split(':'); if ($p[0] -eq $Suffix) { $count = [int]$p[1]; break } }
  $count
}

$script:HibpWork = {
  param($Email, $Key)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  try {
    $r = Invoke-RestMethod -Uri ("https://haveibeenpwned.com/api/v3/breachedaccount/" + [uri]::EscapeDataString($Email) + "?truncateResponse=false") -Headers @{ 'hibp-api-key' = $Key; 'user-agent' = 'GuardianShield-Desktop' } -TimeoutSec 25 -ErrorAction Stop
    @{ Status = 'found'; Data = @($r) }
  } catch {
    $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
    if ($code -eq 404) { @{ Status = 'none' } } elseif ($code -eq 401) { @{ Status = 'badkey' } } elseif ($code -eq 429) { @{ Status = 'rate' } }
    else { @{ Status = 'error'; Msg = $_.Exception.Message } }
  }
}

$script:KevWork = {
  $ErrorActionPreference = 'Stop'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $feed = Invoke-RestMethod -Uri 'https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json' -TimeoutSec 45
  $cut = (Get-Date).AddDays(-30)
  $items = @($feed.vulnerabilities | Where-Object { [datetime]$_.dateAdded -ge $cut } | Sort-Object { [datetime]$_.dateAdded } -Descending | Select-Object -First 40)
  [pscustomobject]@{ Released = $feed.dateReleased; Total = $feed.count; Items = $items }
}
