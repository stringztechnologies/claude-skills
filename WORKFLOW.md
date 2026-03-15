# The Stringz Technologies Development Workflow

> **The Perfected AI-Assisted Development Framework — March 2026**
> Every project follows these 6 phases. No phase begins until the previous deliverable is verified.

---

## How to Use This

1. **Starting a new project?** Open Claude (web, desktop, or Code) and paste:
   ```
   I'm starting a new project. Here's the idea: [describe it in 2-3 sentences].
   
   Follow the Stringz Workflow from github.com/stringztechnologies/claude-skills/WORKFLOW.md
   
   We're in Phase 1: Specify. Interview me to build the spec.
   ```

2. Claude will interview you, generate the spec, and guide you through all 6 phases.

3. At each phase transition, Claude should confirm the deliverable is complete before proceeding.

---

## Phase 1: SPECIFY
**Deliverable:** `SPEC.md`
**Time:** 30-60 minutes
**Who:** You + Claude (chat)

### What happens:
- Claude interviews you using clarifying questions (not you writing a document)
- Questions cover: problem, users, modules, success criteria, what's NOT in scope
- Output is a structured SPEC.md file

### The Interview Prompt:
```
I want to build [brief description]. Interview me in detail — ask me about:
1. Who has the problem and what they currently use
2. The 3-6 core modules (capabilities, not features)
3. User context: device, connectivity, technical literacy, language
4. What "done" looks like (specific scenarios, not vague goals)
5. What is explicitly OUT of scope
6. Tech stack preferences and deployment target

Ask one question at a time. After the interview, generate a SPEC.md I can review.
```

### SPEC.md must contain:
- Problem statement (1 paragraph)
- Module list (3-6 items, one sentence each)
- User context (device, network, literacy)
- Success criteria (specific testable scenarios)
- Out of scope (explicit exclusions)
- Tech stack + deployment target

### Gate: Do NOT proceed to Phase 2 until you've reviewed and approved the spec.

---

## Phase 2: ARCHITECT
**Deliverable:** `CLAUDE.md` + Database Schema + `KNOWLEDGE.md` + `TASKS.md`
**Time:** 30-60 minutes
**Who:** You + Claude (chat → Claude Code)

### What happens:
- Design the full database schema (tables, relationships, RLS policies)
- Create CLAUDE.md with project identity, conventions, file structure
- Create empty KNOWLEDGE.md with section headers
- Create TASKS.md with phased implementation plan
- Identify which existing skills from the library apply
- Identify gaps → plan new skills to create during the build

### CLAUDE.md template:
Copy from `templates/CLAUDE.md.template` and customize for the project.

### Skill selection:
```
Check ~/.claude/skills/ for applicable skills:
- supabase-nextjs-fullstack → if using Supabase + Next.js
- multi-currency-ledger → if handling payments in multiple currencies
- mobile-first-dashboard → if admin dashboard with phone-first design
- notification-queue → if scheduled reminders or notifications
- [add your own as your library grows]
```

### Gate: CLAUDE.md, schema, and TASKS.md must exist in the repo before Phase 3.

---

## Phase 3: IMPLEMENT
**Deliverable:** Working code, committed in waves
**Time:** 2-8 hours depending on scope
**Who:** Claude Code (with your supervision)

### The Wave-Checkpoint Rhythm:
```
Wave 1: Foundation (auth, layout, database setup)
  → Checkpoint: npm run build passes, login works
  → Git commit
  → Claude updates KNOWLEDGE.md

Wave 2: Core modules (the 2-3 most important features)
  → Checkpoint: CRUD works on all entities, data persists
  → Git commit
  → Claude updates KNOWLEDGE.md

Wave 3: Secondary modules + integrations
  → Checkpoint: All features functional, seed data loaded
  → Git commit
  → Claude updates KNOWLEDGE.md

Wave 4: Polish (error handling, loading states, empty states)
  → Checkpoint: npm run build clean, no console errors
  → Git commit + push
```

### Prompt for each wave:
```
/sc:implement "[Phase description from TASKS.md]"

Read CLAUDE.md and KNOWLEDGE.md first.
[Paste the specific tasks for this wave]
```

### Context management rules:
- `/clear` between waves (fresh context per phase)
- Manual `/compact` if context reaches 50%
- Use subagents for research/exploration to keep main context clean
- One task per session — never multi-task in a single session
- Set `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` to save tokens on subagent work

