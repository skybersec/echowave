# Honest Feedback App (working title)

## 1. Vision
A mobile-first application that lets people, teams, and organisations collect **candid, anonymised feedback** through a short 10-question survey. Respondents access the survey via a unique, unguessable URL or QR code. Once a minimum number of **k = 10** responses (recommended k-anonymity for small cohorts) has been reached, the requester receives a private, AI-generated summary highlighting:
• Strengths and what is working well
• Opportunities for improvement
• Overall sentiment & key themes
• Any additional actionable insights

The primary goal is to publish on the **iOS App Store** and **Google Play**, with a web companion site planned for desktop access.

---

## 2. Core User Stories
1. **Requester onboarding**
   • Sign up with email (OAuth for Google/Facebook/Instagram planned).  
   • Choose survey template (Individual, Product, Service, Team, etc.).  
   • Define minimum response threshold *X* for anonymity (default **k = 10**).  
   • Receive unique survey link + QR code to share.

2. **Respondent flow**
   • Visit link / scan QR → mobile-optimized survey page.  
   • Answer 10 questions (mix of MCQ, rating scales, open text).  
   • Submission stored securely & anonymously.

3. **Results & Insights**
   • Once ≥ *X* responses, requester receives notification.  
   • View AI-generated insights + raw (but anonymised) data.  
   • Option to share summary on social networks.

4. **Pricing (future)**
   • Freemium: 1 active survey, up to 20 responses.  
   • Pro \$4.99/mo: unlimited surveys, advanced analytics.  
   • Team \$14.99/mo: shared dashboards, export, integrations.

---

## 3. Architecture (Prototype)
```
+----------------+        REST          +------------------+
|   iOS Client   |  <───────────────▶  |  Local backend   |
|  SwiftUI app   |   (localhost)       |  (Node/Express)  |
+----------------+                     +---------+--------+
                                                 │SQLite
+----------------+                               ▼
| Android Client |                     +------------------+
|  Jetpack      |                     |   Data store     |
|  Compose app   |                     +------------------+
+----------------+
```
• **iOS Front-end**: SwiftUI for native iOS experience  
• **Android Front-end**: Jetpack Compose for native Android experience  
• **Backend**: Node.js + Express with SQLite (swap to Postgres in prod).  
• **AI**: OpenAI GPT-4 via `/summarise` endpoint.  
• **Security**: JWT auth, CORS locked to allowed origins.

### Key Modules
| Layer | Module | Responsibilities |
|-------|--------|-------------------|
| Backend | auth | Registration, login, JWT refresh |
|         | survey | CRUD for survey templates & responses |
|         | analytics | Trigger OpenAI summary once threshold met |
|         | share | Generate QR code (svg/png) & social share links |
| Frontend | onboarding | Account creation & template selection |
|          | feedback | Form rendering & validation |
|          | dashboard | Real-time results + AI summary |

---

## 4. Data Model (simplified)
```
User { id, email, password_hash, created_at }
Survey { id, user_id, template_type, min_responses, url_token, created_at }
Question { id, survey_id, order, type, prompt, choices? }
Response { id, survey_id, submitted_at }
Answer { id, response_id, question_id, value }
Summary { id, survey_id, gpt_model, content_json, created_at }
```

---

## 5. Local Development Guide
1. **Clone repo & move into dir**
```
$ git clone <repo-url> feedback-app
$ cd feedback-app
```
2. **Install backend**
```
$ cd backend
$ npm install
$ cp .env.example .env   # add OPENAI_API_KEY
$ npm run dev            # starts on http://localhost:3000
```
3. **Run iOS client**
```
$ cd ios/EchoWave
$ open EchoWave.xcodeproj
# Select iPhone simulator & press ▶
```
4. **Seed data & test flow**
```
POST /api/v1/surveys/seed
```

### Environment Variables
```
OPENAI_API_KEY=sk-...
JWT_SECRET=supersecret
BASE_URL=http://localhost:3000
```

---

