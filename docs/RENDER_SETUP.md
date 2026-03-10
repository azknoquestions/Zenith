# Deploy Zenith backend to Render

Use this so the app works from anywhere (no localhost). After deployment, the iOS app talks to `https://zenith-backend.onrender.com` (or whatever name you give the service).

## 1. Create the Web Service on Render

1. Go to [dashboard.render.com](https://dashboard.render.com) and sign in (or create an account).
2. Click **New +** → **Web Service**.
3. Connect **GitHub** if you haven’t already, and select the **Zenith** repo (`azknoquestions/Zenith`).
4. Use these settings:

   | Field | Value |
   |-------|--------|
   | **Name** | `zenith-backend` (or any name; the app URL is set in `ApiConfig.swift` to match) |
   | **Region** | Choose closest to you |
   | **Branch** | `main` |
   | **Root Directory** | `backend` |
   | **Runtime** | Node |
   | **Build Command** | `npm install && npm run build` |
   | **Start Command** | `npm start` |
   | **Instance Type** | Free (or paid if you prefer) |

5. Click **Advanced** and add **Environment Variables**. Add each key from your local `.env` (do **not** commit `.env`):

   | Key | Required for | Value |
   |-----|----------------|-------|
   | `PROJECTX_BASE_URL` | Topstep / accounts, quotes, orders | `https://api.topstepx.com` (no trailing slash; Topstep gateway) |
   | `FINNHUB_API_KEY` | News headlines + economic events | your Finnhub key |
   | `NEWSDATA_API_KEY` | Extra news (optional) | your NewsData.io key |
   | `NVIDIA_API_KEY` | AI chat | your NVIDIA API key |
   | `TOPSTEP_BASE_URL` | (optional) | `https://api.topstep.com` |

   The app sends the **user’s Topstep API key** from the device; the backend uses `PROJECTX_BASE_URL` to talk to ProjectX. For “accounts fetch failed” or news not loading, confirm these env vars are set on Render and that `ApiConfig.baseURL` in the app matches your Render URL. Leave `PORT` unset; Render sets it automatically.

6. Click **Create Web Service**. Render will clone the repo, run the build in `backend`, and start the server.

## 2. Get your URL and test

- When the deploy finishes, Render shows the service URL, e.g.  
  `https://zenith-backend.onrender.com`
- In a browser or terminal:

  ```bash
  curl https://zenith-backend.onrender.com/health
  ```

  You should see: `{"status":"ok","service":"zenith-backend"}`

## 3. Match the iOS app to your URL

- The app uses **direct backend** by default (`useSupabase = false`). It calls `baseURL` in `ios/Zenith/Zenith/Services/ApiConfig.swift` (e.g. **https://zenith-backend.onrender.com**).
- If your Render service has a different name, set `baseURL` to that URL (e.g. `https://zenith-api.onrender.com`). That’s the server where your API keys must be set (Render Environment tab).

## 4. Test the app

- Build and run the Zenith app on your phone (or simulator). News, Events, and Zenith AI all use the deployed backend; no need to run anything on your Mac.

## Troubleshooting

- **Build fails**: Check the Render build logs. Ensure **Root Directory** is `backend` and that `npm run build` produces `backend/dist/index.js`.
- **Health check fails**: Confirm env vars are set in Render (Environment tab). Restart the service after changing them.
- **App can’t reach backend**: Confirm the URL in `ApiConfig.swift` matches the Render service URL (including `https://`).
