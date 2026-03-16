# QA Guide — The 8-Phase Comet Audit

> How to test any deployed web application with the thoroughness of a principal QA engineer at Google, Amazon, or Stripe. This is the complete process with exact prompts you can copy and paste.

---

## Quick Start — Auto-Generated Prompts

Instead of manually filling in brackets, run this in Claude Code from your project directory:

```
Use the qa-prompt-generator agent to generate my QA prompts.
```

Claude reads your CLAUDE.md, fills in the URL, modules, and credentials reference, runs a **Phase 0 static pre-check** (scans for hardcoded secrets, missing error boundaries, missing 404 page, favicon, etc.), then outputs all 8 prompts organized in 3 batches — ready to paste into Comet.

Fix any Phase 0 issues before running the Comet audit. If you prefer to fill in the prompts manually, continue reading below.

---

## What Tool Do I Use?

This guide says "Comet" throughout, but **the prompts work in any AI tool that can browse the web.** Here's how to pick:

| Tool | Best For | How to Use |
|------|----------|-----------|
| **Comet (Perplexity Pro/Max)** | Recommended. Browser agent that can log in, click around, and test live sites. | Paste each phase prompt into a separate Comet session |
| **Claude Desktop / web chat** | Good fallback. Can't browse directly, but can guide you through manual testing. | Paste the prompt, then YOU do the testing while Claude tracks results |
| **ChatGPT with browsing** | Works similarly to Comet. | Paste each phase prompt as a separate conversation |
| **Manual testing with the checklist** | If no AI tool is available. Slower but equally thorough. | Use the prompts as a checklist, test each item yourself, record results in a doc |

**The key principle is not which tool you use — it's that the tester is a different context than the builder.** If Claude Code built the app, don't use that same Claude Code session to test it. Use anything else: Comet, a fresh Claude session, ChatGPT, or your own eyeballs.

---

## Why 8 Phases in 3 Batches, Not 1 Giant Prompt

We learned this the hard way during the Arman Apartments build. When you give a browser agent (Comet) one massive prompt covering all 8 testing phases, it does one of two things:

1. **Skims.** It marks phases as "tested" but only spent 10 seconds on each. The output looks thorough but isn't.
2. **Drops phases.** It tests auth and CRUD thoroughly, then runs out of context and skips security, accessibility, and performance entirely.

The fix: **run 8 phases across 3 batches of 2-3 parallel Comet tabs.** Each tab handles one phase, and tabs within a batch run simultaneously. You paste each batch's results into a Claude accumulator session.

| Batch | Phases | Tabs | Why together |
|-------|--------|------|-------------|
| **Batch 1** | 1 (Auth), 2 (CRUD), 3 (Edge Cases) | 3 tabs | Core functionality — must pass before anything else matters |
| **Batch 2** | 4 (Security), 5 (Mobile), 6 (Performance) | 3 tabs | Infrastructure quality — independent of each other |
| **Batch 3** | 7 (Accessibility), 8 (Cross-Browser) | 2 tabs | Polish — can run last since they rarely produce P0s |

This mirrors how QA works at real companies. Nobody runs one test suite that covers everything. They have separate test plans for functional testing, security testing, performance testing, and accessibility testing — each with its own methodology and specialists.

### Time Comparison

| Strategy | Time | Risk |
|----------|------|------|
| Sequential (1 tab at a time) | ~90 min | Thorough but slow |
| **Batched parallel (3 batches)** | **30-40 min** | **Best balance — thorough and fast** |
| All 8 tabs at once | ~20 min | Chaotic — results pile up faster than you can relay them, easy to lose track |

---

## The Batched Handoff Flow

Here's how the three tools work together across 3 batches:

