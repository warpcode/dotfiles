# EMAIL CLASSIFICATION TAXONOMY v2.0

---

## 1. ARCHITECTURE

### 1.1 Pattern

Each email is assigned a comma-separated list of tags:

```
domain[, domain...], [descriptor...], [type...]
```

- **Domain tags** — what the email is *about* (subject area)
- **Descriptor tags** — optional narrowing of the domain (e.g. `broadband` within `utilities`)
- **Type tags** — what the email *is* (document type, action, or status)

All tags are lowercase. Underscores permitted within a tag (`car_hire`, `direct_debit`). No compound `domain_modifier` strings. No tag limit per email.

### 1.2 Locale

This taxonomy is scoped to **England, United Kingdom**. All terminology, institutions, and regulatory references must conform to British English. Do not substitute American equivalents.

| Use | Never use |
|---|---|
| Mobile | Cellular, cell phone |
| Solicitor | Attorney, lawyer |
| Headteacher | Principal |
| Primary / secondary school | Elementary / high school |
| Postcode | Zip code |
| Petrol | Gas (as fuel) |
| Estate agent | Realtor |
| Flat | Apartment |
| Chemist / pharmacy | Drugstore |
| A&E | Emergency room / ER |
| Number plate | License plate |
| National Insurance | Social security |
| Holiday | Vacation |
| Cheque | Check |
| DVLA, HMRC, DWP, NHS | DMV, IRS, SSA, or other US equivalents |

### 1.3 Classification Rules

**RULE 001 — Domain Required**
Every email must carry at least one domain tag. Type tags and descriptor tags alone are not valid classifications.

**RULE 002 — Multi-Domain Permitted**
If an email genuinely spans multiple subject areas, assign all relevant domains. A combined home and car insurance renewal receives both `property` and `automotive`. There is no domain limit.

**RULE 003 — Closed Registries**
Only tags from the registries in Sections 2, 3, and 4 may be assigned. No tags may be synthesised, inferred, or extrapolated outside these lists. If no type tag precisely fits, omit rather than approximate.

**RULE 004 — Type Tags Add Value**
Apply a type tag only when it meaningfully narrows classification beyond the domain alone. Not every email requires one. `automotive, mot` is complete; `automotive, mot, certificate` is redundant.

**RULE 005 — Descriptor Tags Are Optional Narrowing**
Descriptor tags narrow a domain when the domain alone is ambiguous across sub-areas. `utilities, broadband, invoice` is clearer than `utilities, invoice`. Do not apply descriptors that add no discriminating value.

**RULE 006 — Universal Standalones Are Last Resort**
`personal`, `professional`, `international`, and `logistics` apply only when no domain-specific tag from Section 2 fits. Domain-specific tags always take precedence.

---

## 2. DOMAIN REGISTRY

*What the email is about. Multiple domains permitted per email.*

### 2.1 Residential & Property

| Tag | Scope |
|---|---|
| `property` | Residential, land, housing — purchases, rentals, maintenance, valuation |
| `utilities` | Energy, water, and telecoms services supplied to a property |
| `smarthome` | Home automation, smart devices, sensors, and control systems |

### 2.2 Financial

| Tag | Scope |
|---|---|
| `finance` | Banking, savings, investments, credit, debt, and all money management |

### 2.3 People & Institutions

| Tag | Scope |
|---|---|
| `healthcare` | Medical, clinical, dental, optical, and general wellness |
| `school` | Primary and secondary education |
| `childcare` | Nursery, after-school care, and holiday clubs |
| `employment` | Work, career, HR, payroll, and professional development |
| `government` | HMRC, local councils, DVLA, DWP, NHS admin, and public bodies |
| `legal` | Solicitors, courts, formal legal proceedings, regulatory notices |
| `civic` | Elections, voter registration, community groups, local governance |
| `charity` | Charitable organisations, fundraising, voluntary sector |

### 2.4 Possessions & Transport

