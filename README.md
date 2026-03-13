# Claude Code Skills

Reusable Claude Code skills for full-stack development, finance, property management, notifications, and mobile dashboards.

## Skills

### 1. supabase-nextjs-fullstack
Production patterns for Next.js App Router + Supabase full-stack apps — auth, RLS, Server Actions, Storage uploads, Zod validation.

### 2. multi-currency-ledger
Schema patterns and business logic for multi-currency financial transactions with partial payments, exchange rates, and flexible payment methods.

### 3. property-management-core
Data models and UI patterns for residential property management — buildings, units, tenants, leases, inventory checks with photo evidence, dashboard KPIs.

### 4. notification-queue
Scheduled, multi-channel notification system with templated messages, escalation tiers, manual-first workflows, and n8n automation.

### 5. mobile-first-dashboard
Component architecture for phone-first admin dashboards — bottom navigation, sheet modals, KPI cards, action queues, thumb-zone-optimized design.

## Installation

### Claude Code (CLI)

Copy skills to your global skills directory:

```bash
mkdir -p ~/.claude/skills
cp -r supabase-nextjs-fullstack ~/.claude/skills/
cp -r multi-currency-ledger ~/.claude/skills/
cp -r property-management-core ~/.claude/skills/
cp -r notification-queue ~/.claude/skills/
cp -r mobile-first-dashboard ~/.claude/skills/
```

Or install all at once:

```bash
for skill in supabase-nextjs-fullstack multi-currency-ledger property-management-core notification-queue mobile-first-dashboard; do
  cp -r "$skill" ~/.claude/skills/
done
```

### Claude.ai (Web)

Upload the `SKILL.md` file from any skill directory as an attachment in your conversation.

## Usage

Each skill triggers automatically when Claude detects relevant context in your conversation. You can also reference them directly:

- "Use the supabase-nextjs-fullstack skill to set up auth"
- "Follow the multi-currency-ledger patterns for billing"
- "Apply mobile-first-dashboard patterns to this admin panel"

## License

MIT
