# Topstep / ProjectX API key setup

Zenith uses the **ProjectX Gateway API** (Topstep’s platform) so you can see your accounts and trade. You need a **TopstepX API key** (and, for full API use, your **username**) from Topstep.

## 1. Get your API key from Topstep

1. Log in to your **Topstep** account at [topstep.com](https://www.topstep.com).
2. Open **TopstepX™ API Access** in the help center:  
   [TopstepX API Access – Topstep Help Center](https://help.topstep.com/en/articles/11187768-topstepx-api-access)
3. In your Topstep dashboard, go to **Settings** (or **Account** / **API**) and find the **API** or **TopstepX** section.
4. **Create** or **view** your API key. Copy:
   - Your **username** (if shown).
   - Your **API key** (the secret string).
5. Keep these private. Do not share them or commit them to code.

If you don’t see an API section, contact Topstep support and ask for **TopstepX API access** for the ProjectX Gateway.

## 2. How the API auth works (for reference)

The ProjectX Gateway uses **JSON Web Tokens**. Your app sends your credentials once; the server returns a **session token** that is used for later API calls.

- **Auth endpoint (API key):**  
  `POST https://api.thefuturesdesk.projectx.com/api/Auth/loginKey`
- **Body:**  
  `{ "userName": "your_username", "apiKey": "your_api_key" }`
- **Response:**  
  `{ "token": "your_session_token_here", "success": true, "errorCode": 0 }`

Official docs:

- [ProjectX Gateway API – Intro](https://gateway.docs.projectx.com/docs/intro)
- [Authenticate (with API key)](https://gateway.docs.projectx.com/docs/getting-started/authenticate/authenticate-api-key)
- [Connection URLs](https://gateway.docs.projectx.com/docs/getting-started/connection-urls)

## 3. In Zenith

- **First launch:** The app asks for your **TopstepX API key** (and in a future version may also ask for your Topstep **username** for full ProjectX auth).
- Paste the API key (and username if prompted), then tap **Save and continue**. Zenith stores it locally and uses it to talk to the Zenith backend, which can then authenticate to ProjectX on your behalf when we wire the live Topstep/ProjectX endpoints.

## 4. If something doesn’t work

- Confirm you’re using the key from **Topstep** (TopstepX / ProjectX), not a different service.
- Check [TopstepX API Access](https://help.topstep.com/en/articles/11187768-topstepx-api-access) again for dashboard changes.
- For API errors, see [ProjectX Gateway – Authenticate (API key)](https://gateway.docs.projectx.com/docs/getting-started/authenticate/authenticate-api-key).
