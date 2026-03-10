# Fully functional on mobile — free (Supabase only)

Zenith can run entirely on **Supabase’s free tier** with no Render, no paid hosting, and no local server. Your phone talks only to Supabase.

## What you need

1. **Supabase project** (already created: `ikoekzsnhyessmmdpjxp`).
2. **API keys** (from free or trial tiers of each service):
   - **Topstep:** User enters their TopstepX API key in the app (Manage → Connect Topstep). No key in Supabase.
   - **Finnhub:** [finnhub.io](https://finnhub.io) — free tier for news and economic calendar.
   - **NewsData.io (optional):** [newsdata.io](https://newsdata.io) — free tier for extra headlines.
   - **NVIDIA:** [NVIDIA API](https://build.nvidia.com) — for AI chat (check their free tier).

## Setup (one time)

1. **Supabase Dashboard** → your project → **Edge Functions** → **Secrets**. Add:

   | Name | Value |
   |------|--------|
   | `PROJECTX_BASE_URL` | `https://api.topstepx.com` (optional; this is the default) |
   | `FINNHUB_API_KEY` | your Finnhub key |
   | `NEWSDATA_API_KEY` | your NewsData.io key (optional) |
   | `NVIDIA_API_KEY` | your NVIDIA API key |

2. **Deploy the Edge Function** (if you haven’t already):
   - Dashboard → Edge Functions → **zenith-api** → Deploy (upload the code from `supabase/functions/zenith-api/`), or  
   - CLI: `supabase functions deploy zenith-api --project-ref ikoekzsnhyessmmdpjxp`

3. **iOS app:** Keep `useSupabase = true` in `ApiConfig.swift`. No other change.

## Flow

- **Phone** → HTTPS → **Supabase Edge Function (zenith-api)** → ProjectX / Finnhub / NewsData / NVIDIA APIs.
- All logic runs inside the Edge Function. No Node server, no Render, no `BACKEND_URL`, no ngrok.

## Limits (Supabase free tier)

- Edge Function invocations: 500K/month on free tier.
- If you hit limits, consider upgrading Supabase or caching where appropriate.
