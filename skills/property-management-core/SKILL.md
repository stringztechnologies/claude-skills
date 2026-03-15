---
name: property-management-core
description: "Data models, business logic, and UI patterns for residential property management, serviced apartments, and hospitality. Use this skill when building any system that manages buildings, units, tenants, leases, rent collection, or move-in/move-out inventory. Covers full lifecycle from unit setup through tenant onboarding, lease management, occupancy tracking, inventory checks with photo evidence, and dashboard KPIs. Trigger for property management, apartment management, tenant tracking, lease management, unit status, occupancy rates, move-in checklists, move-out inspection, inventory condition reports, or building management dashboards."
---

# Property Management Core Patterns

## Schema

### Buildings

```sql
CREATE TABLE buildings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  country TEXT DEFAULT 'ET',
  total_units INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Units

```sql
CREATE TABLE units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  building_id UUID NOT NULL REFERENCES buildings(id),
  unit_number TEXT NOT NULL,
  floor INT,
  bedrooms INT DEFAULT 1,
  bathrooms NUMERIC(2,1) DEFAULT 1,
  size_sqm NUMERIC(8,2),
  base_rent NUMERIC(12,2),
  currency TEXT DEFAULT 'USD',
  status TEXT NOT NULL DEFAULT 'vacant'
    CHECK (status IN ('vacant', 'occupied', 'maintenance', 'reserved')),
  furnishing TEXT DEFAULT 'furnished'
    CHECK (furnishing IN ('furnished', 'unfurnished', 'semi-furnished')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(building_id, unit_number)
);

CREATE INDEX idx_units_building ON units(building_id);
CREATE INDEX idx_units_status ON units(status);
```

### Unit Status State Machine Trigger

```sql
CREATE OR REPLACE FUNCTION update_unit_status()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.status = 'active') THEN
    UPDATE units SET status = 'occupied', updated_at = now()
    WHERE id = NEW.unit_id;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.status IN ('terminated', 'expired') THEN
    IF NOT EXISTS (
      SELECT 1 FROM leases
      WHERE unit_id = NEW.unit_id AND status = 'active' AND id != NEW.id
    ) THEN
      UPDATE units SET status = 'vacant', updated_at = now()
      WHERE id = NEW.unit_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_unit_status
AFTER INSERT OR UPDATE ON leases
FOR EACH ROW EXECUTE FUNCTION update_unit_status();
```

### Tenants

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,                          -- E.164: +251911234567
  nationality TEXT,                    -- ISO 3166-1 alpha-2
  organization TEXT,
  passport_number TEXT,
  diplomatic_id TEXT,
  id_document_url TEXT,
  preferred_contact TEXT DEFAULT 'phone'
    CHECK (preferred_contact IN ('phone', 'email', 'whatsapp', 'sms')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### Leases

```sql
CREATE TABLE leases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES units(id),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  payer_type TEXT DEFAULT 'tenant'
    CHECK (payer_type IN ('tenant', 'organization', 'third_party')),
  payer_name TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  rent_amount NUMERIC(12,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  payment_day INT DEFAULT 1,
  deposit_amount NUMERIC(12,2),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('draft', 'active', 'expired', 'terminated')),
  contract_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_leases_unit ON leases(unit_id);
CREATE INDEX idx_leases_tenant ON leases(tenant_id);
CREATE INDEX idx_leases_status ON leases(status);
```

## Inventory System

### Items Master List

```sql
CREATE TABLE inventory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES units(id),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  room TEXT,
  quantity INT DEFAULT 1,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Inventory Checks

```sql
CREATE TABLE inventory_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES units(id),
  lease_id UUID REFERENCES leases(id),
  check_type TEXT NOT NULL CHECK (check_type IN ('move_in', 'move_out', 'routine')),
  checked_by UUID REFERENCES auth.users(id),
  checked_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT,
  status TEXT DEFAULT 'in_progress'
    CHECK (status IN ('in_progress', 'completed', 'signed'))
);

CREATE TABLE inventory_check_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  check_id UUID NOT NULL REFERENCES inventory_checks(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES inventory_items(id),
  condition TEXT NOT NULL
    CHECK (condition IN ('excellent', 'good', 'fair', 'poor', 'missing', 'new')),
  photo_urls JSONB DEFAULT '[]'::jsonb,
  notes TEXT
);
```

### Move-In vs Move-Out Comparison

