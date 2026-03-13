---
name: notification-queue
description: "Patterns for building scheduled, multi-channel notification and reminder systems with templated messages, escalation tiers, and manual-first workflows. Use this skill for rent reminders, payment follow-ups, appointment reminders, subscription renewals, invoice follow-ups, or any recurring outreach across SMS, email, WhatsApp, or phone. Also for configurable reminder schedules, per-recipient channel preferences, notification logging, AI-generated message personalization, or n8n automation workflows."
---

# Notification Queue Patterns

## Schema

### Templates

```sql
CREATE TABLE notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  channel TEXT NOT NULL
    CHECK (channel IN ('sms', 'email', 'whatsapp', 'phone')),
  subject TEXT,
  body TEXT NOT NULL,
  escalation_tier TEXT DEFAULT 'friendly'
    CHECK (escalation_tier IN ('friendly', 'neutral', 'firm', 'formal')),
  language TEXT DEFAULT 'en',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Schedules

```sql
CREATE TABLE notification_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  template_id UUID NOT NULL REFERENCES notification_templates(id),
  trigger_type TEXT NOT NULL
    CHECK (trigger_type IN ('days_before_due', 'days_after_due', 'on_due_date', 'manual')),
  trigger_days INT DEFAULT 0,
  escalation_tier TEXT DEFAULT 'friendly',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Notification Log

```sql
CREATE TABLE notification_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id UUID REFERENCES notification_schedules(id),
  template_id UUID REFERENCES notification_templates(id),
  recipient_id UUID NOT NULL,
  recipient_type TEXT DEFAULT 'tenant',
  channel TEXT NOT NULL,
  recipient_address TEXT NOT NULL,
  subject TEXT,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'copied', 'sent', 'delivered', 'failed', 'skipped')),
  sent_at TIMESTAMPTZ,
  sent_by UUID REFERENCES auth.users(id),
  billing_period_id UUID,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notif_log_status ON notification_log(status, created_at);
CREATE INDEX idx_notif_log_recipient ON notification_log(recipient_id, created_at DESC);
```

## Template Rendering

```typescript
export const renderTemplate = (
  template: string,
  variables: Record<string, string | number>
): string =>
  template.replace(/\{\{(\w+)\}\}/g, (_, key) =>
    String(variables[key] ?? `{{${key}}}`)
  );

// renderTemplate("Hi {{name}}, rent of {{amount}} due {{date}}", {
//   name: "Sarah", amount: "$1,500", date: "March 1"
// })
```

## Escalation Tier Templates

```sql
INSERT INTO notification_templates (name, channel, body, escalation_tier) VALUES
('rent_friendly_sms', 'sms',
 'Hi {{tenant_name}}, a friendly reminder that your rent of {{amount}} for {{unit}} is due on {{due_date}}. Let us know if you have any questions!',
 'friendly'),
('rent_neutral_sms', 'sms',
 'Hello {{tenant_name}}, your rent payment of {{amount}} for {{unit}} is due today ({{due_date}}). Please arrange payment at your convenience.',
 'neutral'),
('rent_firm_sms', 'sms',
 'Dear {{tenant_name}}, your rent of {{amount}} for {{unit}} was due on {{due_date}} and remains unpaid. Please make your payment as soon as possible to avoid further action.',
 'firm'),
('rent_formal_email', 'email',
 'Dear {{tenant_name}},

This is a formal notice regarding your outstanding rent payment of {{amount}} for unit {{unit}}, which was due on {{due_date}}.

Please arrange immediate payment. If you are experiencing difficulties, contact our office to discuss arrangements.

Regards,
{{sender_name}}',
 'formal');
```

## Daily Queue Generation with Dedup

