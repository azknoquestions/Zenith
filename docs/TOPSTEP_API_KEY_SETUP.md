# Topstep / ProjectX API key setup

Zenith uses the **ProjectX Gateway API** (Topstep’s platform) so you can see your accounts and trade. You need a **TopstepX API key** and your **Topstep account username** from Topstep.

## 1. Get your API key and username from Topstep

1. Log in to your **Topstep** account at [topstep.com](https://www.topstep.com).
2. Open **TopstepX™ API Access** in the help center:  
   [TopstepX API Access – Topstep Help Center](https://help.topstep.com/en/articles/11187768-topstepx-api-access)
3. In your Topstep dashboard, go to **Settings** → **API** (or **Account** / **TopstepX**). Use **“Link to ProjectX Dashboard”** if shown.
4. Click **“ADD API KEY”** and wait for the key to generate. Copy the key (use the copy icon; avoid screenshots).
5. Note your **username**: the username you use to log in to Topstep (or the Broker UserID shown in the API section). Many keys are tied to this username—if you get 401, try filling the **Username** field in Zenith with this value.
6. Keep key and username private. Do not share them or commit them to code.

If you don’t see an API section, contact Topstep support and ask for **TopstepX API access** for the ProjectX Gateway.

## 2. How the API auth works (for reference)

The ProjectX Gateway uses **JSON Web Tokens**. Your app sends **userName** and **apiKey** once; the server returns a **session token** used for later API calls.

- **Auth endpoint (API key):**  
  `POST https://api.topstepx.com/api/Auth/loginKey`
- **Headers:**  
  `Content-Type: application/json`, `Accept: application/json`
- **Body:**  
  `{ "userName": "your_topstep_username", "apiKey": "your_api_key" }`  
  Use your real Topstep login username (or Broker UserID). A generic placeholder like `"trader"` may be rejected (UserNotFound).
- **Success response:**  
  `{ "token": "your_session_token_here", "success": true, "errorCode": 0, "errorMessage": null }`
- **Failure:**  
  The API may return HTTP 200 with `success: false` and an `errorCode`. See section 5 for codes.

Official docs:

- [ProjectX Gateway API – Intro](https://gateway.docs.projectx.com/docs/intro)
- [Authenticate (with API key)](https://gateway.docs.projectx.com/docs/getting-started/authenticate/authenticate-api-key)
- [Connection URLs](https://gateway.docs.projectx.com/docs/getting-started/connection-urls)
- [Swagger](https://api.thefuturesdesk.projectx.com/swagger/index.html) (definitions for `LoginApiKeyRequest`, `LoginResponse`, `LoginErrorCode`)

## 3. Backend configuration

Your Zenith backend must have the correct ProjectX gateway URL so it can reach Topstep:

- **`PROJECTX_BASE_URL`** – ProjectX Gateway base URL. Default: `https://api.topstepx.com` (Topstep gateway; Topstep-issued keys use this). Optional override in Supabase secrets or backend `.env`. No trailing slash. The generic gateway `https://api.thefuturesdesk.projectx.com` is for other firms; Topstep keys require the Topstep gateway.

The backend exposes a **connection check** at `GET /topstep/connection`. The app sends your API key (and optional username) in headers and receives `{ "connected": true, "accountCount": n }` or `{ "connected": false, "error": "...", "message": "..." }`.

## 4. In Zenith

- **First launch:** The app asks for your **TopstepX API key**. Paste it and tap **Save and continue**.
- **Manage → Connect Topstep:** You can change the key anytime, add an optional **username** (if your key is tied to a username), and tap **Test connection** to verify before saving. Status shows **Connected (N accounts)** or a clear error (e.g. invalid key, timeout, server unavailable).

## 5. If something doesn’t work

- Confirm you’re using the key from **Topstep** (TopstepX / ProjectX), not a different service.
- **Username:** Use your actual Topstep account username (the one you use to log in, or the Broker UserID in Settings → API). Leaving it blank uses a default that can cause **UserNotFound**.
- **401 / invalid key:** In Zenith, use **Test connection** and check the debug response. It includes `projectXBody.errorCode` and `projectXBody.errorMessage` from ProjectX.

ProjectX **LoginErrorCode** (from Swagger) for `loginKey`:

| Code | Name | Meaning |
|------|------|---------|
| 0 | Success | Auth succeeded. |
| 1 | UserNotFound | Username not found—use your Topstep account username. |
| 3 | InvalidCredentials | Key and username don’t match. Use the exact email you use at topstep.com; create a new API key in Settings → API; or contact Topstep. |
| 9 | ApiSubscriptionNotFound | TopstepX API access not enabled for this account. |
| 10 | ApiKeyAuthenticationDisabled | API key auth disabled—enable in Topstep settings. |

- Check [TopstepX API Access](https://help.topstep.com/en/articles/11187768-topstepx-api-access) for dashboard changes.
- For API details: [ProjectX Gateway – Authenticate (API key)](https://gateway.docs.projectx.com/docs/getting-started/authenticate/authenticate-api-key).
