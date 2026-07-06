<p align="center">
  <img src="https://img.icons8.com/sf-regular/96/face-id.png" width="80" alt="FaceLock Pro Logo"/>
</p>

<h1 align="center">FaceLock Pro</h1>

<p align="center">
  <strong>AI-Powered Privacy & App Locker for macOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014+-blue?logo=apple" alt="Platform"/>
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?logo=swift" alt="Swift"/>
  <img src="https://img.shields.io/badge/Architecture-MVVM-green" alt="Architecture"/>
  <img src="https://img.shields.io/badge/AI-Offline%20Only-purple" alt="AI"/>
  <img src="https://img.shields.io/badge/Apple%20Silicon-M1%20|%20M2%20|%20M3%20|%20M4-red" alt="Apple Silicon"/>
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" alt="License"/>
</p>

<p align="center">
  Protect your macOS applications with AI-powered facial recognition.<br/>
  Fast. Secure. Completely offline.
</p>

---

## 🎯 Overview

**FaceLock Pro** is a native macOS desktop application that adds an intelligent privacy layer to your Mac. It protects user-selected applications by requiring facial recognition authentication before granting access — all processed entirely on-device.

No biometric data ever leaves your machine. No cloud. No servers. Just your face and your Mac.

### Why FaceLock Pro?

| Problem | Solution |
|---|---|
| Leaving your Mac unlocked at a coffee shop | Protected apps require face authentication |
| Someone borrowing your laptop opens your Messages | FaceLock Pro intercepts the launch and asks for your face |
| Privacy concerns with cloud-based biometrics | 100% offline — embeddings never leave your device |
| Slow authentication flows | <500ms unlock time using Apple Neural Engine |

---

## ✨ Features

### 🔐 AI Face Unlock
- Real-time facial recognition via front-facing camera
- 512-dimensional face embeddings using ArcFace (InsightFace)
- Cosine similarity matching with configurable confidence threshold
- Sub-500ms authentication on Apple Silicon

### 🛡️ Application Protection
- Lock any installed macOS application (Safari, Chrome, VS Code, Messages, Mail, etc.)
- Background monitoring detects when protected apps launch
- Blocks access until authentication succeeds
- Simple checklist interface to manage protected apps

### 🎭 Liveness Detection
- Prevents spoofing attacks using photos or videos
- Blink detection, head movement tracking, random challenges
- Multi-frame verification for high confidence
- Optional MiniFASNet anti-spoofing model

### 🔑 Multi-Factor Authentication
Flexible authentication cascade with multiple methods:

```
Face Unlock → Touch ID → macOS Password → Application PIN
```

| Method | Technology | Data Storage |
|---|---|---|
| Face Unlock | ArcFace CoreML + Vision | Encrypted embeddings in Keychain |
| Touch ID | LocalAuthentication | Handled by Secure Enclave |
| macOS Password | LocalAuthentication | Handled by macOS |
| Application PIN | Custom (4-8 digits) | Hashed in Keychain |

### ⏱️ Session Management
- Configurable trusted sessions (5 min, 10 min, 30 min, 1 hour, until logout)
- Auto-lock after sleep, screen lock, or inactivity
- Per-app session tracking

### 📊 Activity Logging
- Complete authentication history
- Event tracking: app opened, auth success/failure, lockouts
- Filterable log with timestamps, methods, and confidence scores

### 🔔 Native Notifications
- Authentication success/failure alerts
- New protected app notifications
- Lockout warnings via macOS notification center

### ⚙️ Comprehensive Settings
- **General:** Launch at startup, start minimized, theme selection
- **Security:** Auth methods toggle, confidence threshold slider, max attempts, auto-lock
- **Camera:** Camera selection, liveness detection toggle
- **Privacy:** Clear logs, delete face data, export/import settings

---

## 🏗️ Architecture

