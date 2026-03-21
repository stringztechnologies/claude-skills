---
name: telegram-mini-app
description: "Patterns for building Telegram Mini Apps (TMAs) with React + Vite, tma.js SDK, Telegram WebApp auth, bot integration via Telegraf, and Ethiopian payment flows via Chapa inside Telegram. Use this skill when building any Telegram Mini App, integrating Telegram Bot API with a web frontend, validating Telegram initData on the server, handling Telegram-native UI (MainButton, BackButton, haptics, theme), or connecting Chapa payments to a Telegram bot. Trigger for Telegram Mini App, TMA, Telegram bot with web interface, Telegram WebApp, tma.js, Telegraf bot, or any app deployed inside Telegram's WebView."
---

# Telegram Mini App Patterns

## Dependencies

```bash
# Frontend (React + Vite TMA)
npm install @telegram-apps/sdk-react @telegram-apps/telegram-ui vite react react-dom

# Backend (Bot + Auth + Payments)
npm install telegraf @supabase/supabase-js crypto
```

## Project Structure

```
src/
├── app/                      # React Mini App (Vite)
│   ├── components/
│   │   ├── EqubCard.tsx
│   │   ├── GymPassQR.tsx
│   │   ├── LeaderboardRow.tsx
│   │   └── TsomToggle.tsx
│   ├── hooks/
│   │   ├── useTelegramUser.ts
│   │   └── useThemeParams.ts
│   ├── pages/
│   │   ├── Home.tsx
│   │   ├── EqubDetail.tsx
│   │   ├── Gyms.tsx
│   │   └── Leaderboard.tsx
│   ├── lib/
│   │   ├── api.ts            # Fetch wrapper with initData auth
│   │   └── telegram.ts       # SDK init + theme helpers
│   ├── App.tsx
│   └── main.tsx
├── bot/
│   ├── index.ts              # Telegraf bot entry
│   ├── commands/
│   │   ├── start.ts
│   │   ├── equb.ts
│   │   └── workout.ts
│   └── webhooks/
│       └── chapa.ts          # Chapa payment callback
├── server/
│   ├── auth.ts               # initData HMAC validation
│   ├── routes/
│   │   ├── equb.ts
│   │   ├── gym.ts
│   │   └── payment.ts
│   └── middleware/
│       └── telegramAuth.ts   # Express/Hono middleware
└── lib/
    ├── supabase.ts
    └── chapa.ts              # Chapa SDK wrapper
```

## Telegram WebApp SDK Init

```typescript
// src/app/lib/telegram.ts
import { init, miniApp, themeParams, mainButton, backButton } from "@telegram-apps/sdk-react";

export const initTelegram = () => {
  init();

  // Expand to full height
  miniApp.mount();
  miniApp.expand();
  miniApp.setHeaderColor("secondary_bg_color");

  // Theme params for CSS variables
  themeParams.mount();

  // Main button (Telegram native CTA at bottom)
  mainButton.mount();

  // Back button
  backButton.mount();
};

// Get CSS-compatible theme values
export const getTelegramTheme = () => ({
  bg: themeParams.backgroundColor() ?? "#ffffff",
  text: themeParams.textColor() ?? "#000000",
  hint: themeParams.hintColor() ?? "#999999",
  link: themeParams.linkColor() ?? "#2481cc",
  button: themeParams.buttonColor() ?? "#3390ec",
  buttonText: themeParams.buttonTextColor() ?? "#ffffff",
  secondaryBg: themeParams.secondaryBackgroundColor() ?? "#f0f0f0",
});
```

## Telegram User Hook

```typescript
// src/app/hooks/useTelegramUser.ts
import { useInitData } from "@telegram-apps/sdk-react";

export const useTelegramUser = () => {
  const initData = useInitData();

  if (!initData?.user) return null;

  return {
    id: initData.user.id,
    firstName: initData.user.firstName,
    lastName: initData.user.lastName ?? "",
    username: initData.user.username ?? "",
    languageCode: initData.user.languageCode ?? "am",
    photoUrl: initData.user.photoUrl,
    isPremium: initData.user.isPremium ?? false,
  };
};
```

## Server-Side initData Validation (CRITICAL)

