# How It All Works

> This guide explains how every piece of the Stringz Workflow connects — from first install to client delivery. Read this once and you'll understand the entire system.

---

## The Big Picture

The Stringz Workflow is an **agent-first engineering system**. Instead of writing code yourself, you design the environment — the constraints, context, and feedback loops — that lets AI agents write correct, production-grade code.

The system has three layers:

```
┌─────────────────────────────────────────────────────┐
│                    YOU (Human)                       │
│    Specify intent. Review output. Make decisions.    │
├─────────────────────────────────────────────────────┤
│                 THE FRAMEWORK                        │
│   STRINGZ.md → CLAUDE.md → KNOWLEDGE.md → REVIEW.md │
│   Templates → Skills → Agents → PREFLIGHT            │
├─────────────────────────────────────────────────────┤
│                  THE TOOLS                           │
│   Claude Code → AionUI → Comet → Coolify → Git      │
└─────────────────────────────────────────────────────┘
```

**You** never write code. You specify what to build, review what agents produce, and make business decisions. The **framework** gives agents persistent memory, architectural rules, and domain knowledge. The **tools** execute the work.

---

## Step 1: Install (One Time Per Machine)

```bash
git clone https://github.com/stringztechnologies/claude-skills.git
cd claude-skills
./setup.sh
```

This does three things:

1. **Copies `STRINGZ.md.template` to `~/.claude/STRINGZ.md`** — This is your personal identity file. Claude Code reads it automatically on every session, on every project, on your machine. It tells Claude who you are, what your workflow is, what tools you use, and how to behave when it encounters a new project. Edit it with your name, company, and infrastructure details.

2. **Symlinks all skills to `~/.claude/skills/`** — Skills are reusable domain knowledge. When Claude Code works on a Supabase + Next.js project, it can read the `supabase-nextjs-fullstack` skill for patterns, conventions, and best practices learned from previous projects. Skills compound — every project you complete adds to the library.

3. **Symlinks all agents to `~/.claude/agents/`** — Agents are specialist subagents that Claude Code delegates to. The `architecture-enforcer` checks structural rules. The `security-auditor` scans for vulnerabilities. The `test-writer` generates tests in parallel with the builder. They're available globally so any project can use them.

After setup, install AionUI for parallel agent sessions:
```bash
brew install aionui  # macOS
```

---

## Step 2: Open Any Project

When you run `claude` (Claude Code) in any directory, here's what happens:

```
Claude Code starts
    │
    ├── Reads ~/.claude/STRINGZ.md (your identity — always)
    │
    ├── Checks: does CLAUDE.md exist in this directory?
    │
    ├── YES → Reads CLAUDE.md + KNOWLEDGE.md silently
    │          Proceeds normally. No questions. No interruptions.
    │          This project is already onboarded.
    │
    └── NO → Waits for your first request.
             │
             ├── Read-only request ("explain this", "what does X do")
             │   → Answers directly. No interview. No setup.
             │
             └── Build request ("implement X", "fix Y", "create Z")
                 → Triggers FIRST CONTACT (one time only)
```

**First Contact** is the one-time onboarding interview. It asks 4 questions:

1. **Existing or new?** — Are you onboarding a codebase that already exists, or starting from scratch?
2. **What type?** — Web app, infrastructure, API, mobile, data pipeline, CLI tool?
3. **Tech stack?** — Claude auto-detects from config files, or asks you.
4. **Client or personal?** — Client projects follow the full 6-phase workflow. Personal/experimental projects get a lighter setup.

Then Claude shows the **Skill Coverage Map** — which domains have existing skills and which are gaps. If your project type has no skill, Claude offers to create one as you build.

After the interview, Claude generates the workflow files (CLAUDE.md, KNOWLEDGE.md, REVIEW.md, TASKS.md) and **First Contact never triggers again** for that project.

---

## Step 3: The 6 Phases

Every project — client or personal — follows this sequence. For client deliveries, all 6 phases are mandatory. For personal projects, phases 5 (Brand) and 6 (Deliver) are optional.

