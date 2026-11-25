# Privacy Policy - Chismes

**Effective date:** October 22, 2026  
**Last updated:** November 24, 2026  
**Version:** 1.2

---

## 1. Introduction

Welcome to **Chismes** ("we", "our" or "the app"). We take your privacy very seriously and are committed to protecting your personal data.

This Privacy Policy describes:
- What data we collect
- How we use your data
- Who we share your data with
- Your rights over your data
- How we protect your data

By using Chismes, you accept this Privacy Policy.

---

## 2. Data We Collect

### 2.1. Account Information

**What we collect:**
- Email address
- Username, display name and bio (optional, public)
- Profile photo (optional, public)
- Password (encrypted)

**Why:**
- To create and manage your account
- For secure authentication
- For password recovery

**Where it is stored:**
- Supabase (backend provider)
- Servers located in: United States

### 2.2. Location

**What we collect:**
- **Only your city** (example: "Bogotá, Colombia")
- **We do NOT collect** your exact address or GPS coordinates

**How we obtain it:**
- Low-accuracy GPS (network/WiFi, not high-accuracy GPS)
- Only when you create a chisme
- Only if you grant location permissions

**Why:**
- To automatically set the city of your chismes
- For an improved user experience (Uber/Mercado Libre-style UX)

**Where it is stored:**
- Locally on your phone (SharedPreferences)
- On the server: Only the city of each chisme you publish

**Important:**
- GPS coordinates are used **only temporarily** to detect the city
- They are then discarded **immediately**
- We **NEVER** store your exact coordinates
- We **NEVER** send coordinates to the server
- We only store: city, region, country (names + IDs)

**Permissions:**
- iOS: "When In Use" (only while you use the app)
- Android: `ACCESS_COARSE_LOCATION` (network/WiFi accuracy)
- We do **NOT** request background location permissions

**Control:**
- You can deny location permissions
- You can choose the city manually (without GPS)
- You can forget your saved location at any time

### 2.3. Chisme Content

**What we collect:**
- Chisme title (up to 200 characters)
- Chisme content (up to 1000 characters)
- Image (optional, max 5 MB)
- Audio (optional, max 10 MB)
- City where the chisme took place

**Why:**
- To publish and display your chisme
- To moderate inappropriate content

**Where it is stored:**
- Supabase (database and storage)
- Servers located in: United States

### 2.4. Metadata

**What we collect:**
- Creation date and time
- Moderation status
- Counters (views, likes, comments)

**Why:**
- For the app to function
- For statistics and improvements

---

## 3. How We Use Your Data

### 3.1. Providing the Service

- Create and manage your account
- Publish your chismes
- Display other users' chismes
- Manage interactions (likes, comments)

### 3.2. Content Moderation

To keep Chismes safe, we moderate all content before it is published: chismes and also your profile (username, name, bio and photo).

**Moderation process:**

1. **Local rules** (fast, ~10ms):
   - Credible threats
   - Personal data (email, phone number)
   - Spam (URLs, repetition)

2. **OpenAI Moderation API** (AI, ~200ms):
   - Contextual text and image analysis
   - Detection of: hate, harassment, violence, sexual content, etc.

