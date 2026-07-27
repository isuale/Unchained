// ─────────────────────────────────────────────────────────────────────────────
// Unchained – Stripe backend (Cloudflare Worker)
//
// This is the tiny server that sits between the phone app and Stripe. It exists
// because Stripe's SECRET key (the one that can actually charge cards) must never
// live inside the app. Only this Worker holds it.
//
// It exposes these endpoints:
//   POST /v1/subscribe         – app asks to start a paid subscription; returns
//                                the one-time tokens the in-app card sheet needs.
//   POST /v1/webhook           – Stripe calls this to report payment events; we
//                                record who is (and isn't) a paying subscriber.
//   GET  /v1/entitlement       – app asks "is this email a paying subscriber?"
//   POST /v1/owner/request-code – app asks to email a fresh owner verification
//                                code (see "Owner verification" below).
//   POST /v1/owner/verify-code  – app asks "is this the code you just emailed?"
//
// The free trial does NOT touch this Worker — that's handled locally in the app.
//
// ── Owner verification ───────────────────────────────────────────────────────
// The app's owner-only unlock (see lib/features/plans/domain/owner_access.dart)
// is a two-factor check: an emailed one-time code (handled here, via Resend)
// plus a locally-verified Authy TOTP code (handled entirely on-device, no
// network). request-code always emails env.OWNER_EMAIL — it ignores whatever
// address the caller supplies, so this can never become an open mail relay.
// The code lives in the OWNER_CODES KV store for 10 minutes and is invalidated
// after 5 wrong guesses.
// ─────────────────────────────────────────────────────────────────────────────

import Stripe from 'stripe';

