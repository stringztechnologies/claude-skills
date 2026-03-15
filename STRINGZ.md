# Stringz Technologies — Global Context

> This file lives at ~/.claude/STRINGZ.md and is loaded into every Claude Code session.
> It tells Claude who you are, how you work, and what to do in any project.

## Who I Am
- **Name:** Oretayo Fatokun
- **Company:** Stringz Technologies
- **Location:** Addis Ababa, Ethiopia
- **Role:** Founder — I design, build, and deliver web applications for clients using AI-assisted development

## How I Work
- I follow the **Stringz Workflow v2** (Level 5: Agent-First Engineering)
- Framework repo: github.com/stringztechnologies/claude-skills
- Every project follows 6 phases: Specify → Architect → Implement → Verify+Deploy → Brand → Deliver
- I use Claude Code (Opus) as the primary builder with Sonnet subagents
- I use AionUI for parallel session orchestration
- I deploy to Coolify (self-hosted) or Vercel

## My Stack
- **Framework:** Next.js 15 (App Router)
- **Database:** Supabase (Postgres + Auth + Storage + RLS)
- **Styling:** Tailwind CSS + shadcn/ui
- **Deployment:** Coolify at self-hosted server, auto-deploy from GitHub
- **Testing:** Vitest + Playwright
- **Linting:** Biome

## On Every New Session

1. Check if CLAUDE.md exists at project root
2. If YES → read it and KNOWLEDGE.md silently. Proceed normally. No interview. No preflight.
3. If NO → do NOT immediately interview. Wait for my first request.
   - If my request is read-only (explain, analyze, read, search, "what does X do") → answer it directly. No interview needed.
   - If my request requires building, changing, or creating code → trigger First Contact Interview (one time only).

### First Contact Interview (triggers once, only when building)

Say: "I don't see workflow files for this project. Before I start building, let me ask a few quick questions so I can work effectively. This only happens once."

**Q1:** "Is this an existing project to onboard, or are you starting something new?"
  → Existing: analyze codebase first, then continue to Q2
  → New: continue to Q2

**Q2:** "What type of project is this?"
  - Full-stack web app (Next.js, React, Vue, etc.)
  - Infrastructure / IaC (Terraform, Azure, AWS CDK, Pulumi)
  - Backend API / microservice (Node, Python, Go, Rust)
  - Mobile app (React Native, Swift, Flutter, Kotlin)
  - Data pipeline / ML (Python, notebooks, ETL)
  - CLI tool / library
  - Other (describe)

**Q3:** "What's the tech stack?" (or auto-detect from package.json, requirements.txt, go.mod, Cargo.toml, main.tf, etc. if existing project)

**Q4:** "Is this a client delivery or a personal/experimental project?"
  → Client: full 6-phase workflow (Specify → Deliver)
  → Personal/scrappy: lighter flow — just CLAUDE.md + KNOWLEDGE.md, skip brand and delivery phases

### After the interview, show the Skill Coverage Map:

"Here's what I already have skills for, and what's missing for your project type:"

| Domain | Skill Exists? | Skill Name |
|--------|--------------|------------|
| Supabase + Next.js full-stack | ✅ | supabase-nextjs-fullstack |
| Multi-currency payments | ✅ | multi-currency-ledger |
| Property management | ✅ | property-management-core |
| Notification systems | ✅ | notification-queue |
| Mobile-first dashboards | ✅ | mobile-first-dashboard |
| Agent orchestration | ✅ | fullstack-agent-squad |
| QA auditing (8-phase) | ✅ | web-app-qa-audit |
| Brand/design extraction | ✅ | cloudflare-site-crawler |
| Azure / IaC | ❌ | — (will create if needed) |
| Terraform | ❌ | — (will create if needed) |
| Python / Data / ML | ❌ | — (will create if needed) |
| Mobile (React Native) | ❌ | — (will create if needed) |
| CLI tools | ❌ | — (will create if needed) |

If a needed skill is missing: "No skill exists for [domain] yet. I'll create one as we build — it becomes reusable for your next [domain] project."

### Then proceed based on project type:

**New + Client:** Flow directly into Phase 1 Specify. Interview me to build SPEC.md using the interview prompt from WORKFLOW.md. After SPEC.md is approved, proceed to Phase 2: generate CLAUDE.md, KNOWLEDGE.md, REVIEW.md, TASKS.md, PREFLIGHT.md.

**New + Personal/Scrappy:** Ask only:
  - "Describe what you want to build in 2-3 sentences."
  - "Who is it for?"
  - "What's the one thing it must do?"
  Then generate minimal CLAUDE.md + KNOWLEDGE.md and start building. If it becomes serious later, run the full onboarding.

**Existing project (onboard):** Analyze the codebase → generate CLAUDE.md, KNOWLEDGE.md, REVIEW.md, TASKS.md → run repo-scorer → report the score and gaps.

**Once CLAUDE.md is generated, First Contact NEVER triggers again for this project.**

## PREFLIGHT Checklist (separate from First Contact)

PREFLIGHT is NOT automatic. It is a manual gate run before major implementation work.
Trigger it when:
- I say "run preflight" or "preflight check"
- Starting a multi-wave implementation phase (Phase 3)
- Before a client delivery (Phase 6)

Do NOT run PREFLIGHT on every session or for small tasks.

## Before Any PR or Push
Always run this verification sequence:
1. `npm run lint` — must pass clean
2. `npm run build` — must pass clean
3. Run architecture-enforcer subagent (if available in .claude/agents/)
4. Run security-auditor subagent for any auth/input/API changes
5. Conventional commit messages: `type(scope): description`

## Skills & Agents
- Global skills at: ~/.claude/skills/
- Global agents at: ~/.claude/agents/
- Check which skills apply to the current project before starting implementation

## Communication Preferences
- Be concise. Skip preamble.
- Show code first, explain after if needed.
- When uncertain, say so — don't hallucinate confidence.
- Don't summarize what you just did — I can read the diff.
- Don't suggest things to "consider" unless I ask.

## Context for Claude Desktop / Web Chat
When I start a conversation on Claude Desktop or web, I may paste:
```
I'm Oretayo from Stringz Technologies. I follow the Stringz Workflow v2
(Level 5 Agent-First Engineering). Framework: github.com/stringztechnologies/claude-skills
```
This means: use the workflow principles even in chat — interview me for specs, think in modules, suggest wave-based implementation.
