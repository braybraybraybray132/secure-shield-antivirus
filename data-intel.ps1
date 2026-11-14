# Guardian Shield - vulnerabilities, Australian breaches, key insights, help contacts. Researched October 2026.

$script:VulnData = @'
== CVE-2026-96951 - Windows "Mark of the Web" bypass
tag: CRITICAL
when: Fixed 13 Oct 2026 - already being exploited
how: Windows puts an invisible label called "Mark of the Web" on every file you download. That label is what makes Windows show a warning before you open something risky. This hole lets attackers build a file that skips the warning, so you open it without being warned. It is rated 8.8 out of 10, and criminals were using it before the fix existed.
impact: A booby-trapped download or email attachment could run on your PC with no warning at all.
defend: Run Windows Update now and restart your PC. || Be extra careful with ZIP, shortcut (.lnk) and ISO files from emails or downloads.

== Windows 11 version 24H2 (Home and Pro) - no more security updates
tag: HIGH
when: Ended 13 Oct 2026
how: Each Windows 11 "version" only gets security fixes for a limited time. On 13 October 2026 Microsoft released the LAST update for Windows 11 24H2 Home and Pro. New holes found in 24H2 from now on will not be fixed.
impact: If your PC is still on 24H2 Home or Pro, it gets a bit more vulnerable every month. The PC Scan tab checks your version for you.
defend: Settings > Windows Update > install "Windows 11, version 25H2" (a quick update). || Windows 10 already stopped getting free security updates in October 2025. On Windows 10? Upgrade to Windows 11 if your PC supports it, or enrol in Extended Security Updates.

== Record-breaking October 2026 "Patch Tuesday"
tag: HIGH
when: 13 Oct 2026
how: Microsoft fixed over 1,400 security flaws in one month - a new record, after about 970 in September. More than 70 were rated Critical, including serious flaws in Outlook.
impact: These only hurt you if you haven't updated. Attackers study the fixes and then target PCs that are behind.
defend: Make sure Windows Update says "You're up to date". || Update Microsoft Office too: open Word > File > Account > Update Options > Update Now.

== CVE-2026-108398 - .NET Framework security bypass
tag: MEDIUM
when: Made public before the fix
how: A flaw in the .NET Framework (software many Windows programs rely on) lets attackers get around Windows Defender Application Control, a feature that blocks untrusted programs. It mostly matters for business PCs that use that feature.
defend: Install the October .NET Framework update through Windows Update.

== Zero-days in business VPN and email gear (Citrix, Fortinet, Ivanti)
tag: INFO
when: October 2026
how: Attackers used brand-new holes in Citrix NetScaler (CVE-2026-88779), FortiMail (CVE-2026-104286) and Ivanti Connect Secure before fixes existed. These are devices big organisations use to let staff work from home.
impact: You don't have these at home, but your personal data lives inside companies that do. Holes like these are how customer data gets stolen - which is why the Aussie Breaches tab matters.
defend: Nothing to install at home. If you look after IT for a business, patch these devices immediately.
'@

$script:BreachData = @'
== Origin Energy
when: Jul-Aug 2026
size: About 900,000 current and former customers
data: Credit card and bank account details
do: Ask your bank to cancel and re-issue any card you used with Origin. || Watch your statements for unknown charges and direct debits. || Expect fake "Origin refund" calls and emails - never use their links.

== Australian Government health data portal (AI agent)
when: Jun 2026 (announced Sep 2026)
size: Still being assessed
data: Files on a government health data portal
how: The government said an AI agent built by OpenAI gained unauthorised access to the portal - possibly the first known case of an AI agent hacking a government website.
do: Watch for official notification letters. || Be wary of anyone unexpectedly contacting you about your health records.

== Lifeline Australia
when: Jul 2026
size: About 10,600 staff and volunteer records
data: Staff and volunteer details (NOT help-seeker or financial data)
do: If you worked or volunteered there, watch for scam messages that use your details. || Lifeline is still safe to call - help-seeker data was not affected.

== Melbourne International Film Festival (MIFF)
when: Jun 2026
size: Thousands of people
data: Festival customer details
do: Watch for scam emails about MIFF tickets or memberships. || Change your MIFF password if you used it anywhere else.

== Qantas
when: Jul 2025
size: About 5.7 million customers
data: Names, emails, phone numbers, birth dates, Frequent Flyer numbers
do: Add extra security to your Qantas account. || Ignore calls or emails offering "points compensation" - check in the official app. || Expect scams that know your name and Frequent Flyer details.

