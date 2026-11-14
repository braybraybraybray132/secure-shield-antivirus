# Guardian Shield - the full system security scan. Runs in the background so the window never freezes.
# It returns a list of checks. Each check has points; the Shield Score = points earned / points possible x 100.

$script:ScanWork = {
  $ErrorActionPreference = 'SilentlyContinue'
  $checks = New-Object System.Collections.ArrayList
  function Add-Check([string]$Id, [string]$Title, [string]$Status, [int]$Points, [int]$Max, [string]$Detail, [string]$Fix, [string]$Action) {
    [void]$checks.Add([pscustomobject]@{ Id = $Id; Title = $Title; Status = $Status; Points = $Points; Max = $Max; Detail = $Detail; Fix = $Fix; Action = $Action })
  }
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  $needAdmin = 'Guardian Shield needs Administrator rights to check this. Close it and start it again, choosing YES when Windows asks.'

  # ---- 1. Antivirus (20) ----
  $mp = $null; try { $mp = Get-MpComputerStatus -ErrorAction Stop } catch {}
  $other = @(); try { $other = @(Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction Stop | Where-Object { $_.displayName -notmatch 'Defender' -and (([uint32]$_.productState -band 0x1000) -ne 0) }) } catch {}
  $defOn = [bool]($mp -and $mp.AntivirusEnabled -and $mp.RealTimeProtectionEnabled)
  $avName = 'None found'
  if ($defOn) { $avName = 'Microsoft Defender'; Add-Check 'av' 'Antivirus protection' 'Pass' 20 20 'Microsoft Defender Antivirus is ON and real-time protection is checking every file as it is opened.' '' '' }
  elseif ($other.Count -gt 0) { $avName = $other[0].displayName; Add-Check 'av' 'Antivirus protection' 'Pass' 20 20 "$avName is installed and switched on." '' '' }
  elseif ($mp) { $avName = 'Defender (OFF)'; Add-Check 'av' 'Antivirus protection' 'Fail' 0 20 'Microsoft Defender is installed but REAL-TIME PROTECTION IS OFF. Viruses can run without being stopped. Malware sometimes switches it off on purpose.' 'Press FIX IT, then turn "Real-time protection" ON. If it keeps turning off by itself, run a Full Scan in the Antivirus tab.' 'windowsdefender://threatsettings/' }
  else { Add-Check 'av' 'Antivirus protection' 'Fail' 0 20 'No working antivirus could be found on this PC.' 'Open Windows Security and make sure Virus & threat protection is turned on.' 'windowsdefender://threat/' }

  # ---- 2. Virus definitions age (8) ----
  if ($defOn) {
    $age = [int]$mp.AntivirusSignatureAge
    if ($age -le 2) { Add-Check 'sig' 'Virus definitions up to date' 'Pass' 8 8 "Virus definitions are $age day(s) old - your antivirus knows the newest threats." '' '' }
    elseif ($age -le 7) { Add-Check 'sig' 'Virus definitions up to date' 'Warn' 4 8 "Virus definitions are $age days old. New viruses appear every day." 'Go to the Antivirus tab and press UPDATE VIRUS DEFINITIONS.' 'windowsdefender://threat/' }
    else { Add-Check 'sig' 'Virus definitions up to date' 'Fail' 0 8 "Virus definitions are $age days old - your antivirus can't recognise new viruses." 'Go to the Antivirus tab and press UPDATE VIRUS DEFINITIONS, then run Windows Update.' 'windowsdefender://threat/' }
  } else { Add-Check 'sig' 'Virus definitions up to date' 'Unknown' 0 8 'Only checked when Microsoft Defender is the active antivirus. Your other antivirus updates itself.' '' '' }

  # ---- 3. Threats / infection (15) ----
  $active = @(); $recent = @()
  try {
    $threats = @(Get-MpThreat -ErrorAction Stop)
    $active = @($threats | Where-Object { $_.IsActive } | ForEach-Object { $_.ThreatName })
    $names = @{}; foreach ($t in $threats) { $names[[string]$t.ThreatID] = $t.ThreatName }
    $recent = @(Get-MpThreatDetection -ErrorAction Stop | Where-Object { $_.InitialDetectionTime -gt (Get-Date).AddDays(-30) } | ForEach-Object { $n = $names[[string]$_.ThreatID]; if ($n) { $n } else { 'Unknown threat' } } | Select-Object -Unique)
  } catch {}
  if (-not $mp) { Add-Check 'threat' 'Infection check' 'Unknown' 0 15 'Could not read the antivirus threat history.' '' '' }
  elseif ($active.Count -gt 0) { Add-Check 'threat' 'Infection check' 'Fail' 0 15 ("ACTIVE THREATS FOUND: " + ($active -join ', ') + '. Your PC may be infected right now.') 'Go to the Antivirus tab and run a FULL SCAN. Then open Windows Security > Protection history and choose Remove for each threat.' 'windowsdefender://threat/' }
  elseif ($recent.Count -gt 0) { Add-Check 'threat' 'Infection check' 'Warn' 11 15 ("No active threats, but these were caught in the last 30 days: " + ($recent -join ', ') + '. Your antivirus blocked them - think about where they came from.') 'Run a Quick Scan to be sure, and avoid the site or download that caused it.' 'windowsdefender://threat/' }
  else { Add-Check 'threat' 'Infection check' 'Pass' 15 15 'No viruses or threats found - active or in the last 30 days. Your PC looks clean.' '' '' }

  # ---- 4. Firewall (12) ----
  $fwOn = 0; $fwTotal = 0
  try { $fw = @(Get-NetFirewallProfile -ErrorAction Stop); $fwTotal = $fw.Count; $fwOn = @($fw | Where-Object { [string]$_.Enabled -eq 'True' }).Count } catch {}
  $fw3 = @(); try { $fw3 = @(Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName FirewallProduct -ErrorAction Stop | Where-Object { (([uint32]$_.productState -band 0x1000) -ne 0) }) } catch {}
  if ($fwTotal -gt 0 -and $fwOn -eq $fwTotal) { Add-Check 'fw' 'Firewall' 'Pass' 12 12 'Windows Firewall is ON for all networks (Domain, Private and Public).' '' '' }
  elseif ($fw3.Count -gt 0) { Add-Check 'fw' 'Firewall' 'Pass' 12 12 "$($fw3[0].displayName) firewall is active." '' '' }
  elseif ($fwTotal -gt 0 -and $fwOn -gt 0) { Add-Check 'fw' 'Firewall' 'Warn' 6 12 "The firewall is only on for $fwOn of $fwTotal network types. You are exposed on the others (like cafe Wi-Fi)." 'Press FIX IT and turn the firewall ON for Domain, Private and Public networks.' 'windowsdefender://network/' }
  elseif ($fwTotal -gt 0) { Add-Check 'fw' 'Firewall' 'Fail' 0 12 'The firewall is OFF. Anyone on your network can try to connect to your PC.' 'Press FIX IT and turn the firewall ON for every network type.' 'windowsdefender://network/' }
  else { Add-Check 'fw' 'Firewall' 'Unknown' 0 12 'Could not read the firewall settings.' '' 'windowsdefender://network/' }

  # ---- 5. Windows Update (12) ----
  $last = $null
  try { $au = New-Object -ComObject Microsoft.Update.AutoUpdate; $d = $au.Results.LastInstallationSuccessDate; if ($d -and ([datetime]$d).Year -gt 2000) { $last = [datetime]$d } } catch {}
  if (-not $last) { try { $hf = Get-HotFix | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending | Select-Object -First 1; if ($hf) { $last = [datetime]$hf.InstalledOn } } catch {} }
  $reboot = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
  $updDays = $null
  if ($last) {
    $updDays = [int]((Get-Date) - $last).TotalDays
    $rb = ''; if ($reboot) { $rb = ' A RESTART is waiting to finish installing updates.' }
    if ($updDays -le 35 -and -not $reboot) { Add-Check 'upd' 'Windows updates' 'Pass' 12 12 "Updates were last installed $updDays day(s) ago." '' '' }
    elseif ($updDays -le 35) { Add-Check 'upd' 'Windows updates' 'Warn' 8 12 ("Updates were installed $updDays day(s) ago." + $rb) 'Save your work and restart your PC so the updates can finish.' 'ms-settings:windowsupdate' }
    elseif ($updDays -le 70) { Add-Check 'upd' 'Windows updates' 'Warn' 5 12 ("No updates installed for $updDays days. You are probably missing the October 2026 security fixes." + $rb) 'Press FIX IT > Check for updates > install everything > restart.' 'ms-settings:windowsupdate' }
    else { Add-Check 'upd' 'Windows updates' 'Fail' 0 12 ("No updates installed for $updDays days. Your PC is missing many security fixes, including ones criminals are actively using." + $rb) 'Press FIX IT > Check for updates > install everything > restart. Repeat until it says You''re up to date.' 'ms-settings:windowsupdate' }
  } else { Add-Check 'upd' 'Windows updates' 'Unknown' 0 12 'Could not find when updates were last installed.' 'Open Windows Update and check it says You''re up to date.' 'ms-settings:windowsupdate' }

  # ---- 6. Windows version still supported (10) ----
  $os = Get-CimInstance Win32_OperatingSystem
  $build = [int]$os.BuildNumber; $caption = [string]$os.Caption
  $disp = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
  $biz = $caption -match 'Enterprise|Education|IoT|LTSC'
  $osLabel = "$caption $disp (build $build)"
  if ($build -lt 22000) {
    if ($biz) { Add-Check 'os' 'Windows version supported' 'Warn' 5 10 "$osLabel. Windows 10 consumer support ended in October 2025. Some business/LTSC editions last longer - check your edition's date." 'Plan an upgrade to Windows 11.' 'ms-settings:windowsupdate' }
    else { Add-Check 'os' 'Windows version supported' 'Fail' 0 10 "$osLabel. Windows 10 stopped receiving FREE security updates on 14 October 2025. New holes are no longer fixed unless you joined Extended Security Updates (ESU)." 'Upgrade to Windows 11 if your PC supports it (Settings > Windows Update), or enrol in Extended Security Updates.' 'ms-settings:windowsupdate' }
  }
  elseif ($build -lt 26100) {
    if ($biz -and $build -ge 22631) { Add-Check 'os' 'Windows version supported' 'Warn' 6 10 "$osLabel. Enterprise/Education 23H2 support ends in November 2026." 'Ask your IT team to move to version 25H2.' 'ms-settings:windowsupdate' }
    else { Add-Check 'os' 'Windows version supported' 'Fail' 0 10 "$osLabel. This Windows 11 version no longer gets security updates." 'Press FIX IT and install the newest Windows 11 version (25H2) from Windows Update.' 'ms-settings:windowsupdate' }
  }
  elseif ($build -lt 26200) {
    if ($biz) { Add-Check 'os' 'Windows version supported' 'Pass' 10 10 "$osLabel. Enterprise/Education 24H2 is still supported." '' '' }
    else { Add-Check 'os' 'Windows version supported' 'Fail' 2 10 "$osLabel. Windows 11 24H2 Home and Pro got their LAST security update on 13 October 2026." 'Press FIX IT and install "Windows 11, version 25H2" - it is a small, quick update.' 'ms-settings:windowsupdate' }
  }
  else { Add-Check 'os' 'Windows version supported' 'Pass' 10 10 "$osLabel. This version is supported and gets monthly security fixes." '' '' }

  # ---- 7. User Account Control (5) ----
  $sys = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
  if ($sys.EnableLUA -eq 1 -and $sys.ConsentPromptBehaviorAdmin -ne 0) { Add-Check 'uac' 'User Account Control (UAC)' 'Pass' 5 5 'UAC is on. Programs must ask permission before changing system settings.' '' '' }
  else { Add-Check 'uac' 'User Account Control (UAC)' 'Fail' 0 5 'UAC is OFF or set to never notify. Malware can change your system silently.' 'Press FIX IT and move the slider to the 3rd notch ("Notify me only when apps try to make changes").' 'UserAccountControlSettings.exe' }

  # ---- 8. Secure Boot (4) ----
  try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    if ($sb) { Add-Check 'sboot' 'Secure Boot' 'Pass' 4 4 'Secure Boot is on - only trusted software can start before Windows.' '' '' }
    else { Add-Check 'sboot' 'Secure Boot' 'Warn' 0 4 'Secure Boot is OFF. Hidden "bootkit" malware could load before Windows.' 'Turn on Secure Boot in your PC''s UEFI/BIOS settings (ask a tech-savvy friend if unsure).' '' } }
  catch { if ($isAdmin) { Add-Check 'sboot' 'Secure Boot' 'Warn' 0 4 'This PC uses old-style BIOS or does not support Secure Boot.' 'Newer PCs support it. Consider it when you next upgrade.' '' } else { Add-Check 'sboot' 'Secure Boot' 'Unknown' 0 4 $needAdmin '' '' } }

  # ---- 9. Drive encryption (4) ----
  try { $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ([string]$bl.ProtectionStatus -eq 'On') { Add-Check 'enc' 'Drive encryption' 'Pass' 4 4 'Your system drive is encrypted. If your PC is stolen, your files can''t be read.' '' '' }
    else { Add-Check 'enc' 'Drive encryption' 'Warn' 0 4 'Your system drive is NOT encrypted. If the PC is lost or stolen, a thief can read your files.' 'Turn on BitLocker or Device encryption. Save the recovery key first!' 'ms-settings:deviceencryption' } }
  catch { if ($isAdmin) { Add-Check 'enc' 'Drive encryption' 'Warn' 1 4 'BitLocker is not available on this edition (common on Windows Home).' 'Check Settings > Privacy & security > Device encryption - many Home laptops support it.' 'ms-settings:deviceencryption' } else { Add-Check 'enc' 'Drive encryption' 'Unknown' 0 4 $needAdmin '' '' } }

  # ---- 10. SmartScreen + unwanted-app blocking (4) ----
  $pua = $false; try { $pua = ((Get-MpPreference -ErrorAction Stop).PUAProtection -eq 1) } catch {}
  $ssv = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer').SmartScreenEnabled
  $ss = ($ssv -ne 'Off')
  if ($ss -and $pua) { Add-Check 'ss' 'SmartScreen and unwanted-app blocking' 'Pass' 4 4 'SmartScreen warns you about dangerous downloads, and unwanted-app blocking is on.' '' '' }
  elseif ($ss) { Add-Check 'ss' 'SmartScreen and unwanted-app blocking' 'Warn' 2 4 'SmartScreen is on, but "Potentially unwanted app blocking" is off - adware and junk bundled with free downloads can slip through.' 'Press FIX IT > Reputation-based protection settings > turn on Potentially unwanted app blocking.' 'windowsdefender://appbrowser/' }
  else { Add-Check 'ss' 'SmartScreen and unwanted-app blocking' 'Fail' 0 4 'SmartScreen is OFF. Windows will not warn you before opening dangerous downloads.' 'Press FIX IT and turn on all Reputation-based protection settings.' 'windowsdefender://appbrowser/' }

  # ---- 11. Remote Desktop (2) ----
  $rdp = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
  if ($rdp -eq 0) { Add-Check 'rdp' 'Remote Desktop' 'Warn' 0 2 'Remote Desktop is ON. Criminals scan the internet for PCs with this on and try to guess passwords.' 'If you don''t use it, press FIX IT and turn Remote Desktop OFF.' 'ms-settings:remotedesktop' }
  else { Add-Check 'rdp' 'Remote Desktop' 'Pass' 2 2 'Remote Desktop is off - nobody can log in to this PC over the network.' '' '' }

  # ---- 12. Tamper protection (2) ----
  if ($mp -and $defOn) {
    if ($mp.IsTamperProtected) { Add-Check 'tamper' 'Tamper protection' 'Pass' 2 2 'Tamper protection is on - malware can''t switch off your antivirus.' '' '' }
    else { Add-Check 'tamper' 'Tamper protection' 'Warn' 0 2 'Tamper protection is OFF - malware could switch off your antivirus.' 'Press FIX IT, scroll to Tamper Protection and turn it ON.' 'windowsdefender://threatsettings/' }
  } else { Add-Check 'tamper' 'Tamper protection' 'Unknown' 0 2 'Only checked when Microsoft Defender is the active antivirus.' '' '' }

  # ---- 13. Old SMBv1 protocol (2) ----
  $smbKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10'
  $smb1 = $false; if (Test-Path $smbKey) { if ((Get-ItemProperty $smbKey).Start -ne 4) { $smb1 = $true } }
  if ($isAdmin) { try { if ((Get-SmbServerConfiguration -ErrorAction Stop).EnableSMB1Protocol) { $smb1 = $true } } catch {} }
  if ($smb1) { Add-Check 'smb1' 'Old SMBv1 file sharing' 'Fail' 0 2 'SMBv1 is switched on. This 30-year-old protocol was used by the WannaCry ransomware to spread worldwide.' 'Search "Turn Windows features on or off", untick "SMB 1.0/CIFS File Sharing Support", press OK and restart.' 'optionalfeatures.exe' }
  else { Add-Check 'smb1' 'Old SMBv1 file sharing' 'Pass' 2 2 'SMBv1 is not active.' '' '' }

  # ---- Extra health information (not scored) ----
  try {
    $bad = @(Get-PhysicalDisk -ErrorAction Stop | Where-Object { [string]$_.HealthStatus -ne 'Healthy' })
    if ($bad.Count -gt 0) { Add-Check 'disk' 'Hard disk health' 'Fail' 0 0 ('Disk problem: ' + (($bad | ForEach-Object { "$($_.FriendlyName) is $($_.HealthStatus)" }) -join '; ') + '. It may fail soon.') 'BACK UP YOUR FILES TODAY, then see the Hard Disk Check tab.' '' }
    else { Add-Check 'disk' 'Hard disk health' 'Pass' 0 0 'All drives report Healthy.' '' '' }
  } catch {}
  $freePct = $null
  try { $v = Get-Volume -DriveLetter $env:SystemDrive.Substring(0, 1) -ErrorAction Stop; if ($v.Size -gt 0) { $freePct = [int](100 * $v.SizeRemaining / $v.Size) }
    if ($freePct -lt 10) { Add-Check 'space' 'Free disk space' 'Warn' 0 0 "Only $freePct% of your system drive is free. Windows slows down and updates can fail." 'Settings > System > Storage > Cleanup recommendations, and turn on Storage Sense.' 'ms-settings:storagesense' }
    else { Add-Check 'space' 'Free disk space' 'Pass' 0 0 "$freePct% of your system drive is free." '' '' } } catch {}
  $up = [int]((Get-Date) - $os.LastBootUpTime).TotalDays
  if ($up -gt 14) { Add-Check 'uptime' 'Restarted recently' 'Warn' 0 0 "Your PC hasn't fully restarted for $up days. Some updates only finish after a restart. (Shut down with Fast Startup doesn't count - use Restart.)" 'Save your work and choose Start > Power > Restart.' '' }
  else { Add-Check 'uptime' 'Restarted recently' 'Pass' 0 0 "Last restart was $up day(s) ago." '' '' }

  $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
  $ram = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
  [pscustomobject]@{
    Checks = $checks.ToArray(); IsAdmin = $isAdmin; OSLabel = $osLabel; Computer = $env:COMPUTERNAME; CPU = $cpu; RAM = $ram
    Active = $active; Recent = $recent; AvName = $avName; FwOn = $fwOn; FwTotal = $fwTotal; Fw3 = ($fw3.Count -gt 0); UpdDays = $updDays; Reboot = $reboot
  }
}
