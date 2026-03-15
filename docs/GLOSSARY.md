# Glossary

> Every term used in the Stringz Workflow, defined in one place.

---

### ADR (Architecture Decision Record)
A short document recording why a specific technical decision was made. Stored in `docs/decisions/NNNN-title.md`. Generated automatically by the `decision-recorder` agent after each implementation wave. Preserves the "why" — not just what was built, but what alternatives were considered and rejected.

### Agent
A specialized AI subagent defined as a Markdown file in `agents/`. Each has a specific role, its own system prompt, tool permissions, and runs in isolated context. The framework includes 10 agents.

### AionUI
An open-source desktop GUI that unifies multiple CLI agents into one visual workspace. Used for parallel sessions during Phase 3. Optional — terminal tabs work as an alternative. Install: `brew install aionui`.

### Builder
The primary Claude Code session (Opus) that implements features during Phase 3. Works alongside the Tester and Scout. The Builder writes code; it does not test or review its own output.

### Checkpoint
The verification step after each wave. Includes: lint, build, tests, architecture-enforcer, git commit, KNOWLEDGE.md update. Each checkpoint is a rollback point.

### CLAUDE.md
Project-specific file at the repo root telling Claude Code how this project works: tech stack, structure, conventions, what NOT to do. Read automatically every session. Created during Phase 2 or First Contact.

### Comet
Browser agent used for independent QA. Refers to Perplexity's Comet feature, but the prompts work in any browser agent, a fresh Claude session, or as manual testing checklists. The key: it must be a different context than the builder.

### Context
The information available to an AI agent during a session. A finite, precious resource — performance degrades as it fills. Managed through: `/clear` between waves, `/compact` at 50%, subagent delegation, one task per session.

### Context Engineer
The human role in agent-first engineering. You design the environment — constraints, feedback loops, documentation — that enables agents to produce reliable output. Term popularized by Martin Fowler, 2026.

### First Contact
One-time onboarding interview triggered when CLAUDE.md is missing and you ask to build something. Asks 4 questions, shows the Skill Coverage Map, flows into Phase 1 or generates workflow files. Uses a lazy trigger — doesn't fire on read-only requests. Once CLAUDE.md exists, never triggers again.

### Gate
A condition that must be met before moving to the next phase. Phase 1: SPEC.md approved. Phase 2: repo scores 50+/70. Phase 3: zero BLOCKING violations. Phase 4: zero P0 bugs. Phase 5: visual brand match. Phase 6: client says yes.

### Harness
The full environment of constraints, feedback loops, and tooling that makes agents reliable. Includes: CLAUDE.md, KNOWLEDGE.md, lint rules, hooks, skills, agents. Term from OpenAI's February 2026 "Harness Engineering" paper.

### KNOWLEDGE.md
Project-specific episodic memory. Updated by Claude after every wave. Session #10 inherits all lessons from sessions #1-9. The most important file for compounding intelligence.

### Lazy Trigger
A pattern where an action fires only when needed, not eagerly. First Contact uses this — waits for a build request instead of interrupting on every session without CLAUDE.md.

### Legibility Scorecard
7-metric evaluation of repo AI-readiness (from OpenAI). Metrics: Bootstrap Self-Sufficiency, Task Entrypoints, Validation Harness, Lint Gates, Repo Map, Structured Docs, Decision Records. Scored out of 70. Target: 50+ before implementation, 60+ at delivery.

### Mechanical Enforcement
Rules enforced by tooling (linters, CI, pre-commit hooks, architecture-enforcer), not just documentation. If a rule isn't mechanically enforced, it will eventually be violated.

### P0 / P1 / P2 / P3
Bug severity. P0: blocker (crash, data loss, security hole). P1: critical (wrong behavior). P2: major (cosmetic). P3: minor (polish). Rule: zero P0s before delivery.

### PREFLIGHT
Manual quality gate before Phase 3 or 6. Checks: tools installed, files exist, lint works, build passes, repo scores 50+/70. Not automatic — only when you say "run preflight."

### REVIEW.md
Project-specific review rules, separate from CLAUDE.md build rules. Read by code-reviewer and security-auditor agents. Prevents review concerns from polluting implementation context.

### Scout
Third parallel session during Phase 3. Researches APIs, docs, and patterns for the next wave while Builder and Tester handle the current wave. Runs on Sonnet.

### Skill
Reusable domain knowledge in `skills/[name]/SKILL.md`. Contains patterns, best practices, and lessons from previous projects. Skills compound — every project adds to the library. By project #5, you assemble from tested patterns.

### Skill Coverage Map
Table shown during First Contact listing which domains have skills (✅) and which are gaps (❌). Helps users know what knowledge exists and what needs to be created.

### SPEC.md
The project specification — a contract defining what "done" looks like. Created in Phase 1 through Claude's interview (you don't write it yourself). Contains: problem, modules, user context, success criteria, scope boundaries.

### STRINGZ.md
Your personal identity file at `~/.claude/STRINGZ.md`. Read on every session, every project. Contains: who you are, your workflow, infrastructure, tools, First Contact rules, pre-PR checks. Created from `templates/STRINGZ.md.template` during setup.

### Tester
Second parallel session during Phase 3. Runs `test-writer` agent on Sonnet. Generates tests for features the Builder is implementing.

### Wave
One implementation cycle. Builds 2-3 modules, ends with a checkpoint. Each wave gets fresh context (`/clear`). Tracked in TASKS.md.

### Wave-Checkpoint Rhythm
The core pattern: build a wave → checkpoint (lint, build, test, enforce, commit) → update KNOWLEDGE.md → fresh context → next wave. Prevents the "butterfly effect" where early mistakes compound.

---

*Previous: [Examples](./EXAMPLES.md)*
*Back to: [How It All Works](./HOW-IT-WORKS.md)*