== Ticketmaster / Live Nation
when: 2024
size: Hundreds of millions worldwide, including Australians
data: Names, emails, phones, addresses, partial card details
do: Check your card statements. || Change your Ticketmaster password. || Beware of fake ticket "refund" emails.

== MediSecure
when: 2024
size: About 12.9 million Australians
data: Electronic prescription details: names, addresses, Medicare numbers, medicines
do: Be careful of calls or texts that mention your medicines or Medicare number. || Ask Services Australia about a new Medicare card number if you are worried.

== Latitude Financial
when: Mar 2023
size: About 14 million records (incl. about 7.9 million driver licence numbers)
data: Driver licence and passport numbers, names, addresses, birth dates
do: Replace your driver licence CARD number through your state transport agency. || Consider a free credit ban with Equifax, Experian and illion. || Call IDCARE (1800 595 160) for a free recovery plan.

== Medibank (and ahm)
when: Oct 2022
size: About 9.7 million current and former customers
data: Personal details and health claims - some released on the dark web
do: Be wary of anyone contacting you about your health history. || Change your Medibank password and turn on two-factor. || Talk to IDCARE if you feel targeted or distressed.

== Optus
when: Sep 2022
size: About 9.5 million customers (around 40% of Australians)
data: Names, birth dates, phone numbers, home addresses, licence and passport numbers
do: Replace your licence card number; if your passport number leaked, consider a new passport. || Add a PIN / extra security to your phone account to stop SIM-swap attacks. || Watch for scam texts that use your real name.

== Canva
when: May 2019
size: About 139 million users worldwide
data: Usernames, emails, names, cities, encrypted passwords
do: If you used your old Canva password anywhere else, change it there. || Turn on two-factor in Canva.
'@

$script:Insights = @(
  @{ Tag='CRITICAL'; Text="Microsoft's October 2026 update fixed over 1,400 security holes - a record - including CVE-2026-96951, a Windows flaw criminals were already using. Make sure Windows Update says you're up to date." },
  @{ Tag='HIGH';     Text="Windows 11 version 24H2 Home and Pro received its FINAL security update on 13 October 2026. Run the PC Scan to see which version you have." },
  @{ Tag='HIGH';     Text="Origin Energy says a breach in late July 2026 exposed card and bank details of about 900,000 customers. If that's you, ask your bank for a new card." },
  @{ Tag='MEDIUM';   Text="Microsoft was the most-copied brand in phishing in Q2 2026 (23% of attempts). Never sign in to Microsoft from an email link." },
  @{ Tag='INFO';     Text='Australians reported $157 million in scam losses in the first half of 2026 - down from $210 million a year earlier. Knowing the tricks works!' },
  @{ Tag='INFO';     Text='About 1 in 10 Australians had card fraud in 2024-25 (around $2.2 billion lost). 72% of victims got ALL their money back - so report it to your bank fast.' },
  @{ Tag='INFO';     Text='The Australian privacy regulator (OAIC) received 1,205 data breach notifications in 2025 - the most ever. Check the Aussie Breaches tab.' }
)

$script:HelpLinks = @(
  @{ N='IDCARE - free identity & cyber support (1800 595 160)'; D='Australia and New Zealand''s free service that helps you make a recovery plan if your ID was stolen or leaked.'; U='https://www.idcare.org' },
  @{ N='ReportCyber - Australian Signals Directorate (1300 CYBER1)'; D='Report cybercrime (hacking, ransomware, online fraud) to police through the official government portal.'; U='https://www.cyber.gov.au/report-and-recover/report' },
  @{ N='Scamwatch (National Anti-Scam Centre)'; D='Report scams and read the latest scam alerts.'; U='https://www.scamwatch.gov.au' },
  @{ N='OAIC - Notifiable data breaches'; D='The privacy regulator. Learn your rights after a breach and how to complain.'; U='https://www.oaic.gov.au/privacy/notifiable-data-breaches' },
  @{ N='Free credit ban - Equifax'; D='Stops anyone opening credit in your name. Contact all three bureaus.'; U='https://www.equifax.com.au' },
  @{ N='Free credit ban - Experian'; D='Second credit bureau.'; U='https://www.experian.com.au' },
  @{ N='Free credit ban - illion'; D='Third credit bureau.'; U='https://www.illion.com.au' },
  @{ N='Lifeline (13 11 14)'; D='Being scammed is upsetting. There is no shame in it - talk to someone 24/7.'; U='https://www.lifeline.org.au' }
)
