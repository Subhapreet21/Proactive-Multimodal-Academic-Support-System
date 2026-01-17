# ⚡ Keep-Alive Guide: Beat the Free Tier Limits

You correctly identified two annoying limits of Free Tiers:
1.  **Render**: Sleeps after 15 mins of inactivity.
2.  **Supabase**: Pauses project after 1 week of inactivity.

I have implemented a **"Two-Birds-One-Stone"** fix locally (`/api/health`). Here is how to use it.

---

## 🛠️ The Strategy
I added a special endpoint: **`/api/health`**
*   When accessed, it wakes up the **Render Backend**.
*   Then, it runs a tiny query to your **Supabase Database**.

**Result**: By hitting this one URL automatically, you keep *both* services active!

---

## 📝 Setup Instruction (Do this after deploying)

1.  **Deploy your Backend** to Render (as per previous guide).
2.  **Get your URL**: (e.g., `https://my-app.onrender.com`).
3.  **Sign up for UptimeRobot** (It's Free): [uptimerobot.com](https://uptimerobot.com/).
4.  **Create a New Monitor**:
    *   **Monitor Type**: HTTP(s)
    *   **Friendly Name**: Campus App Keep-Alive
    *   **URL**: `https://YOUR-RENDER-APP-URL.onrender.com/api/health` (Add `/api/health` at the end!)
    *   **Monitoring Interval**: **10 minutes** (Important! Must be less than 15 mins).
5.  **Start Monitor**.

## ✅ What will happen?
*   Every 10 minutes, UptimeRobot hits your app.
*   Render sees traffic -> **Resets 15 min sleep timer**. (App stays awake 24/7).
*   Supabase sees a DB Query -> **Resets 7-day pause timer**. (DB stays active).

**Problem Solved!** 🚀
