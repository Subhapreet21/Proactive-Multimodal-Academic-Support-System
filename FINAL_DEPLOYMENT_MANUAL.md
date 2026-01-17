# 📖 The Final Deployment Manual

This is your **Complete Production Bible**.
It unifies everything: Cloud Hosting, Database Maintenance (Cron Job), and Mobile App Release.

---

## 🌩️ Phase 1: Backend (Cloud Hosting)
*Objective: Host the Node.js server 24/7 for free on Render.*

### 1.1 Prepare Code
*   Ensure your latest code is pushed to your **GitHub Repository**.

### 1.2 Create Render Service
1.  Sign up at [render.com](https://render.com).
2.  Click **"New +"** -> **"Web Service"**.
3.  Connect your GitHub Repo.
4.  **Critical Configuration**:
    *   **Root Directory**: `backend`
    *   **Environment**: `Node`
    *   **Build Command**: `npm install && npm run build`
    *   **Start Command**: `npm run serve`
5.  **Environment Variables** (Add these in the "Environment" tab):
    *   `GEMINI_API_KEY`: *(Key ending in ...Ma38)*
    *   `GEMINI_API_KEY_2`: *(Your backup key)*
    *   `SUPABASE_URL`: *(From your local .env)*
    *   `SUPABASE_SERVICE_ROLE_KEY`: *(From your local .env)*
6.  **Deploy**: Click Create.
    *   Wait for the green checkmark.
    *   **Copy your URL**: `https://your-app-name.onrender.com`.

---

## ⏰ Phase 2: Cron Job (Keep-Alive)
*Objective: Prevent the Free Tier server from sleeping (15 mins) and Database from pausing (7 days).*

### 2.1 The "Cron" Logic
I have already added a special route in your code: `/api/health`.
When this URL is hit:
1.  **Render** wakes up (Reset sleep timer).
2.  **Supabase** executes a query (Reset pause timer).

### 2.2 Setup UptimeRobot (The Automator)
1.  Register at [uptimerobot.com](https://uptimerobot.com/) (Free).
2.  Click **Add New Monitor**.
    *   **Type**: HTTP(s).
    *   **Friendly Name**: Campus Keep Alive.
    *   **URL**: `https://your-app-name.onrender.com/api/health`
        *(Checking endpoint: MUST include `/api/health`)*.
    *   **Interval**: **10 minutes** (Crucial! Must be < 14 mins).
3.  **Create Monitor**.

**Result**: Your "Cron Job" is now active. It will ping your server every 10 mins forever.

---

## 📱 Phase 3: Frontend (Mobile App)
*Objective: Build the installer file connected to the Cloud.*

### 3.1 Link Frontend to Cloud
1.  Open `flutter_app/.env` in VS Code.
2.  Update `API_URL`:
    ```properties
    # API_URL=http://localhost:5002  <-- OLD
    API_URL=https://your-app-name.onrender.com
    ```
    *(Paste the Render URL from Phase 1)*.

### 3.2 Build APK
1.  Open Terminal in VS Code.
2.  Run the build command:
    ```powershell
    cd flutter_app
    flutter clean
    flutter build apk --release
    ```
3.  Wait ~3 minutes.

### 3.3 install
1.  Retrieve file: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`.
2.  Send to phone & Install.

---

## ✅ Final Checklist
- [ ] Backend is active on Render.
- [ ] UptimeRobot is pinging `/api/health` (Green status).
- [ ] Mobile App installed on phone.
- [ ] App works on 4G (WiFi off).

**Congratulations! Your solution is now a standalone product.** 🚀