| Tag | Scope |
|---|---|
| `automotive` | Vehicles, driving, road use, and related regulation |
| `shopping` | Consumer retail purchases across any category |
| `logistics` | Courier and parcel tracking not tied to a specific purchase |
| `pet` | Veterinary care, pet insurance, pet food, and supplies |

### 2.5 Digital & Technical

| Tag | Scope |
|---|---|
| `engineering` | Source code, CI/CD, infrastructure, cloud services, deployments |
| `ai` | Artificial intelligence models, LLMs, agentic frameworks, and AI-specific platforms and tooling |
| `tech` | General technology industry news, software product announcements, SaaS tools, and developer ecosystem updates not tied to your own engineering work |
| `security` | Account security, authentication, access control, data breaches |
| `social` | Social media platform notifications, follows, mentions |

### 2.6 Lifestyle & Leisure

| Tag | Scope |
|---|---|
| `travel` | Flights, hotels, rail, car hire, and package holidays |
| `entertainment` | Gaming, streaming, events, shows, and live experiences |
| `fitness` | Gym memberships, sports clubs, fitness classes, health tracking |
| `food` | Restaurants, takeaways, food delivery platforms, meal kits |
| `rewards` | Loyalty programmes, cashback platforms, and points schemes |

### 2.7 General

| Tag | Scope |
|---|---|
| `personal` | Private family or social correspondence with no commercial domain footprint |
| `professional` | Client work, consulting engagements, freelance pipelines |
| `international` | Cross-border matters, customs clearance, overseas administration |
| `logistics` | Generic parcel tracking with no identifiable purchase or domain context |

---

## 3. DESCRIPTOR TAG REGISTRY

*Optional tags that narrow a domain. Always used alongside a domain tag, never alone.*

### 3.1 Utilities Descriptors
*(use with `utilities`)*

| Tag | Narrows to |
|---|---|
| `electricity` | Electricity supply and billing |
| `gas` | Gas supply and billing |
| `water` | Water and wastewater supply |
| `broadband` | Fixed-line internet service |
| `mobile` | Cellular network subscription |
| `tv` | Television licence or pay-TV service |

### 3.2 Automotive Descriptors
*(use with `automotive`)*

| Tag | Narrows to |
|---|---|
| `mot` | UK mandatory annual roadworthiness certificate — a legal certification, not a routine inspection |
| `service` | Scheduled mechanical maintenance |
| `repair` | Unscheduled mechanical intervention or fault rectification |
| `roadtax` | DVLA vehicle excise licence renewal |
| `parking` | Parking charges, permit applications, or penalty charge notices |

### 3.3 Healthcare Descriptors
*(use with `healthcare`)*

| Tag | Narrows to |
|---|---|
| `dental` | Dental care, hygienist appointments, treatment plans |
| `optical` | Eye examinations, lens prescriptions, eyewear |
| `prescription` | Medication dispensation or repeat prescription management |
| `referral` | Specialist or consultant referral |
| `therapy` | Mental health, physiotherapy, or other non-GP clinical sessions |

### 3.4 Finance Descriptors
*(use with `finance`)*

| Tag | Narrows to |
|---|---|
| `mortgage` | Home loan, remortgage, equity release |
| `creditcard` | Credit card account management |
| `savings` | Savings accounts, ISAs, cash bonds |
| `investment` | Shares, funds, ISAs, portfolio management |
| `loan` | Personal, business, or student loan |
| `tax` | HMRC declarations, self-assessment, tax codes, P60, P45 |
| `pension` | Retirement savings or contribution tracking |
| `dividend` | Share income or distribution payments |
| `direct_debit` | Automated recurring payment mandate |
| `transfer` | Account-to-account or peer money movement |
| `credit_score` | Credit report, score updates, or fraud alerts |

### 3.5 Property Descriptors
*(use with `property`)*

