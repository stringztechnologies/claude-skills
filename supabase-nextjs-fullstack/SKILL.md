---
name: supabase-nextjs-fullstack
description: "Production patterns for Next.js App Router + Supabase full-stack apps. Use this skill whenever building with Next.js and Supabase together — including auth setup, server/client Supabase clients, Server Components for data fetching, Server Actions for mutations, RLS policies, Zod schema validation, middleware auth guards, Supabase Storage uploads with client-side image compression, and environment variable configuration. Trigger this skill when the user mentions Supabase with Next.js, asks about server components vs client components for data, needs auth middleware, wants to set up RLS, needs file upload with Supabase Storage, or is scaffolding a new full-stack project."
---

# Supabase + Next.js App Router Full-Stack Patterns

## Dependencies

```bash
npm install @supabase/supabase-js @supabase/ssr zod compressorjs
```

## Project Structure

```
src/
├── lib/
│   ├── supabase/
│   │   ├── client.ts        # Browser client
│   │   ├── server.ts        # Server client (cookies)
│   │   └── admin.ts         # Service role client
│   └── schemas/             # Zod schemas
├── app/
│   ├── layout.tsx
│   ├── middleware.ts         # Auth guard
│   ├── (auth)/              # Public auth routes
│   └── (dashboard)/         # Protected routes
└── components/
```

## Environment Variables

```env
# .env.local
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Server-only — NEVER prefix with NEXT_PUBLIC_
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

**Rule**: Only `SUPABASE_URL` and `ANON_KEY` get `NEXT_PUBLIC_`. Service role key stays server-only.

## Supabase Client Setup

### Browser Client — `lib/supabase/client.ts`

```typescript
import { createBrowserClient } from "@supabase/ssr";
import type { Database } from "@/lib/database.types";

export const createClient = () =>
  createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
```

### Server Client — `lib/supabase/server.ts`

```typescript
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "@/lib/database.types";

export const createClient = async () => {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Called from Server Component — ignore
          }
        },
      },
    }
  );
};
```

### Admin Client — `lib/supabase/admin.ts`

```typescript
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/database.types";

export const createAdminClient = () =>
  createSupabaseClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
```

**When to use admin**: Server Actions that bypass RLS (e.g., creating records for other users).

## Auth Middleware — `middleware.ts`

```typescript
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/webhooks).*)"],
};

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) => {
            request.cookies.set(name, value);
            response.cookies.set(name, value, options);
          });
        },
      },
    }
  );

  // Refresh session — MUST call getUser() not getSession()
  const { data: { user } } = await supabase.auth.getUser();

  const isAuthRoute = request.nextUrl.pathname.startsWith("/login") ||
    request.nextUrl.pathname.startsWith("/signup");

  if (!user && !isAuthRoute) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  if (user && isAuthRoute) {
    return NextResponse.redirect(new URL("/dashboard", request.url));
  }

  return response;
}
```

## Zod-First Types

```typescript
// lib/schemas/tenant.ts
import { z } from "zod";

export const tenantSchema = z.object({
  full_name: z.string().min(1, "Name is required"),
  email: z.string().email().optional().or(z.literal("")),
  phone: z.string().regex(/^\+?[1-9]\d{1,14}$/, "Invalid phone").optional(),
  nationality: z.string().length(2).optional(),
  organization: z.string().optional(),
});

export type TenantInput = z.infer<typeof tenantSchema>;

export const billingPeriodSchema = z.object({
  unit_id: z.string().uuid(),
  label: z.string().min(1),
  amount_due: z.number().positive(),
  currency: z.enum(["USD", "ETB", "EUR", "GBP", "KES", "NGN"]),
  due_date: z.string().date(),
});

export type BillingPeriodInput = z.infer<typeof billingPeriodSchema>;
```

## Server Actions Pattern

```typescript
// app/(dashboard)/tenants/actions.ts
"use server";

import { revalidatePath } from "next/cache";
import { createAdminClient } from "@/lib/supabase/admin";
import { tenantSchema } from "@/lib/schemas/tenant";

