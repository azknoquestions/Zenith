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

   | Key | Value (paste from your .env) |
   |-----|------------------------------|
   | `FINNHUB_API_KEY` | your Finnhub key |
   | `NVIDIA_API_KEY` | your NVIDIA API key |
   | `TOPSTEP_BASE_URL` | `https://api.topstep.com` |

   Leave `PORT` unset; Render sets it automatically.

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

- The app is already set to use **https://zenith-backend.onrender.com** in `ios/Zenith/Zenith/Services/ApiConfig.swift`.
- If you used a **different service name** on Render (e.g. `zenith-api`), your URL will be `https://zenith-api.onrender.com`. In Xcode, open `ApiConfig.swift` and change the URL to that value.

## 4. Test the app

- Build and run the Zenith app on your phone (or simulator). News, Events, and Zenith AI all use the deployed backend; no need to run anything on your Mac.

## Troubleshooting

- **Build fails**: Check the Render build logs. Ensure **Root Directory** is `backend` and that `npm run build` produces `backend/dist/index.js`.
- **Health check fails**: Confirm env vars are set in Render (Environment tab). Restart the service after changing them.
- **App can’t reach backend**: Confirm the URL in `ApiConfig.swift` matches the Render service URL (including `https://`).
