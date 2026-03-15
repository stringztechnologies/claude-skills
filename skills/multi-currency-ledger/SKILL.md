---
name: multi-currency-ledger
description: "Schema patterns and business logic for any app that tracks financial transactions across multiple currencies with partial payments, exchange rates, and flexible payment methods. Use this skill when building invoicing, rent collection, payment tracking, billing cycles, subscription billing, or any multi-currency financial ledger. Also use for partial payment tracking, payment reconciliation across bank accounts, overdue detection, or denormalized balance calculations with Postgres triggers."
---

# Multi-Currency Ledger Patterns

## Core Schema

### Billing Periods (what's owed)

```sql
CREATE TABLE billing_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES units(id),
  lease_id UUID REFERENCES leases(id),
  label TEXT NOT NULL,
  amount_due NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  due_date DATE NOT NULL,
  amount_paid NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'unpaid'
    CHECK (status IN ('unpaid', 'partial', 'paid', 'overpaid', 'void')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_billing_periods_due ON billing_periods(due_date, status);
CREATE INDEX idx_billing_periods_unit ON billing_periods(unit_id, due_date DESC);
```

### Payments (what's been received)

```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  billing_period_id UUID NOT NULL REFERENCES billing_periods(id),
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL,
  exchange_rate NUMERIC(12,6) DEFAULT 1,
  amount_in_billing_currency NUMERIC(12,2) NOT NULL,
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method TEXT NOT NULL,
  receiving_account_id UUID REFERENCES receiving_accounts(id),
  reference TEXT,
  notes TEXT,
  recorded_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_payments_billing ON payments(billing_period_id);
CREATE INDEX idx_payments_date ON payments(payment_date DESC);
```

### Receiving Accounts

```sql
CREATE TABLE receiving_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  account_type TEXT NOT NULL,
  currency TEXT NOT NULL,
  details JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

## Auto-Update Trigger

```sql
CREATE OR REPLACE FUNCTION update_billing_period_totals()
RETURNS TRIGGER AS $$
DECLARE
  total NUMERIC(12,2);
  due NUMERIC(12,2);