export const createTenant = async (formData: FormData) => {
  // 1. Validate
  const raw = Object.fromEntries(formData);
  const parsed = tenantSchema.safeParse(raw);

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors };
  }

  // 2. Admin client (bypasses RLS for cross-user writes)
  const supabase = createAdminClient();

  const { error } = await supabase
    .from("tenants")
    .insert(parsed.data);

  if (error) return { error: error.message };

  // 3. Revalidate
  revalidatePath("/tenants");
  return { success: true };
};
```

## Server Component Data Fetching

```typescript
// app/(dashboard)/tenants/page.tsx
import { createClient } from "@/lib/supabase/server";

const TenantsPage = async () => {
  const supabase = await createClient();

  const { data: tenants } = await supabase
    .from("tenants")
    .select("id, full_name, phone, email, leases(unit:units(unit_number))")
    .order("full_name");

  return (
    <div className="p-4 space-y-4">
      <h1 className="text-xl font-bold">Tenants</h1>
      {tenants?.map((t) => (
        <div key={t.id} className="p-3 border rounded-lg">
          <p className="font-medium">{t.full_name}</p>
          <p className="text-sm text-muted-foreground">{t.phone}</p>
        </div>
      ))}
    </div>
  );
};

export default TenantsPage;
```

## RLS Policies

```sql
-- Optimized read policy: cache auth.uid() in a subselect
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own org tenants" ON tenants
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users insert own org tenants" ON tenants
  FOR INSERT WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );
```

**Optimization**: Wrap `auth.uid()` in `(SELECT auth.uid())` so Postgres evaluates it once per query, not per row.

## Supabase Storage Upload with Compression

```typescript
// components/PhotoUpload.tsx
"use client";

import { useState } from "react";
import Compressor from "compressorjs";
import { createClient } from "@/lib/supabase/client";
import { Camera, Upload } from "lucide-react";

interface PhotoUploadProps {
  bucket: string;
  path: string;
  onUpload: (url: string) => void;
}

export const PhotoUpload = ({ bucket, path, onUpload }: PhotoUploadProps) => {
  const [uploading, setUploading] = useState(false);
  const supabase = createClient();

  const compress = (file: File): Promise<File> =>
    new Promise((resolve, reject) => {
      new Compressor(file, {
        maxWidth: 1200,
        quality: 0.8,
        success: (result) => resolve(result as File),
        error: reject,
      });
    });

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const compressed = await compress(file);
      const fileName = `${path}/${Date.now()}-${compressed.name}`;

      const { error } = await supabase.storage
        .from(bucket)
        .upload(fileName, compressed);

      if (error) throw error;

      const { data } = supabase.storage
        .from(bucket)
        .getPublicUrl(fileName);

      onUpload(data.publicUrl);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="flex gap-2">
      <label className="flex items-center gap-2 px-4 py-2 border rounded-lg cursor-pointer hover:bg-muted">
        <Upload className="w-4 h-4" />
        {uploading ? "Uploading..." : "Upload"}
        <input type="file" accept="image/*" onChange={handleUpload} className="hidden" />
      </label>
      <label className="flex items-center gap-2 px-4 py-2 border rounded-lg cursor-pointer hover:bg-muted">
        <Camera className="w-4 h-4" />
        Capture
        <input type="file" accept="image/*" capture="environment" onChange={handleUpload} className="hidden" />
      </label>
    </div>
  );
};
```

## Common Mistakes

1. **Using `getSession()` in middleware** — always use `getUser()` for server-side auth checks
2. **Exposing service role key** — never prefix with `NEXT_PUBLIC_`
3. **Forgetting cookie handler try/catch** — Server Components can't set cookies
4. **Not calling `getUser()` in middleware** — sessions expire silently without refresh
5. **RLS without `(SELECT auth.uid())`** — causes per-row evaluation instead of once per query
6. **Uploading uncompressed images** — always compress client-side before Storage upload
7. **Using `createBrowserClient` in Server Components** — no cookie access server-side
