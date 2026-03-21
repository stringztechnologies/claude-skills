---
name: chapa-payment-integration
description: "Ethiopian payment integration patterns using Chapa as the gateway for Telebirr, M-Pesa, CBE Birr, and card payments. Use this skill when accepting payments in ETB, building escrow or pool-based payment flows (like Equb), processing Chapa webhooks, initiating payouts/transfers to mobile wallets, or handling any Ethiopian fintech integration. Covers transaction initialization, webhook HMAC verification, bank transfer payouts, split payments, and the Equb-specific escrow-to-payout lifecycle. Trigger for Chapa, Telebirr, CBE Birr, M-Pesa Ethiopia, Ethiopian payments, ETB transactions, mobile money Ethiopia, or Equb financial flows."
---

# Chapa Payment Integration Patterns

## Dependencies

```bash
npm install axios crypto
# Chapa doesn't have an official Node.js SDK on npm — use direct API calls
```

## Environment Variables

```env
# Server-only — NEVER expose to client
CHAPA_SECRET_KEY=CHASECK_TEST-xxxxxxxxxxxxxxxx
CHAPA_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx

# Public (safe for client)
NEXT_PUBLIC_CHAPA_PUBLIC_KEY=CHAPUBK_TEST-xxxxxxxxxxxxxxxx
```

**Rule**: Secret key and webhook secret are server-only. Only the public key can be in client-side code.

## Chapa API Client

```typescript
// src/lib/chapa.ts
import axios from "axios";

const CHAPA_BASE = "https://api.chapa.co/v1";

const chapaClient = axios.create({
  baseURL: CHAPA_BASE,
  headers: {
    Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}`,
    "Content-Type": "application/json",
  },
});

// ─── Initialize Payment ───────────────────────────────────────
export interface InitializePaymentParams {
  amount: number;
  currency: "ETB";
  email?: string;
  first_name: string;
  last_name: string;
  phone_number?: string;  // +251 format
  tx_ref: string;          // Unique per transaction
  callback_url: string;    // Your webhook endpoint
  return_url?: string;     // Where user goes after payment
  customization?: {
    title?: string;
    description?: string;
    logo?: string;
  };
}

export const initializePayment = async (params: InitializePaymentParams) => {
  const { data } = await chapaClient.post("/transaction/initialize", params);
  return data as {
    status: string;
    message: string;
    data: { checkout_url: string };
  };
};

// ─── Verify Payment ───────────────────────────────────────────
export const verifyPayment = async (txRef: string) => {
  const { data } = await chapaClient.get(`/transaction/verify/${txRef}`);
  return data as {
    status: string;
    message: string;
    data: {
      status: "success" | "pending" | "failed";
      amount: number;
      currency: string;
      charge: number;
      payment_method: string;
      tx_ref: string;
      reference: string;
      first_name: string;
      last_name: string;
    };
  };
};

// ─── Transfer to Bank/Mobile Wallet ───────────────────────────
export interface TransferParams {
  account_name: string;
  account_number: string;  // Phone number for mobile money
  amount: number;
  currency: "ETB";
  reference: string;       // Unique per transfer
  bank_code: string;       // From getBanks() — Telebirr, CBE, etc.
  beneficiary_name: string;
}

export const transferToBank = async (params: TransferParams) => {
  const { data } = await chapaClient.post("/transfers", params);
  return data as {
    status: string;
    message: string;
    data: { reference: string };
  };
};

// ─── Get Available Banks ──────────────────────────────────────
export const getBanks = async () => {
  const { data } = await chapaClient.get("/banks");
  return data.data as Array<{
    id: string;
    name: string;      // "Telebirr", "Commercial Bank of Ethiopia", etc.
    swift: string;
    country_id: number;
    is_mobilemoney: boolean;
    currency: string;
  }>;
};

// ─── Bulk Transfer ────────────────────────────────────────────
// Used for Equb payouts to multiple winners
export interface BulkTransferParams {
  title: string;
  currency: "ETB";
  transfers: Array<{
    account_name: string;
    account_number: string;
    amount: number;
    reference: string;
    bank_code: string;
  }>;
}

