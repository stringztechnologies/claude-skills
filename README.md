# Stringz Technologies — Claude Skills & Workflow Framework

> **The Perfected AI-Assisted Development Framework — March 2026**
> From intent to deployed product in one day. Every time.

## Quick Start

Starting a new project? Open Claude and paste:

```
I'm starting a new project. Here's the idea: [2-3 sentences].

Follow the Stringz Workflow: 6 phases (Specify → Architect → Implement → Deploy+QA → Brand → Deliver).

We're in Phase 1: Specify. Interview me to build the spec. Ask one question at a time.
```

## The Workflow

**[Read WORKFLOW.md](./WORKFLOW.md)** — The complete 6-phase framework.

| Phase | Deliverable | Time |
|-------|-------------|------|
| 1. Specify | SPEC.md | 30-60min |
| 2. Architect | CLAUDE.md + schema + KNOWLEDGE.md | 30-60min |
| 3. Implement | Working code (wave commits) | 2-8hrs |
| 4. Deploy + QA | Live URL, zero P0s | 1-2hrs |
| 5. Brand | Brand-aligned UI | 30-60min |
| 6. Deliver | Client says yes | 30min |

## Templates

Copy these into every new project:

- `templates/SPEC.md.template` — Interview-driven specification
- `templates/CLAUDE.md.template` — Project identity + conventions
- `templates/KNOWLEDGE.md.template` — Accumulated learning journal
- `templates/TASKS.md.template` — Phased task tracker

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

## Subagents

Install in any project by copying to `.claude/agents/`:

- `agents/code-reviewer.md` — Post-implementation quality review
- `agents/security-auditor.md` — Pre-deployment security audit
- `agents/brand-aligner.md` — Generates brand alignment prompts

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
```

## The Philosophy

> You are not a coder. You are a context engineer.
> Your job is to design the environment, constraints, and feedback loops
> that make AI agents produce reliable, production-grade output.

---

**Stringz Technologies** — Addis Ababa & Beyond — 2026
