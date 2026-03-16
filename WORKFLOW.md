<!-- version: 2.2 -->
# The Stringz Technologies Development Workflow — v2

> **Agent-First Engineering Framework — March 2026**
> From intent to deployed product in one day. Every time.
> Level 5: Agent-first. Mechanical enforcement. Parallel execution. Self-verifying agents.

---

## How to Use This

Starting a new project? Open Claude and paste:

```
I'm starting a new project. Here's the idea: [describe it in 2-3 sentences].

Follow the Stringz Workflow v2 from github.com/stringztechnologies/stringz-framework/WORKFLOW.md

We're in Phase 1: Specify. Interview me to build the spec. Ask one question at a time.
```

---

## Phase 1: SPECIFY
**Deliverable:** `SPEC.md`
**Time:** 30-60 minutes
**Who:** You + Claude (chat or voice mode)

### What happens:
Claude interviews you — you don't write the spec yourself. Voice mode (`/voice`) is 3.7x faster than typing if available.

### The Interview Prompt:
```
I want to build [brief description]. Interview me in detail — ask me about:
1. Who has the problem and what they currently use
2. The 3-6 core modules (capabilities, not features)
3. User context: device, connectivity, technical literacy, language
4. What "done" looks like (specific testable scenarios)
5. What is explicitly OUT of scope
6. Tech stack preferences and deployment target
7. Does the client have an existing website/brand to match?

Ask one question at a time. After the interview, generate SPEC.md.
```

### Gate: SPEC.md reviewed and approved before Phase 2.

> **Note:** If this is a new project and you haven't run First Contact yet, it triggers automatically when you first ask Claude Code to build something. First Contact flows into Phase 1 (Specify) and then Phase 2 (Architect) seamlessly. First Contact is the one-time entry point. PREFLIGHT is the recurring quality gate before Phase 3.

---

## Phase 2: ARCHITECT
**Deliverable:** CLAUDE.md + Schema + KNOWLEDGE.md + TASKS.md + REVIEW.md + lint config
**Time:** 30-60 minutes
**Who:** You + Claude (chat → Claude Code)

### What happens:
1. Design full database schema (tables, relationships, RLS)
2. Create CLAUDE.md from template (project identity, conventions, what NOT to do)
3. Create KNOWLEDGE.md from template (empty, ready for Claude to update)
4. Create TASKS.md from template (phased wave plan)
5. Create REVIEW.md from template (review-specific rules, separate from build rules)
6. Configure lint + format gates:
   ```bash
   # Install Biome (or ESLint + Prettier)
   npm install --save-dev @biomejs/biome
   npx biome init
   ```
7. Add pre-commit hook:
   ```bash
   # In package.json scripts:
   "lint": "biome check src/",
   "format": "biome format --write src/",
   "precommit": "npm run lint && npm run build"
   ```
8. Create `docs/decisions/` directory for ADRs
9. Select applicable skills from ~/.claude/skills/
10. Copy subagents to project `.claude/agents/`:
    - architecture-enforcer.md
    - test-writer.md
    - code-reviewer.md
    - security-auditor.md

### Step 11: Verify Development Environment
Before implementation begins, confirm all tools are installed and accessible:

**Required:**
- [ ] Claude Code installed (`claude --version`)
- [ ] Node.js 20+ (`node --version`)
- [ ] Git configured (`git config user.name`)
- [ ] AionUI installed (`aionui --version` or check Applications)
- [ ] Coolify accessible (deployment target)

**AionUI Setup:**
AionUI is the orchestration GUI for running parallel agent sessions. Install once:
- macOS: `brew install aionui`
- Windows/Linux: Download from https://github.com/iOfficeAI/AionUi/releases
- On first launch, AionUI auto-detects Claude Code and other installed CLI agents
- Configure your API keys (Anthropic for Claude, or use existing Claude Code auth)
- Set up MCP tools once in AionUI — they sync to all agents automatically

### Run repo-scorer against the project skeleton:
```
Use the repo-scorer subagent to evaluate this project. We need a score of 50+/70 before starting implementation.
```

### Run PREFLIGHT checklist:
Copy `templates/PREFLIGHT.md.template` into the project and verify every item before proceeding.

