# ☁️ Backend Hosting Guide (Render.com)

Yes! Hosting your backend on a Cloud Server is the **professional/correct** way to deploy. It means your app will work anywhere (University, Home, 4G) **without** your laptop being on or connected.

I recommend **Render.com** because it has a generous **Free Tier** for Node.js apps and connects directly to GitHub.

---

## Step 1: Push your code to GitHub
If you haven't already:
1.  Create a strict repository for your project on GitHub.
2.  Push your code.

## Step 2: Create Web Service on Render
1.  Sign up at [render.com](https://render.com).
2.  Click **"New +"** -> **"Web Service"**.
3.  Connect your GitHub repository.
4.  **Important Settings**:
    *   **Root Directory**: `backend` (Since your `package.json` is inside the `backend` folder).
    *   **Environment**: `Node`
    *   **Build Command**: `npm install && npm run build`
        *(This compiles your TypeScript to JavaScript)*.
    *   **Start Command**: `npm run serve`
        *(This uses the "serve" script I saw in your package.json: `node dist/index.js`)*.

## Step 3: Add Environment Variables
On Render, go to the **"Environment"** tab and add your keys from `.env`.
*You MUST add these, or the app will crash.*

| Key | Value (Copy from your local .env) |
| :--- | :--- |
| `GEMINI_API_KEY` | `...Ma38` (or your valid key) |
| `GEMINI_API_KEY_2` | `...` |
| `SUPABASE_URL` | `https://...` |
| `SUPABASE_ANON_KEY` | `ey...` |
| `PORT` | `5002` (or 8000, Render overrides this automatically usually) |

## Step 4: Deploy & Get URL
1.  Click **Create Web Service**.
2.  Wait ~2 minutes.
3.  Render will give you a public URL (e.g., `https://proactive-system-backend.onrender.com`).

---

## Step 5: Update Flutter App
Now that your backend is on the cloud, update your mobile app to talk to *that* URL instead of your laptop.

1.  Open `flutter_app/.env`.
2.  Update `API_URL`:
    ```properties
    # Old: API_URL=http://10.43.155.145:5002
    API_URL=https://proactive-system-backend.onrender.com
    ```
3.  **Rebuild** your app (`flutter build apk --release`).

## 🎉 Result
Your app now works **globaly**. You can turn off your laptop, go to campus, and the app will still function perfectly because the backend is living in the cloud!