```
BATCH 1 — Core Functionality
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Tab 1: Auth  │ │ Tab 2: CRUD  │ │ Tab 3: Edge  │    ← 3 Comet tabs in parallel
│ (Phase 1)    │ │ (Phase 2)    │ │ (Phase 3)    │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        ▼
              Paste all 3 results into Claude accumulator
              "Here's Batch 1 — Phases 1, 2, 3: [paste]"

BATCH 2 — Infrastructure Quality
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Tab 4: Sec   │ │ Tab 5: Mobile│ │ Tab 6: Perf  │    ← 3 more tabs
│ (Phase 4)    │ │ (Phase 5)    │ │ (Phase 6)    │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        ▼
              Paste all 3 results into Claude accumulator
              "Here's Batch 2 — Phases 4, 5, 6: [paste]"

BATCH 3 — Polish
┌──────────────┐ ┌──────────────┐
│ Tab 7: A11y  │ │ Tab 8: X-Brw │                     ← 2 tabs
│ (Phase 7)    │ │ (Phase 8)    │
└──────┬───────┘ └──────┬───────┘
       │                │
       └────────┬───────┘
                ▼
              Paste both results into Claude accumulator
              "Here's Batch 3 — Phases 7, 8: [paste]"
              "Build the consolidated report."

                        ▼
              Claude generates fix prompt → paste into Claude Code → push
```

**You** are the bridge between Comet (tester) and Claude (fixer). This is intentional — no single AI should both build and test the same code.

---

## AionUI Setup During QA

If you're using AionUI, set up 3 sessions for the QA phase:

| Session | Role | What it does |
|---------|------|-------------|
| Session 1 | **Fixer** (Claude Code) | Receives the consolidated fix prompt after each round. Reads CLAUDE.md + KNOWLEDGE.md. Fixes P0s and P1s. |
| Session 2 | **Accumulator** (Claude Desktop/Web) | Collects Comet results batch by batch. Builds the consolidated report. Generates the fix prompt. |
| Session 3 | **Builder** (Claude Code) | Continues next-wave implementation while QA runs on the current wave. Don't let QA block building. |

Session 3 is the key insight: **QA and building run in parallel.** While Comet audits Wave 2, Session 3 builds Wave 3. When the fix prompt comes back, Session 1 applies it without interrupting the builder.

---

## Before You Start: Set Up the Claude Accumulator

Open a Claude session (Desktop, web, or Code) and paste this once at the beginning:

```
I'm running a Level 5 QA audit on a deployed web application.
I'll paste results from Comet phase by phase (8 phases total).
Track every issue and build me the consolidated report after all 8 phases.

Application: [BRIEF DESCRIPTION — e.g., "property management portal for apartment buildings"]
URL: https://[YOUR-URL]
Modules: [LIST — e.g., Dashboard, Units, Tenants, Leases, Payments, Inventory, Notifications, Settings]
Login: [EMAIL] / [PASSWORD]
Tech stack: [e.g., Next.js 15, Supabase, Tailwind]
```

This gives Claude the context it needs. Now start pasting Comet prompts one at a time.

---

## The 8 Phases

### Phase 1: Authentication & Session Management — Batch 1 of 3
**Time:** 5-10 minutes
**What it tests:** Login, logout, session persistence, protection of routes

**Comet prompt:**
```
You are a senior QA engineer. Test ONLY authentication and session management on https://[URL].

Login credentials: [EMAIL] / [PASSWORD]

Test each of these and report what happens:
1. Login with valid credentials — does the dashboard load?
2. Login with wrong password — is there a clear error message (not a stack trace or blank page)?
3. Sign out — does it redirect to the login page?
4. Sign back in immediately after signing out — does the session work properly?
5. While logged out, navigate directly to a protected URL like /dashboard — does it redirect to login?
6. After logging in, go back to /login — does it redirect to dashboard (not show login again)?
7. Open the app in two browser tabs. Sign out in one tab. What happens in the other tab?
8. Check the browser cookies — is the session cookie httpOnly and Secure?

For each issue found: describe what happened, what should have happened, and rate as P0/P1/P2/P3.
```

**What good output looks like:** Each test explicitly listed with PASS or FAIL, specific details on failures, no vague "everything looked fine."

**Paste result into Claude:** "Here's Phase 1 — Auth & Sessions: [paste]"

---

### Phase 2: Functional Testing (CRUD Per Module) — Batch 1 of 3
**Time:** 15-20 minutes (the longest phase)
**What it tests:** Create, read, update, delete on every entity; form validation

