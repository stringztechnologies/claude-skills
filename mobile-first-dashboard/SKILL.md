---
name: mobile-first-dashboard
description: "UI patterns and component architecture for admin dashboards primarily used on mobile phones. Use this skill for any operations dashboard, management interface, or admin panel where the primary user is on their phone. Covers bottom navigation, responsive shell, card-based KPIs, action queue patterns, sheet modals for mobile forms, camera capture, status badges, table-to-card-list transforms, and thumb-zone-optimized design. Trigger for mobile-first dashboard, admin panel, bottom navigation, responsive admin layouts, or mobile form patterns."
---

# Mobile-First Dashboard Patterns

## Design Tokens

```css
:root {
  --touch-target: 48px;
  --nav-height: 64px;
  --safe-bottom: env(safe-area-inset-bottom, 0px);
  --content-padding: 16px;
  --card-radius: 12px;
  --sheet-radius: 20px;
}
```

## Layout Shell

```tsx
import { BottomNav } from "./BottomNav";
import { Sidebar } from "./Sidebar";

export const AppShell = ({ children }: { children: React.ReactNode }) => (
  <div className="min-h-screen bg-background">
    <Sidebar />
    <main className="md:ml-64 pb-20 md:pb-0">
      <div className="max-w-4xl mx-auto p-4">{children}</div>
    </main>
    <BottomNav />
  </div>
);
```

## Bottom Navigation

