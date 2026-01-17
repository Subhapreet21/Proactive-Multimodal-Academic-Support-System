# 📱 Deployment & Standalone Release Guide

This guide covers how to run your app on your phone **without** a PC connection.

## 1. Deploy the Backend (Required)
Since you won't be running `npm run dev` on your PC, your phone needs a live server to talk to.

### Option A: Render (Free & Easy)
1.  Push your project to **GitHub**.
2.  Go to [Render Dashboard](https://dashboard.render.com/).
3.  Click **New +** $\to$ **Web Service**.
4.  Connect your GitHub repository.
5.  **Settings**:
    -   **Root Directory**: `backend`
    -   **Build Command**: `npm install && npm run build` (or just `npm install` if no build script)
    -   **Start Command**: `npm start`
6.  **Environment Variables**:
    -   Copy all variables from `backend/.env` (SUPABASE_URL, GEMINI_API_KEY, etc.) into Render's "Environment" tab.
7.  **Deploy**: Wait for it to finish. You will get a URL like `https://campus-assistant.onrender.com`.

## 2. Configure Flutter App
Now point your mobile app to this real server instead of your laptop.

1.  Open `flutter_app/.env`.
2.  Update `API_URL`:
    ```ini
    # .env
    API_URL=https://campus-assistant.onrender.com
    # (Use the actual URL you got from Render, NO trailing slash)
    ```

## 3. Build Release APK
This creates the standalone installer file.

1.  Open a terminal in `flutter_app/`.
2.  Run:
    ```bash
    flutter build apk --release
    ```
3.  Wait for it to finish. The file will be at:
    `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

## 4. Install on Phone
1.  **Transfer**: Send this `app-release.apk` file to your phone (via WhatsApp, Google Drive, or USB transfer).
2.  **Install**: Tap the file on your phone. You may need to allow "Install from Unknown Sources".
3.  **Run**: Open the app. It will now connect to the cloud backend and work completely offline from your PC! 🚀