| Tag | Narrows to |
|---|---|
| `mortgage` | Property-secured lending (valid under both `property` and `finance`) |
| `tenancy` | Lease agreements, inventories, deposit protection |
| `counciltax` | Local authority council tax billing and adjustments |
| `maintenance` | Tradesperson quotes, repairs, safety inspections |
| `survey` | Structural surveys, valuations, EPC assessments |
| `planning` | Planning applications, permitted development, council decisions |

### 3.6 Employment Descriptors
*(use with `employment`)*

| Tag | Narrows to |
|---|---|
| `hr` | Performance reviews, holiday approvals, disciplinary, training |
| `pension` | Workplace pension contributions and allocation updates |
| `benefits` | Employee benefits, health cash plans, perks schemes |

### 3.7 School Descriptors
*(use with `school`)*

| Tag | Narrows to |
|---|---|
| `newsletter` | Periodic institutional digest or headteacher briefing |
| `attendance` | Term dates, timetables, holiday schedules, late flags |
| `illness` | Absence notifications, medical declarations |
| `fees` | Tuition demands, club invoicing, dinner money, trip costs |
| `event` | Parents evenings, productions, assemblies, sports days |
| `enquiry` | Admissions queries, placement applications |
| `report` | Academic progress reports and assessment results |

### 3.8 Childcare Descriptors
*(use with `childcare`)*

| Tag | Narrows to |
|---|---|
| `nursery` | Early years care setting (under 5s) |
| `wraparound` | Before and after-school care |
| `holiday_club` | Holiday childcare provision |

### 3.9 Engineering Descriptors
*(use with `engineering`)*

| Tag | Narrows to |
|---|---|
| `repo` | Source code repository activity, PRs, commits |
| `pipeline` | CI/CD build, test, and deployment automation |
| `bug` | Issue tracking, stack traces, vulnerability reports |
| `deployment` | Release or environment promotion |
| `monitoring` | Uptime, performance, error rate, or cost alerts |
| `billing` | Cloud or SaaS usage costs and invoices |
| `access` | Permissions, team membership, API key management |
| `sdk` | SDK or library update notifications |
| `api` | API versioning, deprecation, or breaking change notices |

### 3.9a AI Descriptors
*(use with `ai`)*

| Tag | Narrows to |
|---|---|
| `llm` | Large language model releases, weight updates, or model-specific announcements |
| `agent` | Agentic framework, workflow engine, or autonomous tooling updates |
| `model` | Specific model version release or benchmark announcement |
| `platform` | AI API platform updates (e.g. Anthropic, OpenAI, Google DeepMind) |
| `tooling` | AI developer tooling, plugins, IDE extensions, or integrations |
| `safety` | AI safety, alignment, policy, or governance announcements |

### 3.10 Smarthome Descriptors
*(use with `smarthome`)*

| Tag | Narrows to |
|---|---|
| `automation` | Home Assistant states, automation traces, scene changes |
| `sensor` | Environmental telemetry, battery low, device offline |
| `device` | Hardware status updates, firmware, connectivity |

### 3.11 Security Descriptors
*(use with `security`)*

| Tag | Narrows to |
|---|---|
| `mfa` | Multi-factor authentication codes, OTP, push notifications |
| `breach` | Data breach disclosure or credential exposure notice |
| `signin` | Unexpected or new device sign-in notification |

### 3.12 Travel Descriptors
*(use with `travel`)*

| Tag | Narrows to |
|---|---|
| `flight` | Air travel booking or boarding information |
| `hotel` | Accommodation confirmation or amendment |
| `rail` | Train or coach travel |
| `car_hire` | Vehicle rental reservation |
| `cruise` | Sea voyage booking or itinerary |
| `visa` | Entry visa application or approval |
| `insurance` | Travel insurance policy (also valid as a type tag) |

### 3.13 Entertainment Descriptors
*(use with `entertainment`)*