```sql
SELECT
  ii.name AS item, ii.room,
  mi.condition AS move_in_condition,
  mo.condition AS move_out_condition,
  CASE
    WHEN mi.condition = mo.condition THEN 'unchanged'
    WHEN mo.condition = 'missing' THEN 'missing'
    WHEN mo.condition IN ('poor', 'fair') AND mi.condition IN ('excellent', 'good') THEN 'damaged'
    ELSE 'changed'
  END AS diff_status,
  mi.photo_urls AS move_in_photos,
  mo.photo_urls AS move_out_photos
FROM inventory_items ii
LEFT JOIN inventory_check_items mi ON mi.item_id = ii.id
  AND mi.check_id = (
    SELECT id FROM inventory_checks
    WHERE unit_id = $1 AND check_type = 'move_in' AND lease_id = $2
    ORDER BY checked_at DESC LIMIT 1
  )
LEFT JOIN inventory_check_items mo ON mo.item_id = ii.id
  AND mo.check_id = (
    SELECT id FROM inventory_checks
    WHERE unit_id = $1 AND check_type = 'move_out' AND lease_id = $2
    ORDER BY checked_at DESC LIMIT 1
  )
WHERE ii.unit_id = $1
ORDER BY ii.room, ii.name;
```

## Inventory Wizard UX

```typescript
// Step-through wizard for mobile inventory checks
// 1. Select check type (move_in / move_out / routine)
// 2. For each room, show items as cards
// 3. Per item: tap condition badge -> take photos -> optional notes
// 4. Review summary -> sign off

const CONDITION_BADGES = [
  { value: "excellent", label: "Excellent", color: "bg-emerald-100 text-emerald-800" },
  { value: "good", label: "Good", color: "bg-blue-100 text-blue-800" },
  { value: "fair", label: "Fair", color: "bg-amber-100 text-amber-800" },
  { value: "poor", label: "Poor", color: "bg-rose-100 text-rose-800" },
  { value: "missing", label: "Missing", color: "bg-gray-100 text-gray-800" },
] as const;

// Room navigation: horizontal scroll tabs at top
// Item cards: condition badges as tappable chips, photo grid below
// Progress: "3/12 items checked" with progress bar
```

## Dashboard KPIs

```sql
-- Occupancy rate
SELECT
  b.name AS building,
  COUNT(*) AS total_units,
  COUNT(*) FILTER (WHERE u.status = 'occupied') AS occupied,
  ROUND(COUNT(*) FILTER (WHERE u.status = 'occupied')::NUMERIC / COUNT(*) * 100, 1) AS occupancy_pct
FROM units u
JOIN buildings b ON b.id = u.building_id
GROUP BY b.id, b.name;

-- Revenue this month
SELECT currency,
  SUM(amount_paid) AS collected,
  SUM(amount_due) AS expected,
  SUM(amount_due - amount_paid) AS outstanding
FROM billing_periods
WHERE due_date >= DATE_TRUNC('month', CURRENT_DATE)
  AND due_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
GROUP BY currency;

-- Expiring leases (next 60 days)
SELECT t.full_name, u.unit_number, b.name AS building,
  l.end_date, l.end_date - CURRENT_DATE AS days_remaining
FROM leases l
JOIN tenants t ON t.id = l.tenant_id
JOIN units u ON u.id = l.unit_id
JOIN buildings b ON b.id = u.building_id
WHERE l.status = 'active'
  AND l.end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '60 days'
ORDER BY l.end_date;

-- Action queue
SELECT * FROM (
  SELECT 'overdue' AS type, unit_number, label AS detail, due_date AS action_date
  FROM billing_periods bp JOIN units u ON u.id = bp.unit_id
  WHERE status IN ('unpaid', 'partial') AND due_date < CURRENT_DATE
  UNION ALL
  SELECT 'expiring_lease', u.unit_number, t.full_name, l.end_date
  FROM leases l JOIN units u ON u.id = l.unit_id JOIN tenants t ON t.id = l.tenant_id
  WHERE l.status = 'active' AND l.end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
  UNION ALL
  SELECT 'maintenance', unit_number, notes, updated_at::date
  FROM units WHERE status = 'maintenance'
) actions ORDER BY action_date;
```

## Unit Grid Visualization

```typescript
const STATUS_COLORS = {
  occupied: "bg-emerald-100 border-emerald-300 text-emerald-800",
  vacant: "bg-gray-100 border-gray-300 text-gray-600",
  maintenance: "bg-amber-100 border-amber-300 text-amber-800",
  reserved: "bg-blue-100 border-blue-300 text-blue-800",
} as const;

const UnitGrid = ({ units }: { units: Unit[] }) => (
  <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-2">
    {units.map((unit) => (
      <button
        key={unit.id}
        className={`p-3 rounded-lg border-2 text-center transition-colors ${STATUS_COLORS[unit.status]}`}
      >
        <p className="font-bold text-sm">{unit.unit_number}</p>
        <p className="text-xs capitalize">{unit.status}</p>
      </button>
    ))}
  </div>
);
```
