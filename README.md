# Stringz Technologies — Claude Skills & Workflow Framework

**Framework Version: 2.2**

> **Level 5: Agent-First Engineering — March 2026**
> From intent to deployed product in one day. Every time.
> Mechanical enforcement. Parallel execution. Self-verifying agents.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — the agentic coding engine
- [AionUI](https://github.com/iOfficeAI/AionUi) — orchestration GUI for parallel agent sessions
- [Node.js 20+](https://nodejs.org/) — runtime
- [Git](https://git-scm.com/) — version control
- [Coolify](https://coolify.io/) or Vercel — deployment platform

## Quick Start

```bash
git clone https://github.com/stringztechnologies/stringz-framework.git
cd stringz-framework
./setup.sh
```

That's it. Open Claude Code in any project and the workflow activates automatically.

To update later: `./update.sh`

Windows users: use `.\setup.ps1` instead of `./setup.sh`

### Starting a new project:
```
mkdir my-project && cd my-project && claude
```
Claude detects no CLAUDE.md, runs First Contact when you ask it to build something, and flows into the 6-phase workflow.

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
- `templates/PREFLIGHT.md.template` — Pre-implementation environment & project checklist
- `templates/STRINGZ.md.template` — Personal context — tells every Claude session who you are and how you work
- `templates/ONBOARDING.md.template` — Onboard existing projects to the Stringz Workflow

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
| `cloudflare-site-crawler` | Design | Extract design tokens from websites |

## Agents (11)

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
| `qa-prompt-generator` | Auto-fill QA prompts from CLAUDE.md | 4 (pre-QA) |

## Installation

### Automated (recommended):
```bash
git clone https://github.com/stringztechnologies/stringz-framework.git
cd stringz-framework
./setup.sh
```
The script checks prerequisites, copies STRINGZ.md to `~/.claude/`, symlinks all skills and agents, and prints a summary. Edit `~/.claude/STRINGZ.md` with your personal details after running.

### Orchestration GUI (recommended):
```bash
# macOS
brew install aionui

# Windows/Linux — download from GitHub releases
# https://github.com/iOfficeAI/AionUi/releases
```
AionUI auto-detects Claude Code and provides a visual workspace for running parallel agent sessions.

### Per-project setup:
Templates are copied automatically when Claude runs First Contact on a new project. To copy manually:
```bash
cp stringz-framework/templates/CLAUDE.md.template ./CLAUDE.md
cp stringz-framework/templates/KNOWLEDGE.md.template ./KNOWLEDGE.md
cp stringz-framework/templates/TASKS.md.template ./TASKS.md
cp stringz-framework/templates/REVIEW.md.template ./REVIEW.md
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to add skills, agents, and templates. Team members run `./update.sh` after merges to pick up new additions.

## The Philosophy

> You are not a coder. You are a context engineer.
> Your job is to design environments where agents produce reliable output.

---

**Stringz Technologies** — Addis Ababa & Beyond — 2026