```sql
CREATE OR REPLACE FUNCTION generate_daily_notifications()
RETURNS INT AS $$
DECLARE
  inserted INT := 0;
BEGIN
  INSERT INTO notification_log (
    schedule_id, template_id, recipient_id, channel,
    recipient_address, subject, body, billing_period_id
  )
  SELECT
    ns.id, ns.template_id, t.id,
    COALESCE(t.preferred_contact, nt.channel),
    CASE COALESCE(t.preferred_contact, nt.channel)
      WHEN 'email' THEN t.email
      WHEN 'whatsapp' THEN t.phone
      ELSE t.phone
    END,
    nt.subject, nt.body, bp.id
  FROM notification_schedules ns
  JOIN notification_templates nt ON nt.id = ns.template_id
  JOIN billing_periods bp ON
    CASE ns.trigger_type
      WHEN 'days_before_due' THEN bp.due_date - ns.trigger_days = CURRENT_DATE
      WHEN 'on_due_date' THEN bp.due_date = CURRENT_DATE
      WHEN 'days_after_due' THEN bp.due_date + ns.trigger_days = CURRENT_DATE
    END
  JOIN leases l ON l.id = bp.lease_id AND l.status = 'active'
  JOIN tenants t ON t.id = l.tenant_id
  WHERE ns.is_active
    AND bp.status IN ('unpaid', 'partial')
    AND NOT EXISTS (
      SELECT 1 FROM notification_log nl
      WHERE nl.billing_period_id = bp.id
        AND nl.schedule_id = ns.id
        AND nl.created_at::date = CURRENT_DATE
    );

  GET DIAGNOSTICS inserted = ROW_COUNT;
  RETURN inserted;
END;
$$ LANGUAGE plpgsql;
```

## Manual-First Workflow

```
Queue -> Review -> Copy Message -> Send via WhatsApp/SMS -> Mark Sent
```

### Queue UI

```typescript
const TIER_COLORS = {
  friendly: "bg-blue-100 text-blue-800",
  neutral: "bg-gray-100 text-gray-800",
  firm: "bg-amber-100 text-amber-800",
  formal: "bg-rose-100 text-rose-800",
};

const NotificationQueue = ({ items }: { items: QueueItem[] }) => (
  <div className="space-y-3">
    <h2 className="text-lg font-semibold">Today's Notifications</h2>
    {items.map((item) => (
      <div key={item.id} className="p-4 border rounded-lg space-y-2">
        <div className="flex items-center justify-between">
          <div>
            <p className="font-medium">{item.tenant_name}</p>
            <p className="text-sm text-muted-foreground">
              {item.unit_number} · {item.channel} · {item.recipient_address}
            </p>
          </div>
          <span className={`px-2 py-0.5 rounded-full text-xs ${TIER_COLORS[item.escalation_tier]}`}>
            {item.escalation_tier}
          </span>
        </div>
        <p className="text-sm bg-muted p-2 rounded">{item.body}</p>
        <div className="flex gap-2">
          <button
            onClick={() => { navigator.clipboard.writeText(item.body); updateStatus(item.id, "copied"); }}
            className="px-3 py-1.5 text-sm bg-primary text-primary-foreground rounded-lg"
          >Copy</button>
          <button
            onClick={() => updateStatus(item.id, "sent")}
            className="px-3 py-1.5 text-sm border rounded-lg"
          >Mark Sent</button>
          <button
            onClick={() => updateStatus(item.id, "skipped")}
            className="px-3 py-1.5 text-sm text-muted-foreground border rounded-lg"
          >Skip</button>
        </div>
      </div>
    ))}
  </div>
);
```

## AI Message Generation

```typescript
const generatePersonalizedMessage = async (context: {
  tenant_name: string;
  amount: string;
  unit: string;
  due_date: string;
  days_overdue: number;
  payment_history: string;
  tier: "friendly" | "neutral" | "firm" | "formal";
}) => {
  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-6",
    max_tokens: 300,
    messages: [{
      role: "user",
      content: `Write a ${context.tier} rent reminder SMS (under 160 chars) for:
- Tenant: ${context.tenant_name}
- Amount: ${context.amount} for ${context.unit}
- Due: ${context.due_date} (${context.days_overdue} days overdue)
- History: ${context.payment_history}

Tone: friendly=warm casual, neutral=professional, firm=direct urgent, formal=official notice.
Return only the message text.`,
    }],
  });

  return response.content[0].text;
};
```

## n8n Workflow Pattern

```
Cron (8am) -> Query Supabase (due today) -> Render Templates -> Insert notification_log -> Summary Email to admin
```

```json
{
  "cron": { "trigger": "0 8 * * *" },
  "supabase_query": {
    "operation": "executeQuery",
    "query": "SELECT * FROM generate_daily_notifications()"
  },
  "render": {
    "code": "for (const item of $input.all()) { item.json.rendered_body = item.json.body.replace(/\\{\\{(\\w+)\\}\\}/g, (_, k) => item.json.variables[k] || ''); }; return $input.all();"
  },
  "admin_summary": {
    "to": "admin@property.com",
    "subject": "Daily Queue: {{$items.length}} messages"
  }
}
```