// GET /paid — the page Stripe's Payment Link redirects the browser to after a
// successful checkout. Stripe's redirect field only accepts http(s) URLs, so
// it can't jump straight to the unchained://paid app deep link — this page
// bounces the browser there instead. Served from the Worker (not the
// beunchained.app website) so it doesn't depend on the home-server's uptime,
// since this step is payment-critical.
const PAID_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Payment successful — Be Unchained</title>
  <meta name="robots" content="noindex" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
  <style>
    :root { --blue: #1E5FFF; --green: #00D26A; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { height: 100%; }
    body {
      background: #000; color: #fff; font-family: 'Inter', system-ui, sans-serif;
      display: flex; align-items: center; justify-content: center;
      text-align: center; padding: 24px; min-height: 100dvh;
    }
    .card { max-width: 420px; width: 100%; }
    .check {
      width: 96px; height: 96px; border-radius: 50%; background: var(--green);
      display: flex; align-items: center; justify-content: center; margin: 0 auto 28px;
    }
    .check svg { width: 52px; height: 52px; stroke: #fff; stroke-width: 5;
      fill: none; stroke-linecap: round; stroke-linejoin: round; }
    h1 { font-family: 'DM Serif Display', Georgia, serif; font-size: 32px;
      font-weight: 400; margin-bottom: 14px; }
    p { color: rgba(255,255,255,.72); font-size: 16px; line-height: 1.5; margin-bottom: 32px; }
    .btn {
      display: inline-block; width: 100%; padding: 17px 24px; border-radius: 28px;
      background: var(--blue); color: #fff; font-size: 17px; font-weight: 600;
      text-decoration: none; border: none; cursor: pointer;
    }
    .hint { margin-top: 18px; font-size: 13px; color: rgba(255,255,255,.45); }
  </style>
</head>
<body>
  <div class="card">
    <div class="check">
      <svg viewBox="0 0 24 24"><polyline points="4 12 10 18 20 6" /></svg>
    </div>
    <h1>Payment successful</h1>
    <p>Your subscription is active. Head back to the Be Unchained app to continue.</p>
    <a class="btn" id="openApp" href="unchained://paid">Return to the app</a>
    <div class="hint">If the button doesn't open the app, just switch back to it manually.</div>
  </div>

  <script>
    // Try to reopen the app automatically. Browsers may require a tap, so the
    // button above is always the reliable path.
    setTimeout(function () {
      window.location.href = 'unchained://paid';
    }, 600);
  </script>
</body>
</html>
`;

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

    try {
      // /health and /v1/entitlement don't talk to Stripe, so they must not
      // require STRIPE_SECRET_KEY — building the client is deferred until a
      // route that actually needs it.
      if (pathname === '/v1/entitlement' && request.method === 'GET') {
        return await handleEntitlement(url, env);
      }
      if (pathname === '/v1/owner/request-code' && request.method === 'POST') {
        return await handleOwnerRequestCode(env);
      }
      if (pathname === '/v1/owner/verify-code' && request.method === 'POST') {
        return await handleOwnerVerifyCode(request, env);
      }
      if (pathname === '/' || pathname === '/health') {
        return json({ ok: true, service: 'unchained-stripe-backend' });
      }
      if (pathname === '/paid' && request.method === 'GET') {
        return new Response(PAID_HTML, {
          headers: { 'content-type': 'text/html; charset=utf-8' },
        });
      }

      const stripe = new Stripe(env.STRIPE_SECRET_KEY, {
        httpClient: Stripe.createFetchHttpClient(),
        apiVersion: '2025-08-27.basil',
      });

      if (pathname === '/v1/subscribe' && request.method === 'POST') {
        return await handleSubscribe(request, env, stripe);
      }
      if (pathname === '/v1/webhook' && request.method === 'POST') {
        return await handleWebhook(request, env, stripe);
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
  console.log(`webhook event received: type=${type} id=${event.id} customer=${obj.customer} status=${obj.status}`);

  // Resolve the customer's email (some events carry it, some need a lookup).
  async function emailFor(customerId) {
    if (!customerId) return null;
    const c = await stripe.customers.retrieve(customerId).catch((err) => {
      console.error(`customer lookup failed for ${customerId}: ${err && err.message || err}`);
      return null;
    });
    if (!c || c.deleted) {
      console.log(`customer ${customerId} missing or deleted`);
      return null;
    }
    if (!c.email) {
      console.log(`customer ${customerId} has no email on file`);
    }
    return (c.email || '').toLowerCase() || null;
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

// ── POST /v1/owner/request-code ──────────────────────────────────────────────
// Generates a fresh 6-digit code, stores it in KV for 10 minutes, and emails it
// to env.OWNER_EMAIL via Resend. Rate-limited to one send per 60s (Cloudflare
// KV's minimum TTL) so a stuck "resend" button can't spam the inbox. Ignores
// any email in the request body — there is exactly one recipient, fixed
// server-side.
const CODE_TTL_SECONDS = 600;
const MAX_ATTEMPTS = 5;
const RESEND_COOLDOWN_SECONDS = 60;

async function handleOwnerRequestCode(env) {
  const now = Date.now();
  const lastSentRaw = await env.OWNER_CODES.get('lastSent');
  if (lastSentRaw && now - Number(lastSentRaw) < RESEND_COOLDOWN_SECONDS * 1000) {
    return json({ error: 'rate_limited' }, 429);
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));
  await env.OWNER_CODES.put(
    'verify',
    JSON.stringify({ code, attempts: 0 }),
    { expirationTtl: CODE_TTL_SECONDS },
  );
  await env.OWNER_CODES.put('lastSent', String(now), {
    expirationTtl: RESEND_COOLDOWN_SECONDS,
  });

  const emailResponse = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${env.RESEND_API_KEY}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      from: 'Unchained <onboarding@resend.dev>',
      to: [env.OWNER_EMAIL],
      subject: 'Your Unchained owner verification code',
      text: `Your verification code is ${code}. It expires in 10 minutes.`,
    }),
  });
  if (!emailResponse.ok) {
    const detail = await emailResponse.text().catch(() => '');
    console.error(`Resend send failed: ${emailResponse.status} ${detail}`);
    return json({ error: 'send_failed' }, 502);
  }

  return json({ sent: true });
}

// ── POST /v1/owner/verify-code ───────────────────────────────────────────────
// Body: { "code": "123456" }. Consumes the code on a correct match (one-time
// use); locks it out after 5 wrong guesses, forcing a fresh request-code.
async function handleOwnerVerifyCode(request, env) {
  const body = await request.json().catch(() => ({}));
  const submitted = String(body.code || '').trim();

  const raw = await env.OWNER_CODES.get('verify');
  if (!raw) return json({ valid: false });

  const record = JSON.parse(raw);
  if (record.attempts >= MAX_ATTEMPTS) {
    await env.OWNER_CODES.delete('verify');
    return json({ valid: false });
  }

  if (submitted && submitted === record.code) {
    await env.OWNER_CODES.delete('verify');
    return json({ valid: true });
  }

  record.attempts += 1;
  await env.OWNER_CODES.put('verify', JSON.stringify(record), {
    expirationTtl: CODE_TTL_SECONDS,
  });
  return json({ valid: false });
}