BEGIN
  SELECT COALESCE(SUM(amount_in_billing_currency), 0) INTO total
  FROM payments
  WHERE billing_period_id = COALESCE(NEW.billing_period_id, OLD.billing_period_id);

  SELECT amount_due INTO due
  FROM billing_periods
  WHERE id = COALESCE(NEW.billing_period_id, OLD.billing_period_id);

  UPDATE billing_periods SET
    amount_paid = total,
    status = CASE
      WHEN total = 0 THEN 'unpaid'
      WHEN total < due THEN 'partial'
      WHEN total = due THEN 'paid'
      WHEN total > due THEN 'overpaid'
    END,
    updated_at = now()
  WHERE id = COALESCE(NEW.billing_period_id, OLD.billing_period_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payment_totals
AFTER INSERT OR UPDATE OR DELETE ON payments
FOR EACH ROW EXECUTE FUNCTION update_billing_period_totals();
```

## Overdue Detection Cron

```sql
CREATE OR REPLACE FUNCTION detect_overdue_billing_periods()
RETURNS void AS $$
BEGIN
  UPDATE billing_periods
  SET status = CASE
    WHEN amount_paid > 0 THEN 'partial'
    ELSE 'unpaid'
  END
  WHERE due_date < CURRENT_DATE
    AND status IN ('unpaid', 'partial')
    AND amount_paid < amount_due;
END;
$$ LANGUAGE plpgsql;
```

## Billing Period Auto-Generation

```sql
CREATE OR REPLACE FUNCTION generate_billing_periods(
  p_lease_id UUID,
  p_start_date DATE,
  p_end_date DATE,
  p_amount NUMERIC,
  p_currency TEXT,
  p_day_of_month INT DEFAULT 1
)
RETURNS SETOF billing_periods AS $$
DECLARE
  curr DATE := p_start_date;
  unit UUID;
BEGIN
  SELECT unit_id INTO unit FROM leases WHERE id = p_lease_id;

  WHILE curr <= p_end_date LOOP
    RETURN QUERY
    INSERT INTO billing_periods (unit_id, lease_id, label, amount_due, currency, due_date)
    VALUES (
      unit, p_lease_id,
      TO_CHAR(curr, 'Month YYYY'),
      p_amount, p_currency,
      DATE_TRUNC('month', curr) + (p_day_of_month - 1) * INTERVAL '1 day'
    )
    RETURNING *;
    curr := curr + INTERVAL '1 month';
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

## Cross-Currency Payment

```typescript
const recordCrossCurrencyPayment = async (
  supabase: SupabaseClient,
  billingPeriodId: string,
  amount: number,
  paymentCurrency: string,
  exchangeRate: number,
  method: string,
  accountId?: string
) => {
  const amountInBillingCurrency = Math.round(amount * exchangeRate * 100) / 100;

  const { data, error } = await supabase.from("payments").insert({
    billing_period_id: billingPeriodId,
    amount,
    currency: paymentCurrency,
    exchange_rate: exchangeRate,
    amount_in_billing_currency: amountInBillingCurrency,
    payment_method: method,
    receiving_account_id: accountId,
  }).select().single();

  return { data, error };
};
```

## Currency Formatting

```typescript
const CURRENCY_CONFIG: Record<string, { locale: string; decimals: number }> = {
  USD: { locale: "en-US", decimals: 2 },
  ETB: { locale: "am-ET", decimals: 2 },
  EUR: { locale: "de-DE", decimals: 2 },
  GBP: { locale: "en-GB", decimals: 2 },
  KES: { locale: "en-KE", decimals: 2 },
  NGN: { locale: "en-NG", decimals: 2 },
};

export const formatCurrency = (amount: number, currency: string): string => {
  const config = CURRENCY_CONFIG[currency] ?? { locale: "en-US", decimals: 2 };
  return new Intl.NumberFormat(config.locale, {
    style: "currency",
    currency,
    minimumFractionDigits: config.decimals,
    maximumFractionDigits: config.decimals,
  }).format(amount);
};
```

## Payment Method Presets

```typescript
export const PAYMENT_METHODS = [
  { value: "cash", label: "Cash" },
  { value: "zelle", label: "Zelle" },
  { value: "bank_transfer", label: "Bank Transfer" },
  { value: "wise", label: "Wise" },
  { value: "wire", label: "Wire" },
  { value: "telebirr", label: "Telebirr" },
  { value: "cbe_birr", label: "CBE Birr" },
  { value: "mpesa", label: "M-Pesa" },
  { value: "paypal", label: "PayPal" },
  { value: "check", label: "Check" },
  { value: "other", label: "Other" },
] as const;

// Render as tappable chips
const PaymentMethodPicker = ({ value, onChange }: {
  value: string;
  onChange: (v: string) => void;
}) => (
  <div className="flex flex-wrap gap-2">
    {PAYMENT_METHODS.map((m) => (
      <button
        key={m.value}
        type="button"
        onClick={() => onChange(m.value)}
        className={`px-3 py-1.5 rounded-full text-sm border transition-colors ${
          value === m.value
            ? "bg-primary text-primary-foreground border-primary"
            : "bg-background hover:bg-muted border-border"
        }`}
      >
        {m.label}
      </button>
    ))}
  </div>
);
```

## Key Queries

### Dashboard Summary

```sql
SELECT
  TO_CHAR(due_date, 'YYYY-MM') AS month,
  currency,
  SUM(amount_due) AS total_due,
  SUM(amount_paid) AS total_paid,
  SUM(amount_due - amount_paid) AS outstanding,
  COUNT(*) FILTER (WHERE status = 'paid') AS paid_count,
  COUNT(*) FILTER (WHERE status IN ('unpaid', 'partial')) AS unpaid_count
FROM billing_periods
WHERE due_date >= DATE_TRUNC('year', CURRENT_DATE)
GROUP BY month, currency
ORDER BY month DESC;
```

### Ledger View (per unit)

```sql
SELECT
  bp.label, bp.amount_due, bp.amount_paid, bp.currency, bp.status, bp.due_date,
  COALESCE(
    json_agg(json_build_object(
      'amount', p.amount, 'currency', p.currency,
      'method', p.payment_method, 'date', p.payment_date,
      'exchange_rate', p.exchange_rate
    )) FILTER (WHERE p.id IS NOT NULL), '[]'::json
  ) AS payments
FROM billing_periods bp
LEFT JOIN payments p ON p.billing_period_id = bp.id
WHERE bp.unit_id = $1
GROUP BY bp.id
ORDER BY bp.due_date DESC;
```

### Outstanding Balances

```sql
SELECT
  u.unit_number, b.name AS building, bp.currency,
  SUM(bp.amount_due - bp.amount_paid) AS balance,
  MIN(bp.due_date) AS oldest_due
FROM billing_periods bp
JOIN units u ON u.id = bp.unit_id
JOIN buildings b ON b.id = u.building_id
WHERE bp.status IN ('unpaid', 'partial')
GROUP BY u.id, u.unit_number, b.name, bp.currency
ORDER BY balance DESC;
```