FaceLock Pro follows the **MVVM (Model-View-ViewModel)** architecture pattern with clean layer separation:

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                  │
│         SwiftUI Views + ViewModels               │
│  Welcome | Dashboard | Settings | Unlock | ...   │
├─────────────────────────────────────────────────┤
│            Business Logic Layer                  │
│    AuthenticationManager | FaceRecognitionMgr    │
│    AppMonitorService | SessionManager | ...      │
├─────────────────────────────────────────────────┤
│           Machine Learning Layer                 │
│      Vision Framework | ArcFace CoreML           │
│      MiniFASNet | EmbeddingGenerator             │
├─────────────────────────────────────────────────┤
│              Storage Layer                       │
│      Keychain | SQLite/SwiftData | UserDefaults  │
├─────────────────────────────────────────────────┤
│              System Layer                        │
│   NSWorkspace | AVFoundation | LocalAuth | ...   │
└─────────────────────────────────────────────────┘
```

### AI Pipeline

```
Camera Feed
    ↓
Vision Face Detection (bounding box + 76 landmarks)
    ↓
Face Alignment (affine transform → 112×112)
    ↓
Liveness Detection (blink/head pose/challenges)
    ↓
ArcFace Feature Extraction (CoreML inference)
    ↓
512-Dimensional Embedding
    ↓
Cosine Similarity (vs. stored reference)
    ↓
Authentication Decision (threshold comparison)
    ↓
Unlock / Deny
```

---

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|---|---|---|
| **Language** | Swift 5.9+ | Type-safe, performant, native |
| **UI** | SwiftUI | Declarative, modern interface |
| **App Framework** | AppKit | Window management, system integration |
| **Camera** | AVFoundation | Real-time camera capture |
| **Face Detection** | Vision Framework | Hardware-accelerated face/landmark detection |
| **Face Recognition** | ArcFace (CoreML) | 512-dim embedding extraction |
| **Liveness** | Vision + MiniFASNet | Anti-spoofing detection |
| **Hardware Accel** | Apple Neural Engine | Fast on-device ML inference |
| **Vector Math** | Accelerate (vDSP) | SIMD cosine similarity |
| **Auth Fallback** | LocalAuthentication | Touch ID + macOS password |
| **Secrets** | Keychain Services | Encrypted embedding storage |
| **Database** | SQLite / SwiftData | Activity logs, app list |
| **App Monitoring** | NSWorkspace | App launch detection |
| **Notifications** | UserNotifications | Native macOS alerts |
| **Project Gen** | XcodeGen | `.xcodeproj` from YAML |

---

## 📋 Requirements

- **macOS 14.0** (Sonoma) or later
- **Apple Silicon** Mac (M1, M2, M3, M4)
- **Xcode 15.0+** (for building)
- **Camera** (built-in FaceTime HD or external)
- **XcodeGen** (for project generation)

---

## 🚀 Getting Started

### Prerequisites

```bash
# Install XcodeGen (one-time)
brew install xcodegen

# Verify Xcode command-line tools
xcode-select --install
```

### Clone & Build

```bash
# Clone the repository
git clone https://github.com/ThanojBuddhima/applockPro.git
cd applockPro

# Generate the Xcode project
xcodegen generate

# Build from command line
xcodebuild build \
  -project AppLockPro.xcodeproj \
  -scheme AppLockPro \
  -configuration Debug \
  -destination 'platform=macOS'

