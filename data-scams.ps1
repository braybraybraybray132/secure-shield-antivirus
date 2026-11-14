# Guardian Shield - scam intelligence (card fraud + phishing). Researched October 2026.
# Format: "== Title" starts an item. "key: value" lines. "||" separates bullet points.

$script:CardData = @'
== "Your bank" asks you to read out a one-time code
tag: CRITICAL
when: Very common in 2026
how: You get a call or text that looks like it is from your bank's fraud team. They say there is a suspicious payment and "to stop it" you must read out the code they just texted you. That code is actually what the criminal needs to approve a payment, log in to your account, or add YOUR card to THEIR phone wallet (Apple Pay / Google Pay).
impact: Once they have the code they can spend money on your card or empty your account. Because YOU gave the code away, getting the money back can be harder.
defend: Never read a one-time code out to anyone - a real bank will never ask for it. || Hang up and call the number printed on the back of your card yourself. || Read the whole text the code arrives in: it often says what it is for, e.g. "to add your card to a digital wallet". || Turn on instant transaction alerts in your banking app.

== Fake online shops ("ghost stores")
tag: HIGH
when: Peaks around sales, Christmas and big events
how: Criminals build a shop that looks real and advertise it on Facebook, Instagram and TikTok with huge discounts. You pay by card, nothing arrives (or junk arrives), and your card details are kept and used again later. Some copy real stores almost perfectly - in early 2026 fake shops cloned the official Winter Olympics merchandise store. Avast reported blocking about 430,000 visits to fake shops in Australia.
impact: You lose the money, AND your card number, name and address are now in criminals' hands.
defend: Search the shop name plus the word "scam" or "reviews" before buying. || Look the business up on abr.business.gov.au and check it has a real address and phone number. || Be very suspicious of prices 50-90% cheaper than everywhere else. || Pay with PayPal, Apple Pay or Google Pay - they hide your real card number from the shop. || Never pay a shop by bank transfer, gift cards or crypto.

== Fake "brand survey" prizes
tag: HIGH
how: A message or pop-up says you have been chosen to win an iPhone, gift card or "loyalty reward" from a big brand. You do a short survey and pay a small "shipping fee". The website only exists for a few days, so filters don't catch it. The fee form steals your card details and often signs you up to a hidden monthly subscription.
impact: Small charges keep appearing on your card and your card details get sold to other criminals.
defend: Real companies never make you pay to receive a prize. || Close any pop-up that says you have "won". || Check your statement every week - criminals often test stolen cards with tiny $1-$5 charges first.

== Breach follow-up card fraud (Origin Energy and others)
tag: HIGH
when: August - October 2026
how: When a company is hacked, criminals use the stolen data two ways: they try stolen card numbers directly, and they contact victims pretending to be the company ("we are refunding you because of the breach, please confirm your card"). In August 2026 Origin Energy said a breach in late July exposed credit card and bank account details of about 900,000 current and former customers.
impact: If you were a customer, your card number may be known to criminals, and you may receive very convincing "official" messages.
defend: If you were affected, ask your bank to cancel and re-issue your card - it is free. || Never confirm card details through a link in a message about a breach - log in to the company's real app or website yourself. || Watch your statements closely for the next 12 months.

== Card skimming at ATMs, petrol pumps and kiosks
tag: MEDIUM
how: A thin fake reader is fitted over the real card slot, and a tiny hidden camera or fake keypad records your PIN. The criminals make a copy of your card and withdraw cash.
defend: Wiggle the card slot - if it is loose, bulky or a different colour, don't use it. || Cover the keypad with your other hand when typing your PIN. || Use tap-and-pay instead of inserting your card whenever you can. || Use ATMs inside banks or shopping centres.

== Fake ticket sellers
tag: MEDIUM
how: Tickets to sold-out concerts, finals or big tournaments are "resold" on Facebook, Gumtree or fake resale websites. You pay, and the tickets are fake, already used, or never arrive.
defend: Buy only from the official seller or its official resale page. || Never pay a stranger by bank transfer or PayID for tickets. || If the deal is cheap AND "must be paid right now", walk away.

== Refund and "overpayment" scams
tag: MEDIUM
how: Someone says you are owed money - an overpaid tax refund, a bank fee refund, or a refund for a subscription you never had. To "process" it they ask for your card details, or ask you to install a remote-access app so they can "help", then they move money out of your account.
defend: The ATO and banks never ask for your card number to give you a refund. || Never let a caller install AnyDesk, TeamViewer, QuickSupport or similar on your computer or phone. || Hang up and ring the organisation using a number you looked up yourself.

== Personal loan scams
tag: MEDIUM
when: Scamwatch alert, March 2026
how: Fake lenders advertise easy loans with "no credit check". After you apply, they ask for an "upfront fee", "insurance" or your card details before paying out. The loan never arrives. Scamwatch issued a warning about this in March 2026.
defend: Real lenders take fees out of the loan - they don't ask you to pay first. || Check the lender holds an Australian Credit Licence (search on ASIC's Moneysmart website). || Never send ID documents to a lender you found through a social media ad.

== Subscription traps and "free trials"
tag: LOW
how: A free trial for a game, app or diet product needs your card "just for verification". The fine print signs you up to expensive monthly charges that are hard to cancel.
defend: Read the terms before entering your card. || Use a virtual card or a low-limit card for trials (many Australian banks offer virtual cards in their app). || Set a phone reminder to cancel before the trial ends.
'@

