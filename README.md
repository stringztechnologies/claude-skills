# Stringz Technologies — Claude Skills & Workflow Framework

> **Level 5: Agent-First Engineering — March 2026**
> From intent to deployed product in one day. Every time.
> Mechanical enforcement. Parallel execution. Self-verifying agents.

## Quick Start

Starting a new project? Open Claude and paste:

```
I'm starting a new project. Here's the idea: [2-3 sentences].

Follow the Stringz Workflow v2 from github.com/stringztechnologies/claude-skills/WORKFLOW.md

We're in Phase 1: Specify. Interview me to build the spec. Ask one question at a time.
```

## The Workflow

**[Read WORKFLOW.md](./WORKFLOW.md)** — The complete 6-phase agent-first framework.

| Phase | Deliverable | Agents Used | Time |
|-------|-------------|-------------|------|
| 1. Specify | SPEC.md | None (human + Claude chat) | 30-60min |
| 2. Architect | CLAUDE.md + schema + REVIEW.md + lint | repo-scorer | 30-60min |
| 3. Implement | Working code (wave commits) | architecture-enforcer, test-writer, decision-recorder | 2-8hrs |
| 4. Verify + Deploy | Live URL, zero P0s | visual-verifier, security-auditor + Comet QA | 1-2hrs |
| 5. Brand | Brand-aligned UI | brand-aligner + Comet comparison | 30-60min |
| 6. Deliver | Client says yes | repo-scorer, onboarding-writer, maintenance-scanner | 30-60min |

## Mastery Levels

| Level | Name | Description |
|-------|------|-------------|
| 1 | Vibe Coding | Prompt and pray. No structure, no persistence. |
| 2 | Structured Prompting | CLAUDE.md, SPEC.md. Context persists across sessions. |
| 3 | Workflow Engineering | 6-phase process. Templates. Skills. Wave-checkpoint rhythm. |
| 4 | Multi-Agent | Parallel execution. Builder + Tester + Scout. Subagent delegation. |
| 5 | **Agent-First Engineering** | Mechanical enforcement. Self-verifying agents. ADRs. Repo scoring. Full autonomy with guardrails. |

## Templates

Copy these into every new project:

- `templates/SPEC.md.template` — Interview-driven specification
- `templates/CLAUDE.md.template` — Project identity + conventions
- `templates/KNOWLEDGE.md.template` — Accumulated learning journal
- `templates/TASKS.md.template` — Wave-based task tracker
- `templates/REVIEW.md.template` — Review-specific rules (separate from build rules)

## Skills Library

Reusable domain knowledge that compounds across projects:

| Skill | Domain | Use When |
|-------|--------|----------|
| `supabase-nextjs-fullstack` | Full-stack | Next.js + Supabase project |
| `multi-currency-ledger` | Finance | Payments in multiple currencies |
| `property-management-core` | Real Estate | Buildings, units, tenants, leases |
| `notification-queue` | Messaging | Scheduled reminders, multi-channel |
| `mobile-first-dashboard` | UI/UX | Phone-first admin dashboard |
| `fullstack-agent-squad` | Dev Process | Agent orchestration patterns |
| `web-app-qa-audit` | QA | Systematic testing of deployed apps |
| `cloudflare-site-crawler` | Design | Extract design tokens from websites |

## Agents (10)

Install in any project by copying to `.claude/agents/`:

| Agent | Purpose | Phase |
|-------|---------|-------|
| `architecture-enforcer` | Mechanical rule checking against CLAUDE.md | 3 (each wave) |
| `test-writer` | Generate tests in parallel with builder | 3 (parallel) |
| `code-reviewer` | Post-implementation quality review | 3 (checkpoint) |
| `decision-recorder` | Auto-generate Architecture Decision Records | 3 (checkpoint) |
| `visual-verifier` | Boot app, check routes, report errors | 4 (pre-deploy) |
| `security-auditor` | Security vulnerability scan | 4 (pre-deploy) |
| `brand-aligner` | Generate brand alignment prompts | 5 |
| `repo-scorer` | 7-metric legibility scorecard (70-point scale) | 2 + 6 |
| `maintenance-scanner` | Tech debt detection | 6 + weekly |
| `onboarding-writer` | Generate setup guides and docs | 6 (delivery) |

## Installation

### Skills (global — available in all projects):
```bash
# Clone the repo
git clone https://github.com/stringztechnologies/claude-skills.git

# Symlink skills to global Claude Code location
ln -s $(pwd)/claude-skills/skills/* ~/.claude/skills/

# Symlink agents
ln -s $(pwd)/claude-skills/agents/* ~/.claude/agents/
```

### Per-project setup:
```bash
# Copy templates into a new project
cp claude-skills/templates/CLAUDE.md.template ./CLAUDE.md
cp claude-skills/templates/KNOWLEDGE.md.template ./KNOWLEDGE.md
cp claude-skills/templates/TASKS.md.template ./TASKS.md
cp claude-skills/templates/REVIEW.md.template ./REVIEW.md
```

## The Philosophy

> You are not a coder. You are a context engineer.
> Your job is to design environments where agents produce reliable output.

---

**Stringz Technologies** — Addis Ababa & Beyond — 2026