**Comet prompt:**
```
You are a senior QA engineer. Test ONLY CRUD operations on https://[URL].
Login: [EMAIL] / [PASSWORD]

For EACH of these modules — [LIST YOUR MODULES, e.g., Units, Tenants, Leases, Payments, Inventory, Notifications, Settings]:

CREATE:
- Fill out the creation form with valid data — does the entity appear in the list?
- Submit with empty required fields — does it show validation errors?
- Submit with invalid data (wrong email format, negative numbers, text in number fields) — is it rejected?

READ:
- Open the entity detail/edit page — do all fields display correctly?
- Check that related entities are linked (e.g., tenant shows their unit, lease shows tenant name)

UPDATE:
- Edit a field and save — does the change persist after page refresh?
- Do you see a success confirmation (toast/message) after saving?

DELETE (if supported):
- Delete an entity — is it removed from the list?
- Is there a confirmation dialog before deletion?

Test each module separately. For each issue: module name, action (create/read/update/delete), what happened, what should have happened, severity (P0/P1/P2/P3).
```

**Paste result into Claude:** "Phase 2 — CRUD testing: [paste]"

---

### Phase 3: Data Integrity & Edge Cases — Batch 1 of 3
**Time:** 10-15 minutes
**What it tests:** Data persistence, special characters, empty states, boundary conditions

**Comet prompt:**
```
You are a senior QA engineer. Test ONLY data integrity and edge cases on https://[URL].
Login: [EMAIL] / [PASSWORD]

Test these specific scenarios:
1. Create an entity, then hard refresh the page (Ctrl+R) — does the data persist or was it only in local state?
2. Visit every page/section with ZERO data (no entries) — does each show a helpful empty state message, or does it crash/show blank?
3. Enter special characters in text fields: quotes ("test"), ampersands (AT&T), angle brackets (<script>), emoji (🏠), and any local language characters if applicable — do they save and display correctly without breaking the page?
4. Enter maximum length text in a name/description field (200+ characters) — does it save? Does the UI truncate gracefully or overflow?
5. Enter negative numbers where positive is expected (e.g., -500 for a payment amount) — is it rejected?
6. Try dates at boundaries: today, yesterday, a date far in the past (1900-01-01), a date far in the future (2099-12-31) — do they work or cause errors?
7. Create 15+ items in any list — does the page handle many items properly (scrolling, pagination, or at least not crashing)?
8. Open two browser tabs on the same entity edit page, make different edits in each, save both — what happens?

For each issue: scenario number, what happened, severity.
```

**Paste result into Claude:** "Phase 3 — Edge cases: [paste]"

---

### Phase 4: Security (OWASP Top 10 Essentials) — Batch 2 of 3
**Time:** 10-15 minutes
**What it tests:** Access control, injection, secrets exposure, headers

**Comet prompt:**
```
You are a senior security engineer. Test ONLY security on https://[URL].
Login: [EMAIL] / [PASSWORD]

Test these specific things:

ACCESS CONTROL:
1. Change an entity ID in the URL to a random UUID (e.g., /tenants/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee) — do you get a 404/access denied, or do you see someone else's data?
2. Try accessing admin routes or API endpoints you shouldn't have access to

INJECTION:
3. Enter this in a text field and save: ' OR 1=1; DROP TABLE --
   Does it save safely or cause a database error?
4. Enter this in a text field: <script>alert('xss')</script>
   Does the page execute the script or display it as text?

SECRETS EXPOSURE:
5. Open browser DevTools → Network tab. Browse through the app. Are any API keys, tokens, or secrets visible in request/response headers or bodies?
6. View the page source (Ctrl+U). Search for "key", "secret", "token", "password" — is anything hardcoded?

HTTP HEADERS:
7. In DevTools Network tab, click on any page request. Check response headers:
   - Content-Security-Policy: present?
   - X-Frame-Options: present?
   - X-Content-Type-Options: present?
   - Strict-Transport-Security: present?

COOKIES:
8. In DevTools → Application → Cookies. Check the session cookie:
   - Is it marked HttpOnly? (prevents JavaScript access)
   - Is it marked Secure? (HTTPS only)

For each finding: what you tested, what you found, severity (P0 for actual vulnerabilities, P1 for missing headers, P2 for best-practice gaps).
```

**Paste result into Claude:** "Phase 4 — Security: [paste]"

---