```typescript
// src/server/auth.ts
import crypto from "crypto";

/**
 * Validate Telegram Mini App initData using HMAC-SHA256.
 * This MUST be done server-side before trusting any user identity.
 * 
 * @see https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app
 */
export const validateInitData = (
  initDataRaw: string,
  botToken: string
): { valid: boolean; user?: TelegramUser } => {
  const params = new URLSearchParams(initDataRaw);
  const hash = params.get("hash");
  params.delete("hash");

  // Sort params alphabetically
  const dataCheckString = Array.from(params.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, value]) => `${key}=${value}`)
    .join("\n");

  // HMAC-SHA256 with bot token as key
  const secretKey = crypto
    .createHmac("sha256", "WebAppData")
    .update(botToken)
    .digest();

  const computedHash = crypto
    .createHmac("sha256", secretKey)
    .update(dataCheckString)
    .digest("hex");

  if (computedHash !== hash) {
    return { valid: false };
  }

  // Parse user from validated data
  const userRaw = params.get("user");
  const user = userRaw ? JSON.parse(userRaw) : undefined;

  return { valid: true, user };
};

// Types
interface TelegramUser {
  id: number;
  first_name: string;
  last_name?: string;
  username?: string;
  language_code?: string;
  is_premium?: boolean;
  photo_url?: string;
}
```

## Auth Middleware

```typescript
// src/server/middleware/telegramAuth.ts
import { validateInitData } from "../auth";

export const telegramAuthMiddleware = (botToken: string) => {
  return (req: Request, res: Response, next: Function) => {
    const initData = req.headers["x-telegram-init-data"] as string;

    if (!initData) {
      return res.status(401).json({ error: "Missing Telegram init data" });
    }

    const { valid, user } = validateInitData(initData, botToken);

    if (!valid || !user) {
      return res.status(401).json({ error: "Invalid Telegram auth" });
    }

    // Attach user to request
    (req as any).telegramUser = user;
    next();
  };
};
```

## API Client with Auto-Auth

```typescript
// src/app/lib/api.ts
import { retrieveLaunchParams } from "@telegram-apps/sdk-react";

const API_BASE = import.meta.env.VITE_API_URL;

export const api = async (path: string, options: RequestInit = {}) => {
  const { initDataRaw } = retrieveLaunchParams();

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "x-telegram-init-data": initDataRaw ?? "",
      ...options.headers,
    },
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({ error: "Request failed" }));
    throw new Error(error.error ?? `HTTP ${res.status}`);
  }

  return res.json();
};

// Usage
// const equbs = await api("/equbs");
// const result = await api("/equbs/join", { method: "POST", body: JSON.stringify({ equb_id }) });
```

## Telegraf Bot Setup

```typescript
// src/bot/index.ts
import { Telegraf, Markup } from "telegraf";

const bot = new Telegraf(process.env.TELEGRAM_BOT_TOKEN!);

const MINI_APP_URL = process.env.MINI_APP_URL!; // Your Vercel/Coolify deployed URL

// /start command — launches the Mini App
bot.command("start", (ctx) => {
  ctx.reply(
    "Welcome to FitEqub! 💪\nJoin fitness challenges, earn money, and stay healthy.",
    Markup.inlineKeyboard([
      [Markup.button.webApp("Open FitEqub", MINI_APP_URL)],
      [Markup.button.callback("My Equbs", "my_equbs")],
      [Markup.button.callback("Today's Workout", "today_workout")],
    ])
  );
});

// Inline button to open Mini App from any chat
bot.command("equb", (ctx) => {
  ctx.reply(
    "Join a Fitness Equb and earn while you work out!",
    Markup.inlineKeyboard([
      [Markup.button.webApp("Browse Equbs", `${MINI_APP_URL}/equbs`)],
    ])
  );
});

// Notification sender (called by n8n or cron)
export const sendEqubNotification = async (
  chatId: number,
  message: string,
  miniAppPath?: string
) => {
  const keyboard = miniAppPath
    ? Markup.inlineKeyboard([
        [Markup.button.webApp("View Details", `${MINI_APP_URL}${miniAppPath}`)],
      ])
    : undefined;

  await bot.telegram.sendMessage(chatId, message, {
    parse_mode: "HTML",
    ...keyboard,
  });
};

// Webhook mode for production (Coolify/Vercel)
export const setupWebhook = async (webhookUrl: string) => {
  await bot.telegram.setWebhook(webhookUrl);
  return bot.webhookCallback("/api/telegram-webhook");
};

// Polling mode for development
export const startPolling = () => bot.launch();
```

