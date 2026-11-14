# Guardian Shield - Shield AI Adviser knowledge base (offline).
# "kw:" = keywords (comma separated, lowercase). "a:" = answer. Lines starting "+ " continue the answer on a new line.

$script:AdviserData = @'
== hello
kw: hello, hi , hey, g'day, gday, good morning, sup
a: G'day, Agent! I'm Shield AI. Ask me anything about keeping your PC, accounts and money safe.
+ Try: "Why is my score low?", "I think I have a virus", or "How do I spot a scam text?"

== virus
kw: virus, infected, malware, trojan, spyware, slow, pop-up, popup, weird, acting strange, adware
a: Signs a PC might be infected: it is suddenly very slow, pop-ups appear even when no browser is open, your browser home page changed by itself, unknown programs appear, the antivirus was switched off by itself, or friends get messages you didn't send.
+ What to do, step by step:
+ 1. Open the Antivirus tab and press UPDATE VIRUS DEFINITIONS (so Defender knows the newest viruses).
+ 2. Press FULL SCAN and let it finish - you can keep using the PC.
+ 3. Open Malware Checker and press AUDIT STARTUP PROGRAMS to look for unknown programs starting with Windows.
+ 4. Uninstall programs you don't recognise: Settings > Apps > Installed apps.
+ 5. If it is still acting strange, use Windows Security > Virus & threat protection > Scan options > Microsoft Defender Offline scan - it restarts the PC and scans before Windows loads, which catches stubborn malware.
+ 6. Afterwards, change your important passwords from a different device.

== clicked link
kw: clicked, i clicked, opened the link, entered my password, typed my password, gave my details, fell for
a: Don't panic - acting quickly makes a big difference. Here is exactly what to do:
+ 1. If you typed a PASSWORD: change it now on the real website (type the address yourself). If you use that password anywhere else, change those too. Turn on two-factor authentication.
+ 2. If you typed CARD or BANK details: call your bank straight away on the number on the back of your card and ask them to block the card.
+ 3. If something DOWNLOADED or you ran a command: disconnect from the internet and run a Full Scan in the Antivirus tab.
+ 4. If you gave ID details (licence, passport, Medicare): call IDCARE free on 1800 595 160.
+ 5. Report it at scamwatch.gov.au to help warn others.

== password
kw: password, passwords, strong password, passphrase, good password
a: A strong password is LONG, RANDOM and UNIQUE.
+ - LONG: at least 14-16 characters. Length beats complexity.
+ - RANDOM: no names, pets, birthdays, footy teams or keyboard patterns like qwerty.
+ - UNIQUE: a different password for every account, so one leak can't unlock everything.
+ Easiest method: a passphrase of 5-6 random words, like Tiger-Pocket-Cloud-Mango-Seven-42. Use the Password Lab tab to generate one and test it.
+ Can't remember them all? That's normal - use a password manager (Bitwarden is free). Then you only remember one master passphrase.

== password manager
kw: password manager, bitwarden, 1password, lastpass, remember passwords, keepass
a: A password manager is a locked digital vault that stores all your passwords. You remember ONE strong master password and it fills in the rest.
+ Why it's safer: you can have a different, random password everywhere, and it only fills passwords on the REAL website - so it also protects you from fake login pages.
+ Good options: Bitwarden (free), 1Password (paid), or the manager built into Microsoft Edge / Google Chrome / Apple devices.
+ Always protect the manager itself with two-factor authentication.