### Phase 1: Specify

**What you do:** Describe the project in 2-3 sentences. Then Claude interviews you — you don't write the spec yourself. Claude asks about the problem, users, modules, success criteria, and scope boundaries. You answer. Claude generates `SPEC.md`.

**What Claude does:** Asks structured questions, synthesizes your answers into a formal specification.

**Agents used:** None — this is a human + Claude conversation.

**Deliverable:** `SPEC.md` — the contract that defines what "done" looks like.

**Gate:** You review and approve SPEC.md before Phase 2 begins.

*Example from the Arman build: "Property management web app for apartment complexes in Addis Ababa. First client runs a high-rise in Bole. Everyone uses paper and WhatsApp. Core modules: Units, Tenants, Leases, Payments, Inventory, Notifications." That description, plus 15 minutes of Claude's interview questions, produced a complete SPEC.md.*

---

### Phase 2: Architect

**What you do:** Review the database schema, file structure, and conventions Claude proposes. Approve or adjust.

**What Claude does:** Designs the full database schema (tables, relationships, RLS policies). Creates CLAUDE.md (project identity), KNOWLEDGE.md (empty, ready for learning), TASKS.md (phased wave plan), and REVIEW.md (review-specific rules). Configures linting. Selects applicable skills.

**Agents used:** `repo-scorer` — evaluates the project skeleton against the 7-metric legibility scorecard. Target: 50+/70 before implementation begins.

**Deliverable:** CLAUDE.md + database schema + KNOWLEDGE.md + TASKS.md + REVIEW.md + lint config.

**Gate:** All files exist, repo scores 50+/70 on legibility. Run PREFLIGHT checklist.

*Example from the Arman build: 13 tables designed (buildings, units, tenants, leases, billing_periods, payments, inventory_items, inventory_checks, inventory_check_items, receiving_accounts, notification_templates, notification_schedules, notification_log). RLS policies on all tables. CLAUDE.md with Next.js App Router conventions, signOut scope rule, and explicit "what NOT to do" section.*

---

### Phase 3: Implement