## 6. OpenAI Integration
Endpoint `/api/v1/surveys/:id/summary` calls OpenAI with the following prompt structure:
```
You are an expert organisational psychologist...
Here are N anonymous responses: [JSON]...
Provide a concise summary with: strengths, opportunities, sentiment, actionable tips.
```
Returned JSON is stored and displayed in the dashboard.

### Prompt-Injection Safeguards
• Server-side template locks the system & assistant messages; answers are inserted only into a `{{responses}}` placeholder.  
• User text is escaped (no markdown/HTML) and truncated to model limits.  
• Filter strips tokens such as "Ignore previous instructions", code fences, or markdown headings that could break the template.  
• Chat Completions are called with controlled `max_tokens`, low `temperature`, and optional `tools/function_call` to sandbox output.  
• Final markdown is run through an allow-list renderer before display.

---

## 7. Anonymity & Security Considerations
• We enforce **k-anonymity with k = 10** — insights are released only after ten distinct participants have responded, **unlocking the psychological safety required for candid, unfiltered feedback**.  
• Results are **withheld until `responses ≥ 10`**; if the user sets a higher threshold the higher value is honoured.  
• To mitigate "fake filler" responses, each respondent must pass an *authenticity check* (choose one per-survey): email verification, OAuth login, or one-time invite token.
• One response per verified identity; duplicate detection via hashed email, device fingerprint & IP rate-limiting.  
• reCAPTCHA v3 enabled to deter bots.  
• URLs use 128-bit tokens (≈ 22 Base64 chars) → resistant to guessing.  
• HTTPS enforced in production; localhost self-signed cert optional.  
• PII stripped before AI call; only answer text is shared with OpenAI.  
• **Respondent disclaimer:** "Please do NOT include any personal or identifying information (e.g. name, email, phone number, address, company, social-media handles) in your answers." This notice is displayed above every open-text question.  
• Automatic PII scanner (regex + ML) redacts accidental identifiers before data is stored.  
• GDPR & CCPA compliant data deletion endpoints.

---

## 8. Roadmap
| Phase | Goals |
|-------|-------|
| 0.1 | iOS MVP on localhost; hard-coded templates |
| 0.2 | Custom question builder, response threshold config |
| 0.3 | OAuth (Google/Facebook), deploy to TestFlight |
| 0.4 | Android release, Firebase hosting for respondent web forms |
| 0.5 | Stripe billing, multi-language support |
| 1.0 | Public launch on App Store & Google Play, marketing site |

---

## 9. Enhanced User-Experience Features (Planned)
1. **Adaptive Questioning** – Follow-up prompts appear only when a response is vague or highly emotional, reducing respondent fatigue.  
2. **AI Action-Plan Cards** – Convert insights into 3-5 concrete tasks the requester can pin, snooze, or check off.  
3. **Longitudinal Dashboards** – Track key metrics across multiple survey cycles to visualise progress.  
4. **Benchmarking (Opt-in)** – Compare aggregated sentiment to anonymised peers in the same industry or role.  
5. **Custom Branding & White-Label Links** – Paid tiers can add logos, colour themes, and custom domains.  
6. **Kudos Wall** – Positive snippets auto-categorised into a shareable mosaic for motivation.  
7. **Multilingual Auto-Detection** – Detect locale, localise the survey, and auto-translate answers back to the owner's language.  
8. **Accessibility-First Design** – WCAG 2.2 AA, dark-mode, reduced-motion, full keyboard support.  
9. **Calendar Nudges** – One-click "Add Reminder" for respondents who postpone, boosting completion rates.  
10. **Embedded Widget & Browser Extension** – Collect feedback in-app or contextually inside any website.

---

## 10. Branding & Growth Strategy
### Brand Essence
• **Working Title:** *EchoWave* (alternatives: *MirrorPulse*, *TrueNorth Feedback*).  
• **Tagline:** "Hear the candid truth, grow with it."  
• **Tone & Voice:** Compassionate, growth-minded, scientifically credible.  
• **Visual Identity:** Calming teal + deep navy palette, rounded sans-serif type, spiral "echo-wave" icon inside a dialogue bubble.