# Run the app
open ~/Library/Developer/Xcode/DerivedData/AppLockPro-*/Build/Products/Debug/FaceLock\ Pro.app
```

### Open in Xcode

```bash
# Generate project and open in Xcode
xcodegen generate
open AppLockPro.xcodeproj
# Press ⌘R to build and run
```

> **Note:** After adding or removing Swift files, regenerate the project with `xcodegen generate`.

---

## 📁 Project Structure

```
applockPro/
├── project.yml                          # XcodeGen project specification
├── README.md                            # This file
├── docs/
│   └── report.tex                       # LaTeX project report
│
├── AppLockPro/
│   ├── App/
│   │   ├── AppLockProApp.swift          # @main SwiftUI entry point
│   │   ├── AppDelegate.swift            # NSApplicationDelegate (background lifecycle)
│   │   ├── AppState.swift               # Shared observable app state
│   │   ├── Info.plist                   # App metadata + camera usage description
│   │   └── AppLockPro.entitlements      # Camera entitlement (non-sandboxed)
│   │
│   ├── Models/
│   │   ├── ProtectedApp.swift           # Protected app + installed app models
│   │   ├── FaceEmbedding.swift          # 512-dim ArcFace embedding container
│   │   ├── AuthMethod.swift             # Authentication method enum
│   │   ├── AuthenticationResult.swift   # Auth attempt result model
│   │   ├── ActivityLogEntry.swift       # Activity log entry + event types
│   │   └── AppSettings.swift            # Observable settings + session timeout
│   │
│   ├── Views/
│   │   ├── ContentView.swift            # Root view (onboarding ↔ main app router)
│   │   ├── Components/
│   │   │   └── SidebarView.swift        # NavigationSplitView sidebar
│   │   ├── Welcome/
│   │   │   └── WelcomeView.swift        # 4-step onboarding wizard
│   │   ├── Dashboard/
│   │   │   └── DashboardView.swift      # Stats, quick actions, recent activity
│   │   ├── ProtectedApps/
│   │   │   └── ProtectedAppsView.swift  # App list + picker sheet
│   │   ├── Enrollment/
│   │   │   └── EnrollmentWizardView.swift # Face capture wizard (5 states)
│   │   ├── History/
│   │   │   └── ActivityHistoryView.swift  # Filterable event log
│   │   ├── Settings/
│   │   │   └── SettingsView.swift       # 4-tab settings panel
│   │   ├── Unlock/
│   │   │   └── UnlockDialogView.swift   # Multi-method auth dialog
│   │   └── About/
│   │       └── AboutView.swift          # App info + technology badges
│   │
│   ├── ViewModels/                      # (Milestone 2+)
│   ├── Managers/                        # (Milestone 4+)
│   ├── Services/                        # (Milestone 2+)
│   ├── AI/                              # (Milestone 3+)
│   ├── Database/                        # (Milestone 5+)
│   ├── Extensions/                      # (Milestone 2+)
│   │
│   ├── Utilities/
│   │   ├── Constants.swift              # App-wide constants and thresholds
│   │   └── Logger.swift                 # os.Logger with categorized subsystems
│   │
│   └── Resources/
│       └── Assets.xcassets              # AccentColor + AppIcon (placeholder)
│
├── AppLockPro.xcodeproj/               # Generated by XcodeGen (do not edit manually)
└── Scripts/                             # (Milestone 3: model conversion scripts)
```

---

## 🔒 Security Model

FaceLock Pro is designed with a **privacy-first** security architecture:

### Data Protection
| Data | Storage | Encryption |
|---|---|---|
| Face embeddings | macOS Keychain | AES-256 (Keychain encryption) |
| Application PIN | macOS Keychain | Salted hash |
| Activity logs | Local SQLite | App-level (on-device only) |
| Settings | UserDefaults | None (non-sensitive) |
| Raw face images | **Never stored** | Deleted immediately after embedding |

### Security Principles
- ✅ **Zero cloud upload** — All biometric data stays on-device
- ✅ **No image storage** — Raw captures are discarded after processing
- ✅ **Keychain-only secrets** — PINs and embeddings in Apple's secure storage
- ✅ **Local inference** — All AI models run on-device via CoreML + ANE
- ✅ **Liveness detection** — Prevents photo/video replay attacks
- ✅ **Non-sandboxed** — Required for app monitoring (cannot be on Mac App Store)
- ✅ **Hardened runtime** — Code signing with Developer ID for distribution

### Threat Model
| Threat | Mitigation |
|---|---|
| Photo replay attack | Liveness detection (blink, head movement) |
| Video replay attack | Multi-frame consistency + random challenges |
| Stolen embeddings | AES-256 encryption in Keychain |
| Brute force PIN | Max attempts + cooldown + lockout |
| Background process bypass | NSWorkspace monitoring + KVO on runningApplications |

---

## 🗺️ Development Roadmap

The project is built in **7 milestones**, each producing a working increment:

| # | Milestone | Status | Description |
|---|---|---|---|
| 1 | **Project Setup & UI Shell** | ✅ Complete | Xcode project, all screens, navigation, models |
| 2 | **Camera & Face Detection** | 🔲 Planned | AVFoundation + Vision Framework integration |
| 3 | **AI Face Recognition** | 🔲 Planned | ArcFace CoreML, enrollment, authentication |
| 4 | **App Monitoring & Protection** | 🔲 Planned | NSWorkspace monitoring, unlock flow |
| 5 | **Multi-Factor Authentication** | 🔲 Planned | Touch ID, PIN, logging, notifications |
| 6 | **Liveness Detection** | 🔲 Planned | Anti-spoofing challenges |
| 7 | **Polish & Release** | 🔲 Planned | Animations, performance, distribution |

### Detailed Timeline

```
Week 1  ✅  Project setup, SwiftUI skeleton, navigation
Week 2  🔲  Camera preview, face detection, landmarks
Week 3  🔲  ArcFace model conversion, embedding pipeline
Week 4  🔲  Enrollment wizard, face authentication flow
Week 5  🔲  App monitoring, protection, unlock panel
Week 6  🔲  Touch ID, PIN, activity logs, notifications
Week 7  🔲  Liveness detection, anti-spoofing
Week 8  🔲  Polish, performance, testing, release candidate
```

---

## ⚡ Performance Targets

| Metric | Target | Method |
|---|---|---|
| Face detection | <100 ms | Vision Framework (GPU-accelerated) |
| Face recognition | <300 ms | ArcFace CoreML (Apple Neural Engine) |
| Total unlock time | <500 ms | Optimized pipeline |
| CPU usage (idle) | <10% | Event-driven monitoring |
| Memory footprint | <200 MB | Efficient model loading |
| Battery impact | Minimal | CoreML + ANE optimization |

---

## 🖥️ Screens

FaceLock Pro includes the following screens, all navigable via a sidebar:

| Screen | Description |
|---|---|
| **Welcome** | 4-step onboarding wizard (intro → permissions → enrollment intro → complete) |
| **Dashboard** | Protection status, stats cards, quick actions, recent activity |
| **Protected Apps** | List of protected apps with search, toggle switches, add/remove |
| **Face Enrollment** | Guided face capture wizard with progress tracking |
| **Activity History** | Filterable log of all authentication events |
| **Settings** | 4-tab settings (General, Security, Camera, Privacy) |
| **Unlock Dialog** | Authentication popup with Face/TouchID/Password/PIN switcher |
| **About** | App info, version, technology stack |

---

## 🔮 Future Enhancements

- 👥 Multiple user profiles
- ⌚ Apple Watch proximity unlock
- 📍 Geofencing (trusted locations)
- 📁 Secure file vault & folder protection
- 💾 Encrypted backups
- 🧠 AI anomaly detection
- 🔌 Plugin architecture
- 🏢 Enterprise management (MDM)
- 📋 Clipboard protection
- 🌐 Browser extension integration
- 📱 Remote lock capability

---

## 🤝 Contributing

This project is currently in active development. Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/applockPro.git
cd applockPro

# Install dependencies
brew install xcodegen

# Generate project
xcodegen generate

# Build and run
xcodebuild build -project AppLockPro.xcodeproj -scheme AppLockPro
```

### Code Style
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use MVVM architecture for all new features
- Add DocC comments to all public APIs
- Keep views focused and reusable

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

> **Note:** The ArcFace model (InsightFace) has its own licensing terms. See [InsightFace License](https://github.com/deepinsight/insightface/blob/master/LICENSE) for details on commercial use.

---

## 🙏 Acknowledgments

- [InsightFace / ArcFace](https://github.com/deepinsight/insightface) — Face recognition model
- [Apple Vision Framework](https://developer.apple.com/documentation/vision) — Face detection & landmarks
- [Apple Core ML](https://developer.apple.com/documentation/coreml) — On-device ML inference
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — Xcode project generation

---

<p align="center">
  Built with ❤️ for macOS · Designed for Apple Silicon · Privacy First
</p>