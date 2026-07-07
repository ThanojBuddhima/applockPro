<p align="center">
  <img src="https://img.icons8.com/sf-regular/96/face-id.png" width="80" alt="AppLock Pro Logo"/>
</p>

<h1 align="center">AppLock Pro</h1>

<p align="center">
  <strong>AI-Powered Privacy & App Locker for macOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014+-blue?logo=apple" alt="Platform"/>
  <img src="https://img.shields.io/badge/AI-Offline%20Only-purple" alt="AI"/>
  <img src="https://img.shields.io/badge/Apple%20Silicon-M1%20|%20M2%20|%20M3%20|%20M4-red" alt="Apple Silicon"/>
</p>

<p align="center">
  Protect your macOS applications with AI-powered facial recognition.<br/>
  Fast. Secure. Completely offline.
</p>

---

## 📄 Project Report

For an in-depth look at the architecture, design decisions, and AI implementation details of AppLock Pro, please read the official [Project Report](https://github.com/ThanojBuddhima/applockPro/blob/main/docs/report.pdf).

---

## 🎯 What is AppLock Pro?

**AppLock Pro** is a native macOS desktop application that adds a privacy layer to your Mac. It allows you to lock specific apps (like Messages, Mail, WhatsApp, or Safari) and requires your face to unlock them.

Everything is processed entirely on your Mac. **No biometric data ever leaves your machine. No cloud. No servers. Just your face and your Mac.**

### Perfect For:
- **Coffee Shops:** Step away without worrying about someone opening your private apps.
- **Sharing your Mac:** Let a friend borrow your laptop to browse the web without them reading your iMessages.
- **Privacy:** Keep your personal data safe from prying eyes.

---

## ✨ Features

- **🔐 True App Locking:** When a protected app is opened, it is instantly frozen in the background. It cannot process data, play audio, or show notifications until you unlock it.
- **🤖 Fast Face ID:** Uses Apple's Neural Engine to unlock your apps in milliseconds.
- **🛡️ Complete Privacy:** 100% offline. Your face data is never saved as an image and never uploaded.
- **⏱️ Smart Sessions:** Choose to require Face ID every single time you open an app, or set a grace period (e.g., 5 minutes, 1 hour, or until you log out).
- **🔑 Backup Unlock:** If your camera is covered, you can always fall back to your Mac's password.

---

## 🚀 How to Install

1. Download the latest `AppLockPro.dmg` from the **[Releases](https://github.com/ThanojBuddhima/applockPro/releases)** page.
2. **Bypassing macOS Security Warnings:** Because this is an indie developer app, macOS may show a "malware" or "cannot be verified" warning when you try to open the DMG.
   - **Try this first:** **Right-click** (or Control-click) the downloaded `AppLockPro.dmg` file, select **Open**, and click **Open** again.
   - **If there is no "Open" button (only "Move to Bin"):** Click **Done**. Open your Mac's **System Settings** > **Privacy & Security**. Scroll down to **Security**, find the message about AppLockPro being blocked, and click **Open Anyway**.
3. Once the file opens, drag the **AppLock Pro** icon into your **Applications** folder.
4. **First Launch:** When launching the app for the very first time, you may need to repeat the security step:
   - **Right-click** AppLock Pro in your Applications folder and select **Open**. (Or use the System Settings method again if needed).

---

## 📖 How to Use

1. **Launch AppLock Pro** from your Applications folder.
2. **Follow the Onboarding:** The app will guide you through granting Camera permissions and scanning your face for the first time.
3. **Lock Apps:** Go to the **Protected Apps** tab in the sidebar and click the `+` button to add apps like Mail, Messages, or WhatsApp.
4. **Test it out:** Close the AppLock Pro window (it stays running in your menu bar). Try to open one of your protected apps. You'll be greeted with a Face ID scanner!

---

## ⚙️ Settings & Configuration

In the Settings tab, you can customize how AppLock Pro works:

- **Session Timeout:** Decide how often you want to be asked for your face.
  - *Always Authenticate:* Asks for your face every time you bring the app to the foreground.
  - *Time-based (5m, 1h, etc.):* Once unlocked, the app stays unlocked for this duration.
  - *Until Logout:* Unlock it once, and it stays unlocked until you quit AppLock Pro.
- **Start at Login:** Keep AppLock Pro running automatically when you turn on your Mac.
- **Security Threshold:** Adjust how strict the facial recognition is.

---

## 🙋 Frequently Asked Questions

**Does this drain my battery?**
No! AppLock Pro is highly optimized. The AI models only run for a fraction of a second when you are actively trying to open a locked app. The rest of the time, the app sits idle using virtually 0% CPU.

**What happens if the app crashes or I quit it?**
If AppLock Pro is completely quit (Command+Q), it stops protecting your apps. For maximum security, we recommend hiding the AppLock Pro window rather than quitting the app entirely.

**Can I reset my face?**
Yes! Go to the Privacy section in Settings and click "Reset Face Data". You will need to re-enroll your face.

---

<p align="center">
  Built for macOS · Designed for Apple Silicon · Privacy First
</p>