**Data shared with OpenAI:**
- ✅ Chisme text and image (title, content and photo, if any)
- ✅ What you change in your profile (username, name, bio and photo)
- ❌ We do **NOT** share: your email, location, audio, or who you are (we don't send your identifier)

**Retention by OpenAI:**
- OpenAI retains what we send for **30 days** (abuse monitoring)
- It is then deleted automatically
- **It is NOT used to train AI models**

**Source:** [OpenAI API Data Usage Policies](https://openai.com/policies/api-data-usage-policies)

**Decisions:**
- **Approved:** Published immediately
- **Review:** The chisme stays hidden until a moderator reviews it. Profiles are not reviewed: the change is rejected and your profile stays as it was
- **Rejected:** Not published; you receive feedback

### 3.3. Improving the Service

- Analyze app usage
- Fix technical errors
- Improve features

### 3.4. Communication

- Notifications about your account
- Responding to your inquiries
- Information about policy changes

---

## 4. Who We Share Your Data With

### 4.1. Service Providers

**Supabase** (Backend and storage):
- Purpose: Database, authentication, file storage
- Location: United States
- Policy: [Supabase Privacy Policy](https://supabase.com/privacy)

**OpenAI** (Content moderation):
- Purpose: Text and image analysis to detect inappropriate content
- Data shared: text and images from chismes and profile changes
- Retention: 30 days, then deleted
- Location: United States
- Policy: [OpenAI Privacy Policy](https://openai.com/policies/privacy-policy)

### 4.2. Legal Compliance

We may disclose your data if:
- Required by law
- Necessary to protect legal rights
- Necessary to prevent fraud or abuse

### 4.3. International Transfers

Your data may be transferred to and stored on servers located outside your country (United States).

We ensure that these transfers comply with:
- GDPR (for users in the EU): Standard Contractual Clauses (SCC)
- Other applicable regulations

### 4.4. We Do NOT Sell Your Data

We **NEVER** sell, rent or share your personal data with third parties for marketing purposes.

---

## 5. Your Rights

### 5.1. Access

You have the right to request a copy of your personal data.

### 5.2. Rectification

You can correct your name, username, bio and photo in Profile → Edit profile. For other data, write to privacy@chismes.app from your account email.

### 5.3. Erasure ("Right to be forgotten")

You can delete your account at any time from the app.

**How to exercise it:**
- In the app: Profile → Delete account (we ask you to confirm twice)
- Without the app: write to privacy@chismes.app from your account's email address
  (response within 30 days)

**What is deleted, immediately and permanently:**
- Your account and your profile
- All your chismes, including those published anonymously, along with their photos and audio
- Your reports on other chismes

**What is retained:**
- If any of your content was rejected by moderation, we keep an
  anonymous record of those violations: an encrypted (non-reversible) fingerprint of your
  email address and how many violations you had by severity. It does not store your name, your
  content or your identifier. It serves only to prevent a sanctioned account from
  erasing its history and signing up again with the same email address.
- Technical error logs: these are unlinked from your account.
- Backups: may contain your data until they are rotated in their
  normal cycle; they are not used to restore deleted accounts.

### 5.4. Portability

You can request a copy of your data in a structured format (JSON).

### 5.5. Objection

You can object to the processing of your data for certain purposes.

### 5.6. Restriction

You can request that we restrict the processing of your data.

### 5.7. Forget Location

You can delete your saved city at any time:
- Profile → Privacy → Forget location

You can also turn on **Don't save location**: the app will not remember your city and will ask you for it with each chisme.

**Effect:**
- The locally saved city is deleted
- Chismes already published are not affected
- You will be asked for your location again next time

---

## 6. Data Security

We implement technical and organizational measures to protect your data:

### 6.1. Encryption

- **In transit:** TLS/HTTPS for all communications
- **At rest:** Hashed passwords (bcrypt)

### 6.2. Restricted Access

- Only authorized personnel have access to sensitive data
- Principle of least privilege

### 6.3. Auditing

- Logs of access to sensitive data
- Periodic security reviews

### 6.4. Media Quarantine

- Images and audio are uploaded to private buckets (quarantine)
- They are only made public after moderation
- Prevents inappropriate content before approval

### 6.5. Data Minimization

- We only collect strictly necessary data
- GPS: Only low accuracy (city), not high accuracy (exact street)
- Logs: Do not record GPS coordinates in production

### 6.6. Attempt Limits

- Rate limiting to prevent abuse
- Protection against brute-force attacks

**Note:** No system is 100% secure. We do our best, but we cannot guarantee absolute security.

---

## 7. Data Retention

### 7.1. Active Account

- Account data: For as long as your account is active
- Chismes: Indefinitely (or until you delete them)
- Saved location: Until you forget it or close your account

### 7.2. Deleted Account

- Account data, profile, chismes and their media: deleted immediately (see 5.3)
- Anonymous record of moderation violations (only if there were any): for as long as
  necessary to prevent abuse
- Technical error logs: unlinked from the account

### 7.3. Moderation (OpenAI)

- Text sent to OpenAI: 30 days (then deleted)

### 7.4. Aggregated Data

- Anonymous/aggregated data: Indefinitely (for statistics)

---

## 8. Minors

Chismes is **NOT** directed at children under 13 years of age.

- We do not knowingly collect data from children under 13
- If we discover that a minor has provided us with data, we will delete it

**If you are a parent:**
- Contact: privacy@chismes.app if you believe your child has provided data

---

## 9. Cookies and Similar Technologies

### 9.1. Cookies

We currently do **NOT** use cookies in the mobile app.

**Future (if applicable):**
- Session cookies (authentication)
- Analytics (optional, with consent)

### 9.2. Device Identifiers

- We use device identifiers for authentication
- We do not track your activity across apps

---

## 10. Changes to this Policy

We may update this Privacy Policy from time to time.

**We will notify you:**
- Major changes: In-app notification
- Minor changes: Update of the "Last updated" date above

**Your responsibility:**
- Review this policy periodically
- Continuing to use the app = accepting the changes

---

## 11. Legal Compliance

### 11.1. GDPR (Europe)

If you reside in the European Union:
- You have additional rights (see section 5)
- Legal basis for processing: Consent, performance of a contract
- You may file complaints with your data protection authority

### 11.2. CCPA (California)

If you reside in California:
- Right to know what data we collect
- Right to request deletion
- Right to opt out of the sale of data (we do not sell data)

### 11.3. LGPD (Brazil)

If you reside in Brazil:
- You have rights similar to those under the GDPR
- You may file complaints with the ANPD

---

## 12. Contact

### 12.1. Privacy Questions

**Email:** privacy@chismes.app  
**Response:** Within 30 days

### 12.2. Exercising Your Rights

To exercise your rights (access, erasure, portability):
- Send an email to: privacy@chismes.app
- Include: Your account email address, a description of your request

### 12.3. Data Protection Officer (DPO)

(If applicable in the future)

**Email:** dpo@chismes.app

---

## 13. Summary (TL;DR)

**What do we collect?**
- Email, password (encrypted)
- City (NOT exact coordinates)
- Chisme content (text, image, audio)

**How do we use it?**
- Provide the service
- Moderate content (with help from OpenAI)
- Improve the app

**Who do we share it with?**
- Supabase (backend)
- OpenAI (text and images to moderate, 30 days)
- We do NOT sell your data

**Your rights:**
- Access, rectify, delete
- Forget location
- Data portability

**Security:**
- Encryption (TLS/HTTPS)
- Media quarantine
- Data minimization (GPS LOW, not HIGH)

**Contact:**
- privacy@chismes.app

---

## 14. Languages

This Privacy Policy is available in:
- Spanish
- English

In case of conflict, the Spanish version prevails.

---

**Questions?** Contact: privacy@chismes.app

**Effective date:** October 22, 2026  
**Last updated:** November 24, 2026

---

© 2026 Chismes. All rights reserved.