| Tag | Narrows to |
|---|---|
| `gaming` | Video games, console network, downloadable content |
| `streaming` | Video or audio streaming platform |
| `event` | Concert, show, festival, or live experience |
| `sport` | Sporting event attendance or sports media subscription |

### 3.14 Shopping Descriptors
*(use with `shopping`)*

| Tag | Narrows to |
|---|---|
| `grocery` | Supermarket or food retail specifically |
| `subscription` | Recurring consumer membership or subscription box |
| `offer` | Promotional voucher, discount code, or sale notification |
| `warranty` | Product warranty, guarantee, or extended cover |
| `marketplace` | Third-party marketplace seller (eBay, Vinted, Depop, etc.) |

### 3.15 Rewards Descriptors
*(use with `rewards`)*

| Tag | Narrows to |
|---|---|
| `loyalty` | Supermarket or retailer points balance and updates |
| `cashback` | Cashback platform payouts and tracking updates |

---

## 4. TYPE TAG REGISTRY

*What the email is. Applicable across any domain unless noted.*

### 4.1 Document Types

| Tag | Applies when |
|---|---|
| `invoice` | A payment is demanded or is outstanding |
| `receipt` | A payment has been confirmed and processed |
| `statement` | A periodic account, balance, or usage summary |
| `quotation` | A price estimate — not yet a binding payment demand |
| `contract` | A binding legal or commercial agreement |
| `policy` | An insurance or terms-of-service document |
| `certificate` | A legal or regulatory certification document |
| `payslip` | A salary, wage, or earnings record |
| `letter` | Formal written correspondence with no other fitting type |
| `ticket` | An entry token for an event, journey, or service |
| `report` | A summary, analysis, or progress document |
| `itinerary` | An assembled schedule of travel or event activities |

### 4.2 Transaction Types

| Tag | Applies when |
|---|---|
| `payment` | A payment has been processed, confirmed, or is due |
| `refund` | A payment reversal is in progress or has completed |
| `claim` | An insurance or warranty claim has been submitted |
| `renewal` | An expiring service, policy, or licence is being extended |
| `cancellation` | A service, subscription, or order has been terminated |
| `upgrade` | A plan, service, or account level has been improved |
| `donation` | A charitable, voluntary, or crowdfunded payment |
| `cashback` | A reward, rebate, or incentive payment is being issued |
| `fine` | A penalty charge, regulatory sanction, or fixed penalty notice |
| `chargeback` | A disputed transaction or bank reversal in progress |

### 4.3 Action & Event Types

| Tag | Applies when |
|---|---|
| `order` | A purchase or service request has been initiated |
| `delivery` | Goods or parcels are dispatched, in transit, or arriving |
| `return` | An item is being sent back to the sender or merchant |
| `booking` | A reservation or slot has been confirmed |
| `appointment` | A scheduled meeting, visit, or consultation |
| `registration` | Signing up to a service, event, or programme |
| `application` | A formal request has been submitted awaiting a decision |
| `complaint` | A dispute, grievance, or escalation has been raised |
| `reminder` | A follow-up nudge where action is required or overdue |
| `enquiry` | An outbound question or request for information has been sent |

### 4.4 Status & Alert Types

| Tag | Applies when |
|---|---|
| `alert` | A security-critical or time-sensitive urgent notification |
| `confirmation` | An action, booking, or instruction has been confirmed |
| `notification` | A general status update requiring no immediate action |
| `expiry` | Something is about to lapse, expire, or run out |
| `welcome` | A new account, service, or membership has been onboarded |
| `update` | A change to existing terms, details, pricing, or configuration |
| `newsletter` | A periodic digest, broadcast, or informational mailing |

### 4.5 Software & Release Types

| Tag | Applies when |
|---|---|
| `release` | A software version, model, or product has been publicly released |
| `changelog` | A detailed list of changes, fixes, or improvements in a new version |
| `cve` | A Common Vulnerabilities and Exposures security disclosure |
| `deprecation` | A feature, API, or service is being phased out with advance notice |
| `eol` | End of life or sunset notice — support or availability ending permanently |
| `patch` | A targeted bug fix or security patch outside a scheduled release cycle |
| `beta` | An early access, preview, or beta programme invitation or update |