### Gate: All waves committed, `npm run build` passes, app is functional.

---

## Phase 4: DEPLOY + QA
**Deliverable:** Live URL with zero P0 bugs
**Time:** 1-2 hours
**Who:** Coolify auto-deploy + Comet browser (or separate Claude session)

### Deploy:
```bash
git push  # Coolify auto-deploys from GitHub
```

### QA — Use a DIFFERENT AI tool than the one that built it:
Open Comet (Perplexity), a fresh Claude session, or any browser agent and paste:

```
You are a senior QA engineer. Test https://[your-url] systematically:

Login with: [email] / [password]

Test in this order:
1. Auth: Login → use app → sign out → sign back in
2. Every CRUD path: Create, read, update, delete on each entity
3. Empty states: What does each page show with zero data?
4. Error paths: Bad form data, nonexistent URLs, edge cases
5. Mobile: Test at 393px width — navigation, button overflow, readability
6. Performance: Page load times, image sizes

Categorize every issue as:
- P0: Broken, blocks usage
- P1: Wrong behavior but usable
- P2: Polish/cosmetic
- P3: Nice to have

Output a single Claude Code prompt that fixes all P0s and P1s.
```

### Fix cycle:
1. Paste the QA prompt output into Claude Code
2. Push fixes
3. Re-run QA audit
4. Repeat until zero P0s

### Gate: Zero P0 bugs on the live URL.

---

## Phase 5: BRAND ALIGNMENT
**Deliverable:** Pixel-perfect brand match with client's identity
**Time:** 30-60 minutes
**Who:** Comet comparison + Claude Code

### The Two-Site Comparison:
Open a browser agent with both sites and paste:

```
You are a senior UI designer. Compare these two sites:
TAB 1: [client's official website]
TAB 2: [your portal URL] (login: [credentials])

For each inconsistency, give me:
- What the official site has (exact hex colors, font names, sizes)
- What the portal has
- The exact CSS/Tailwind fix
- Priority (high/medium/low)

End with a single Claude Code prompt to apply all high-priority fixes.
```

### Apply:
1. Paste the generated Claude Code prompt
2. Handle logo separately (download/convert/recolor if needed)
3. Push
4. Visual verification on live URL

### Important: CSS extraction alone is insufficient. Always do a visual comparison after applying changes.

### Gate: Portal visually matches client's brand identity.

---

## Phase 6: DELIVER
**Deliverable:** Client says yes
**Time:** 30 minutes
**Who:** You (human)

### Before the meeting:
- [ ] Change default password (never share credentials from chat history)
- [ ] Take desktop screenshot of the login page
- [ ] Take mobile screenshot
- [ ] Send WhatsApp: screenshots + link + "when can we walk through this?"
- [ ] Do NOT send credentials — save for the call

### The demo (5 minutes, no slides):
1. Login page — they see their brand
2. Dashboard — real KPIs
3. The one feature that solves their biggest pain point — full workflow
4. Pull it up on THEIR phone — hand it to them
5. Say the price once, confidently. Then stop talking.

### Pricing framework:
- Setup: Based on complexity and client's revenue context
- Monthly: $200-$300/month for hosting + support + updates
- Never go below a floor that signals quality
- The monthly retainer is where the real money is long-term

---

## After Every Project

### Extract and push skills:
Any reusable pattern discovered during the build should become a skill:
```bash
# Create the skill
mkdir -p ~/.claude/skills/[skill-name]
# Write SKILL.md with the pattern
# Push to the repo
cd ~/claude-skills && git add -A && git commit -m "skill: [name]" && git push
```

### Update this workflow:
If you discovered a better process, update WORKFLOW.md. The workflow itself is a living document.

---

## Quick Reference

| Phase | Deliverable | Tool | Time |
|-------|-------------|------|------|
| 1. Specify | SPEC.md | Claude chat | 30-60min |
| 2. Architect | CLAUDE.md + schema + KNOWLEDGE.md | Claude chat → Code | 30-60min |
| 3. Implement | Working code (wave commits) | Claude Code | 2-8hrs |
| 4. Deploy + QA | Live URL, zero P0s | Coolify + Comet | 1-2hrs |
| 5. Brand | Brand-aligned UI | Comet + Claude Code | 30-60min |
| 6. Deliver | Client says yes | You (human) | 30min |

**Total: One focused day for an MVP. Every time.**