export const bulkTransfer = async (params: BulkTransferParams) => {
  const { data } = await chapaClient.post("/bulk-transfers", params);
  return data;
};
```

## Webhook Verification (CRITICAL)

```typescript
// src/server/webhooks/chapa.ts
import crypto from "crypto";

/**
 * Verify Chapa webhook signature using HMAC-SHA256.
 * MUST be done before processing any payment callback.
 */
export const verifyChapaWebhook = (
  payload: string | Buffer,
  signature: string,
  webhookSecret: string
): boolean => {
  const expectedSignature = crypto
    .createHmac("sha256", webhookSecret)
    .update(payload)
    .digest("hex");

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
};

// Express/Hono webhook handler
export const chapaWebhookHandler = async (req: Request, res: Response) => {
  const signature = req.headers["x-chapa-signature"] as string;
  const rawBody = JSON.stringify(req.body);

  if (!signature || !verifyChapaWebhook(rawBody, signature, process.env.CHAPA_WEBHOOK_SECRET!)) {
    console.error("Invalid Chapa webhook signature");
    return res.status(401).json({ error: "Invalid signature" });
  }

  const event = req.body;
  const txRef = event.tx_ref;
  const status = event.status;

  // Double-verify with Chapa API (defense in depth)
  const verification = await verifyPayment(txRef);

  if (verification.data.status !== "success") {
    console.warn(`Payment ${txRef} verification failed: ${verification.data.status}`);
    return res.status(200).json({ received: true }); // Acknowledge but don't process
  }

  // Process based on tx_ref prefix convention
  if (txRef.startsWith("equb_stake_")) {
    await processEqubStakePayment(txRef, verification.data);
  } else if (txRef.startsWith("gym_pass_")) {
    await processGymPassPayment(txRef, verification.data);
  }

  return res.status(200).json({ received: true });
};
```

## Transaction Reference Convention

```typescript
// Generate unique, parseable transaction references
export const generateTxRef = (
  type: "equb_stake" | "gym_pass" | "equb_payout" | "sponsor",
  entityId: string,
  userId: string | number
): string => {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 6);
  return `${type}_${entityId}_${userId}_${timestamp}_${random}`;
};

// Parse tx_ref back to components
export const parseTxRef = (txRef: string) => {
  const parts = txRef.split("_");
  // equb_stake_EQUBID_USERID_TIMESTAMP_RANDOM
  if (parts[0] === "equb" && parts[1] === "stake") {
    return {
      type: "equb_stake" as const,
      equbId: parts[2],
      userId: parts[3],
    };
  }
  if (parts[0] === "gym" && parts[1] === "pass") {
    return {
      type: "gym_pass" as const,
      gymId: parts[2],
      userId: parts[3],
    };
  }
  return null;
};
```

## Equb Stake Payment Flow

```typescript
// Complete flow: User joins Equb → pays stake via Chapa → webhook confirms → ledger updated

// Step 1: User initiates payment from Mini App
export const initiateEqubStake = async (
  equbId: string,
  user: TelegramUser,
  stakeAmount: number
) => {
  const txRef = generateTxRef("equb_stake", equbId, String(user.id));

  const result = await initializePayment({
    amount: stakeAmount / 100, // Convert from cents to ETB
    currency: "ETB",
    first_name: user.first_name,
    last_name: user.last_name ?? "User",
    phone_number: user.phone,
    tx_ref: txRef,
    callback_url: `${process.env.API_URL}/webhooks/chapa`,
    return_url: `${process.env.MINI_APP_URL}/equbs/${equbId}?payment=success`,
    customization: {
      title: "FitEqub Stake",
      description: `Equb stake payment`,
      logo: `${process.env.MINI_APP_URL}/logo.png`,
    },
  });

  return {
    checkout_url: result.data.checkout_url,
    tx_ref: txRef,
  };
};

