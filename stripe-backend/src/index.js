// ─────────────────────────────────────────────────────────────────────────────
// Unchained – Stripe backend (Cloudflare Worker)
//
// This is the tiny server that sits between the phone app and Stripe. It exists
// because Stripe's SECRET key (the one that can actually charge cards) must never
// live inside the app. Only this Worker holds it.
//
// It exposes three endpoints:
//   POST /v1/subscribe    – app asks to start a paid subscription; returns the
//                           one-time tokens the in-app card sheet needs.
//   POST /v1/webhook      – Stripe calls this to report payment events; we record
//                           who is (and isn't) a paying subscriber.
//   GET  /v1/entitlement  – app asks "is this email a paying subscriber?"
//
// The free trial does NOT touch this Worker — that's handled locally in the app.
// ─────────────────────────────────────────────────────────────────────────────

import Stripe from 'stripe';

// Small helper: build a JSON HTTP response with permissive CORS (handy for
// testing from a browser; the native app doesn't care about CORS).
function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json',
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET,POST,OPTIONS',
      'access-control-allow-headers': 'content-type',
    },
  });
}

// Map a Stripe price id back to our internal plan name, using the allow-list in
// wrangler.toml. Returns null if the price isn't one of ours (reject it).
function planForPrice(env, priceId) {
  if (priceId === env.PRICE_MONTHLY) return 'monthly';
  if (priceId === env.PRICE_AI) return 'ai_plan';
  if (priceId === env.PRICE_FOREVER) return 'forever';
  return null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;

    // Browsers send a preflight OPTIONS before a cross-site POST; answer it.
    if (request.method === 'OPTIONS') return json({}, 204);

    const stripe = new Stripe(env.STRIPE_SECRET_KEY, {
      httpClient: Stripe.createFetchHttpClient(),
      apiVersion: '2025-08-27.basil',
    });

    try {
      if (pathname === '/v1/subscribe' && request.method === 'POST') {
        return await handleSubscribe(request, env, stripe);
      }
      if (pathname === '/v1/webhook' && request.method === 'POST') {
        return await handleWebhook(request, env, stripe);
      }
      if (pathname === '/v1/entitlement' && request.method === 'GET') {
        return await handleEntitlement(url, env);
      }
      if (pathname === '/' || pathname === '/health') {
        return json({ ok: true, service: 'unchained-stripe-backend' });
      }
      return json({ error: 'not_found' }, 404);
    } catch (err) {
      // Never leak internals to the client; log the full error for `wrangler tail`.
      console.error('Worker error:', err);
      return json({ error: 'server_error', message: String(err && err.message || err) }, 500);
    }
  },
};

// ── POST /v1/subscribe ───────────────────────────────────────────────────────
// Body: { "email": "user@example.com", "priceId": "price_..." }
// Creates (or reuses) a Stripe customer for that email, opens a subscription in
// "incomplete" state, and returns the tokens the app's card sheet needs to take
// the first payment. Once the card sheet succeeds, Stripe fires the webhook that
// marks the email as active.
async function handleSubscribe(request, env, stripe) {
  const body = await request.json().catch(() => ({}));
  const email = (body.email || '').trim().toLowerCase();
  const priceId = (body.priceId || '').trim();

  if (!email || !email.includes('@')) return json({ error: 'invalid_email' }, 400);

  const plan = planForPrice(env, priceId);
  if (!plan) return json({ error: 'unknown_price' }, 400);

  // Reuse a customer if this email already has one, else create it.
  const existing = await stripe.customers.list({ email, limit: 1 });
  const customer = existing.data[0] || (await stripe.customers.create({ email }));

  // Create the subscription but don't require payment yet — the app's card sheet
  // will confirm the first invoice's PaymentIntent.
  const subscription = await stripe.subscriptions.create({
    customer: customer.id,
    items: [{ price: priceId }],
    payment_behavior: 'default_incomplete',
    payment_settings: { save_default_payment_method: 'on_subscription' },
    expand: ['latest_invoice.confirmation_secret'],
    metadata: { app: 'unchained', plan },
  });

  // An "ephemeral key" lets the app's card sheet safely talk to Stripe on behalf
  // of this one customer, without ever seeing the secret key.
  const ephemeralKey = await stripe.ephemeralKeys.create(
    { customer: customer.id },
    { apiVersion: '2025-08-27.basil' },
  );

  const clientSecret = subscription.latest_invoice?.confirmation_secret?.client_secret;
  if (!clientSecret) return json({ error: 'no_client_secret' }, 500);

  return json({
    plan,
    subscriptionId: subscription.id,
    customerId: customer.id,
    paymentIntentClientSecret: clientSecret,
    ephemeralKey: ephemeralKey.secret,
    publishableKey: env.STRIPE_PUBLISHABLE_KEY,
  });
}

// ── POST /v1/webhook ─────────────────────────────────────────────────────────
// Stripe calls this URL on real events (payment succeeded, subscription changed
// or cancelled). We verify the signature so nobody can fake events, then update
// the entitlement store so the app knows the truth.
async function handleWebhook(request, env, stripe) {
  const signature = request.headers.get('stripe-signature');
  const payload = await request.text();

  let event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      payload,
      signature,
      env.STRIPE_WEBHOOK_SECRET,
      undefined,
      Stripe.createSubtleCryptoProvider(),
    );
  } catch (err) {
    console.error('Webhook signature check failed:', err.message);
    return json({ error: 'bad_signature' }, 400);
  }

  const type = event.type;
  const obj = event.data.object;

  // Resolve the customer's email (some events carry it, some need a lookup).
  async function emailFor(customerId) {
    if (!customerId) return null;
    const c = await stripe.customers.retrieve(customerId).catch(() => null);
    return c && !c.deleted ? (c.email || '').toLowerCase() : null;
  }

  if (type === 'customer.subscription.created' ||
      type === 'customer.subscription.updated' ||
      type === 'customer.subscription.deleted') {
    const email = await emailFor(obj.customer);
    if (email) {
      const active = ['active', 'trialing', 'past_due'].includes(obj.status) &&
                     type !== 'customer.subscription.deleted';
      const plan = obj.metadata?.plan || planForPrice(env, obj.items?.data?.[0]?.price?.id) || 'unknown';
      const record = {
        active,
        plan,
        status: type === 'customer.subscription.deleted' ? 'canceled' : obj.status,
        subscriptionId: obj.id,
        currentPeriodEnd: obj.current_period_end || null,
        updatedAt: event.created,
      };
      await env.ENTITLEMENTS.put(email, JSON.stringify(record));
      console.log(`entitlement ${email} -> active=${active} plan=${plan} status=${record.status}`);
    }
  }

  // Always 200 quickly so Stripe doesn't retry unnecessarily.
  return json({ received: true });
}

// ── GET /v1/entitlement?email=user@example.com ───────────────────────────────
// The app calls this on launch to decide whether to unlock a paid plan.
async function handleEntitlement(url, env) {
  const email = (url.searchParams.get('email') || '').trim().toLowerCase();
  if (!email || !email.includes('@')) return json({ error: 'invalid_email' }, 400);

  const raw = await env.ENTITLEMENTS.get(email);
  if (!raw) return json({ active: false, plan: null });

  const record = JSON.parse(raw);
  return json({
    active: !!record.active,
    plan: record.plan || null,
    status: record.status || null,
    currentPeriodEnd: record.currentPeriodEnd || null,
  });
}
