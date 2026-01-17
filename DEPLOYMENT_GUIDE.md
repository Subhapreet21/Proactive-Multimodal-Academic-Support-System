# 📱 Wireless Deployment Guide

This guide allows you to install your app on a physical Android device and use it **without a USB cable** (disconnected from the PC).

## 📡 Principle
Since your backend (Node.js) is running on your Laptop, your Phone needs to reach your Laptop over WiFi.
1.  **Laptop & Phone** must be on the **SAME WiFi Network**.
2.  **API_URL** in the app must point to your Laptop's **Local IP Address**.

---

## Step 1: Find your Local IP Address
I detected a likely IP from your network logs: **`10.43.155.145`**
*If that doesn't work, run `ipconfig` in a terminal and look for "IPv4 Address" under your Wi-Fi adapter.*

---

## Step 2: Configure the App
1.  Open `flutter_app/.env`.
2.  Change `API_URL` to your Local IP:
    ```properties
    # API_URL=http://127.0.0.1:5002  <-- DELETE or COMMENT THIS (Only works on PC)
    API_URL=http://10.43.155.145:5002
    ```
    *(Replace `10.43.155.145` with your actual IP if different).*

---

## Step 3: Allow Connection (Firewall)
Your PC might block the phone from connecting to port `5002`.
1.  Press `Win` key, type **"Firewall"**, open **"Allow an app through Windows Firewall"**.
2.  Click **Change settings** (top right).
3.  Find **Node.js JavaScript Runtime** in the list.
4.  Ensure **Private** (and Public, if you are on university wifi) checkmarks are **ON**.
5.  Click **OK**.

---

## Step 4: Build the Release APK
Now, create the installer file. In your VS Code terminal (inside `flutter_app` folder):

```powershell
cd flutter_app
flutter clean
flutter build apk --release
```

This may take 1-3 minutes.

---

## Step 5: Install on Phone
1.  Locate the generated file on your PC:
    `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
2.  Transfer this file to your phone (WhatsApp, Google Drive, Bluetooth, or USB copy).
3.  On your phone, tap the **APK file** to install.
    *   *You may need to "Allow installation from unknown sources".*

## 🎉 Done!
You can now unplug the USB cable. As long as your Laptop is running the backend (`npm run dev`) and both devices are on the same WiFi, the app will work perfectly!