### Gate: CLAUDE.md, schema, TASKS.md, REVIEW.md, lint config all exist. PREFLIGHT checklist complete. Repo scores 50+/70 on legibility.

---

## Phase 3: IMPLEMENT
**Deliverable:** Working code, committed in waves with automated verification
**Time:** 2-8 hours
**Who:** Claude Code (Opus main + Sonnet subagents) — multiple parallel sessions

### Parallel Execution Setup:
Open AionUI and create 3 parallel sessions:

| Session | Agent | Role | Model |
|---------|-------|------|-------|
| Session 1 | Claude Code | **Builder** — implements features from TASKS.md | Opus |
| Session 2 | Claude Code | **Test Writer** — generates tests for built features | Sonnet |
| Session 3 | Claude Code / Gemini CLI | **Scout** — researches APIs, patterns for next wave | Sonnet |

AionUI advantages over raw terminals:
- All 3 sessions visible simultaneously in one window
- Independent context per session (no cross-contamination)
- MCP tools configured once, shared across all sessions
- Session history saved locally in SQLite — resume anytime
- Visual file preview without switching to Finder/Explorer

Set subagent model for cost efficiency:
```bash
export CLAUDE_CODE_SUBAGENT_MODEL=claude-sonnet-4-6
```

### The Wave-Checkpoint Rhythm:

```
WAVE:
  1. Start fresh session. Claude reads CLAUDE.md + KNOWLEDGE.md
  2. Give it the current phase from TASKS.md
  3. Let it build (don't micromanage)

CHECKPOINT (after each wave):
  4. Run lint: npm run lint
  5. Run build: npm run build
  6. Run tests: npm run test (if tests exist)
  7. Run architecture-enforcer subagent
  8. Git commit with conventional commit message
  9. Claude updates KNOWLEDGE.md
  10. Decision-recorder subagent generates ADRs

CONTEXT MANAGEMENT:
  - /clear between waves (fresh context per phase)
  - Manual /compact at 50% context
  - Ctrl+B to background long-running subagents
  - Never operate above 70% context usage
```

### Wave Template Prompt:
```
/sc:implement "[Phase description from TASKS.md]"

Read CLAUDE.md and KNOWLEDGE.md first.

[Paste specific tasks for this wave]

After implementation:
1. Run `npm run lint && npm run build`
2. Use the architecture-enforcer subagent to check for violations
3. Fix any violations
4. Update KNOWLEDGE.md with decisions made
5. Git commit with message: "feat: [description]"
```

### Gate: All waves committed. Build passes. Lint passes. Architecture-enforcer reports 0 BLOCKING violations.

---

## Phase 4: VERIFY + DEPLOY
**Deliverable:** Live URL with zero P0 bugs, automated + manual verification
**Time:** 1-2 hours
**Who:** Visual-verifier subagent + Coolify + Comet browser

### Step 1: Automated Verification (NEW — agent verifies own work)
```
Use the visual-verifier subagent to check the application before deployment.
```
The visual-verifier boots the app, checks every route, reports console errors, and verifies mobile responsiveness. Fix any issues it finds.

### Step 2: Run Tests
```bash
npm run test
```
All tests must pass before deployment.

### Step 3: Deploy
```bash
git push  # Coolify auto-deploys
```

### Step 4: Independent QA (different AI, different context)
Open Comet browser or a fresh Claude session and paste the QA audit prompt:

```
You are a senior QA engineer. Test https://[your-url] systematically.
Login with: [email] / [password]

Test: auth flow, every CRUD path, empty states, error paths, mobile at 393px, performance.

Categorize as P0 (broken), P1 (wrong), P2 (polish), P3 (nice-to-have).
Output a Claude Code prompt that fixes all P0s and P1s.
```

### Step 5: Fix Cycle
1. Paste QA fix prompt into Claude Code
2. Run architecture-enforcer after fixes
3. Push → auto-deploy
4. Re-audit until zero P0s

### Step 6: Security Audit
```
Use the security-auditor subagent to audit the codebase before client delivery.
```

### Gate: Zero P0 bugs. Security audit clean. Visual-verifier passes.

---

## Phase 5: BRAND ALIGNMENT
**Deliverable:** Pixel-perfect brand match
**Time:** 30-60 minutes
**Who:** Comet two-site comparison + brand-aligner subagent + Claude Code