### Phase 5: Mobile Responsiveness — Batch 2 of 3
**Time:** 10-15 minutes
**What it tests:** Layout, navigation, touch targets, overflow at phone and tablet sizes

**Comet prompt:**
```
You are a senior frontend engineer. Test ONLY mobile responsiveness on https://[URL].
Login: [EMAIL] / [PASSWORD]

Test at these 4 viewport widths using browser DevTools device emulation:

PHONE — iPhone 14 Pro (393px wide):
1. Can you see and use the navigation? Is there a bottom nav, hamburger menu, or sidebar that works at this width?
2. Does any content overflow horizontally? Scroll right on every page to check.
3. Can you tap every button without accidentally hitting adjacent elements? Are buttons at least 48px tall?
4. Do all forms work? Can you fill them out, select dropdowns, pick dates, and submit?
5. Do modals/dialogs/sheets display correctly? Can you scroll within them?
6. Is all text readable without zooming?

PHONE — Samsung Galaxy S24 (360px wide):
7. Same checks as above, but at the tighter 360px width. Does anything break that worked at 393px?

TABLET — iPad Air (820px):
8. Does the layout adapt to the extra space? Or is it just a stretched phone layout?
9. Does the sidebar show at this width or is it still collapsed?

DESKTOP — 1440px:
10. Does the full layout render correctly? Sidebar visible? Content well-spaced?

For each issue: device/width, page, what's broken, screenshot description if possible, severity.
```

**Paste result into Claude:** "Phase 5 — Mobile: [paste]"

---

### Phase 6: Performance & UX Polish — Batch 2 of 3
**Time:** 5-10 minutes
**What it tests:** Load times, bundle size, loading states, feedback, error handling

**Comet prompt:**
```
You are a senior performance engineer. Test ONLY performance and UX polish on https://[URL].
Login: [EMAIL] / [PASSWORD]

PERFORMANCE:
1. Measure time from entering the URL to seeing an interactive dashboard. Target: under 3 seconds.
2. Navigate between 3-4 pages — measure transition time. Target: under 1 second per navigation.
3. Open DevTools → Network tab. Check the JavaScript bundle sizes. Is any single route's First Load JS over 200KB?
4. Check images in the Network tab. Are any images over 500KB? Are they WebP or unoptimized JPEG/PNG?

UX POLISH:
5. Create, update, or delete something — do you see a success toast/confirmation message?
6. Trigger an error (submit invalid data) — do you see a clear error message?
7. Go to a URL that doesn't exist (e.g., /this-page-does-not-exist) — is there a branded 404 page?
8. Check the browser tab — does it show the correct favicon and page title?
9. Open DevTools Console — are there any JavaScript errors or warnings?
10. Trigger a slow operation (if possible) — do you see a loading spinner or skeleton?

For each issue: what you tested, the measurement or finding, severity.
```

**Paste result into Claude:** "Phase 6 — Performance: [paste]"

---

### Phase 7: Accessibility (WCAG 2.1 AA Essentials) — Batch 3 of 3
**Time:** 5-10 minutes
**What it tests:** Keyboard navigation, contrast, labels, focus indicators

**Comet prompt:**
```
You are an accessibility specialist. Test ONLY WCAG 2.1 AA compliance on https://[URL].
Login: [EMAIL] / [PASSWORD]

KEYBOARD NAVIGATION:
1. Starting from the login page, can you tab through every interactive element? Try logging in using only the keyboard (Tab to fields, Enter to submit).
2. After login, can you navigate the entire app using only Tab, Shift+Tab, Enter, and Escape? Can you reach every menu item, button, and form field?
3. When tabbing, can you visually see which element is focused? Is there a clear focus ring/outline?

FORMS:
4. Are all form inputs associated with visible labels? Or do they only have placeholder text that disappears when you type?
5. When a form validation error appears, is the error message near the field and clearly associated with it?

COLOR & CONTRAST:
6. Is all text readable against its background? Check particularly: light gray text on white, colored text on colored backgrounds. Minimum contrast ratio: 4.5:1 for normal text, 3:1 for large text.
7. Is any information conveyed only through color? (e.g., status indicated only by red/green with no text label)

STRUCTURE:
8. Does the page have proper heading hierarchy (h1 → h2 → h3, no skipped levels)?
9. Do images have descriptive alt text?

For each issue: what you tested, what you found, WCAG criterion if known, severity.
```

