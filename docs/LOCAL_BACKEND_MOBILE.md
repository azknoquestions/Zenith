# Run backend locally and test on your phone (optional)

**Recommended:** Use **Supabase only** (no local backend). Set `PROJECTX_BASE_URL`, `FINNHUB_API_KEY`, `NEWSDATA_API_KEY`, and `NVIDIA_API_KEY` in Supabase Edge Function secrets and redeploy **zenith-api**. The app then works on mobile for free with no separate server.

If you prefer to run the Node backend on your Mac and proxy through Supabase, use **ngrok** as below. You would need to restore the proxy-only Edge Function and set `BACKEND_URL` to your ngrok URL.

## 1. Run the backend on your Mac

```bash
cd backend
npm run dev
```

The server runs at `http://localhost:4000`. Your **`.env`** in `backend/` is used (all API keys stay on your machine).

## 2. Expose it with ngrok

1. Install [ngrok](https://ngrok.com) (e.g. `brew install ngrok` or download from ngrok.com).
2. In a second terminal:

   ```bash
   ngrok http 4000
   ```

3. Copy the **HTTPS** URL ngrok shows (e.g. `https://abc123.ngrok-free.app`). This URL changes each time you start ngrok (unless you have a paid plan with a fixed subdomain).

## 3. Point Supabase at your backend

1. Open [Supabase Dashboard](https://supabase.com/dashboard/project/ikoekzsnhyessmmdpjxp/settings/functions) → your project → **Edge Functions** → **Secrets**.
2. Add or edit:
   - **Name:** `BACKEND_URL`
   - **Value:** your ngrok HTTPS URL (e.g. `https://abc123.ngrok-free.app`) — **no trailing slash**.

The **zenith-api** Edge Function forwards the app’s requests to this URL. Your phone → Supabase → ngrok → your Mac’s Node server (and its `.env`).

## 4. Test on your phone

- Keep `npm run dev` and `ngrok http 4000` running.
- On your phone, open the Zenith app. It already uses Supabase; Supabase will proxy to your ngrok URL.
- Accounts, news, and AI use the keys in your local `backend/.env`.

## Notes

- If you restart ngrok, the URL changes — update `BACKEND_URL` in Supabase.
- The Edge Function was updated to use **`BACKEND_URL`** (not `RENDER_BACKEND_URL`). If you had the old secret, add `BACKEND_URL` and you can remove the old one.
- Redeploy the **zenith-api** Edge Function after changing the code (e.g. the secret name). If you only changed the secret in the dashboard, no redeploy is needed.
