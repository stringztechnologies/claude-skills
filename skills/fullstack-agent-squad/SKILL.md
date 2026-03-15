---
name: fullstack-agent-squad
description: "Agent orchestration patterns for full-stack projects using SuperClaude /sc: commands and agent personas. Defines how to decompose features into parallel agent tasks with dependency ordering, map domain skills to agent roles (@backend-architect, @frontend-architect, @security-engineer, @quality-engineer, @devops), coordinate Wave→Checkpoint→Wave execution, and maintain persistent session memory via KNOWLEDGE.md. Use this skill whenever /sc:spawn or /sc:task is called on a full-stack feature, when breaking work into multi-agent subtasks, when setting up a new project CLAUDE.md with agent routing, or when coordinating parallel backend + frontend + security + testing workflows."
---

# Full-Stack Agent Squad Orchestration

## 1. Agent Role → Skill Mapping

### @agent-backend-architect

**Reads skills:**
- `supabase-nextjs-fullstack` — Server Actions pattern (validate→admin client→revalidatePath), createServerClient/createAdminClient setup, RLS policy syntax
- `multi-currency-ledger` — billing_periods + payments schema, balance update trigger, overdue detection, currency formatting, billing auto-generation
- `property-management-core` — buildings→units→leases→tenants schema, unit status state machine trigger, inventory system (checks + check_items), dashboard KPI queries
- `notification-queue` — notification_templates + schedules + log schema, daily queue generation function, template rendering

**Owns:** Database migrations, Postgres functions/triggers, Server Actions, Zod validation schemas, Edge Functions, cron jobs.

**Output format:** SQL migration files + TypeScript Server Action files + Zod schema files.

### @agent-frontend-architect

**Reads skills:**
- `mobile-first-dashboard` — BottomNav, Sidebar, AppShell layout, KPI cards (2x2 grid, alert variant), ActionQueue, MobileSheet (side="bottom" h-[85vh]), FAB, StatusBadge, ResponsiveList (table→card transform), PhotoCapture with compressorjs
- `supabase-nextjs-fullstack` — Client component patterns, camera capture input (`capture="environment"`), createBrowserClient usage

**Owns:** React components, page.tsx files, layout.tsx files, Tailwind styling, client-side interactivity, loading.tsx skeletons.

**Output format:** TSX component files following mobile-first-dashboard patterns. Server Components for data, Client Components only for interactivity.

### @agent-security-engineer

**Reads skills:**
- `supabase-nextjs-fullstack` — Auth middleware.ts (getUser not getSession), RLS with `(SELECT auth.uid())` optimization, env var rules (NEXT_PUBLIC_ only for URL+anon), service role isolation

**Owns:** RLS policy review, auth flow validation, input validation audit (Zod schemas complete?), CORS configuration, env var security, permission checks.

**Output format:** SQL RLS policies + security review checklist + recommended fixes.

**Special power:** Can VETO any agent's output on security grounds and force revision.

### @agent-quality-engineer

**Reads skills:** All skills as needed for the feature under review.

**Owns:** Edge case identification, validation logic review, mobile responsiveness checks, integration test scenarios, cross-browser verification.

**Output format:** Test scenarios document + identified edge cases + UX issues list. Reviews after each Story completes.

### @agent-devops

**Reads skills:**
- `supabase-nextjs-fullstack` — env var configuration, deployment patterns

**Owns:** Coolify/Docker deployment, CI/CD pipeline, Supabase project setup (storage buckets, Edge Function deploy, pg_cron), domain configuration, SSL.

**Output format:** Dockerfile/docker-compose updates + CI config + deployment checklist.

---

## 2. Feature Decomposition Template

When `/sc:spawn` or `/sc:task` is called with a full-stack feature:

```
Epic: [Feature Name]
│
├── Story: Schema & Backend (@agent-backend-architect)
│   Skills loaded: [relevant skills from mapping above]
│   ├── Task: Database migration (tables, indexes, constraints)
│   ├── Task: Postgres functions/triggers
│   ├── Task: Zod validation schemas
│   └── Task: Server Actions (CRUD operations)
│
├── Story: Frontend UI (@agent-frontend-architect) [depends on Schema]
│   Skills loaded: [relevant skills from mapping above]
│   ├── Task: Page component (Server Component for data fetching)
│   ├── Task: Interactive components (Client Components for forms/modals)
│   ├── Task: Mobile-responsive layout (bottom sheet, cards, touch targets)
│   └── Task: Status indicators and feedback (badges, toasts, loading)
│
├── Story: Security Review (@agent-security-engineer) [parallel with Frontend]
│   Skills loaded: supabase-nextjs-fullstack (auth/RLS section)
│   ├── Task: RLS policies for new tables
│   ├── Task: Server Action input validation audit
│   └── Task: Auth/permission checks
│
└── Story: Quality Review (@agent-quality-engineer) [depends on all]
    ├── Task: Edge case testing scenarios
    ├── Task: Mobile UX verification (touch targets, thumb zone)
    └── Task: Data integrity checks
```