== 2fa
kw: 2fa, mfa, two-factor, two factor, authenticator, one-time code, passkey, otp
a: Two-factor authentication (2FA) means logging in needs TWO things: something you know (your password) and something you have (your phone).
+ Even if a criminal steals your password, they still can't get in without your phone.
+ Best to worst: 1) Passkeys (use your fingerprint/face - can't be phished), 2) Authenticator apps (Microsoft Authenticator, Google Authenticator), 3) SMS text codes (better than nothing).
+ IMPORTANT: never read a code out to anyone or type it into a site you reached from a link. The code is only for YOU.

== scam text
kw: scam, text, sms, message, is this a scam, suspicious, toll, parcel, auspost, delivery
a: Quick scam test - a message is almost certainly a scam if it:
+ 1. Pretends to be a company or government department,
+ 2. Says it's urgent ("pay today", "account suspended"),
+ 3. Wants you to tap a link or call a number in the message,
+ 4. Asks for money, a password, a code, or card details.
+ Never use links or numbers in the message. Open the official app or type the website address yourself.
+ Paste the message into Email Guard > Phishing Detector and I'll check it for over 15 warning signs.

== phishing
kw: phishing, phish, fake email, email scam, spoof, fake website
a: Phishing is when criminals pretend to be a trusted company to trick you into clicking, logging in or paying.
+ Spot it:
+ - Look at the REAL sender address, not just the name. "Microsoft Support <alert@micros0ft-help.xyz>" is fake.
+ - Hover over links (don't click!) to see where they really go.
+ - Generic greetings like "Dear Customer".
+ - Spelling mistakes, threats, prizes, or rushed deadlines.
+ The Phishing Radar tab shows the scams going around right now.

== card fraud
kw: card, credit card, debit card, transaction, charge, unauthorised, fraud on my, someone used, bank account
a: If someone used your card:
+ 1. Lock the card in your banking app straight away (most Australian banks have a "lock card" button).
+ 2. Call your bank on the number on the back of the card and report the fraud.
+ 3. Ask for a new card number and ask about a chargeback (getting the money back). About 72% of Australian card fraud victims get ALL their money back, so it is worth acting fast.
+ 4. Check the last few months of statements for small charges you don't recognise.
+ 5. Change your passwords for shopping sites where your card is saved.

== breach
kw: breach, optus, medibank, latitude, qantas, origin, leaked, data leak, stolen data, medisecure, ticketmaster
a: If you were in a data breach:
+ 1. Open the Aussie Breaches tab, tick the companies you used, and press BUILD MY PERSONAL ACTION PLAN.
+ 2. If a driver licence number leaked: get a new licence CARD number from your state transport agency.
+ 3. If your passport number leaked: consider replacing it.
+ 4. Put a free credit ban on with Equifax, Experian and illion so no-one can borrow money in your name.
+ 5. Change your password for that company and anywhere you reused it.
+ 6. Expect scam calls that use your real details - knowing your name doesn't make a caller genuine.
+ IDCARE (1800 595 160) will help you for free.

== identity theft
kw: identity, identity theft, stolen identity, licence, passport, credit ban, credit report
a: Identity theft is when a criminal uses your details (name, birth date, licence or passport number) to pretend to be you - often to open loans, phone plans or bank accounts.
+ Protect yourself:
+ - Get a free credit report from Equifax, Experian and illion once a year and check for loans you didn't take.
+ - A credit ban (free, 21 days, can be extended) stops new credit being opened in your name.
+ - Replace leaked licence card numbers and passports.
+ - Call IDCARE on 1800 595 160 for a free, personal recovery plan.

== update windows
kw: update, windows update, 24h2, 25h2, windows 10, end of support, upgrade, patch
a: Updates are the single most important protection - most hacks use holes that were already fixed by an update the victim never installed.
+ Important dates:
+ - Windows 10 stopped getting free security updates in October 2025.
+ - Windows 11 version 24H2 Home and Pro got its last update on 13 October 2026.
+ How to update: Settings > Windows Update > Check for updates. Install everything, including "Windows 11, version 25H2" if offered, then RESTART.
+ The PC Scan tab tells you which version you have and if it's still supported.

== zero day
kw: zero-day, zero day, 0day, cve, vulnerability, exploit, what is a vulnerability
a: A VULNERABILITY is a mistake in software that lets criminals break in, like a faulty lock.
+ An EXPLOIT is the tool criminals build to use that mistake.
+ A ZERO-DAY is a hole attackers used before the maker had a fix - the software maker had "zero days" to fix it.
+ A CVE number (e.g. CVE-2026-96951) is just an ID tag so experts everywhere can talk about the same hole.
+ The cure for nearly all of them: install updates. See the Threat Feed tab for the latest.

== ransomware
kw: ransomware, encrypted my files, ransom, files locked, backup, backups
a: Ransomware locks (encrypts) all your files and demands payment to unlock them. Paying doesn't guarantee you get them back.
+ The best defence is a BACKUP:
+ - 3 copies of important files, on 2 different kinds of storage, 1 kept elsewhere (like OneDrive or Google Drive).
+ - Unplug your external backup drive after use so ransomware can't reach it.
+ Also turn on "Ransomware protection > Controlled folder access" in Windows Security > Virus & threat protection.
+ If it happens: disconnect from the internet, don't pay, and report it at cyber.gov.au.

== firewall
kw: firewall, network, ports, blocking
a: A firewall is like a bouncer at the door of your PC: it decides which internet connections are allowed in and out.
+ Windows has a free one built in. It should be ON for all three networks: Domain, Private and Public.
+ To check: Windows Security > Firewall & network protection. The PC Scan tab checks it for you.
+ If a game asks to get through the firewall, allow it only on Private networks (home), not Public (cafes, airports).

== defender enough
kw: defender, is defender enough, need antivirus, buy antivirus, which antivirus, norton, mcafee, avast
a: For most people, Microsoft Defender (built into Windows) is enough IF it is switched on, updated, and Windows itself is up to date. Independent testing labs regularly rate it highly.
+ What matters more than which antivirus you have:
+ - Keeping Windows and apps updated,
+ - Not downloading cracked software or cheats,
+ - Using unique passwords and two-factor.
+ Never run two real-time antiviruses at once - they fight each other and slow your PC.

== gaming
kw: game, gaming, cheat, cheats, mod menu, steam, discord, roblox, fortnite, minecraft, skins, nitro, robux, epic, valorant
a: Gamers are a top target because game accounts and skins are worth real money.
+ The big dangers:
+ - Cheats, mod menus, cracks and "free" games often contain password stealers. They grab your browser passwords, Discord token and crypto wallets in seconds.
+ - "Vote for my team" / "free Nitro" / "I accidentally reported you" messages lead to fake login pages.
+ - Fake Steam or Discord "staff" - real staff never DM you.
+ Protect yourself: Steam Guard Mobile Authenticator, 2FA on every gaming account, and only download mods from trusted official sites. Check any download in the Malware Checker first.

== remote access
kw: remote, anydesk, teamviewer, tech support, microsoft called, support scam, quick assist, someone called me
a: Microsoft, your bank, your internet company and the police will NEVER call you out of the blue and ask to access your computer.
+ If someone is on the phone asking you to install AnyDesk, TeamViewer, Quick Assist or similar - hang up.
+ If you already let them in:
+ 1. Unplug the internet (or turn off Wi-Fi) immediately.
+ 2. Uninstall the remote-access program (Settings > Apps).
+ 3. Call your bank if you logged in to banking while they were connected.
+ 4. Run a Full Scan and change your passwords from another device.

== public wifi
kw: wifi, wi-fi, public wifi, vpn, hotspot, cafe, airport
a: Public Wi-Fi (cafes, airports, hotels) is shared with strangers. Most websites now use HTTPS (the padlock), which protects your data, but fake hotspots with real-sounding names do exist.
+ Tips: avoid banking on public Wi-Fi, use your phone's mobile data instead, and choose "Public network" when Windows asks.
+ A VPN encrypts your connection - useful on public Wi-Fi - but it doesn't stop viruses or scams.

== report
kw: report, where do i report, police, help, who do i call, scamwatch, reportcyber
a: Where to get help in Australia:
+ - Money lost? Call your BANK first, right now.
+ - Cybercrime (hacking, online fraud): ReportCyber at cyber.gov.au, or call 1300 CYBER1 (1300 292 371).
+ - Scams: report at scamwatch.gov.au to warn others.
+ - Identity stolen or leaked: IDCARE, free, 1800 595 160.
+ - Feeling upset: Lifeline 13 11 14. Being scammed is not your fault.

== hacked account
kw: hacked, account hacked, someone logged in, can't log in, cant log in, instagram, facebook, tiktok, snapchat, gmail, outlook, account taken
a: If an account was hacked:
+ 1. Use the site's official "forgot password" or "my account was hacked" page (e.g. facebook.com/hacked).
+ 2. Once back in: change the password to a new, unique one and turn on two-factor.
+ 3. Check settings the hacker may have changed: recovery email, phone number, email forwarding rules and connected apps.
+ 4. Log out of all other sessions/devices.
+ 5. Warn friends - hackers often message them asking for money or codes.
+ If your EMAIL was hacked, fix that first - it controls everything else.

== shopping
kw: shopping, fake shop, online store, website legit, buy online, marketplace, facebook marketplace, gumtree
a: Before buying from a shop you don't know:
+ - Search the shop name + "scam" and read reviews on independent sites.
+ - Check the ABN at abr.business.gov.au and look for a real address and phone number.
+ - If prices are 50-90% cheaper than everywhere else, it's almost certainly fake.
+ - Pay with PayPal, Apple Pay, Google Pay or a credit card - never bank transfer, gift cards or crypto.
+ On Marketplace/Gumtree: meet in person and inspect before paying, and never accept "overpayments".

== investment
kw: crypto, bitcoin, investment, trading, get rich, forex, returns
a: Investment scams cause some of the biggest losses in Australia. Warning signs: guaranteed high returns, celebrity "endorsements" (often deepfakes), pressure to invest quickly, someone you met online "teaching" you to trade, or being asked to pay a fee to withdraw your "profits".
+ Check if a company is licensed on ASIC's Moneysmart website before investing anything. If you can't withdraw your money - stop sending more.

== romance
kw: romance, dating, met online, girlfriend, boyfriend, love, relationship
a: Romance scammers build a relationship online for weeks or months, then have an emergency and need money - or want to "teach" you to invest. They always have an excuse not to video call or meet.
+ Rule: never send money, gift cards or crypto to someone you haven't met in person. Do a reverse image search of their photos. Talk to a friend or family member - scammers try to keep you isolated.

== job
kw: job, jobs, work from home, task, employment, recruiter, side hustle
a: Job scams in 2026 often arrive by WhatsApp or text: "earn $300 a day liking videos" or "rating products". You earn a little at first, then must "top up" with your own money to unlock bigger tasks - and it all disappears.
+ Real jobs never ask you to pay to work, and real recruiters don't hire over WhatsApp with no interview.

== ai voice
kw: deepfake, voice, ai voice, voice clone, hi mum, family emergency
a: Criminals can copy a voice from a few seconds of video. If a "family member" calls in a panic asking for money:
+ 1. Hang up and call them back on the number you already have.
+ 2. Ask a question only they'd know - or use a family safe word you agreed on.
+ 3. Never send money in a rush. Real emergencies can wait 5 minutes for you to check.

== government
kw: mygov, ato, tax, centrelink, medicare, government, warrant, arrest, fine
a: Government impersonation is common. Remember:
+ - myGov never sends links to sign in - type my.gov.au yourself.
+ - The ATO never threatens arrest and never asks for gift cards, crypto or payment to a personal account.
+ - Check any message by logging in to myGov directly, or call the agency on a number from its official website.

== kids
kw: kids, children, child, son, daughter, parental, family, teenager
a: Keeping kids safe online:
+ - Use Microsoft Family Safety (free) for screen time and content limits on Windows and Xbox.
+ - Keep gaming consoles and PCs in shared spaces for younger kids.
+ - Teach them: never share passwords, never click "free Robux/V-Bucks", and tell a grown-up if anything feels weird - they won't get in trouble.
+ - Set up 2FA on their gaming accounts and link them to a parent email.
+ - The eSafety Commissioner (esafety.gov.au) has great guides and a reporting service for online bullying.

== disk
kw: disk, drive, hard drive, ssd, storage, space, full, slow drive
a: Your drive stores everything. Open the Hard Disk Check tab to see each drive's health and free space.
+ - If a drive shows WARNING or UNHEALTHY: back up your files TODAY - it may fail soon.
+ - If a drive is over 90% full: Windows slows down and updates can fail. Free space with Settings > System > Storage > Cleanup recommendations, and turn on Storage Sense.
+ - HDDs (spinning drives) are slower and wear out mechanically; SSDs are faster and more reliable.

== encryption
kw: encryption, bitlocker, device encryption, encrypt, laptop stolen
a: Encryption scrambles everything on your drive so that if your laptop is lost or stolen, nobody can read your files without signing in.
+ - Windows Pro: turn on BitLocker (Control Panel > BitLocker Drive Encryption).
+ - Windows Home: look for Settings > Privacy & security > Device encryption.
+ IMPORTANT: save your recovery key (it's usually saved to your Microsoft account automatically) - without it you could lose access if something changes.

== uac
kw: uac, user account control, admin, administrator
a: User Account Control (UAC) is the pop-up that asks "Do you want to allow this app to make changes?". It's annoying but important - it stops programs secretly changing your system. Keep it ON.
+ Only click YES when YOU just started installing something you trust. If it pops up out of nowhere, click NO.

== secure boot
kw: secure boot, uefi, bios, boot
a: Secure Boot makes sure only trusted software can start your PC before Windows loads. It blocks "bootkits" - nasty malware that hides underneath Windows where antivirus can't see it. Windows 11 PCs normally have it on. If it's off, it can be turned on in your PC's UEFI/BIOS settings - ask a tech-savvy friend if unsure, as getting it wrong can stop the PC starting.

== remote desktop
kw: remote desktop, rdp
a: Remote Desktop lets other computers control yours over the network. Criminals constantly scan the internet for PCs with it switched on to guess passwords. If you don't use it, turn it OFF: Settings > System > Remote Desktop.

== smb
kw: smb, smb1, smbv1, wannacry, file sharing
a: SMBv1 is a 30-year-old file-sharing system that the WannaCry ransomware used to spread around the world in 2017. Modern PCs don't need it. To remove it: search "Turn Windows features on or off", untick "SMB 1.0/CIFS File Sharing Support", press OK and restart.

== thanks
kw: thanks, thank you, cheers, legend, awesome
a: Anytime, Agent! Every question you ask makes you harder to scam. Keep that Shield Score high.
'@