```tsx
"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { Home, Building2, Users, CreditCard, Bell } from "lucide-react";

const NAV_ITEMS = [
  { href: "/dashboard", icon: Home, label: "Home" },
  { href: "/units", icon: Building2, label: "Units" },
  { href: "/tenants", icon: Users, label: "Tenants" },
  { href: "/billing", icon: CreditCard, label: "Billing" },
  { href: "/notifications", icon: Bell, label: "Alerts" },
] as const;

export const BottomNav = () => {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-background border-t md:hidden z-50"
         style={{ paddingBottom: "var(--safe-bottom)" }}>
      <div className="flex items-center justify-around h-16">
        {NAV_ITEMS.map(({ href, icon: Icon, label }) => {
          const isActive = pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className={`flex flex-col items-center justify-center gap-0.5 min-w-[48px] min-h-[48px] rounded-lg transition-colors ${
                isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <Icon className="w-5 h-5" />
              <span className="text-[10px] font-medium">{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
};
```

## Sidebar (Desktop)

```tsx
"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { Home, Building2, Users, CreditCard, Bell, Settings } from "lucide-react";

const SIDEBAR_ITEMS = [
  { href: "/dashboard", icon: Home, label: "Dashboard" },
  { href: "/units", icon: Building2, label: "Units" },
  { href: "/tenants", icon: Users, label: "Tenants" },
  { href: "/billing", icon: CreditCard, label: "Billing" },
  { href: "/notifications", icon: Bell, label: "Notifications" },
  { href: "/settings", icon: Settings, label: "Settings" },
];

export const Sidebar = () => {
  const pathname = usePathname();

  return (
    <aside className="hidden md:flex md:flex-col md:w-64 md:fixed md:inset-y-0 border-r bg-card">
      <div className="p-4 border-b">
        <h1 className="text-lg font-bold">Property Manager</h1>
      </div>
      <nav className="flex-1 p-2 space-y-1">
        {SIDEBAR_ITEMS.map(({ href, icon: Icon, label }) => {
          const isActive = pathname.startsWith(href);
          return (
            <Link key={href} href={href}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                isActive ? "bg-primary/10 text-primary font-medium" : "text-muted-foreground hover:bg-muted"
              }`}>
              <Icon className="w-4 h-4" />{label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
};
```

## KPI Cards

```tsx
interface KPICardProps {
  label: string;
  value: string | number;
  subtitle?: string;
  alert?: boolean;
}

const KPICard = ({ label, value, subtitle, alert }: KPICardProps) => (
  <div className={`p-4 rounded-xl border ${alert ? "border-rose-200 bg-rose-50" : "bg-card"}`}>
    <p className="text-xs text-muted-foreground font-medium uppercase tracking-wide">{label}</p>
    <p className={`text-2xl font-bold mt-1 ${alert ? "text-rose-600" : ""}`}>{value}</p>
    {subtitle && <p className="text-xs text-muted-foreground mt-0.5">{subtitle}</p>}
  </div>
);

// 2x2 grid on mobile, 4-col on desktop
const DashboardKPIs = ({ data }: { data: DashboardData }) => (
  <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
    <KPICard label="Occupancy" value={`${data.occupancy}%`} subtitle={`${data.occupied}/${data.total} units`} />
    <KPICard label="Revenue" value={data.revenue} subtitle="This month" />
    <KPICard label="Outstanding" value={data.outstanding} alert={data.hasOverdue} />
    <KPICard label="Expiring" value={data.expiring} subtitle="Next 30 days" />
  </div>
);
```

## Action Queue

```tsx
import { ChevronRight } from "lucide-react";

const ACTION_ICONS = {
  overdue: "🔴", expiring_lease: "🟡", maintenance: "🔧", move_out: "📦",
};

const ActionQueue = ({ actions }: { actions: Action[] }) => (
  <div className="space-y-2">
    <h2 className="text-base font-semibold">Today's Actions</h2>
    <div className="divide-y border rounded-xl overflow-hidden">
      {actions.map((action) => (
        <button key={action.id}
          className="flex items-center gap-3 w-full p-3 text-left hover:bg-muted transition-colors min-h-[48px]">
          <span className="text-lg">{ACTION_ICONS[action.type]}</span>
          <div className="flex-1 min-w-0">
            <p className={`text-sm font-medium truncate ${action.urgent ? "text-rose-600" : ""}`}>{action.title}</p>
            <p className="text-xs text-muted-foreground truncate">{action.subtitle}</p>
          </div>
          <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
        </button>
      ))}
    </div>
  </div>
);
```

## Sheet Modal (Mobile Forms)

```tsx
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";

export const MobileSheet = ({ trigger, title, children }: {
  trigger: React.ReactNode; title: string; children: React.ReactNode;
}) => (
  <Sheet>
    <SheetTrigger asChild>{trigger}</SheetTrigger>
    <SheetContent side="bottom" className="h-[85vh] rounded-t-2xl overflow-y-auto">
      <SheetHeader><SheetTitle>{title}</SheetTitle></SheetHeader>
      <div className="py-4 space-y-4">{children}</div>
    </SheetContent>
  </Sheet>
);
```

## FAB (Floating Action Button)

```tsx
import { Plus } from "lucide-react";

export const FAB = ({ onClick, label = "Add" }: { onClick: () => void; label?: string }) => (
  <button onClick={onClick} aria-label={label}
    className="fixed bottom-20 right-4 md:bottom-6 md:right-6 w-14 h-14 bg-primary text-primary-foreground rounded-full shadow-lg flex items-center justify-center hover:bg-primary/90 active:scale-95 transition-all z-40">
    <Plus className="w-6 h-6" />
  </button>
);
```

## Status Badge

```tsx
const STATUS_STYLES = {
  occupied: "bg-emerald-100 text-emerald-800",
  active: "bg-emerald-100 text-emerald-800",
  paid: "bg-emerald-100 text-emerald-800",
  vacant: "bg-gray-100 text-gray-600",
  partial: "bg-amber-100 text-amber-800",
  maintenance: "bg-amber-100 text-amber-800",
  unpaid: "bg-rose-100 text-rose-800",
  overdue: "bg-rose-100 text-rose-800",
  expired: "bg-rose-100 text-rose-800",
  reserved: "bg-blue-100 text-blue-800",
  draft: "bg-blue-100 text-blue-800",
} as const;

export const StatusBadge = ({ status }: { status: keyof typeof STATUS_STYLES }) => (
  <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
    STATUS_STYLES[status] ?? "bg-gray-100 text-gray-600"
  }`}>{status}</span>
);
```

## Table to Card Responsive Transform

```tsx
const ResponsiveList = <T extends { id: string }>({
  items, columns, renderCard,
}: {
  items: T[];
  columns: { key: keyof T; label: string }[];
  renderCard: (item: T) => React.ReactNode;
}) => (
  <>
    <div className="md:hidden space-y-2">
      {items.map((item) => <div key={item.id}>{renderCard(item)}</div>)}
    </div>
    <table className="hidden md:table w-full">
      <thead>
        <tr className="border-b">
          {columns.map((col) => (
            <th key={String(col.key)} className="text-left p-3 text-sm font-medium text-muted-foreground">{col.label}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {items.map((item) => (
          <tr key={item.id} className="border-b hover:bg-muted/50">
            {columns.map((col) => (
              <td key={String(col.key)} className="p-3 text-sm">{String(item[col.key])}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  </>
);
```

## Photo Capture

```tsx
"use client";

import { useState } from "react";
import Compressor from "compressorjs";
import { Camera, X, Image } from "lucide-react";

export const PhotoCapture = ({ photos, onAdd, onRemove, maxPhotos = 5 }: {
  photos: string[]; onAdd: (url: string) => void; onRemove: (i: number) => void; maxPhotos?: number;
}) => {
  const [uploading, setUploading] = useState(false);

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const compressed = await new Promise<File>((resolve, reject) => {
        new Compressor(file, { maxWidth: 1200, quality: 0.8, success: (r) => resolve(r as File), error: reject });
      });
      onAdd(URL.createObjectURL(compressed));
    } finally { setUploading(false); e.target.value = ""; }
  };

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-2">
        {photos.map((url, i) => (
          <div key={i} className="relative w-20 h-20 rounded-lg overflow-hidden border">
            <img src={url} alt="" className="w-full h-full object-cover" />
            <button onClick={() => onRemove(i)}
              className="absolute top-0.5 right-0.5 w-5 h-5 bg-black/60 text-white rounded-full flex items-center justify-center">
              <X className="w-3 h-3" />
            </button>
          </div>
        ))}
      </div>
      {photos.length < maxPhotos && (
        <div className="flex gap-2">
          <label className="flex items-center gap-2 px-4 py-2.5 border rounded-lg cursor-pointer hover:bg-muted min-h-[48px]">
            <Camera className="w-4 h-4" /><span className="text-sm">{uploading ? "..." : "Camera"}</span>
            <input type="file" accept="image/*" capture="environment" onChange={handleFile} className="hidden" />
          </label>
          <label className="flex items-center gap-2 px-4 py-2.5 border rounded-lg cursor-pointer hover:bg-muted min-h-[48px]">
            <Image className="w-4 h-4" /><span className="text-sm">Gallery</span>
            <input type="file" accept="image/*" onChange={handleFile} className="hidden" />
          </label>
        </div>
      )}
    </div>
  );
};
```

## Performance Rules

1. **Skeleton loading** over spinners
2. **Optimistic updates** — update UI before server confirms
3. **`loading="lazy"`** on below-fold images
4. **Server Components by default** — `"use client"` only for interactivity
5. **Compress images client-side** — compressorjs maxWidth 1200, quality 0.8
6. **300ms debounce** on search inputs
7. **Cache dashboard data** with revalidate or SWR

## Touch Target Rules

- All interactive elements: `min-h-[48px] min-w-[48px]`
- Form inputs: `h-12` (48px)
- Buttons: `py-3` minimum
- List items: `min-h-[48px]`
- FAB: `w-14 h-14` (56px)