---

## 3. Execution Strategy — Wave → Checkpoint → Wave

```
Wave 1 (parallel):
  ├── @agent-backend-architect: Schema migration + Postgres functions + Zod schemas
  └── @agent-security-engineer: Review existing auth patterns, prepare RLS templates

Checkpoint 1:
  ✓ Migration committed
  ✓ `supabase gen types typescript` run → database.types.ts updated
  ✓ Zod schemas committed
  ✓ RLS policy templates ready

Wave 2 (parallel):
  ├── @agent-backend-architect: Server Actions using committed Zod schemas
  ├── @agent-frontend-architect: Pages + components using generated types
  └── @agent-security-engineer: RLS policies for new tables + Server Action audit

Checkpoint 2:
  ✓ Feature functionally complete
  ✓ All Server Actions have Zod validation
  ✓ RLS policies applied
  ✓ UI renders on mobile and desktop

Wave 3:
  └── @agent-quality-engineer: Full review across all outputs
      ├── Edge cases (empty states, error states, boundary values)
      ├── Mobile UX (48px targets, sheet modals, camera capture)
      └── Cross-currency / cross-timezone if applicable

Checkpoint 3:
  ✓ All quality issues resolved
  ✓ KNOWLEDGE.md updated
  ✓ Feature ready for deploy
```

### Dependency Rules

- Frontend MUST NOT start page components until Zod schemas exist (needs types)
- Frontend CAN start layout/shell components in parallel with backend
- Security MUST review RLS before feature ships
- Quality runs LAST — needs complete feature to review
- Each wave can have internal parallelism (multiple backend tasks at once)

---

## 4. Subagent Context Budget

Each spawned subagent receives a minimal, focused context to maximize working capacity:

```
Per subagent budget:
┌─────────────────────────────────┬──────────┐
│ Agent persona charter           │ ~200 tok │
│ Relevant domain skill(s) (1-2) │ ~4K tok  │
│ Project CLAUDE.md               │ ~500 tok │
│ Target files (read before edit) │ ~3K tok  │
│ KNOWLEDGE.md (if exists)        │ ~1K tok  │
├─────────────────────────────────┼──────────┤
│ Total context load              │ <10K tok │
│ Remaining for work              │ 90%+     │
└─────────────────────────────────┴──────────┘
```

**Rules:**
- Never load all 6 skills into one agent — load only mapped skills per role
- Never load full codebase — read only files the agent will modify
- Always include KNOWLEDGE.md for cross-session continuity
- Prefer `Glob` + `Read` target files over broad exploration

---

## 5. Session Memory Protocol

After each feature module completes, append to the project's `KNOWLEDGE.md`:

```markdown
## [Feature Name] - [YYYY-MM-DD]

### Decisions
- [What was decided and why]
- [Alternative considered and why rejected]

### Conventions Established
- [Naming patterns, e.g., "billing periods use `label` not `name`"]
- [File locations, e.g., "Server Actions in app/(dashboard)/[feature]/actions.ts"]
- [Component patterns, e.g., "all forms use MobileSheet on mobile"]

### Learnings
- [What worked well]
- [What needed revision and why]

### Agent Notes
- Backend: [schema choices, trigger trade-offs, function design]
- Frontend: [component hierarchy, state management approach]
- Security: [RLS decisions, concerns flagged, mitigations applied]
- Quality: [edge cases found, UX issues identified]
```

**Why this matters:**
- Session 1 builds Tenants → establishes naming conventions
- Session 2 builds Payments → reads KNOWLEDGE.md, follows same patterns
- Session 5 builds Notifications → has full history of all decisions
- New team member's first session → reads KNOWLEDGE.md, understands everything
- New sessions always start by reading KNOWLEDGE.md

---

## 6. Conflict Resolution Protocol

When agents produce conflicting outputs:

| Conflict Type | Priority Agent | Resolution |
|---|---|---|
| Schema/data model | @agent-backend-architect | Backend owns data truth |
| UI/UX pattern | @agent-frontend-architect | Frontend owns user experience |
| Security concern | @agent-security-engineer | **VETO power** — can force revision |
| Performance trade-off | Whoever owns the layer | Discuss if cross-cutting |
| Naming convention | First agent to establish | Documented in KNOWLEDGE.md |