$script:PhishData = @'
== "ClickFix" fake CAPTCHA - "press Windows + R and paste"
tag: CRITICAL
when: One of the biggest malware tricks right now
how: A website - often a fake game mod, cheat, crack or "free download" page - shows a box that looks like a normal "I'm not a robot" check. It tells you to press Windows + R, then Ctrl + V, then Enter. Behind the scenes it has ALREADY copied a hidden command to your clipboard. Pasting it runs malware that steals your passwords, Discord and Steam logins, and crypto wallets.
impact: Your whole PC can be taken over in seconds - and antivirus may not stop it, because YOU ran the command yourself.
defend: No real website EVER needs you to press Windows + R, or paste anything into Run, PowerShell or Terminal. || If a page asks for that, close the tab immediately. || If you already did it: disconnect from the internet, run a Full Scan in the Antivirus tab, then change your passwords from a different, clean device.

== Microsoft 365 / Outlook fake login pages
tag: HIGH
when: Microsoft was the most-copied brand - 23% of phishing attempts in Q2 2026
how: An email says your mailbox is full, a file has been shared with you, or your password expires today. The link opens a perfect copy of the Microsoft sign-in page. Whatever you type goes straight to the criminal. Some kits even steal your logged-in "session", which gets them past two-factor codes.
defend: Look at the address bar - real Microsoft logins are on login.microsoftonline.com or login.live.com. || Don't log in from email links - open Outlook or office.com yourself. || Use an authenticator app or a passkey - much harder to phish than SMS codes.

== Social media "age check" phishing
tag: HIGH
when: Since Australia's under-16 social media rules began
how: Criminals send messages pretending to be Instagram, TikTok, Snapchat or the government, saying you must "verify your age" or your account will be deleted. The link asks for your login, a photo of your licence or passport, or a card payment.
defend: Real platforms do age checks inside the app, not through a link in a text or email. || Never send photos of your ID through a link. || If unsure, open the app directly and check its notifications there.

== Parcel delivery texts
tag: HIGH
how: "AusPost: your parcel is on hold, pay $1.95 to redeliver" - or the same from DHL, Toll or a "courier". The link leads to a fake payment page that steals your card. Delivery-notification scams were one of the top warnings during Scams Awareness Week 2026.
defend: Australia Post will never text or email asking you to pay to deliver a parcel. || Track parcels only in the official app or by typing the tracking number into the real website. || Delete the text and report it at scamwatch.gov.au.

== Unpaid toll texts (Linkt and others)
tag: MEDIUM
how: A text says you have an unpaid toll and will be fined unless you pay today. The link goes to a fake payment page.
defend: Log in to your toll account yourself, or call the number on the official website. || Toll companies don't threaten you with instant fines in a text with a link.

== myGov, ATO and Centrelink impersonation
tag: HIGH
how: Emails and texts say you have a tax refund, a debt, or must update your details, with a link to a fake myGov login. Fake callers may even say there is a warrant for your arrest over unpaid tax.
defend: myGov never sends a link to sign in - always type my.gov.au yourself. || The ATO will never threaten arrest or ask for payment in gift cards or crypto. || Check any alert by logging in to myGov directly.

== AI voice cloning and "Hi Mum" messages
tag: HIGH
how: Criminals copy someone's voice from a few seconds of social media video, then call a parent or grandparent sounding exactly like their child: "I've been in an accident, I need money now". The text version starts: "Hi Mum, I dropped my phone, this is my new number".
defend: Agree on a family "safe word" only real family would know. || Hang up and call the person back on the number you already have saved. || Treat ANY urgent request for money as suspicious - even from a familiar voice.

== Fake invoices and "our bank details have changed"
tag: HIGH
how: An email that looks like it is from a tradie, landlord, school or supplier says their bank details have changed, or attaches an invoice. The new account belongs to the criminal. Researchers flagged invoice scams as a top threat in 2026.
defend: Always phone the person on a number you ALREADY know before paying to new bank details. || If your banking app warns that the account name doesn't match, stop and check.

== Gamer phishing: Steam, Discord, free skins, "vote for my team"
tag: HIGH
how: A friend's hacked account messages you: "vote for my team in this tournament", "free Nitro", "I accidentally reported you, talk to this Steam admin", or offers free skins. The link opens a fake Steam or Discord login - sometimes a fake pop-up window drawn inside the web page. They steal your account and your inventory, then use it to scam your friends.
defend: Steam staff never message you on Discord or Steam chat. || Check the address bar says steamcommunity.com or discord.com EXACTLY. || Turn on Steam Guard Mobile Authenticator and Discord two-factor. || Never download "cheats", "mod menus" or free versions of paid games - they are the No.1 way gamers get password-stealing malware.

== QR code phishing ("quishing")
tag: MEDIUM
how: Fake QR stickers are stuck over real ones on parking meters, posters and restaurant tables, or sent in emails. Scanning leads to a fake payment or login page.
defend: Read the website address your phone shows before tapping it. || Pay for parking in the official council app. || Don't scan QR codes in unexpected emails.

== Fake "Your computer is infected" pop-ups
tag: MEDIUM
how: A web page suddenly goes full screen, beeps, and shows a fake Microsoft or antivirus warning with a phone number. The "technician" asks you to install remote-access software and pay to "fix" the problem.
defend: Microsoft and real antivirus programs NEVER show a phone number to call. || If the browser won't close, press Ctrl + Shift + Esc, choose the browser and click End task. || Real warnings come from Windows Security or Guardian Shield - not from a website.

== Breach "compensation" scams
tag: MEDIUM
how: After big breaches (Qantas, Optus, Medibank, Origin Energy) criminals contact people pretending to be the company or a law firm, offering compensation, a refund or "identity protection" - if you pay a fee or hand over details.
defend: Check any breach notice by logging in to the company's official app or website. || Genuine class actions don't ask for card details to join. || Unsure? Call IDCARE free on 1800 595 160.
'@
