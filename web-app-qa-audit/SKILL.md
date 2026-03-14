---
name: web-app-qa-audit
description: "Comprehensive QA audit for live web applications — tests every route, link, button, form, and workflow end-to-end. Use this skill when a web app is deployed and needs testing, when the user says 'audit this app', 'test the live site', 'QA this', 'what's broken', 'review this site', or 'check if everything works'. Works with any web app — not limited to property management. Requires a URL and optionally login credentials. Produces a prioritized bug report with P0/P1/P2/P3 categories."
---

# Web App QA Audit

Systematic QA audit for live web applications. This skill transforms Claude into a senior QA engineer who methodically tests every surface of a deployed app.

## When to Use
- After deploying any web app (MVP, staging, production)
- Before showing an app to a client or stakeholder
- After a batch of fixes to verify nothing regressed
- Anytime someone says "test this", "audit this", "what's broken", "review the site"

## Required Inputs
- **URL**: The live app URL
- **Credentials**: Login email/password (if auth-protected)
- **Context**: What the app does (optional but helps prioritize findings)

## Audit Process

Execute these 8 phases in order. Do NOT skip any phase.

### Phase 1: Access & Auth
- Load the URL — does it resolve? SSL valid? Redirect working?
- If login required: submit credentials, verify redirect after login
- Test: wrong password → error message shown?
- Test: can you access protected routes without login?
- Check: is there a logout button? Does it work?

### Phase 2: Navigation Inventory
Map every navigable route in the app:
- Click every item in the primary nav (sidebar, bottom nav, header)
- Click every item in secondary nav (tabs, sub-menus, "More" pages)
- Click every link in the footer
- For EACH route found:
  - Does it load (200) or 404?
  - Does it show real content or a placeholder?
  - Record the path: /dashboard, /units, /tenants, etc.

Output a route map:
```
✅ /dashboard — loads, has content
✅ /units — loads, shows unit grid
❌ /inventory — 404
⚠️ /settings — loads but empty placeholder
```

### Phase 3: Click Every Interactive Element
For each page discovered in Phase 2:

- Click every button — does it perform its action?
- Click every card/row that has hover state — does it navigate?
- Click every link-styled text — does it go somewhere?
- Open every modal/sheet/dialog — does it open and close?
- Submit every form — does it validate, submit, show feedback?
- Test every dropdown/select — does it show options?
- Test every toggle/switch — does it change state?

Record mismatches: "element looks clickable but does nothing" is a P0 bug.

### Phase 4: Core Workflow Testing
Identify the app's primary workflows and test each end-to-end:

- **CRUD cycles**: Create entity → appears in list? Edit → changes persist? Delete → removed from list?
- **Multi-step flows**: Does each step work? Can you go back? Does the final submit work?
- **Data relationships**: Creating a parent → does the child reflect it? (e.g., creating a lease → unit status changes)
- **File uploads**: Do they upload? Do they display after?
- **Exports/downloads**: Do PDFs/CSVs generate and download?

### Phase 5: Data Consistency

- Do displayed numbers match reality? (totals, counts, percentages)
- Are dates reasonable or obviously wrong? (watch for hardcoded dates, "164 days overdue" type bugs)
- Are currencies formatted correctly with proper symbols?
- Do status badges/colors match the actual state?
- Does the dashboard KPI data match what the detail pages show?

### Phase 6: Mobile Responsiveness
Resize browser to 375px width (iPhone SE) and test:

- Does the layout adapt? (no horizontal scroll)
- Is the bottom nav visible and functional?
- Are tap targets at least 48px?
- Do forms in bottom sheets scroll properly?
- Is text readable without zooming?
- Do tables transform to card lists?

### Phase 7: Missing Basics Checklist

- [ ] Page titles in browser tab (not all "Untitled" or same title)
- [ ] Loading states during navigation (skeleton, spinner, or progress)
- [ ] Empty states when no data ("No tenants yet — add one")
- [ ] Confirmation before destructive actions (delete, terminate)
- [ ] Toast/success feedback after actions (save, create, delete)
- [ ] Error messages when things fail (not silent failures)
- [ ] Logout accessible from the UI
- [ ] Favicon present
- [ ] No console errors visible in browser DevTools

### Phase 8: Performance Quick Check

- Initial page load time (should be < 3s on broadband)
- Navigation between pages (should be < 1s)
- Any obvious janky animations or layout shifts
- Images: are they optimized or massive raw uploads?

## Report Format

Structure the output as:

```markdown
# QA Audit Report: [App Name]
**URL**: [url]
**Date**: [date]
**Auditor**: Claude QA Skill

## Route Map
[list every route with ✅/❌/⚠️ status]

## Findings

### 🔴 P0 — Critical (broken, 404, missing core workflow)
[numbered list with: what you did → what you expected → what happened → URL path]

### 🟠 P1 — High (incomplete feature, misleading UX, data bugs)
[numbered list]

### 🟡 P2 — Medium (polish, consistency, missing feedback)
[numbered list]

### 🔵 P3 — Low (nice to have, minor improvements)
[numbered list]

## Priority Fix List
[ordered list of what to fix first]

## What's Working Well
[list of things that ARE working correctly — important for morale]
```

## Execution Notes

### If using Claude Code with Playwright MCP:
- Use Playwright to actually navigate and click elements
- Take screenshots of broken states
- Check browser console for errors via `page.evaluate`

### If using Claude Code with curl/fetch only:
- Fetch each route and check HTTP status codes
- Parse HTML for nav links, buttons, forms
- Flag anything that returns non-200

### If using Comet browser or similar browsing agent:
- Navigate visually through every screen
- Click everything interactively
- Resize window for mobile testing

### If used as a prompt (no browser access):
- Ask the user to navigate and report what they see
- Guide them through each phase systematically
- Compile their observations into the report format

## Tips for Better Audits
- Test with seed data AND with empty data (no records)
- Test the "second use" — create something, then create another
- Try submitting forms with empty required fields
- Try special characters in text inputs
- Try extremely long text in inputs
- Check what happens when you hit the back button mid-flow