**Paste result into Claude:** "Phase 7 — Accessibility: [paste]"

---

### Phase 8: Cross-Browser — Batch 3 of 3
**Time:** 5 minutes
**What it tests:** Rendering consistency between Chrome and Safari (or Firefox)

**Comet prompt:**
```
You are a frontend engineer. Test ONLY cross-browser compatibility on https://[URL].
Login: [EMAIL] / [PASSWORD]

Open the app in Safari (or Firefox if Safari isn't available) and compare against Chrome:

1. Does the login page render identically?
2. Does the dashboard layout match? Any shifted elements, missing backgrounds, or broken grid?
3. Do backdrop-filter effects (blur, frosted glass) work in both browsers?
4. Do CSS grid and flexbox gap properties render consistently?
5. Do custom fonts load properly in both browsers?
6. Do form inputs (dropdowns, date pickers) work in both browsers?
7. Do any animations or transitions behave differently?

Only report DIFFERENCES between browsers. If everything matches, say "No cross-browser issues found."

For each difference: page, what's different, which browser is correct, severity.
```

**Paste result into Claude:** "Phase 8 — Cross-browser: [paste]"

---

## After All 3 Batches: Get the Consolidated Report

Once you've pasted all 3 batches (8 phases) into Claude, say:

```
You now have all 3 batches (8 QA phases). Build me:

1. A consolidated issue table:
   | # | Phase | Page | Issue | Device | Severity |
   
2. Summary counts: P0: [n] | P1: [n] | P2: [n] | P3: [n]

3. Overall verdict: READY FOR DELIVERY / NEEDS P0 FIXES / NEEDS SIGNIFICANT WORK

4. A single Claude Code prompt that fixes ALL P0 and P1 issues.
   Reference specific files and include exact changes needed.
   Start the prompt with: Read CLAUDE.md and KNOWLEDGE.md first.
```

---

## The Fix Cycle

```
Round 1: 3 batches (8 phases) → Claude report → fix P0s in Session 1 → push
Round 2: Re-run ONLY the batches that had P0s → fix remaining → push
Round 3: Quick smoke test (1 tab per batch) → confirm zero P0s
```

You don't re-run all 3 batches every round. After Round 1, you only re-test the batches where issues were found. If P0s were only in Batch 1 (auth/CRUD/edge cases), skip Batches 2 and 3 in Round 2.

*From the Arman build: Round 1 found P0s in auth and mobile (Batches 1+2). Round 2 found P1s in responsive breakpoints (Batch 2 only). Round 3: P2s only. Round 4: zero P0s, zero P1s. Ready for delivery.*

---

## Severity Guide

| Severity | Meaning | Action | Examples |
|----------|---------|--------|----------|
| **P0** | Blocker | Fix immediately. Do not deliver. | Login broken, XSS vulnerability, data not saving, app crashes on mobile |
| **P1** | Critical | Fix before delivery. | Wrong calculation, missing validation, broken nav on one device |
| **P2** | Major | Fix if time allows. | Misaligned button, inconsistent spacing, missing loading state |
| **P3** | Minor | Track for later. | Better animation, tooltip clarity, border-radius inconsistency |

**Rule: Zero P0s before delivery. Zero P1s before delivery if time allows. P2s and P3s can ship.**

---

## Tips for Better Comet Results

1. **Be specific.** "Test the payment form" gets skimmed. "Submit with amount -500, then 0, then blank, then valid" gets tested.
2. **One phase per session.** Don't combine. Short prompts produce thorough results.
3. **Ask for evidence.** Add "describe exactly what you see on screen" to force Comet to actually look, not guess.
4. **If Comet says "everything looks fine" with no details, re-run.** Good QA output is specific. Vague output means it didn't test.
5. **The accumulator Claude session catches gaps.** It compares expected coverage against actual results across all 8 phases.

---

*Previous: [How It All Works](./HOW-IT-WORKS.md)*
*Next: [Examples](./EXAMPLES.md) — real walkthrough from the Arman Apartments build*