**What you do:** Open AionUI (or 2-3 terminal tabs if you don't have AionUI) with 3 parallel sessions. Give the Builder the current wave from TASKS.md. Review output at each checkpoint.

**What Claude does:** Implements features in waves. Each wave builds 2-3 modules, verifies with lint/build/test, commits, and updates KNOWLEDGE.md.

**Agents used:**
- `test-writer` — generates tests in parallel with the builder (Session 2)
- `architecture-enforcer` — checks structural rules after each wave
- `decision-recorder` — auto-generates Architecture Decision Records
- `code-reviewer` — reviews code quality at checkpoints

**The Wave-Checkpoint Rhythm:**
```
WAVE 1: Foundation (auth, layout, database)
  → Checkpoint: lint passes, build passes, login works
  → Git commit → KNOWLEDGE.md updated → ADRs generated

WAVE 2: Core modules
  → Checkpoint: CRUD works, data persists
  → Git commit → KNOWLEDGE.md updated

WAVE 3: Secondary modules
  → Checkpoint: all features functional
  → Git commit → KNOWLEDGE.md updated

WAVE 4: Polish (error handling, loading states, seed data)
  → Checkpoint: build clean, no console errors
  → Git commit + push
```

**Context management rules:**
- `/clear` between waves — fresh context prevents drift
- `/compact` at 50% — never let context exceed 70%
- `Ctrl+B` to background long-running subagents
- Opus for the main builder, Sonnet for subagents (saves tokens)

**Deliverable:** Working code, committed in waves, all checkpoints passed.

**Gate:** All waves committed. `npm run build` passes. Architecture-enforcer reports zero BLOCKING violations.

*Example from the Arman build: 10 implementation phases across one day. Each phase committed separately. KNOWLEDGE.md accumulated 20+ decisions including: "signOut must use { scope: 'local' }", "dropped CHECK constraints on payment_method for flexible freetext UI", "billing_periods uses lease_id FK not source_id". Session #10 was dramatically faster than Session #1 because KNOWLEDGE.md carried all lessons forward.*

---

### Phase 4: Verify + Deploy

**What you do:** Push to trigger auto-deploy. Run the visual-verifier. Run Comet QA in 8 separate phases, pasting results back to Claude. Fix P0s and P1s.

**What Claude does:** Fixes issues from QA reports. Runs security audit.

**Agents used:**
- `visual-verifier` — boots the app, checks every route, reports errors (before human QA)
- `security-auditor` — scans for auth bypasses, secrets in code, missing validation

**External tool:** Comet (Perplexity browser agent) is recommended, but any tool that provides a **fresh context** works — a new Claude Desktop session, ChatGPT with browsing, or manual testing using the prompts as a checklist. The critical rule: the AI that built the code should NOT be the AI that tests it. Different context eliminates the builder's blind spots. See [QA-GUIDE.md](./QA-GUIDE.md) for tool alternatives.

**The 8 QA phases** (each run as a separate Comet session):
1. Authentication & session management
2. CRUD operations per module
3. Data integrity & edge cases
4. Security (OWASP Top 10 essentials)
5. Mobile responsiveness (4 viewports)
6. Performance & UX polish
7. Accessibility (WCAG 2.1 AA)
8. Cross-browser

See [QA-GUIDE.md](./QA-GUIDE.md) for the complete process and exact prompts.

**Deliverable:** Live URL with zero P0 bugs. Security audit clean.

**Gate:** Zero P0s. Zero critical security findings.

*Example from the Arman build: 4 QA rounds with Comet. Round 1 found P0s: signOut breaking re-login, missing mobile navigation. Round 2 found P1s: auth breakpoint mismatch (lg: vs md:). Round 3 found P2s: notification links overflowing on mobile. Round 4: zero P0s, zero P1s.*

---

### Phase 5: Brand Alignment

**What you do:** Open Comet with both sites side by side (client's official website vs your portal). Paste the comparison report into Claude Code.

**What Claude does:** Replaces the entire color system, updates typography, swaps logos, warms surfaces — all in one commit.

**Agents used:** `brand-aligner` — takes the comparison report and generates a single executable fix prompt.

**Important:** CSS extraction alone is insufficient for brand matching. Always do a visual verification after applying changes. A site can look gold due to photography and overlays, but the CSS might report green utility colors.

**Deliverable:** Portal visually matches client's brand identity.

**Gate:** Visual verification confirms brand alignment.

*Example from the Arman build: Comet found 10 inconsistencies. Major: accent color was emerald (#10B981) instead of the client's gold (#C9A84C). The entire color system was replaced in one commit. Crest logo was extracted from the client's favicon.ico, recolored from peach to gold using Pillow, and placed in the sidebar and login page. One push transformed the portal from "generic SaaS" to "luxury property brand."*

---

### Phase 6: Deliver

**What you do:** Send screenshots + link to the client. Demo on their phone. Say the price.

**What Claude does:** Nothing — this is a human phase. But agents help prepare.

**Agents used:**
- `repo-scorer` — final legibility score (target: 60+/70)
- `onboarding-writer` — generates setup guide, architecture overview, API reference, deployment guide
- `maintenance-scanner` — establishes baseline for ongoing maintenance

**Demo flow (5 minutes, no slides):**
1. Login page — they see their own brand, their own building photo
2. Dashboard — real KPIs
3. The ONE feature that solves their biggest pain — full workflow
4. Pull it up on THEIR phone — hand it to them
5. Say the price once, confidently. Stop talking.

**Deliverable:** Client says yes.

*Example from the Arman build: WhatsApp sent with desktop screenshot of the gold-branded login page showing the building's photo and crest. Client responded within minutes: "Quick! Looks neat... I'll definitely call you when I'm free."*

---

## How the Files Connect

```
STRINGZ.md (global — YOUR identity)
    │  Read on EVERY session, EVERY project
    │  Lives at ~/.claude/STRINGZ.md
    ▼
CLAUDE.md (per-project — the PROJECT's identity)
    │  Read on every session in THIS project
    │  Created once during First Contact or Phase 2
    │
    ├── KNOWLEDGE.md ← Updated by Claude after EVERY wave (the project's memory)
    ├── REVIEW.md ← Review rules, separate from build rules
    ├── TASKS.md ← Checked off as waves complete
    ├── SPEC.md ← The contract — what "done" means
    └── PREFLIGHT.md ← Manual quality gate before Phase 3 or 6
```

---

## How the Agents Connect

```
Phase 2: repo-scorer ──────── "Score: 52/70. Gaps: no tests, no lint."
Phase 3: test-writer ──────── Parallel with builder (Session 2)
         architecture-enforcer After EACH wave: "0 violations"
         decision-recorder ── After EACH wave: generates ADRs
         code-reviewer ────── At checkpoints: quality review
Phase 4: visual-verifier ──── "All routes 200. 0 console errors."
         security-auditor ─── "No secrets. RLS on all tables."
Phase 5: brand-aligner ────── Takes Comet report → fix prompt
Phase 6: repo-scorer ──────── Final: "67/70. Grade: A."
         onboarding-writer ── Generates all docs
         maintenance-scanner  Baseline: "3 stale deps, 2 TODOs"
```

---

## How Skills Compound

**Project 1 (Arman Apartments):** Created 8 skills — supabase-nextjs-fullstack, multi-currency-ledger, property-management-core, notification-queue, mobile-first-dashboard, fullstack-agent-squad, web-app-qa-audit, cloudflare-site-crawler.

**Project 2 (hypothetical Azure project):** Would create new skills — azure-landing-zone, terraform-modules. The workflow, agents, and templates still apply.

**Project 3 (hypothetical SaaS):** Reuses supabase-nextjs-fullstack, notification-queue, mobile-first-dashboard. Creates new skills for stripe-billing, multi-tenant-auth.

By Project 5, you're assembling from tested patterns, not building from scratch.

---

## The Three Scenarios

### Scenario A: Brand New Project
```
mkdir new-project && cd new-project && claude
→ No CLAUDE.md → First Contact on first build request
→ 4 questions → skill map → Phase 1 interview → SPEC.md
→ Phase 2-6 follows
```

### Scenario B: Existing Project (Pre-Workflow)
```
cd old-project && claude
→ No CLAUDE.md → First Contact on first build request
→ "Existing project to onboard" → analyzes codebase
→ Generates all workflow files → repo-scorer baseline
→ Proceeds with your request
```

### Scenario C: Quick Personal Hack
```
mkdir experiment && cd experiment && claude
→ "New" → "CLI tool" → "Personal"
→ Minimal CLAUDE.md + KNOWLEDGE.md
→ Starts building immediately
→ Run full onboarding later if it becomes serious
```

---

## Summary

| Piece | Job |
|-------|-----|
| STRINGZ.md | Your identity (global, every session) |
| First Contact | Onboards new projects (one time, lazy trigger) |
| SPEC.md | Defines "done" (Phase 1) |
| CLAUDE.md | Project identity (Phase 2) |
| KNOWLEDGE.md | Project memory (updated every wave) |
| REVIEW.md | Review rules (separate from build) |
| TASKS.md | Progress tracker (checked off per wave) |
| PREFLIGHT.md | Quality gate (manual, before Phase 3/6) |
| Skills | Domain knowledge that compounds |
| Agents | Specialists that fire at specific points |
| AionUI | Parallel session workspace (or use terminal tabs) |
| Comet | Independent QA — different AI tests different AI's work (or any browser agent / fresh Claude session) |
| setup.sh | Installs everything (one command) |
| update.sh | Pulls latest (one command) |

Nothing is magic. Every piece is a markdown file, a shell script, or a convention. The power comes from how they connect — and from the fact that every project makes the system smarter for the next one.

---

*Next: [QA Guide](./QA-GUIDE.md) — the 8-phase Comet testing process with exact prompts*