## Telegram-Native UI Patterns

### MainButton (Telegram's native bottom CTA)

```typescript
import { mainButton } from "@telegram-apps/sdk-react";
import { useEffect } from "react";

// Use Telegram's native MainButton instead of a custom button
// for primary actions — it's always visible, always tappable
export const useMainButton = (
  text: string,
  onClick: () => void,
  options?: { loading?: boolean; disabled?: boolean }
) => {
  useEffect(() => {
    mainButton.setText(text);
    mainButton.show();

    if (options?.loading) {
      mainButton.showProgress();
    } else {
      mainButton.hideProgress();
    }

    mainButton.on("click", onClick);

    return () => {
      mainButton.off("click", onClick);
      mainButton.hide();
    };
  }, [text, onClick, options?.loading]);
};

// Usage in a page:
// useMainButton("Join Equb — 500 ETB", handleJoinEqub, { loading: isJoining });
```

### BackButton

```typescript
import { backButton } from "@telegram-apps/sdk-react";
import { useEffect } from "react";
import { useNavigate } from "react-router-dom";

export const useBackButton = () => {
  const navigate = useNavigate();

  useEffect(() => {
    backButton.show();
    backButton.on("click", () => navigate(-1));

    return () => {
      backButton.off("click", () => navigate(-1));
      backButton.hide();
    };
  }, [navigate]);
};
```

### Haptic Feedback

```typescript
import { hapticFeedback } from "@telegram-apps/sdk-react";

// Use for confirmation actions (payment, join equb)
export const hapticSuccess = () => hapticFeedback.notificationOccurred("success");
export const hapticError = () => hapticFeedback.notificationOccurred("error");
export const hapticTap = () => hapticFeedback.impactOccurred("light");
```

## Theming — Match Telegram's Native Look

