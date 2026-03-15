---
name: web-app-qa-audit
description: "Level 5 QA audit for live web applications — 8 phases covering auth, CRUD, data integrity, OWASP security, 4-viewport mobile, performance targets, WCAG 2.1 AA accessibility, and cross-browser. Use when a web app is deployed and needs testing: 'audit this app', 'test the live site', 'QA this', 'what's broken', 'check if everything works'. Project-agnostic. Produces a prioritized bug table (P0-P3) with a copy-paste Claude Code fix prompt."
---

# Web App QA Audit — Level 5

Systematic QA audit for any live web application. Transforms Claude into a senior QA engineer who methodically tests every surface of a deployed app across 8 phases.

## When to Use
- After deploying any web app (MVP, staging, production)
- Before showing an app to a client or stakeholder
- After a batch of fixes to verify nothing regressed
- Anytime someone says "test this", "audit this", "what's broken", "review the site"

## Required Inputs
- **URL**: `[APP_URL]`
- **Credentials**: `[EMAIL]` / `[PASSWORD]` (if auth-protected)
- **Modules**: `[MODULE_LIST]` — the app's core modules (e.g., tenants, units, payments)
- **Tech Stack**: `[TECH_STACK]` — framework + database (e.g., Next.js + Supabase)

## The Audit Prompt

Paste the following into a **different AI tool** than the one that built the app (Comet, fresh Claude session, or any browser agent):

```
You are a senior QA engineer. Perform a comprehensive 8-phase audit of [APP_URL].

Login: [EMAIL] / [PASSWORD]
Modules: [MODULE_LIST]
Tech stack: [TECH_STACK]

Execute ALL 8 phases. Do NOT skip any phase. Test systematically — do not explore randomly.

---

## Phase 1: Authentication & Session Management

1. Load [APP_URL] — does it resolve? SSL valid? Correct redirect?
2. Submit login with valid credentials → verify redirect to dashboard
3. Submit login with wrong password → error message shown? (not blank fail)
4. Submit login with empty fields → validation prevents submission?
5. After login, open a new tab → session persists?
6. Click logout → session cleared? Redirected to login?
7. After logout, hit browser back → cannot access protected routes?
8. Try accessing [APP_URL]/dashboard directly without login → redirected?

---

## Phase 2: Functional Testing (CRUD per Module)

For EACH module in [MODULE_LIST], test the complete CRUD cycle:

**Create:**
- Open the create form/modal
- Submit with valid data → entity appears in list?
- Submit with empty required fields → validation fires?
- Submit with special characters (quotes, ampersands, unicode) → handles gracefully?
- Submit with extremely long text (500+ chars) → truncated or handled?

**Read:**
- List view loads with data → correct count?
- Detail view shows all fields correctly?
- Pagination works (if applicable)?
- Search/filter returns correct results?
- Sort changes order correctly?

**Update:**
- Edit an existing entity → changes persist after save?
- Cancel edit → original data preserved?
- Edit with invalid data → validation catches it?

**Delete:**
- Delete prompts for confirmation?
- After delete → entity removed from list?
- Related data handled correctly? (cascade or orphan warning)

---

## Phase 3: Data Integrity & Edge Cases

1. Dashboard KPIs match detail page totals (count entities, sum amounts)
2. Dates display correctly (no "Invalid Date", no obviously wrong years)
3. Currency amounts formatted with correct symbol and decimals
4. Status badges match actual data state (active/inactive, paid/unpaid)
5. Empty states: remove all data for one module → shows helpful empty state (not blank page or error)
6. Boundary test: create entity with minimum required fields only
7. Boundary test: create entity with ALL optional fields filled
8. Relationship integrity: create parent → child reflects it; delete parent → child handles gracefully
9. Concurrent state: open same record in two tabs, edit in both → no silent data loss
10. Back button behavior: mid-form back → no data corruption

---

## Phase 4: Security (OWASP Top 10 Essentials)

1. **Broken Access Control:** Can you access other users' data by changing IDs in the URL?
   - Try: [APP_URL]/api/[entity]/[other-user-id]
   - Try: modify request payloads to reference other users' records
2. **Injection:** Do text inputs accept and safely render HTML tags? (`<script>alert(1)</script>`)
3. **XSS:** Does user-generated content render safely? Check names, descriptions, comments.
4. **Sensitive Data Exposure:** Are API keys, tokens, or passwords visible in:
   - Browser DevTools → Network tab (response bodies)
   - Page source (View Source)
   - Console output
5. **Security Misconfiguration:** Check response headers:
   - X-Content-Type-Options: nosniff
   - X-Frame-Options or CSP frame-ancestors
   - Strict-Transport-Security present
6. **CSRF:** Do mutation requests use POST/PUT/DELETE (not GET)?
7. **Authentication:** Are session tokens HttpOnly? Secure flag set?

---

## Phase 5: Mobile Responsiveness (4 Viewports)

Test at EACH of these widths:

| Viewport | Device | Width |
|----------|--------|-------|
| Small phone | iPhone SE / Galaxy S8 | 360px |
| Standard phone | iPhone 15 / Pixel 8 | 393px |
| Tablet | iPad Mini | 820px |
| Desktop | Standard monitor | 1440px |

For each viewport, check:
1. No horizontal scroll (nothing overflows the viewport)
2. Navigation adapts (sidebar collapses, bottom nav appears on mobile)
3. Touch targets ≥ 48px on all interactive elements
4. Forms are usable (inputs not cut off, keyboards don't obscure fields)
5. Tables transform to cards or scroll horizontally with indication
6. Modals/sheets fit the viewport (not clipped or overflowing)
7. Text readable without zooming (minimum 14px body text)
8. Images scale correctly (no pixelation, no overflow)

---

## Phase 6: Performance & UX Polish

**Performance Targets:**
- Initial page load: < 3 seconds
- Navigation between pages: < 1 second
- JavaScript bundle: < 200KB (gzipped)
- Largest Contentful Paint (LCP): < 2.5 seconds
- No layout shifts during load (CLS < 0.1)

**UX Polish Checklist:**
- [ ] Page titles update per route (not all "Untitled" or same title)
- [ ] Loading states during data fetch (skeleton, spinner, or shimmer)
- [ ] Empty states when no data ("No [entities] yet — create one")
- [ ] Confirmation before destructive actions (delete, terminate)
- [ ] Toast/success feedback after mutations (save, create, delete)
- [ ] Error messages when operations fail (not silent failures)
- [ ] Favicon present and correct
- [ ] No console errors in browser DevTools (filter: errors only)
- [ ] No console.log debug output in production
- [ ] Images optimized (WebP, lazy loaded, appropriate dimensions)

---

## Phase 7: Accessibility (WCAG 2.1 AA Essentials)

1. **Keyboard Navigation:** Can you tab through all interactive elements in logical order?
2. **Focus Indicators:** Is the currently focused element visually obvious?
3. **Skip Link:** Is there a "Skip to content" link for keyboard users?
4. **Form Labels:** Every input has an associated label (not just placeholder text)?
5. **Color Contrast:** Text meets 4.5:1 ratio against background (check: dark text on light, light text on dark, text on colored backgrounds)
6. **Alt Text:** All meaningful images have descriptive alt text?
7. **ARIA:** Modals trap focus? Dynamic content announced? Buttons have accessible names?
8. **Error Identification:** Form errors identify the specific field and describe the error?
9. **Zoom:** Content usable at 200% browser zoom without horizontal scroll?

---

## Phase 8: Cross-Browser

If possible, verify in:
- Chrome (primary)
- Safari (especially for iOS rendering)
- Firefox (layout differences)

Check for: layout breaks, font rendering differences, form input styling, date picker behavior.

---

## Output Format

Structure ALL findings in this table format:

| # | Severity | Phase | Page/Route | Device | Issue | Expected | Actual | Suggested Fix |
|---|----------|-------|------------|--------|-------|----------|--------|---------------|
| 1 | P0 | Auth | /login | All | Wrong password shows no error | Error message | Blank page | Add error toast on auth failure |
| 2 | P1 | CRUD | /tenants | Desktop | Delete has no confirmation | Confirm dialog | Instant delete | Add confirmation modal |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |

### Severity Definitions:
- **P0 — Critical:** Broken functionality, data loss, security vulnerability, 404 on core route. Blocks usage.
- **P1 — High:** Wrong behavior, misleading UX, missing validation, accessibility failure. Usable but incorrect.
- **P2 — Medium:** Polish issues, missing feedback, inconsistent spacing, minor responsive issues. Works but rough.
- **P3 — Low:** Nice-to-have improvements, micro-interactions, animation polish. Works fine as-is.

### Summary:
```
P0: X issues (must fix before delivery)
P1: X issues (fix before client demo)
P2: X issues (fix in polish pass)
P3: X issues (backlog)
```

### What's Working Well:
[List 3-5 things that ARE working correctly — important for morale and context]

---

## Claude Code Fix Prompt

End your report with a copy-paste prompt that fixes all P0s and P1s:

```
Fix the following P0 and P1 issues found in the QA audit.

