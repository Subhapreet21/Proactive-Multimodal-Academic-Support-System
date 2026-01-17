# 🚀 Ultimate Deployment Guide: Campus Assistant

This guide covers the **Full Production Deployment**. By the end, you will have:
1.  A **Backend** running 24/7 on the Cloud (Render).
2.  A **Mobile App** (APK) installed on your phone that works **anywhere** (not just on home WiFi).

---

## 🌩️ Phase 1: Deploy Backend to Cloud (Render)
*Goal: Move the Node.js server from your laptop to the internet.*

1.  **Push to GitHub**: Ensure your project code is pushed to a GitHub Repository.
2.  **Create Service**:
    *   Go to [Render.com](https://render.com) and create a **"Web Service"**.
    *   Connect your GitHub Repo.
3.  **Configure Render**:
    *   **Root Directory**: `backend`
    *   **Runtime**: `Node`
    *   **Build Command**: `npm install && npm run build`
    *   **Start Command**: `npm run serve`
4.  **Add Environment Variables** (in Render "Environment" tab):
    *   `GEMINI_API_KEY`: *(Your Key ending in ...Ma38)*
    *   `GEMINI_API_KEY_2`: *(Second Key)*
    *   `SUPABASE_URL`: *(From your .env)*
    *   `SUPABASE_ANON_KEY`: *(From your .env)*
    *   `PORT`: `5002`
5.  **Deploy**: Click "Create Web Service". Wait for it to go live.
    *   **Copy the URL** it gives you (e.g., `https://my-campus-app.onrender.com`).

---

## 🔗 Phase 2: Connect App to Cloud
*Goal: Tell the mobile app to talk to the new Cloud Server instead of your laptop.*

1.  Open your local project file: `flutter_app/.env`.
2.  Update the `API_URL`:
    ```properties
    # OLD (Local): API_URL=http://10.43.155.145:5002
    # NEW (Cloud):
    API_URL=https://my-campus-app.onrender.com
    ```
    *(Use the actual URL from Render)*.

---

## 📱 Phase 3: Build & Install Mobile App
*Goal: Create the final installer file.*

1.  Open your terminal in VS Code.
2.  Navigate to the Flutter folder and build:
    ```powershell
    cd flutter_app
    flutter clean
    flutter build apk --release
    ```
3.  **Wait**: This takes 2-5 minutes.
4.  **Locate the APK**:
    *   File is at: `flutter_app\build\app\outputs\flutter-apk\app-release.apk`
5.  **Install**:
    *   Copy this file to your Android phone (USB, WhatsApp, Drive).
    *   Tap to install.

---

## 🎉 Success!
You now have a **Production-Grade Application**.
*   **No Laptop Required**: You can turn off your computer. The backend runs on Render.
*   **Works Anywhere**: You can use the app on 4G, University WiFi, or anywhere else.
