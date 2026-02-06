# ⚡ Keep-Alive Guide: Beat the Free Tier Limits

You correctly identified two annoying limits of Free Tiers:
1.  **Render**: Sleeps after 15 mins of inactivity.
2.  **Supabase**: Pauses project after 1 week of inactivity.

I have implemented a **"Two-Birds-One-Stone"** fix locally (`/api/health`). Here is how to use it.

---

## 🛠️ The Strategy
I added a special endpoint: **`/api/health`**
1.  **Instant Response**: It returns `200 OK` **immediately** to satisfy UptimeRobot (preventing 503/Timeout errors).
2.  **Background Wake-Up**: After responding, it silently runs a query to **Supabase** in the background.

**Result**: 
*   **Render** stays awake because it handled a request.
*   **Supabase** wakes up (if asleep) because it received a query, but UptimeRobot **doesn't wait** for this slow process.
*   **No More False Alarms**: Even if Supabase takes 20 seconds to wake up, your status page remains Green (Online).

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