**Process:**
1. @agent-quality-engineer flags the mismatch
2. Priority agent makes the call
3. @agent-security-engineer can override ANY decision on security grounds
4. Resolution documented in KNOWLEDGE.md with reasoning

---

## 7. Example: Spawning "Payments Module"

```
/sc:spawn "build the payments module for property management app"
```

### Decomposition

```
Epic: Payments Module
│
├── Story: Schema & Backend (@agent-backend-architect)
│   Skills: supabase-nextjs-fullstack, multi-currency-ledger
│   ├── Task: billing_periods + payments + receiving_accounts migration
│   │   File: supabase/migrations/00X_payments.sql
│   ├── Task: update_billing_period_totals trigger
│   │   File: (same migration)
│   ├── Task: detect_overdue_billing_periods cron function
│   │   File: (same migration)
│   ├── Task: generate_billing_periods auto-generation function
│   │   File: (same migration)
│   ├── Task: Zod schemas (recordPaymentSchema, createBillingPeriodSchema)
│   │   File: src/lib/schemas/billing.ts
│   └── Task: Server Actions (recordPayment, getBillingPeriods, getOverdue)
│       File: src/app/(dashboard)/billing/actions.ts
│
├── Story: Frontend UI (@agent-frontend-architect) [after Wave 1]
│   Skills: mobile-first-dashboard, multi-currency-ledger (formatCurrency)
│   ├── Task: Rent ledger page (billing period cards + nested payment list)
│   │   File: src/app/(dashboard)/billing/page.tsx
│   ├── Task: Record payment MobileSheet (currency selector, method chips)
│   │   File: src/components/billing/RecordPaymentSheet.tsx
│   ├── Task: Overdue ActionQueue component
│   │   File: src/components/billing/OverdueList.tsx
│   ├── Task: Payment KPI cards (revenue, outstanding, overdue count)
│   │   File: src/components/dashboard/PaymentKPIs.tsx
│   └── Task: All-building overview with currency filter
│       File: src/app/(dashboard)/billing/overview/page.tsx
│
├── Story: Security (@agent-security-engineer) [parallel with Wave 2]
│   Skills: supabase-nextjs-fullstack (auth/RLS section)
│   ├── Task: RLS for billing_periods (org-scoped read, admin write)
│   ├── Task: RLS for payments (org-scoped, no delete policy)
│   └── Task: Server Action audit (Zod validation complete? Admin client justified?)
│
└── Story: Quality (@agent-quality-engineer) [Wave 3]
    ├── Task: Partial payment → full payment transition
    ├── Task: Cross-currency with exchange rate (ETB→USD)
    ├── Task: Zero/negative amount rejection
    ├── Task: Overpayment handling
    └── Task: Mobile sheet form on 320px screen
```

### Wave Execution

```
Wave 1:
  @agent-backend-architect → migration + triggers + Zod schemas
  @agent-security-engineer → review existing auth, draft RLS templates

Checkpoint 1: ✓ supabase gen types, schemas committed

Wave 2:
  @agent-backend-architect → Server Actions
  @agent-frontend-architect → ledger page, payment sheet, KPI cards
  @agent-security-engineer → RLS policies, action audit

Checkpoint 2: ✓ Feature complete, all policies applied

Wave 3:
  @agent-quality-engineer → edge cases, mobile UX, currency edge cases

Checkpoint 3: ✓ KNOWLEDGE.md updated, ready to ship
```

---

## 8. Project CLAUDE.md Agent Routing Template

Add this to any new project's `CLAUDE.md` to enable automatic agent routing:

```markdown
## Agent Routing

When spawning subagents for features, use fullstack-agent-squad skill for:
- Feature decomposition into Epic → Story → Task
- Agent-to-skill mapping
- Wave execution ordering
- Post-feature KNOWLEDGE.md updates

### Role Assignments
- Schema/migration/triggers → @agent-backend-architect + supabase-nextjs-fullstack + [domain skills]
- React components/pages → @agent-frontend-architect + mobile-first-dashboard
- Auth/RLS/security → @agent-security-engineer + supabase-nextjs-fullstack
- After each module → @agent-quality-engineer reviews all outputs
- Deployment → @agent-devops

### Active Skills
- supabase-nextjs-fullstack (backend + frontend patterns)
- multi-currency-ledger (financial logic)
- property-management-core (domain model)
- notification-queue (messaging system)
- mobile-first-dashboard (UI components)
- fullstack-agent-squad (this orchestration layer)

## Session Memory
Maintain KNOWLEDGE.md at project root. Read at session start. Append after each module completes.
```
