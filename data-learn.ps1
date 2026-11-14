# Guardian Shield - page headers, "explained simply" lessons, and safety tips.

# Each page: Tag, Title, Subtitle, Lesson (the "EXPLAINED SIMPLY" box)
$script:PageInfo = @{
  Dashboard = @('// COMMAND CENTRE', 'Dashboard', 'Your PC''s safety at a glance.',
    'The SHIELD SCORE is a mark out of 100, like a school test for your computer''s security. Guardian Shield runs 13 safety checks (Is the antivirus on? Is the firewall on? Is Windows updated? Has any virus been found? and more). Each check is worth points. Important things like antivirus are worth more points. 90+ means your PC is a fortress. Under 60 means there are holes a criminal could use. The INFECTION STATUS box tells you if your antivirus has found a virus on this PC.')
  Scan = @('// DIAGNOSTICS', 'PC Scan - What''s Wrong?', 'Every check, what it found, why it matters, and how to fix it.',
    'A "vulnerability" is a weak spot - like an unlocked window in a house. This page lists every check from the scan. GREEN (PASS) means that part is safe. YELLOW (WARN) means it is not great. RED (FAIL) means it is a real problem - fix those first. GREY means Guardian Shield could not check it (usually because it was not opened as Administrator). Many problems have a FIX IT button that opens the exact Windows setting for you.')
  AV = @('// ANTIVIRUS ENGINE', 'Antivirus', 'Scan for viruses using the Microsoft Defender engine built into Windows.',
    'An ANTIVIRUS is a program that looks at files and recognises viruses, a bit like a security guard with a book of criminals'' photos. That "book" is called the VIRUS DEFINITIONS - it must be updated often so it knows the newest viruses. Guardian Shield uses Microsoft Defender, the free antivirus engine built into Windows 10 and 11, which independent labs rate highly. A QUICK SCAN checks the places viruses usually hide (a few minutes). A FULL SCAN checks every single file (can take hours). You can keep using your PC while it scans.')
  Malware = @('// THREAT ANALYSIS', 'Malware Checker', 'Not sure if a file is safe? Check it before you open it.',
    'MALWARE means "malicious software" - any program made to harm you: viruses, password stealers, ransomware (locks your files and demands money) and spyware. Tests run on your file: 1) a Defender virus scan, 2) a digital signature check - like a seal on an envelope that proves which company made it, 3) the file type - some types can run programs, 4) the "double extension" trick (holiday.jpg.exe pretends to be a photo), 5) where it came from, 6) a fingerprint (SHA-256 hash) you can look up on VirusTotal, which checks it against 70+ antivirus engines. Only the fingerprint is used - your file is never uploaded.')
  Disk = @('// HARDWARE', 'Hard Disk Check', 'Is your drive healthy, and is it running out of space?',
    'Your HARD DISK (or SSD) is where every file, photo and game is stored. Drives wear out over time. Windows keeps a health report for each drive, and Guardian Shield reads it for you. It also checks free space: when a drive is over 90% full, Windows gets slow and updates can fail - which is a security problem too. "Scan for errors" checks the drive''s file system (its filing cabinet) for damage without changing anything. If a drive says WARNING or UNHEALTHY, back up your files today.')
  Pass = @('// IDENTITY', 'Password Lab', 'Check how strong a password is, see if it has leaked, and create unbreakable ones.',
    'Criminals guess passwords with computers that try BILLIONS of guesses per second. They start with the most common passwords and words, then add numbers and symbols the way people usually do (Password1!). So LENGTH matters most: every extra character makes it massively harder. A LEAKED password is one that was stolen in a breach and is now on criminals'' lists. The leak check uses a clever privacy trick called k-anonymity: only the first 5 characters of a scrambled code (a SHA-1 hash) of your password are sent, never the password itself.')
  Email = @('// IDENTITY', 'Email Guard', 'Find out if your email was in a data breach, and test suspicious messages.',
    'A DATA BREACH is when hackers steal a company''s customer list. If your email is in one, criminals may have your password for that site, and they will send you more scam emails. PHISHING ("fishing") is when a criminal sends a message pretending to be a company you trust, to trick you into clicking a link, typing your password or paying money. Email itself cannot be "infected" just by arriving - the danger is clicking links, opening attachments, or replying with information.')
  Breach = @('// AUSTRALIA', 'Aussie Breaches', 'Big Australian data breaches you could have been caught up in.',
    'Australian companies must tell you if a breach is likely to cause you serious harm (the Notifiable Data Breaches scheme). But many people miss the letter or email. Tick the companies you have used, then press the button: Guardian Shield builds a personal action plan with the exact steps for what was stolen. A driver licence number can be used to open accounts in your name, so licences and passports are the most important things to replace.')
  Card = @('// FRAUD INTEL', 'Card Fraud Radar', 'Credit and debit card scams going around right now, and how to beat them.',
    'CARD FRAUD is when someone uses your card details without permission. About 1 in 10 Australians had card fraud in 2024-25 (Australian Bureau of Statistics). The GOOD news: 72% of victims got all their money back from their bank. Your 3 strongest shields: 1) never read out a code sent to your phone, 2) pay with Apple Pay / Google Pay / PayPal so shops never see your real card number, 3) turn on instant transaction alerts in your bank app so you spot fraud within minutes.')
  Phish = @('// FRAUD INTEL', 'Phishing Radar', 'Fake messages, websites and calls doing the rounds right now.',
    'Almost every phishing scam uses the same 4 tricks: PRETEND to be someone you trust, create URGENCY ("act now or else"), ask you to CLICK or CALL, then ask for MONEY, a PASSWORD or a CODE. If a message has all four - it is a scam. The golden rule: never use the link or phone number in the message. Close it, then go to the company''s app or website yourself. You can paste any suspicious message into Email Guard to test it.')
  Vulns = @('// THREAT FEED', 'Threat Feed', 'Newest security holes, how they could affect you and your PC.',
    'A VULNERABILITY is a mistake in software that criminals can use to break in. Each one gets an ID like CVE-2026-12345 ("CVE" = Common Vulnerabilities and Exposures). A ZERO-DAY is a hole criminals used before the maker had a fix ready - the most dangerous kind. "PATCH TUESDAY" is the second Tuesday of every month, when Microsoft releases its fixes. Nearly every hole is closed by simply installing updates - that is the single most powerful thing you can do.')
  AI = @('// ADVISER', 'Shield AI Adviser', 'Ask any safety question in plain English.',
    'Shield AI is a built-in expert adviser that works offline, so your questions never leave this PC. It knows about viruses, scams, passwords, breaches, gaming safety and what to do in an emergency - and it can read YOUR latest scan results to explain what is wrong with your PC. Type a question, or tap one of the suggestion buttons. It explains things step by step.')
  Tips = @('// TRAINING', 'Safety Tips', 'Simple habits that stop most attacks.',
    'You do not need to be a computer expert to be safe. Five habits block the vast majority of attacks: 1) keep Windows and apps updated, 2) use a different strong password for every account (a password manager remembers them), 3) turn on two-factor authentication, 4) never click links in unexpected messages, 5) back up your files. Each section below explains WHY each tip works.')
  Member = @('// PROFILE', 'Membership', 'Your Guardian Shield rank, badges and history.',
    'Every safety action you take earns XP (experience points), just like a game. Earn XP to climb from RECRUIT to LEGEND and unlock badges. Membership is FREE and lifetime - there is nothing to buy. Your profile is saved only on this PC (in your AppData folder) and is never sent online.')
}

