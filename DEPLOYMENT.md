# Deployment Guide for Campus Assistant Web

This guide covers how to deploy your full-stack application (React Native Frontend + Node.js Backend).

## Prerequisites

1.  **Vercel Account**: [Sign up here](https://vercel.com/signup).
2.  **GitHub Repository**: Ensure your code is pushed to GitHub.

---

## Part 1: Deploying Frontend (Vercel)

Vercel is excellent for deploying Vite/React apps.

1.  **Log in to Vercel** and go to your **Dashboard**.
2.  Click **"Add New..."** -> **"Project"**.
3.  **Import** your GitHub repository (`Campus-Assistant-Web`).
4.  **Configure Project**:
    *   **Framework Preset**: Select `Vite`.
    *   **Root Directory**: Click `Edit` and select `frontend`. **This is crucial.**
    *   **Environment Variables**: Add any frontend env vars here (e.g., `VITE_CLERK_PUBLISHABLE_KEY`, `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_API_URL`).
        *   *Note*: For `VITE_API_URL`, you will perform this deployment *first*, then come back and update it once your backend is deployed.
5.  Click **Deploy**.

Your frontend is now live!

---

## Part 2: Deploying Backend

You have two main options for the backend.

### Option A: Vercel (Serverless) - *Quickest*
**Best for:** Simple APIs, quick setup.
**Limitation:** Free plan has a 10-second timeout. Long-running AI requests might time out.

1.  **Go to Vercel Dashboard** again.
2.  Click **"Add New..."** -> **"Project"**.
3.  **Import** the *same* GitHub repository (`Campus-Assistant-Web`) again.
4.  **Configure Project**:
    *   **Project Name**: Give it a different name (e.g., `campus-assistant-backend`).
    *   **Framework Preset**: Select `Other`.
    *   **Root Directory**: Click `Edit` and select `backend`.
    *   **Build Command**: `npm run build` (or leave default if it picks up `tsc`).
    *   **Output Directory**: `dist` (or leave default).
    *   **Environment Variables**: copy all variables from your `backend/.env` file (e.g., `PORT`, `DATABASE_URL`, `SUPABASE_URL`, `GEMINI_API_KEY`, etc.).
5.  **Important**: Ensure the `vercel.json` file exists in your `backend` folder (I have created this for you).
6.  Click **Deploy**.

### Option B: Render or Railway (Persistent Server) - *Recommended for AI*
**Best for:** Long-running tasks, WebSockets, reliability.

1.  **Sign up** at [Render.com](https://render.com/).
2.  Click **New +** -> **Web Service**.
3.  Connect your GitHub repo.
4.  **Settings**:
    *   **Root Directory**: `backend`
    *   **Build Command**: `npm install && npm run build`
    *   **Start Command**: `npm start`
5.  **Environment Variables**: Add all your backend secrets here.
6.  Click **Create Web Service**.

---

## Part 3: Connecting Frontend to Backend

Once your backend is deployed (either on Vercel or Render), you will get a URL (e.g., `https://campus-assistant-backend.vercel.app` or `https://campus-api.onrender.com`).

1.  Go back to your **Frontend Project on Vercel**.
2.  Go to **Settings** -> **Environment Variables**.
3.  Edit (or Add) `VITE_API_URL`.
4.  Set the value to your new backend URL (e.g., `https://campus-assistant-backend.vercel.app`).
    *   *Note*: Ensure no trailing slash `/` if your code appends it, or check your API calls.
5.  Go to **Deployments** and **Redeploy** the latest commit for changes to take effect.