```typescript
// src/app/lib/theme.ts
// Telegram Mini Apps should feel native to Telegram.
// Use Telegram's CSS variables, not custom colors.

export const TG_THEME_CSS = `
  :root {
    --tg-bg: var(--tg-theme-bg-color, #ffffff);
    --tg-text: var(--tg-theme-text-color, #000000);
    --tg-hint: var(--tg-theme-hint-color, #999999);
    --tg-link: var(--tg-theme-link-color, #2481cc);
    --tg-button: var(--tg-theme-button-color, #3390ec);
    --tg-button-text: var(--tg-theme-button-text-color, #ffffff);
    --tg-secondary-bg: var(--tg-theme-secondary-bg-color, #f0f0f0);
    --tg-section-bg: var(--tg-theme-section-bg-color, #ffffff);
    --tg-section-header: var(--tg-theme-section-header-text-color, #6d7885);
    --tg-subtitle: var(--tg-theme-subtitle-text-color, #6d7885);
    --tg-accent: var(--tg-theme-accent-text-color, #3390ec);
    --tg-destructive: var(--tg-theme-destructive-text-color, #e53935);
  }

  body {
    background: var(--tg-bg);
    color: var(--tg-text);
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
    overflow-x: hidden;
  }
`;
```

### Section Component (Telegram-native grouping)

```tsx
export const Section = ({
  header,
  children,
}: {
  header?: string;
  children: React.ReactNode;
}) => (
  <div className="mb-4">
    {header && (
      <p style={{ color: "var(--tg-section-header)" }}
        className="text-xs font-medium uppercase tracking-wide px-4 mb-1">
        {header}
      </p>
    )}
    <div style={{ background: "var(--tg-section-bg)" }}
      className="rounded-xl overflow-hidden divide-y divide-[var(--tg-secondary-bg)]">
      {children}
    </div>
  </div>
);
```

### Cell Component (Telegram-native list item)

```tsx
export const Cell = ({
  title,
  subtitle,
  before,
  after,
  onClick,
}: {
  title: string;
  subtitle?: string;
  before?: React.ReactNode;
  after?: React.ReactNode;
  onClick?: () => void;
}) => (
  <button
    onClick={onClick}
    className="flex items-center gap-3 w-full px-4 py-3 text-left active:bg-[var(--tg-secondary-bg)] transition-colors min-h-[48px]"
  >
    {before && <div className="shrink-0">{before}</div>}
    <div className="flex-1 min-w-0">
      <p className="text-sm font-medium truncate" style={{ color: "var(--tg-text)" }}>
        {title}
      </p>
      {subtitle && (
        <p className="text-xs truncate" style={{ color: "var(--tg-subtitle)" }}>
          {subtitle}
        </p>
      )}
    </div>
    {after && <div className="shrink-0">{after}</div>}
  </button>
);
```

## BotFather Setup Checklist

```
1. /newbot → Create bot, save token
2. /setmenubutton → Set Mini App URL as menu button
3. /mybots → Select bot → Bot Settings → Configure Mini App
   - Enable Mini App
   - Set Mini App URL (your deployed URL)
   - Upload icon (512x512 PNG)
   - Set loading screen colors
4. /setdescription → "FitEqub — Earn money by working out"
5. /setabouttext → Short bio
6. /setuserpic → Bot avatar
```

## Deployment Patterns

### Coolify (Recommended for FitEqub)

```dockerfile
# Dockerfile for combined bot + API + Mini App
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./

ENV NODE_ENV=production
EXPOSE 3000

# Serves: Mini App static files + API routes + Telegram webhook
CMD ["node", "dist/server/index.js"]
```

### Environment Variables

```env
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
MINI_APP_URL=https://fitequb.yourdomain.com
CHAPA_SECRET_KEY=CHAPA-SECK-xxxxx
CHAPA_WEBHOOK_SECRET=whsec_xxxxx
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

## Anti-Fraud for Equbs (MVP Level)

```typescript
// Prevent one person creating multiple accounts to game Equb payouts
export const validateEqubJoin = async (
  telegramUserId: number,
  equbId: string,
  supabase: SupabaseClient
) => {
  // 1. Check if already a member
  const { data: existing } = await supabase
    .from("equb_members")
    .select("id")
    .eq("equb_id", equbId)
    .eq("user_id", telegramUserId)
    .single();

  if (existing) return { error: "Already a member of this Equb" };

  // 2. Check Telegram account age (via user ID range heuristic)
  // Lower IDs = older accounts. Very new accounts are suspicious.
  // This is a rough heuristic — proper KYC comes with Telebirr integration later.
  if (telegramUserId > 7_000_000_000) {
    // Account created very recently — flag for review
    console.warn(`New account ${telegramUserId} attempting to join Equb ${equbId}`);
  }

  // 3. Check concurrent Equb count (limit to 3 active Equbs per user)
  const { count } = await supabase
    .from("equb_members")
    .select("id", { count: "exact", head: true })
    .eq("user_id", telegramUserId)
    .in("status", ["joined", "paid"]);

  if ((count ?? 0) >= 3) {
    return { error: "Maximum 3 active Equbs at a time" };
  }

  return { valid: true };
};
```

## Common Mistakes

1. **Not validating initData server-side** — anyone can forge a Telegram user ID. ALWAYS validate HMAC.
2. **Using custom bottom navigation** — use Telegram's native BackButton and MainButton instead for primary actions. Custom nav is fine for in-app tabs.
3. **Hardcoding colors** — always use `var(--tg-theme-*)` CSS variables so the app matches the user's Telegram theme (light/dark).
4. **Blocking the UI on load** — Telegram shows a loading screen. Call `miniApp.ready()` only after your initial data fetch completes.
5. **Not expanding the app** — call `miniApp.expand()` on init or the app renders in a half-height sheet.
6. **Using localStorage** — use Telegram's CloudStorage API for persistence across devices: `cloudStorage.setItem(key, value)`.
7. **Forgetting safe area** — Telegram has status bar and bottom safe areas. Use `env(safe-area-inset-bottom)`.
8. **Large bundle size** — Ethiopian users have slow/expensive data. Keep initial bundle under 200KB. Lazy-load non-critical routes.
