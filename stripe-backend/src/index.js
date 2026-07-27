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

// 160x160 PNG of the app logo, embedded as base64 so the owner-code email
// shows it without depending on an externally hosted URL. Regenerate from
// assets/images/logo.png if the logo ever changes (resize to ~160x160 first
// -- the source asset is 1024x1024 and far too large to inline as-is).
const OWNER_EMAIL_LOGO_BASE64 = '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';

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
        return await handleOwnerRequestCode(env, url.origin);
      }
      if (pathname === '/v1/owner/verify-code' && request.method === 'POST') {
        return await handleOwnerVerifyCode(request, env);
      }
      // Serves the logo used in the owner-code email as a real image URL —
      // Gmail (and most webmail clients) silently strip inline base64 <img>
      // data URIs, so the logo must be hosted rather than embedded.
      if (pathname === '/assets/owner-code-logo.png' && request.method === 'GET') {
        const bytes = Uint8Array.from(atob(OWNER_EMAIL_LOGO_BASE64), (c) => c.charCodeAt(0));
        return new Response(bytes, {
          headers: {
            'content-type': 'image/png',
            'cache-control': 'public, max-age=31536000, immutable',
          },
        });
      }
      // Debug-only: renders the owner-code email body in a browser so it can
      // be inspected without sending a real email. Not linked from the app.
      if (pathname === '/v1/owner/preview-email' && request.method === 'GET') {
        return new Response(ownerCodeEmailHtml('123456', url.origin), {
          headers: { 'content-type': 'text/html; charset=utf-8' },
        });
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

// Branded HTML body for the owner-code email, matching the app's own dark
// palette (pure black background, #0A0E18 card, #1E5FFF accent — same values
// as the owner-unlock dialog in owner_unlock_dialog.dart). Explicit bgcolor
// attributes plus a "dark only" color-scheme hint keep it fixed regardless of
// the client's light/dark setting — without the hint, Gmail was auto-
// inverting an undeclared design (it inverted a plain white card into a
// near-black one before this was added). The logo is a hosted URL, not a
// data URI: Gmail (and most webmail clients) silently strip inline base64
// <img> tags, which otherwise falls back to broken alt text.
function ownerCodeEmailHtml(code, origin) {
  return `<!DOCTYPE html>
<html lang="en" style="background:#000000;">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="color-scheme" content="dark only" />
  <meta name="supported-color-schemes" content="dark only" />
  <style>
    html, body { background:#000000 !important; margin:0; padding:0; }
  </style>
</head>
<body style="margin:0;padding:0;background:#000000;" bgcolor="#000000">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#000000;padding:32px 16px;width:100%;" bgcolor="#000000">
    <tr><td align="center">
      <table role="presentation" width="100%" style="max-width:420px;background:#0A0E18;border-radius:16px;overflow:hidden;font-family:Arial,Helvetica,sans-serif;border:1px solid #1B2435;" bgcolor="#0A0E18">
        <tr><td align="center" style="padding:32px 32px 8px;">
          <img src="${origin}/assets/owner-code-logo.png" width="64" height="64" alt="Unchained" style="border-radius:14px;display:block;" />
        </td></tr>
        <tr><td align="center" style="padding:8px 32px 0;">
          <h1 style="margin:0;font-size:20px;color:#FFFFFF;font-weight:600;">Owner verification</h1>
        </td></tr>
        <tr><td align="center" style="padding:16px 32px 0;">
          <p style="margin:0;font-size:14px;line-height:1.5;color:#55606F;">Enter this code in the app to continue:</p>
        </td></tr>
        <tr><td align="center" style="padding:20px 32px;">
          <span style="display:inline-block;font-size:32px;font-weight:700;letter-spacing:8px;color:#1E5FFF;">${code}</span>
        </td></tr>
        <tr><td align="center" style="padding:0 32px 32px;">
          <p style="margin:0;font-size:12px;color:#9AA3B2;">Expires in 10 minutes. If you didn't request this, ignore this email.</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

async function handleOwnerRequestCode(env, origin) {
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
      html: ownerCodeEmailHtml(code, origin),
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
