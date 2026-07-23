# Unchained – Stripe backend (Cloudflare Worker)

The tiny server that lets the app take real payments through Stripe. It holds the
Stripe **secret** key (which must never be inside the phone app) and does three
jobs: start a subscription, receive Stripe webhooks, and tell the app who is a
paying subscriber.

You only set this up **once**. Everything below is copy‑paste.

---

## What you need first

- Your Stripe **secret** key: `sk_test_...` (Stripe → Desarrolladores → Claves de API).
- You already have the price IDs and publishable key filled into `wrangler.toml`.

---

## One‑time setup

Run these from inside the `stripe-backend/` folder.

```bash
# 1. Install dependencies
npm install

# 2. Log in to Cloudflare (opens a browser once)
npx wrangler login

# 3. Create the storage that remembers who paid
npx wrangler kv namespace create ENTITLEMENTS
#    -> copy the "id" it prints, and paste it into wrangler.toml
#       (replace REPLACE_WITH_KV_NAMESPACE_ID)

# 4. Store the SECRET key (paste sk_test_... when prompted; it is NOT saved in any file)
npx wrangler secret put STRIPE_SECRET_KEY

# 5. Deploy
npx wrangler deploy
#    -> copy the URL it prints, e.g. https://unchained-stripe-backend.<you>.workers.dev
```

## Connect the webhook (so Stripe can tell us about payments)

1. Stripe → **Desarrolladores → Webhooks → Add endpoint**.
2. Endpoint URL: your Worker URL + `/v1/webhook`
   (e.g. `https://unchained-stripe-backend.<you>.workers.dev/v1/webhook`).
3. Select events: `customer.subscription.created`, `customer.subscription.updated`,
   `customer.subscription.deleted`.
4. Save, then copy the **Signing secret** (`whsec_...`) and store it:

```bash
npx wrangler secret put STRIPE_WEBHOOK_SECRET   # paste whsec_...
npx wrangler deploy                             # redeploy so it takes effect
```

Give the app your Worker URL and it's wired end to end.

---

## Test it works

```bash
# Should return {"ok":true,...}
curl https://unchained-stripe-backend.<you>.workers.dev/health
```

Watch live logs while you test a purchase in the app:

```bash
npx wrangler tail
```

Use Stripe test card **4242 4242 4242 4242**, any future expiry, any CVC.

---

## Going live later

1. Recreate the 3 products in Stripe **Live** mode, get the `price_...` IDs.
2. In `wrangler.toml`, swap the price IDs and set `STRIPE_PUBLISHABLE_KEY` to `pk_live_...`.
3. `npx wrangler secret put STRIPE_SECRET_KEY` → paste `sk_live_...`.
4. Add a **live** webhook endpoint, `npx wrangler secret put STRIPE_WEBHOOK_SECRET` → paste its `whsec_...`.
5. `npx wrangler deploy`.

---

## Endpoints (for reference)

| Method | Path | Purpose |
|---|---|---|
| POST | `/v1/subscribe` | `{ email, priceId }` → tokens for the in‑app card sheet |
| POST | `/v1/webhook` | Stripe → us: payment/subscription events |
| GET | `/v1/entitlement?email=` | app → us: "is this email a paying subscriber?" |
| GET | `/health` | uptime check |