// Step 2: Webhook processes confirmed payment
const processEqubStakePayment = async (
  txRef: string,
  paymentData: VerifiedPayment
) => {
  const parsed = parseTxRef(txRef);
  if (!parsed || parsed.type !== "equb_stake") return;

  const supabase = createAdminClient();

  // Insert into immutable ledger
  await supabase.from("equb_ledger").insert({
    equb_id: parsed.equbId,
    user_id: parsed.userId,
    entry_type: "stake_in",
    amount: Math.round(paymentData.amount * 100), // Store in cents
    currency: "ETB",
    payment_method: paymentData.payment_method, // "telebirr", "cbe_birr", etc.
    external_ref: paymentData.reference,
    description: `Stake payment via ${paymentData.payment_method}`,
  });

  // Update member status
  await supabase
    .from("equb_members")
    .update({
      status: "paid",
      paid_at: new Date().toISOString(),
      payment_ref: paymentData.reference,
    })
    .eq("equb_id", parsed.equbId)
    .eq("user_id", parsed.userId);

  // Recalculate pot
  const { data: stakes } = await supabase
    .from("equb_ledger")
    .select("amount")
    .eq("equb_id", parsed.equbId)
    .eq("entry_type", "stake_in");

  const totalPot = (stakes ?? []).reduce((sum, s) => sum + s.amount, 0);

  await supabase
    .from("equb_rooms")
    .update({ total_pot: totalPot })
    .eq("id", parsed.equbId);

  // Notify user via Telegram bot
  await sendEqubNotification(
    Number(parsed.userId),
    `✅ Your ${paymentData.amount} ETB stake for the Equb has been confirmed!`
  );
};
```

## Equb Payout Flow

```typescript
// Called by settle_equb() or n8n cron after Equb ends

export const processEqubPayouts = async (equbId: string) => {
  const supabase = createAdminClient();

  // Get qualified winners
  const { data: winners } = await supabase
    .from("equb_members")
    .select("user_id, payout_amount, users(phone, telegram_id)")
    .eq("equb_id", equbId)
    .eq("qualified", true)
    .gt("payout_amount", 0);

  if (!winners?.length) return;

  // Get Telebirr bank code
  const banks = await getBanks();
  const telebirr = banks.find((b) => b.name.toLowerCase().includes("telebirr"));

  if (!telebirr) {
    console.error("Telebirr bank code not found");
    return;
  }

  // Process each payout
  for (const winner of winners) {
    const user = winner.users as any;
    const payoutETB = winner.payout_amount / 100; // Convert cents to ETB
    const reference = generateTxRef("equb_payout", equbId, String(winner.user_id));

    try {
      const result = await transferToBank({
        account_name: user.display_name ?? "FitEqub Winner",
        account_number: user.phone, // Telebirr uses phone number
        amount: payoutETB,
        currency: "ETB",
        reference,
        bank_code: telebirr.id,
        beneficiary_name: user.display_name ?? "FitEqub Winner",
      });

      // Record in ledger
      await supabase.from("equb_ledger").insert({
        equb_id: equbId,
        user_id: winner.user_id,
        entry_type: "payout",
        amount: winner.payout_amount,
        currency: "ETB",
        payment_method: "telebirr",
        external_ref: reference,
        description: `Equb payout: ${payoutETB} ETB to ${user.phone}`,
      });

      // Update member record
      await supabase
        .from("equb_members")
        .update({
          payout_ref: reference,
          payout_at: new Date().toISOString(),
        })
        .eq("equb_id", equbId)
        .eq("user_id", winner.user_id);

      // Notify winner via Telegram
      await sendEqubNotification(
        user.telegram_id,
        `🎉 You won ${payoutETB} ETB from your Fitness Equb! The money has been sent to your Telebirr. Screenshot and share! 💪`,
        `/equbs/${equbId}`
      );
    } catch (error) {
      console.error(`Payout failed for user ${winner.user_id}:`, error);

      // Record failed payout for retry
      await supabase.from("equb_ledger").insert({
        equb_id: equbId,
        user_id: winner.user_id,
        entry_type: "payout",
        amount: winner.payout_amount,
        currency: "ETB",
        payment_method: "telebirr",
        description: `FAILED payout attempt: ${(error as Error).message}`,
      });
    }
  }
};
```

## Gym Day Pass Payment

```typescript
export const initiateGymDayPass = async (
  gymId: string,
  user: TelegramUser,
  appPrice: number // in ETB cents
) => {
  const txRef = generateTxRef("gym_pass", gymId, String(user.id));

  const result = await initializePayment({
    amount: appPrice / 100,
    currency: "ETB",
    first_name: user.first_name,
    last_name: user.last_name ?? "User",
    tx_ref: txRef,
    callback_url: `${process.env.API_URL}/webhooks/chapa`,
    return_url: `${process.env.MINI_APP_URL}/gyms/${gymId}?pass=purchased`,
    customization: {
      title: "FitEqub Day Pass",
      description: "Gym day pass",
    },
  });

  return { checkout_url: result.data.checkout_url, tx_ref: txRef };
};
```

## Payment Method Display

```typescript
// Map Chapa's payment_method field to display labels
export const CHAPA_METHOD_LABELS: Record<string, string> = {
  telebirr: "Telebirr",
  cbe_birr: "CBE Birr",
  mpesa: "M-Pesa",
  ebirr: "eBirr",
  awash_birr: "Awash Birr",
  visa: "Visa",
  mastercard: "Mastercard",
  amex: "Amex",
  bank_transfer: "Bank Transfer",
};