### Step 1: Two-Site Comparison (Comet)
```
You are a senior UI designer. Compare:
TAB 1: [client's website] — the official brand
TAB 2: [portal URL] — login: [credentials]

For each inconsistency: exact hex colors, font names, CSS fix, priority.
End with a single Claude Code prompt for all high-priority fixes.
```

### Step 2: Logo Extraction
Download/extract the client's logo. Convert and recolor if needed (use Pillow/ImageMagick). Place in public/.

### Step 3: Apply Brand Changes
Paste the Comet-generated prompt into Claude Code. Or use the brand-aligner subagent:
```
Use the brand-aligner subagent with this comparison report: [paste report]
```

### Step 4: Visual Verification
Check the live URL after changes deploy. CSS extraction alone is insufficient — always verify visually.

### Gate: Portal visually matches client's brand.

---

## Phase 6: DELIVER
**Deliverable:** Client says yes
**Time:** 30-60 minutes
**Who:** You (human)

### Pre-Meeting Checklist:
- [ ] Change default password
- [ ] Run security-auditor one final time
- [ ] Run repo-scorer — target 60+/70
- [ ] Run onboarding-writer to generate docs
- [ ] Take desktop + mobile screenshots
- [ ] Send WhatsApp: screenshots + link + "when can we walk through this?"
- [ ] Do NOT send credentials in the message

### The Demo (5 minutes, no slides):
1. Login page — their brand, their building photo, their logo
2. Dashboard — real KPIs
3. The ONE feature that solves their biggest pain — full workflow
4. Pull it up on THEIR phone — hand it to them
5. Say the price once, confidently. Stop talking.

### Post-Delivery:
- [ ] Run decision-recorder to finalize all ADRs
- [ ] Run maintenance-scanner as baseline
- [ ] Extract reusable skills from this project → push to stringz-framework repo
- [ ] Update WORKFLOW.md if you discovered a better process

### Gate: Client says yes. Invoice sent.

---

## Parallel Agent Orchestration Guide

### For Each Wave (during Phase 3):

```
┌─────────────────────────────────────────┐
│           YOU (Human Director)           │
│  Specify intent. Review output. Decide. │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│Builder│ │Tester │ │Scout  │
│(Opus) │ │(Sonnet│ │(Sonnet│
│       │ │       │ │       │
│Writes │ │Writes │ │Reads  │
│code   │ │tests  │ │docs,  │
│for    │ │for    │ │finds  │
│current│ │current│ │APIs   │
│wave   │ │wave   │ │for    │
│       │ │       │ │next   │
│       │ │       │ │wave   │
└───┬───┘ └───┬───┘ └───┬───┘
    │         │         │
    └────┬────┘         │
         │              │
    ┌────▼────┐         │
    │Enforcer │    ┌────▼────┐
    │(Sonnet) │    │Recorder │
    │         │    │(Sonnet) │
    │Checks   │    │         │
    │arch     │    │Writes   │
    │rules    │    │ADRs     │
    └────┬────┘    └────┬────┘
         │              │
         └──────┬───────┘
                │
         ┌──────▼──────┐
         │  Git Commit  │
         │  + Push      │
         └─────────────┘
```

### For Deployment (Phase 4):

```
Push → Auto-Deploy → Visual-Verifier → Comet QA → Security Audit → Fix → Repeat
```

---

## Agent Inventory

| Agent | File | Purpose | Phase | Model |
|-------|------|---------|-------|-------|
| AionUI | Desktop app | Parallel session orchestration, scheduled automation, unified MCP | All phases | N/A (GUI) |
| architecture-enforcer | agents/architecture-enforcer.md | Mechanical rule checking | 3 (each wave) | Sonnet |
| test-writer | agents/test-writer.md | Generate tests in parallel | 3 (parallel) | Sonnet |
| code-reviewer | agents/code-reviewer.md | Quality review after build | 3 (checkpoint) | Sonnet |
| security-auditor | agents/security-auditor.md | Security vulnerability scan | 4 (pre-deploy) | Sonnet |
| visual-verifier | agents/visual-verifier.md | Boot app, check routes/errors | 4 (pre-QA) | Sonnet |
| brand-aligner | agents/brand-aligner.md | Generate brand fix prompt | 5 | Sonnet |
| decision-recorder | agents/decision-recorder.md | Auto-generate ADRs | 3 (checkpoint) | Sonnet |
| repo-scorer | agents/repo-scorer.md | Legibility scorecard (7 metrics) | 2 (setup) + 6 (delivery) | Sonnet |
| maintenance-scanner | agents/maintenance-scanner.md | Tech debt detection | 6 (post-delivery) + weekly | Sonnet |
| onboarding-writer | agents/onboarding-writer.md | Generate docs and guides | 6 (delivery) | Sonnet |