Read CLAUDE.md and KNOWLEDGE.md first.

## P0 Fixes (Critical)
1. [file:component] — [exact issue] → [exact fix]
2. ...

## P1 Fixes (High)
1. [file:component] — [exact issue] → [exact fix]
2. ...

After all fixes:
1. npm run lint && npm run build
2. Use architecture-enforcer to verify no new violations
3. Update KNOWLEDGE.md with bugs fixed
4. git add -A && git commit -m "fix: resolve P0/P1 issues from QA audit" && git push
```
```

## Execution Notes

### Using Comet browser or AionUI browser agent (recommended):
- Navigate visually through every screen
- Click everything interactively
- Resize window for each viewport width
- Check DevTools console and network tabs

### Using Claude Code with Playwright MCP:
- Use Playwright to navigate and click elements
- Take screenshots of broken states
- Check browser console via `page.evaluate`
- Test at each viewport with `page.setViewportSize()`

### Using Claude Code with fetch only:
- Fetch each route and check HTTP status codes
- Parse HTML for nav links, buttons, forms
- Flag non-200 responses and missing elements

### If no browser access:
- Guide the user through each phase systematically
- Ask them to navigate and report what they see
- Compile observations into the report format

## Tips for Better Audits
- Always use a **different AI** than the one that built the app
- Test with seed data AND with empty data (zero records)
- Test the "second use" — create one entity, then create another
- Test the "edit immediately after create" flow
- Try rapid-fire actions (submit form twice quickly)
- Check what the app looks like on first login (onboarding state)