### 4.6 Insurance & Protection Types
*(apply alongside a domain — the domain identifies the asset or subject being insured)*

| Tag | Applies when |
|---|---|
| `insurance` | An insurance policy document, renewal, claim, or quote |

---

## 5. LIFECYCLE ROUTING

**RULE 007 (TODO INITIALISATION)**
Any email carrying type tags `invoice`, `appointment`, `contract`, or `mot`, or descriptor tag `prescription`, must be initialised with execution state `status/todo` on ingestion.

**RULE 008 (URGENT BYPASS)**
Any email carrying type tag `alert` or `fine` must bypass routine review queues and trigger immediate notification pipelines. `security, mfa` emails are excluded from this rule as they are transient and time-limited by nature.

---

## 6. CLASSIFICATION EXAMPLES

| Email | Tags |
|---|---|
| Tradesperson quote for boiler replacement | `property, utilities, gas, quotation` |
| Car insurance renewal from Admiral | `automotive, insurance, renewal` |
| Pet insurance claim and invoice from Bought By Many | `pet, insurance, claim, invoice` |
| MOT certificate received from garage | `automotive, mot, certificate` |
| BT broadband price increase notice | `utilities, broadband, update` |
| HMRC self-assessment tax return reminder | `finance, government, tax, reminder` |
| School newsletter with term dates | `school, newsletter, attendance` |
| NHS appointment confirmation letter | `healthcare, appointment, confirmation` |
| Amazon order confirmation | `shopping, order, confirmation` |
| DPD parcel out for delivery (no purchase context) | `logistics, delivery, notification` |
| Council tax band reassessment notice | `property, government, counciltax, notification` |
| Combined home and contents insurance renewal | `property, insurance, renewal` |
| GitHub Actions pipeline failure | `engineering, pipeline, alert` |
| New sign-in from unknown device | `security, signin, alert` |
| Payslip from employer | `employment, payslip` |
| Flight booking confirmation | `travel, flight, booking, confirmation` |
| Speeding penalty charge notice | `automotive, government, fine, invoice` |
| Gym membership renewal | `fitness, subscription, renewal` |
| Charity direct debit confirmation | `charity, finance, direct_debit, confirmation` |
| Optical prescription ready for collection | `healthcare, optical, prescription, notification` |
| P60 from employer | `employment, finance, tax, certificate` |
| Vinted item sold notification | `shopping, marketplace, notification` |
| Home Assistant device offline alert | `smarthome, device, alert` |
| Local election polling card | `civic, government, notification` |
| Mortgage statement from lender | `property, finance, mortgage, statement` |
| New Claude model release announcement | `ai, llm, model, release` |
| Anthropic API breaking change notice | `ai, engineering, platform, deprecation` |
| LangChain framework update changelog | `ai, tech, agent, changelog` |
| OpenAI CVE security disclosure | `ai, security, cve, alert` |
| Kimi K2 code model release | `ai, llm, model, release` |
| GitHub Copilot new feature announcement | `ai, tech, tooling, release` |
| Ollama new version release | `ai, tech, llm, release` |
| Home Assistant beta release notes | `smarthome, tech, beta, changelog` |
| Docker critical security patch | `engineering, tech, cve, patch` |
| Node.js end of life notice | `engineering, tech, eol` |
| PHP 8.4 release announcement | `engineering, tech, release, changelog` |
| Redis CVE advisory | `engineering, security, cve, alert` |
| SaaS tool announcing feature deprecation | `tech, deprecation, notification` |
| AI safety research newsletter | `ai, safety, newsletter` |
| Weekly developer digest (e.g. TLDR, Hacker Newsletter) | `tech, newsletter` |
