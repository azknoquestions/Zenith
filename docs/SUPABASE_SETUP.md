# Zenith + Supabase

Zenith can use **Supabase** for cloud backend and optional data sync.

## Project (already created)

- **Project ID:** `ikoekzsnhyessmmdpjxp`
- **URL:** `https://ikoekzsnhyessmmdpjxp.supabase.co`
- **Region:** us-east-1

## 1. Supabase URL and keys in the app

In the iOS app, point to Supabase for the API base URL and use the anon key for Edge Function calls:

- **Supabase URL:** `https://ikoekzsnhyessmmdpjxp.supabase.co`
- **Edge Functions base:** `https://ikoekzsnhyessmmdpjxp.supabase.co/functions/v1`
- **Anon key:** Set in `ApiConfig` or via Xcode environment (see below). Get from [Supabase Dashboard](https://supabase.com/dashboard/project/ikoekzsnhyessmmdpjxp/settings/api): Project Settings → API → anon public.

The app sends the anon key in the `Authorization: Bearer <anon_key>` header for all Supabase requests (see `ApiConfig.supabaseAnonKey` and `supabaseHeaders()`). If your project’s anon key differs, update `ApiConfig.supabaseAnonKey` in Xcode. Edge Functions can use JWT verification (default) or be deployed with `verify_jwt: false`.

## 2. Secrets (for Edge Functions) — free, no separate backend

The **zenith-api** Edge Function runs the full backend (Topstep, news, AI) on Supabase. **No Node server, Render, or BACKEND_URL needed.** Set these in [Supabase Dashboard](https://supabase.com/dashboard/project/ikoekzsnhyessmmdpjxp/settings/functions) → Edge Functions → Secrets:

| Secret | Required for | Description |
|--------|----------------|--------------|
| `PROJECTX_BASE_URL` | Topstep (accounts, quotes, orders, bars) | Optional override. Default: `https://api.topstepx.com` (Topstep gateway). No trailing slash. |
| `FINNHUB_API_KEY` | News headlines + economic events | Your Finnhub API key. |
| `NEWSDATA_API_KEY` | Extra news (optional) | Your NewsData.io API key. |
| `NVIDIA_API_KEY` | AI chat | Your NVIDIA API key. |

The app sends the **user’s Topstep API key** in the request header; you don’t put it in Supabase. After adding or changing secrets, redeploy the **zenith-api** function (Dashboard → Edge Functions → zenith-api → Deploy, or `supabase functions deploy zenith-api`).

## 3. Apply migrations

Migrations live under `supabase/migrations/`. Apply them via:

- **Supabase MCP (Cursor):** use the `apply_migration` tool with `project_id: ikoekzsnhyessmmdpjxp` and the migration name + SQL.
- **Supabase CLI:** `supabase link --project-ref ikoekzsnhyessmmdpjxp` then `supabase db push`.

## 4. Deploy the zenith-api Edge Function (required — 404 means it’s not deployed)

The app calls `https://ikoekzsnhyessmmdpjxp.supabase.co/functions/v1/zenith-api`. If you see **HTTP 404**, the function is not deployed yet.

**Option A — Supabase CLI (recommended)**  
From the repo root:

```bash
cd "/Users/zak/Library/Mobile Documents/com~apple~CloudDocs/Zenith"
npx supabase functions deploy zenith-api --project-ref ikoekzsnhyessmmdpjxp
```

You’ll be prompted to log in if needed. The function code is in `supabase/functions/zenith-api/index.ts`.

**Option B — Supabase Dashboard**  
1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/ikoekzsnhyessmmdpjxp/functions).  
2. Create a new function named **zenith-api**, paste the contents of `supabase/functions/zenith-api/index.ts`, and deploy.

After deploying, set the secrets (see section 2) and try the app again.

## 5. iOS and Supabase

The app is already set to use Supabase (`useSupabase = true` in `ApiConfig.swift`). It calls the **zenith-api** Edge Function. All logic runs on Supabase’s free tier — no separate backend or Render. Just set the four secrets above and redeploy the function; the app works on any mobile device.

## 6. Optional: sync watchlist and risk settings

If you applied the `user_settings` migration and use Supabase Auth (e.g. anonymous sign-in), the app can read/write `user_settings` (watchlist, risk_settings) from Supabase so they sync across devices. The current app uses local storage only until you add the Supabase client and auth.