---

## Templates

| Template | Purpose |
|----------|---------|
| templates/SPEC.md.template | Interview-driven project specification |
| templates/CLAUDE.md.template | Project identity and conventions |
| templates/KNOWLEDGE.md.template | Accumulated learning journal |
| templates/TASKS.md.template | Wave-based task tracker |
| templates/REVIEW.md.template | Review-specific rules (separate from build rules) |
| templates/PREFLIGHT.md.template | Pre-implementation environment & project checklist |

---

## The Toolchain (Level 5)

| Layer | Tool | Purpose |
|-------|------|---------|
| Specification | Claude (chat/voice) | Interview, spec generation |
| Context | CLAUDE.md + KNOWLEDGE.md + REVIEW.md | Persistent memory |
| Implementation | Claude Code (Opus + Sonnet subagents) | Agentic coding |
| **Orchestration** | **AionUI** | **Parallel sessions, scheduled automation, unified MCP** |
| Skills | ~/.claude/skills/ + GitHub repo | Reusable domain knowledge |
| Deployment | Coolify / Vercel + auto-deploy | One push to production |
| QA | Comet browser + visual-verifier agent | Independent audit |
| Brand | Comet comparison + brand-aligner agent | Design token extraction |
| Version Control | Git with conventional commits | Rollback + review |
| Delivery | WhatsApp + live demo | Screenshots sell, demos close |

---

## The 10 Commandments (v2)

1. **Specify before you build.** Interview, don't type. Voice mode if available.
2. **CLAUDE.md is your harness.** Not optional. Not a suggestion. The foundation everything runs on.
3. **KNOWLEDGE.md is episodic memory.** Every wave adds learning. Session #10 inherits all lessons.
4. **Enforce mechanically, not documentationally.** Lint gates. Pre-commit hooks. Architecture-enforcer. If a rule isn't enforced by CI, it will be violated.
5. **Parallelize ruthlessly.** Builder + Tester + Scout running simultaneously. Opus for complex work, Sonnet for focused subagents.
6. **Agents verify their own work.** Visual-verifier boots the app. Architecture-enforcer checks rules. Tests confirm behavior. Humans review — they don't discover.
7. **Builder ≠ Tester ≠ Reviewer.** Three different contexts. Three different blind spots eliminated.
8. **Build generic, brand later.** One pass. One commit. Maximum visual impact.
9. **Skills compound. Agents compound. Decisions compound.** Extract patterns into skills. Define agents for repeated work. Record decisions in ADRs. Every project makes the next one faster.
10. **The product sells itself.** Screenshots first. Demo on their device. Say the price once. Stop talking.

---

## Quick Reference

| Phase | Deliverable | Agents Used | Time |
|-------|-------------|-------------|------|
| 1. Specify | SPEC.md | None (human + Claude chat) | 30-60min |
| 2. Architect | CLAUDE.md + schema + REVIEW.md + lint | repo-scorer | 30-60min |
| 3. Implement | Working code (wave commits) | architecture-enforcer, test-writer, decision-recorder | 2-8hrs |
| 4. Verify + Deploy | Live URL, zero P0s | visual-verifier, security-auditor + Comet QA | 1-2hrs |
| 5. Brand | Brand-aligned UI | brand-aligner + Comet comparison | 30-60min |
| 6. Deliver | Client says yes | repo-scorer, onboarding-writer, maintenance-scanner | 30-60min |

**Orchestration:** All parallel sessions run through AionUI for visual management.

---

*Stringz Technologies — Agent-First Engineering — March 2026*
*"You are not a coder. You are a context engineer."*