### Engagement & Reward Loops
1. **Growth Points & Levels** – Each completed feedback cycle yields points; levelling up unlocks new analytics themes and avatar frames.  
2. **Streaks & Milestones** – Consecutive weeks of collecting feedback create a streak; hit milestones (3, 6, 12 cycles) to earn badges.  
3. **Kudos Spotlight** – Randomised positive quote pops up upon login, triggering dopamine without revealing identities.  
4. **Weekly Digest Email** – AI-generated "progress postcard" summarises new insights + streak status; shareable with a click.  
5. **Social Share Cards** – Auto-generated OG images showcasing top strengths; encourage posting to LinkedIn, Instagram Stories, etc.  
6. **Referral Flywheel** – Invite friends/teams; each verified signup grants free "AI Action-Plan" credits or extends Pro trial.  
7. **Seasonal Challenges** – Quarterly themed challenges (e.g., "Radical Candour Month") boost community engagement and PR.

### Go-To-Market (GTM) Phases
| Phase | Objective | Key Tactics |
|-------|-----------|-------------|
| Pre-launch | Build waitlist | Viral referral waitlist (SparkLoop), teaser video on Product Hunt Upcoming, gated beta for coaches |
| Launch | Drive installs & buzz | Product Hunt + Hacker News post, intro discounts, LinkedIn ads targeting HR/Engineering managers, TikTok creator partnerships |
| Post-launch | Sustain growth | Content hub on feedback psychology, podcast sponsorships, webinar series with thought-leaders, customer success case studies |

### Channel Mix
• **Content Marketing:** SEO pillars—"how to get honest feedback", "team retrospective templates".  
• **Community:** Private Discord/Slack for power users & coaches.  
• **Influencers:** Partner with career-development TikTokers, leadership LinkedIn voices.  
• **Paid Ads:** High-intent Google Search + retargeting, niche LinkedIn groups (PeopleOps, Product).  
• **Lifecycle Emails & Push:** Behaviour-based sequences—onboarding tour, nudge when responses < k, re-engage cold users.

### Ethical Considerations
We leverage behavioural design (streaks, social proof) **without dark patterns**—users can pause notifications, hide streaks, and export/delete data at any time.

---

## 11. Advanced Privacy & Security Controls (Planned)
1. **End-to-End Encryption (E2EE)** – Encrypt answers client-side with a per-survey symmetric key; server stores only ciphertext.  
2. **Differential Privacy Layer** – Add calibrated noise to aggregated stats to thwart inference attacks.  
3. **Two-Factor & Passkey Support** – WebAuthn/FIDO2 and TOTP codes for requester accounts.  
4. **Blind-Index Duplicate Checking** – Hash-and-pepper identifiers to dedupe without storing raw values.  
5. **Secure Proxy for OpenAI Calls** – Strip metadata and route via a proxy enforcing quotas and timeouts.  
6. **Strict CSP & COOP/COEP Headers** – Defend against XSS and cross-origin leaks in web views.  
7. **Data-Retention Controls** – Auto-purge raw responses after X days (default 90).  
8. **Immutable Audit & Access Logs** – Chain-hashed logs available for GDPR "right to audit."  
9. **Continuous Vulnerability Scanning & SBOM** – Automated SCA plus exported software bill of materials.  
10. **Annual Pen-Test & Bug-Bounty Policy** – Commit to third-party testing and public security.txt.  
11. **Incident-Response Runbook** – Pre-defined procedures for breach handling and disclosure.  
12. **Optional Self-Hosted Deployment** – Docker/K8s chart for on-prem use behind corporate firewalls.

---

## 12. Contributing
Pull requests are welcome! Please open an issue first to discuss changes.  
Run `npm test && swift test` before submission.

---

## 13. License
`MIT` – see LICENSE file.

---

*Let's build a kinder world through honest feedback!* 
