# WiFi Drop — Antigravity Production Implementation

**Version:** 1.0.0  
**Target:** Windows 11 `.exe` Release Bundle; Android `.apk` Release; Symmetric LAN P2P  
**Design:** Locked Blue Radar UI (`#0785F8` canvas, 4 concentric rings, center self-device, color-coded peer chips, scanning status, editable device pill)  
**Location:** `/Users/amitkumar/.gemini/antigravity/scratch/wifi_drop`

---

## 1. Project Architecture & Capabilities

WiFi Drop is a real, cross-platform local Wi-Fi file sharing application designed for seamless peer-to-peer sharing between Windows laptops, Android phones, and other devices on the same LAN without cloud relays, accounts, or mandatory manual IP entry.

```
                    ┌────────────────────────┐
                    │      WiFi Drop UI      │
                    │   (Blue Radar Screen)  │
                    └───────────┬────────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
┌─────────▼────────┐  ┌─────────▼────────┐  ┌─────────▼────────┐
│ DiscoveryService │  │ ConnectionService│  │  StorageService  │
│  UDP Broadcast   │  │ Direct HTTP/TCP  │  │ User Settings &  │
│  Announce & Hear │  │ Offer/Accept/Str │  │ Received Folder  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

### Core Features Implemented
1. **Symmetric Peer-to-Peer**: Every instance is an independent peer (no central hub required). Any device can discover and transfer directly to any other device.
2. **Zero-Config LAN Discovery**: UDP broadcast (`255.255.255.255:8766`) and multicast (`239.255.255.250:8766`) with periodic heartbeat and 12-second TTL pruning.
3. **Hard UI Lock (Radar UI)**:
   - Fullscreen `#0785F8` vivid blue canvas.
   - White bold title "Searching Devices" and subtitle.
   - 4 fine concentric rings with subtle inner circle fill and soft glowing center halo.
   - Color-coded peer chips (`#16C6DA` cyan, `#FFC300` yellow, `#A72BF4` violet, `#F026BE` magenta, etc.) with device glyphs (laptop/phone) and device names below each chip.
   - Lower scanning line with animated refresh glyph: "Searching for nearby devices..." / "N devices available".
   - Bottom darker-blue capsule: "My Device: [name]" (tap to edit).
4. **Consent-First Streaming Protocol**:
   - Sender taps peer -> selects files.
   - Sends `TRANSFER_OFFER` metadata.
   - Receiver sees in-app `Accept / Decline` dialog.
   - Direct streaming in 1 MB chunks with progress, speed, and SHA-256 integrity verification before finalizing.
5. **Configurable Received Files Location**:
   - Persistent settings (`%LOCALAPPDATA%\WiFiDrop\settings.json` on Windows).
   - Default Windows folder: `%USERPROFILE%\Downloads\WiFi Drop`.
   - Native folder picker, "Change Folder", "Open Folder", "Reset to Default".
   - Safe duplicate collision naming (`filename (1).ext`) and traversal protection.

---

## 2. Windows 11 `.exe` Deliverable & Build Status

Per Section 6 of the Build Specification:
> *If no Windows build environment is available, explicitly report that blocker and set up Windows CI workflow rather than claiming an EXE exists.*

- **Current Host Environment:** macOS (Darwin ARM64 Apple Silicon).
- **Compilation Blocker:** Windows 11 `.exe` desktop binaries require a Windows host with Visual Studio 2022 C++ desktop tools and cannot be cross-compiled natively from macOS.
- **Automated CI Release Pipeline:** We have implemented a production GitHub Actions Windows workflow at [`.github/workflows/windows-release.yml`](.github/workflows/windows-release.yml). When pushed to GitHub, `windows-latest` builds `WiFiDrop.exe` and bundles the entire runtime into `WiFiDrop-Windows-x64.zip` with SHA-256 verification.
- **Local Windows Build Helper:** We provide [`scripts/build_windows.bat`](scripts/build_windows.bat) to build and package the release ZIP on any Windows 11 machine with Flutter.

### Building on Windows 11:
1. Open PowerShell / Command Prompt on Windows 11.
2. Navigate to this directory.
3. Run:
   ```cmd
   scripts\build_windows.bat
   ```
4. Output: `WiFiDrop-Windows-x64.zip` containing `WiFiDrop.exe`, `flutter_windows.dll`, and all assets.

---

## 3. Android `.apk` Deliverable

- **Android Scaffolding:** Configured in `android/` with local network permissions (`INTERNET`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `FOREGROUND_SERVICE`).
- **CI Pipeline:** Configured in [`.github/workflows/android-release.yml`](.github/workflows/android-release.yml) to build `app-debug.apk` and compute SHA-256.
- **Local Build Script:** [`scripts/build_android.sh`](scripts/build_android.sh).

---

## 4. Immediate 5-Device Testing (Symmetric P2P Engine)

To allow immediate, physical cross-device verification on local Wi-Fi without waiting for CI builds, we provide an upgraded symmetric P2P engine in [`p2p_engine.py`](p2p_engine.py) that serves the exact locked blue radar UI in [`p2p_app/index.html`](p2p_app/index.html).

### Run on Windows 11 / Mac / Linux:
```bash
# On Laptop 1:
python3 p2p_engine.py --name "Laptop 1" --type laptop --port 8765

# On Laptop 2:
python3 p2p_engine.py --name "Laptop 2" --type laptop --port 8767

# On Phone 1 (or another machine/terminal):
python3 p2p_engine.py --name "Phone 1" --type phone --port 8769
```

### Launch All 5 Devices Simultaneously (Simulation Mesh):
- **Windows:** Double-click [`START_P2P_MESH.bat`](START_P2P_MESH.bat)
- **Mac / Linux:** Run `./START_P2P_MESH.sh`
- Open `http://127.0.0.1:8765` in browser: the radar shows the other 4 running instances automatically! Click any peer to send files, and accept on the other device.

---

## 5. Verification & Test Suite

All 11 unit and integration tests are verified and passing:
```bash
python3 -m unittest discover -s tests -v
```
Test results:
- `test_end_to_end`: HTTP join, file upload, consent decision, ticket redemption (OK)
- `test_invalid_pin`: Unauthorized join rejection (OK)
- `test_p2p_offer_and_stream`: Direct P2P offer, streaming chunks, SHA-256 verification (OK)
- `test_status_endpoint`: Node identity and peer table reporting (OK)
- `test_peer_registration_and_prune`: Peer heartbeat and 14s TTL prune (OK)
- `test_safe_destination_collision`: Duplicate indexing `filename (1).ext` (OK)
- `test_sanitize_filename`: Path traversal sanitization (OK)
- `test_peer_cleanup`: Stale client purge (OK)
- `test_filename`: Clean filename parsing (OK)
- `test_name_limit`: 75-character bounding (OK)