export const getPaymentMethodLabel = (method: string): string =>
  CHAPA_METHOD_LABELS[method] ?? method;

// Payment method icons (emoji-based for TMA lightweight UI)
export const CHAPA_METHOD_ICONS: Record<string, string> = {
  telebirr: "📱",
  cbe_birr: "🏦",
  mpesa: "💚",
  visa: "💳",
  mastercard: "💳",
  bank_transfer: "🏛️",
};
```

## ETB Formatting

```typescript
export const formatETB = (amountInCents: number): string => {
  const etb = amountInCents / 100;
  return new Intl.NumberFormat("am-ET", {
    style: "currency",
    currency: "ETB",
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(etb);
};

// formatETB(50000) → "ETB 500"
// formatETB(75050) → "ETB 750.50"
```

## n8n Workflow Pattern for Settlement

```
Cron (midnight) 
  → Query Supabase: "SELECT id FROM equb_rooms WHERE status = 'active' AND end_date <= CURRENT_DATE"
  → For each: Call settle_equb(equb_id) via Supabase RPC
  → For each winner: Call Chapa transfer API
  → Insert ledger entries
  → Send Telegram notifications via bot
  → Summary email to admin
```

## Testing with Chapa Sandbox

```typescript
// Chapa provides test credentials:
// Secret: CHASECK_TEST-xxxxxxxx
// Public: CHAPUBK_TEST-xxxxxxxx

// Test card numbers:
// Success: 4200 0000 0000 0000 (any expiry, any CVV)
// Failure: 4000 0000 0000 0002

// Test mobile money:
// Any phone number works in test mode
// Telebirr test: +251911234567
```

## Common Mistakes

1. **Not verifying webhooks** — always check `x-chapa-signature` HMAC before processing payments.
2. **Not double-verifying** — after webhook, call `verifyPayment(txRef)` to confirm with Chapa's API directly.
3. **Storing amounts as floats** — store all amounts in ETB cents (integers) to avoid floating-point errors.
4. **Not handling idempotency** — webhooks can fire multiple times. Check if the ledger entry already exists before inserting.
5. **Exposing secret key** — `CHAPA_SECRET_KEY` must never appear in client-side code or NEXT_PUBLIC_ variables.
6. **Forgetting the tx_ref convention** — use parseable prefixes (`equb_stake_`, `gym_pass_`) so webhook handlers can route correctly.
7. **Not handling transfer failures** — Telebirr payouts can fail (wrong number, daily limits). Always log failures and implement retry logic.
8. **Ignoring Chapa's rate limits** — bulk payouts should be spaced out, not fired simultaneously. Use n8n's built-in delay between items.
