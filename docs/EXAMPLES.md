# Examples — Real Project Walkthroughs

> These are real examples from actual projects built using the Stringz Workflow. Every decision, bug, and outcome described here actually happened.

---

## Example 1: Arman Apartments — From Zero to Client Demo in One Day

**Client:** Arman Apartments, a luxury building in Bole, Addis Ababa, Ethiopia
**Problem:** Building manager uses paper ledgers and WhatsApp to track tenants, rent, and inventory
**Result:** Full property management portal, branded to match their marketing site, deployed live
**Live URL:** arman.stringztechnologies.com
**Time:** One focused day (approximately 10 hours)

---

### Phase 1: Specify (30 minutes)

**Starting input:**
> "Property management web app for apartment complexes in Addis Ababa. First client runs a high-rise in Bole. Everyone uses paper and WhatsApp."

Claude interviewed and uncovered details the initial description didn't include:

- Tenants are a **mix of Ethiopian and international** residents — phone input needs country codes, payments happen in **multiple currencies** (ETB, USD, EUR, GBP)
- The "rent pager" concept (client's term) isn't a monthly ledger — it's an **active collection workflow** where tenants pay in partial installments and need multiple reminders
- **Inventory management** is the killer feature, not rent collection — furnished apartment disputes at checkout cost the building real money. Timestamped photos with condition tracking solves this.
- The **Ethiopian calendar** (Ge'ez) is 7-8 years behind Gregorian — leases are written in Ethiopian dates
- **Chapa** (Ethiopian payment gateway) integration deferred to Phase 2 — manual payment logging first

**SPEC.md output:** 6 core modules (Units, Tenants, Leases, Payments, Inventory, Notifications), admin-only MVP, mobile-first design, English UI with Amharic localization later.

**Lesson learned:** The interview uncovered that inventory with photo evidence was the real pain point, not rent tracking. If we'd built based on the initial description alone, we would have prioritized the wrong feature.

---

### Phase 2: Architect (45 minutes)

**Database schema:** 13 tables designed upfront before writing any code:
- `buildings`, `units`, `tenants`, `leases` (core entities)
- `billing_periods`, `payments` (rent ledger — split design for partial payments)
- `inventory_items`, `inventory_checks`, `inventory_check_items` (photo-based checklist)
- `receiving_accounts` (where rent goes — CBE, Zelle, Wise)
- `notification_templates`, `notification_schedules`, `notification_log` (reminder system)

**Key architectural decisions recorded in KNOWLEDGE.md:**
- Payments table is **immutable** — INSERT only, no UPDATE/DELETE
- `billing_periods` uses `lease_id` FK, not a generic `source_id`
- `buildings` table included even for single-building MVP — costs nothing now, saves migration later
- RLS policies on every table from day one

---

### Phase 3: Implement (6 hours, 10 waves)

**Wave 1:** Foundation — scaffold, schema migration, auth, dashboard shell
**Wave 2:** Units — floor grid with color-coded status
**Waves 3-4:** Tenants + Leases with multi-step creation
**Waves 5-7:** Payments (multi-currency), Inventory (camera + photos), Notifications
**Waves 8-10:** Receipts, CSV export, seed data, Dockerfile

**Key bugs caught and recorded in KNOWLEDGE.md:**
1. **signOut breaking re-login** — default Supabase `signOut()` uses global scope. Fix: `{ scope: 'local' }`. Recorded once, never repeated.
2. **CHECK constraints vs freetext UI** — database constraints conflicted with flexible form inputs. Dropped constraints, let Zod handle validation.
3. **Phone input format** — used `react-phone-number-input` with default country ET for international tenants.

**8 skills created during this phase** — each extracted as a reusable pattern, not hardcoded to Arman.

---

### Phase 4: Deploy + QA (2 hours)

**4 QA rounds with Comet:**
- Round 1: P0s — signOut scope issue, missing mobile navigation
- Round 2: P1s — auth breakpoint mismatch (lg: vs md:), notification link overflow
- Round 3: P2s only — minor spacing
- Round 4: Zero P0s, zero P1s. Ready.

**Critical lesson:** Claude Code had "fixed" signOut during implementation but the fix was incomplete — right code in one file, wrong code in the shared utility. Comet caught it because it tested the deployed app, not the source code. **Builder ≠ tester.**

---

### Phase 5: Brand Alignment (1 hour)

**Problem:** Portal was emerald green. Client's site is warm gold.

**Comet found 10 inconsistencies.** The biggest: accent color `#10B981` (emerald) should be `#C9A84C` (gold).

**Logo extraction:** Downloaded favicon.ico (524x524). Recolored from peach to gold using Python + Pillow. Created light gold variant for dark sidebar.

**One commit** replaced every `emerald-*` class with `arman-gold`, swapped the logo, warmed surfaces, restyled buttons.

**Lesson:** The Cloudflare crawler returned green from CSS but the site *looks* gold due to photography and overlays. CSS extraction alone doesn't capture visual brand identity. Added a "Visual Brand Verification" step to the skill.

---

### Phase 6: Deliver (30 minutes)

**WhatsApp:** Two screenshots + URL. No credentials.
**Client response:** "Quick! Looks neat... I'll definitely call you when I'm free."
**Pricing:** $7,000 setup + $250/month (walkthrough pending).

---

### Timeline

| Time | Phase | What Happened |
|------|-------|---------------|
| 10:30 AM | Specify | Spec interview, SPEC.md generated |
| 11:15 AM | Architect | Schema, CLAUDE.md, KNOWLEDGE.md, TASKS.md |
| 11:30 AM | Implement | Wave 1: foundation |
| 12:00 PM | Implement | Waves 2-4: units, tenants, leases |
| 1:00 PM | Implement | Waves 5-7: payments, inventory, notifications |
| 2:30 PM | Implement | Waves 8-10: receipts, export, seed data, Docker |
| 3:00 PM | Deploy + QA | Deployed, QA round 1 |
| 3:30 PM | QA | P0 fixes, QA round 2 |
| 4:00 PM | QA | P1 fixes, QA round 3-4 |
| 4:30 PM | Brand | Two-site comparison, gold accent swap |
| 5:30 PM | Deliver | Screenshots + WhatsApp to client |
| 5:35 PM | | Client responds ✅ |

---

### What Made It Fast

1. **Spec interview** prevented building the wrong thing
2. **Schema-first** meant no database refactoring mid-build
3. **KNOWLEDGE.md** prevented re-discovering the same bugs
4. **Brand as a separate phase** — no time wasted on colors during implementation
5. **Comet as independent tester** caught what the builder couldn't see

---

### Tools Used vs Alternatives

This build happened before AionUI was added to the workflow:

| What We Used | Alternative |
|---|---|
| Claude Code in terminal tabs | AionUI for visual parallel sessions |
| Comet (Perplexity Pro) for QA | Any browser agent, fresh Claude session, or manual testing with QA-GUIDE prompts |
| Coolify for deployment | Vercel, Railway, Fly.io, or any Docker host |
| SuperClaude for orchestration | Native Claude Code subagents |
| Supabase (Frankfurt) | Neon, PlanetScale, self-hosted Postgres |

**The methodology is tool-agnostic.** The prompts, wave-checkpoint rhythm, and builder/tester separation work regardless of which specific tools you use.

---

*Previous: [QA Guide](./QA-GUIDE.md)*
*Next: [Glossary](./GLOSSARY.md) — definitions of every framework term*