$script:TipsData = @'
== Accounts and passwords
icon: E72E
tips: Use a different password for every account. If one site is hacked, criminals try that password everywhere else (called "credential stuffing"). || Use a password manager (Bitwarden is free; 1Password, or the one built into your browser) - it remembers everything so you only learn ONE master password. || Turn on two-factor authentication (2FA) everywhere, especially email, banking and gaming. Even if your password leaks, the criminal still can't get in. || Prefer an authenticator app or passkey over SMS codes - SIM-swap criminals can steal texts. || Your EMAIL is the master key: whoever controls it can reset all your other passwords. Protect it best.

== Keeping your PC safe
icon: E7F8
tips: Turn on automatic updates for Windows, your browser and your games launcher. Updates close the holes criminals use. || Keep Microsoft Defender (or another good antivirus) switched on with real-time protection. || Only download software from the official website or the Microsoft Store. || Use a standard (non-administrator) account for everyday use if you can - malware then can't change system settings. || Restart your PC at least once a week so updates finish installing.

== Gaming safety
icon: E7FC
tips: Cheats, mod menus, "free" games, cracks and key generators are the No.1 way gamers get password-stealing malware. || Never log in to Steam, Epic, Riot or Discord through a link someone sends you. || Turn on Steam Guard Mobile Authenticator and 2FA on Discord, Epic, Xbox and PlayStation. || "Free Robux / V-Bucks / skins / Nitro" offers are always scams. || Trade only through the official trade system - never "trust trades". || Never share your screen with someone while logged into accounts or wallets.

== Money and cards
icon: E8C7
tips: Turn on instant transaction alerts and card lock in your banking app. || Never read out or type in a one-time code that someone else asked for. || Pay with Apple Pay, Google Pay or PayPal online - they hide your real card number. || If money disappears, call your bank IMMEDIATELY on the number on your card - the faster you call, the better the chance of getting it back. || Real banks, police, the ATO and Microsoft never ask for gift cards, crypto or remote access to your PC.

== Your phone
icon: E8EA
tips: Keep your phone updated - phones get security fixes too. || Only install apps from the official App Store or Google Play. || Set a screen lock (PIN, fingerprint or face). || Add a PIN to your mobile account with your phone company to stop SIM-swap attacks. || Don't tap links in unexpected texts - Australia gets millions of scam texts every year.

== Home Wi-Fi and networks
icon: E701
tips: Change your router's default admin password. || Use WPA2 or WPA3 security with a long Wi-Fi password. || Update your router's firmware, and replace routers that no longer get updates. || On public Wi-Fi, avoid banking, or use your phone's mobile data instead. || Keep the Windows Firewall switched on - it blocks unwanted connections.

== Backups (your insurance against ransomware)
icon: E777
tips: Follow the 3-2-1 rule: 3 copies of important files, on 2 different types of storage, with 1 copy somewhere else (like the cloud). || OneDrive, Google Drive or an external drive all work. || Unplug your backup drive after backing up, so ransomware can't reach it. || Test that you can actually open a file from your backup.

== If something goes wrong - emergency plan
icon: E7BA
tips: 1) Stay calm. Being scammed or hacked is NOT your fault, and it happens to smart people every day. || 2) If money is involved, call your bank straight away. || 3) If you think your PC has a virus: disconnect from the internet, then run a Full Scan in the Antivirus tab. || 4) Change your passwords from a DIFFERENT, clean device, starting with your email. || 5) Report it: ReportCyber (cyber.gov.au) and Scamwatch. || 6) If your ID was stolen, call IDCARE free on 1800 595 160.
'@
