# WiFi Drop — ANTIGRAVITY FINAL BUILD SPEC

**Date:** 2026-11-21  
**Target:** Windows 11 `.exe` first; Android `.apk` second; iOS later  
**Purpose:** Build a REAL cross-device local Wi-Fi file-sharing app with the **same blue radar UI** as the supplied reference screenshot.  
**Source status:** This document is a build specification, **not a built or tested `.exe`**.

> **ANTIGRAVITY — PRIMARY COMMAND**  
> Work inside the existing project when available. Implement the requirements below in working code, not just mock screens. Keep the supplied `reference/searching-devices.png` as the definitive **radar screen design reference**. Preserve its vivid blue fullscreen field, white “Searching Devices” title, concentric rings, central self-device icon, scattered colorful peer icons, their labels, and the low scanning/status/device-name area. Scale responsively to Windows and Android without replacing the radar with a card/list dashboard. Build and test a real Windows `.exe`, with honest build logs, before claiming completion. Do not stop after creating code or a `.bat` build script.

---

## 1. The exact user scenario (acceptance story)

Five devices connected to **the same usable local Wi-Fi/LAN**:

- `Laptop 1` — Windows 11, WiFi Drop open
- `Laptop 2` — Windows 11, WiFi Drop open
- `Laptop 3` — Windows 11, WiFi Drop open
- `Mobile 1` — Android, WiFi Drop open
- `Mobile 2` — Android, WiFi Drop open

On each device, the radar shows **the other four devices automatically**, each with correct laptop/phone icon and its real friendly device name. The **current/self device is fixed in the center**, not counted among discovered peers. A newly opened instance appears, and a closed/disconnected instance disappears after its heartbeat expires. Tapping/clicking a peer opens **Send Files / Send Folder** actions. Receiver gets **Accept / Reject**. Accepted files land in the receiver's selected save location. Every device may send to every other device as long as LAN routing/permissions allow it. No central cloud, account, router-admin action, manual IP address, or mandatory QR scan during normal use.

**Only active WiFi Drop instances should appear.** Do not scan the router's entire client list or show generic nearby devices. The radar is a **visual arrangement**, not a physical-distance measurement.

## 2. HARD UI LOCK — match the user's screenshot

### 2.1 What the image shows

The supplied reference is a portrait mobile mockup. The actual app screen:

1. A bright/saturated **blue full-screen** canvas (approximately `#0785F8`, adjust visually against `reference/searching-devices.png`).
2. Top-left white bold heading **“Searching Devices”**.
3. One large center-lower radar with **4 fine, semi-transparent concentric rings**, a subtly lighter inner circular area, and a circular bright blue/cyan glow around the self icon at radar center.
4. Peer nodes scattered on the rings: small **cyan, yellow, violet, magenta** circular chips with minimal white device glyphs. **Device names in small white text below each node.**
5. Below radar: a white refresh/spinner symbol plus **“Searching for nearby devices”** while scanning; switch to `4 devices available` when detected, but continue passive discovery.
6. Lower hint: **“Open WiFi Drop on another device connected to the same Wi-Fi.”**
7. Bottom rounded darker-blue capsule: **“My Device: [real user-editable name]”**. Do not hardcode “Nord Prime”.

The image outside the phone (white/gray marketing heading and phone-outline graphic) is **presentation framing, not app UI**. Do not put the giant outer heading or giant phone frame inside the app.

### 2.2 Visual tokens

| Token | Starting value |
|---|---|
| Canvas | `#0785F8` |
| White title/text | `#FFFFFF` |
| Secondary white | `#E5F3FF` |
| Ring stroke | `rgba(255,255,255,0.22)` 1–1.5px |
| Inner radar overlay | `rgba(255,255,255,0.12)` |
| Center device halo | two soft cyan rings; no excessive neon |
| Peer 1 | `#16C6DA` cyan |
| Peer 2 | `#FFC300` yellow |
| Peer 3 | `#A72BF4` violet |
| Peer 4 | `#F026BE` magenta |
| Additional peers | deterministic accessible palette, stable per device ID |
| My-device pill | slightly deeper blue `#0071E5` |
| Text | system font, clean, no 3D effect |

Use **relative coordinates** based on available radar width/height. Avoid cropping labels on Android safe areas or on Windows resize. Simple slow pulsing ring is optional; obey reduced-motion accessibility preferences. Keep visible keyboard focus, screen-reader labels, and an optional **accessible device list toggle** secondary to the radar (never replace default radar).

### 2.3 Windows layout

- On Windows, open **the same blue radar screen** in a native app window. Start at e.g. 1100×750, minimum around 780×600 (adapt layout if narrower).
- Keep title near top-left within blue canvas; settings icon and transfer history at upper right, minimalist and unobtrusive.
- Radar centered and scaled to height. Center self-node labeled `My PC` or custom name.
- Peer labels and positions stable across refreshes; no random dancing/moving on each render.
- Bottom status text, easy-to-read `My Device` pill, and optional tiny `Change Save Folder` shortcut in Settings, not large default cards.
- Drag a file onto a peer chip as optional enhancement (must be tested), plus click/tap send as standard.

### 2.4 Android layout

- Fullscreen screenshot-like bright blue screen, safe-area handling for system status/navigation bars.
- Touch nodes at least 44–48 logical px target sizes; readable names; if >8 peers, switch to collision-avoiding zones and a discreet expanded peer list.
- Device chooser, file picker, incoming request and progress screens should preserve the blue + white brand style.

### 2.5 UI states to implement, not fake

`network-unavailable`, `request-permission`, `searching`, `no-peers`, `peers-online`, `peer-disconnected`, `receiving-request`, `sending`, `receiving`, `completed`, `cancelled`, `failed`, `save-location-error`. Provide a clear retry / open network settings / choose folder action where appropriate. Never populate live UI with hardcoded example peers.

---

## 3. User experience: exact flows

### 3.1 First run (Windows)

1. User installs/runs WiFi Drop; app explains local network discovery in one short sentence.
2. Derive a friendly device name from OS (editable under Settings), do not expose account name publicly if user chooses a custom alias.
3. Ask for Windows Private-network firewall permission when needed; explain why. **Never request Public network access automatically.**
4. App immediately opens radar, advertises presence, browses peers, and shows scanning/no-peer guidance.
5. No login, PIN, QR or IP field on the ordinary happy path.

### 3.2 First run (Android)

1. Install/open APK.
2. Request relevant LAN/Wi-Fi permissions only when platform/version requires; give graceful explanation. Use Android Storage Access Framework for media/files and save folder where possible.
3. Ask for optional device name, then show same radar.
4. Automatic peer discovery while app is in foreground on compatible same LAN. Don't promise iPhone-like background reliability.

### 3.3 Send a file

1. Sender taps peer on radar → bottom sheet/modal shows correct name/type and `Send Files`, `Send Folder` (if supported), `Cancel`.
2. Sender selects one/multiple files via OS-native picker; display exact names/sizes, selected peer, total bytes and Send button.
3. Sender sends a **metadata request**, not bulk bytes yet, unless protocol specifically provides a bounded staged-transfer mode.
4. Receiver sees native/in-app prompt: sender name, number of files, total size, filenames/preview if safe, `Accept` / `Reject`.
5. If accepted, start transfer with progress on **both devices**, speed, bytes, transfer status, Cancel.
6. Receiver writes to a temporary file in the selected destination volume, validates checksum, atomically renames to final safe file name, and shows `Open Folder` (Windows) or `Open File`/`View in Files` (Android).
7. Sender should get real completion acknowledgement **after receiver validation**, not merely after upload bytes sent.

### 3.4 Offline / failure

- Receiver closes app: node goes offline after TTL and any open request fails clearly.
- Transfer interrupted: mark failure, clean up temporary files safely; resume from chunks can be phase 2, but do not pretend partial files are complete.
- Receiver rejects/times out: sender sees accurate reason; no final file saved.
- Duplicate name: use `filename (1).ext`, never overwrite existing by default.
- Insufficient disk space: reject before or during transfer with meaningful message and cleanup.
- File picker cancelled: no request sent.

---

## 4. Settings — SAVE LOCATION MUST WORK

**Required Settings entries**:

- `Device Name` — editable, persisted, reflected on peers on next presence update.
- `Received Files Location` — visible absolute path / Android document-tree label, with **Change Folder**, **Open Folder** (where supported), and `Reset to Default`.
- `Ask before receiving files` — ON by default; untrusted devices can never auto-send arbitrary files. Trusted-device rules later.
- `My Devices / Paired Devices` — trust, remove trust, verify fingerprints or pairing codes.
- `Transfer History` — file metadata/status, clear history.
- `About` — app version, privacy notes.

**Windows default:** `%USERPROFILE%\Downloads\WiFi Drop` (create on first use). User can select D:, E:, removable drive, or nested folder using a **native folder picker**. Validate permissions and available space. Persist to per-user app settings (for example `%LOCALAPPDATA%\WiFiDrop\settings.json`), not an app installation folder. If selected path disappears, explain it and ask the user to select another; do **not** silently move data elsewhere without informing them.

**Android default:** a user-visible Downloads/WiFi Drop destination via supported OS storage APIs; exact path and picker capabilities depend on Android version. Use SAF `ACTION_OPEN_DOCUMENT_TREE` and persist URI access when supported. Do not falsely claim a normal full filesystem path exists for every Android URI; never rely on unrestricted storage permission. If destination is revoked, show re-select dialog.

**Data storage architecture:**

- Final accepted files → receiver's configured destination; sender's setting never determines receiver's path.
- Temporary transfers → controlled app cache **and cleaned after rejection/cancel/failure**; prefer staging on the final destination volume for atomic rename; clearly describe temp-space needs.
- App settings → per-user local app data (never cloud).
- Optional transfer metadata/history → local SQLite or JSON; do not keep copies of successfully delivered files in application cache.
- Changing location affects **new transfers** only; existing files remain where stored.
- Browser-based fallback receivers: browser controls their download path. Never describe browser downloads as if the desktop setting controls them.

---

## 5. Engineering architecture — REAL device-to-device

### 5.1 Recommended implementation strategy

**Primary recommendation: Flutter (Dart) shared UI** for Windows + Android, with small native adapters/plugins where needed. Reason: one radar layout/design system, shared transfer logic, native OS packaging. Verify all dependencies work on target versions before adoption. Avoid locking a package to an unverified old version; choose stable supported versions at build time.

Structure:

```
wifi_drop/
  README.md
  docs/BUILD_SPEC.md
  reference/searching-devices.png
  lib/
    main.dart
    app.dart
    ui/radar/radar_screen.dart
    ui/radar/radar_painter.dart
    ui/radar/peer_node.dart
    ui/send/send_sheet.dart
    ui/receive/incoming_request.dart
    ui/transfers/transfer_progress.dart
    ui/settings/settings_screen.dart
    core/models/{peer,transfer,settings}.dart
    core/discovery/{discovery_service,peer_registry}.dart
    core/network/{connection_service,transfer_protocol}.dart
    core/security/{identity,pairing,trust_store}.dart
    core/storage/{storage_service,received_file_service}.dart
  windows/                    # Flutter Windows host + native integrations
  android/                    # Flutter Android host + native integrations
  test/                       # unit/widget tests
  integration_test/           # on-device tests
  scripts/                    # Windows build helper
  .github/workflows/          # Windows CI release artifact
```

Avoid embedding a Python HTTP server that forces all devices to join one special hub as the **final solution**. The user wants symmetric peers: every installed app instance can independently discover, send and receive. A temporary browser/hub compatibility mode may remain as an explicitly marked legacy mode, never the primary architecture.

### 5.2 Automatic discovery

Use **mDNS/DNS-SD** on compatible LANs (service type e.g. `_wifidrop._tcp.local`) plus a carefully scoped fallback if needed; protocol includes `peer_id`, `display_name`, `device_type`, protocol version, listening port, ephemeral reachability data. Periodically publish and browse while app is active. Handle multicast lock/permissions on Android where appropriate. On Windows bind network interfaces correctly; network changes cause graceful re-advertise. Implement peer registry with TTL and dedupe by stable app-generated peer ID, not IP alone.

- Show peer only after its **real** discoverable service record and reachability handshake.
- Peer appearance under normal LAN conditions should be quick, but do not guarantee an exact number of seconds across all routers.
- Remove stale peers after bounded TTL; when offline show disabled state and accurate user feedback.
- Some routers isolate clients / block multicast. Offer **QR/manual pairing as fallback** for those situations where unicast LAN connection still works. QR is not required for normal discovery.
- Never claim cross-subnet discovery without routing/support; guest networks may block device-to-device transfer entirely.

### 5.3 Connections and protocol

Use peer-to-peer local TCP/HTTP2 or authenticated HTTPS connection (choose stack after real platform testing). Design a versioned message schema:

```
HELLO {protocol_version, peer_id, public_key, device_name, capabilities}
PAIR_REQUEST {peer_id, verification_code_or_qr_challenge}
PAIR_RESPONSE {accepted, key_binding}
TRANSFER_OFFER {transfer_id, file_count, file_names, sizes, total_bytes}
TRANSFER_DECISION {transfer_id, accepted, reason?}
TRANSFER_CHUNK {transfer_id, file_id, offset, length, bytes, integrity_metadata}
TRANSFER_ACK {transfer_id, received_bytes, final_integrity_status}
TRANSFER_CANCEL {transfer_id, reason}
PEER_STATUS {peer_id, capabilities, online}
```

These are conceptual contract fields: implement with a typed framing/protocol (avoid raw concatenated untrusted JSON/binary without length limits). Enforce limits on request sizes and number of concurrent transfers. Handle IPv4/IPv6 where supported.

### 5.4 Security (must not skip for release)

- Device identity uses locally stored asymmetric keys. Bind trusted peer identity to key (not editable name/IP).
- First-contact pairing uses QR/SAS confirmation or explicit mutual verification; receiver always consents to file offer, unless user explicitly enables narrowly scoped trusted-peer auto accept.
- **Encrypt and authenticate transfer contents**, e.g. TLS with verified pinned paired identity, or well-reviewed authenticated transport library. No certificate validation bypasses, no custom encryption.
- File size limits, rate limiting, bounded queues, safe filenames/path traversal protection, no remote code execution, no automatic opening of received files.
- Do not silently open public firewall access. Windows app should create/configure only minimum necessary private-network access with the user's consent.
- No analytics/telemetry by default and no external servers required for core operation.

### 5.5 Transfer mechanics

- Stream files, don't read multi-GB files fully into RAM.
- Provide progress on sender/receiver; total bytes, percentage, current speed.
- End-to-end integrity digest, temp file finalization, reliable acknowledgements.
- Multi-file batch with per-file and aggregate progress.
- Cancelling a transfer really stops network IO and cleans partial data.
- Folder support on Windows: preserve relative paths safely (reject absolute paths and `..`). On Android, folder sending may depend on OS picker and is a documented capability, not guaranteed.
- No asserted hard unlimited size; 4+ GB transfer tests and storage limitations must be measured.

---

## 6. Windows EXE is a required deliverable

Antigravity should provide a real runnable Windows executable, not just `.bat` and Python sources.

1. Develop on a **Windows 11** build machine/runner with current stable Flutter/Visual Studio desktop C++ tooling.
2. Run `flutter doctor -v`; fix Windows desktop prerequisites, `flutter pub get`, `flutter analyze`, `flutter test`.
3. Run `flutter build windows --release` (or the appropriately configured supported Windows packaging command).
4. Package the **entire Windows release output** into `WiFiDrop-Windows-x64.zip` or an installer. Do not send one raw `.exe` alone if DLLs/assets are required. If an installer is made, specify whether signed/unsigned.
5. Verify `WiFiDrop.exe` launches from a clean extracted release directory on Windows 11 **without Python**; launch actual radar UI and confirm Settings persistence. Ideally test a second physical Windows PC.
6. Produce SHA-256 for archive, version, concise install instructions and build logs.
7. Optionally create GitHub Actions Windows CI to generate `WiFiDrop-Windows-x64.zip` in workflow artifacts; CI build success is not the same as physical multi-device network verification.

**IMPORTANT:** When Android support isn't done, Windows must still independently discover and transfer to other Windows instances. Do not mislabel the Windows ZIP as containing a built Android APK.

## 7. Android APK deliverable (second milestone)

1. Implement OS-compatible discover/advertise adapters and LAN permissions (current Android API rules), file picker, receive location SAF, foreground transfer notifications as needed.
2. Build a debug APK initially using `flutter build apk --debug` and test with real Android phones. Provide actual `.apk` and install instructions.
3. Windows↔Android and Android↔Android, bidirectional, both devices can receive; verify Accept/Reject, cancellation, file integrity, destination settings.
4. Later build a release-signed APK/AAB and document signing/privacy requirements. Do not call debug APK production-ready.
5. iOS is a separate later milestone requiring Mac/Xcode build environment and relevant local network permissions; no false promise of an iOS `.exe`/APK.

---

## 8. Build phases — do not skip validation

| Phase | Outcome / pass gate |
|---|---|
| 0. Audit | Inspect current v0.3 project, screenshot, existing tests; mark reusable backend vs prototype-only; no invented test results |
| 1. Locked UI | Pixel-faithful mobile + responsive Windows radar, with **demo mode visibly labeled**; screenshot comparison supplied |
| 2. Real Windows discovery | Two Windows instances detect each other on same LAN; offline expiry verified; no hardcoded peers |
| 3. Secure Windows transfer | Offer → receiver consent → stream → integrity ACK; custom save folder; error cases |
| 4. Windows EXE | Release build and package actually created on Windows; basic launch validation |
| 5. Android app | Same blue radar, discovery permissions, file picker/save destination, Android APK |
| 6. Cross-device testing | PC↔PC, PC↔Android, Android↔Android both directions; 3 laptops + 2 mobiles realistic test |
| 7. Hardening | Encryption verification, stress tests, logs, usability polish, documented limitations |

At the end of **each** phase: show actual changed files, commands executed, results/errors, and the next step. Don't say “working” when only static code exists.

## 9. Required real QA matrix

- Windows 11 ↔ Windows 11: discover each other; 1 MB, 500 MB, 4 GB file; Unicode name; duplicate name; cancel; reject; offline; custom `D:\` save folder; folder persistence after restart.
- Windows ↔ Android: both directions; selected Android destination; receiving phone locked/background restrictions documented; 500 MB video; integrity verified.
- Android ↔ Android: same Wi-Fi, no Windows host required; accepted files saved to correct receiver-selected location.
- Five devices: Laptop 1/2/3 + Phone 1/2 simultaneously; each shows 4 peers on radar; peer opens/closes, names unique, no icon overlap.
- Networking: 2.4GHz and 5GHz clients on same LAN; guest AP isolation fails with useful message; firewall restricted; switching Wi-Fi; unplug/airplane mode; multicast blocked; QR fallback when unicast is permitted.
- Security: spoofed peer name doesn't grant trust, unknown peer requires consent, path traversal attempts rejected, malformed packets safe, failed checksum rejects completion, no file silently auto-opens.
- Install: `.exe` release directory works without Python; Windows Defender/SmartScreen behavior documented for unsigned binaries; clean uninstall removes app not user's received files.

**Acceptance is NOT satisfied by unit tests alone.** Ask for physical device test results where Antigravity cannot run on the user's LAN.

## 10. Minimal user-facing UI copy

- Radar title: `Searching Devices`
- Empty status: `Searching for nearby devices...`
- No peers: `Open WiFi Drop on another device connected to the same Wi-Fi.`
- With peers: `4 devices available` (actual count)
- Current device: `My Device: [name]`
- Peer modal: `[name]`, `Send Files`, `Send Folder`, `Cancel`
- Receiver popup: `[name] wants to send [N] files ([size]).`, `Accept`, `Reject`
- Progress: `Sending to [name]`, `Receiving from [name]`, `%`, `bytes`, `speed`, `Cancel`
- Success: `Transfer complete`, `Open Folder` / `View File`
- Settings: `Device Name`, `Received Files Location`, `Change Folder`, `Ask Before Receiving`, `Transfer History`

## 11. Explicit DON'Ts

- **DO NOT** redesign the UI into white dashboard/cards, dark-mode-only screens or a conventional device list as the main experience.
- **DO NOT** recreate the phone mockup's outer advertising/marketing layout inside the product.
- **DO NOT** invent proximity distances or pretend the rings measure Wi-Fi signal.
- **DO NOT** show mock devices in live mode.
- **DO NOT** require a hub PC or manual URL/PIN to discover all native installed peers in normal conditions.
- **DO NOT** save all files permanently to a fixed C: path. Make receiver folder user-configurable as specified.
- **DO NOT** falsely say EXE/APK built if only source/scripts are available.
- **DO NOT** call unencrypted prototype traffic secure; implement real authentication and encryption before a production release.

## 12. COPY-READY ANTIGRAVITY EXECUTION PROMPT

Paste this section as the **first message** into Antigravity after adding this document and the screenshot to the project:

```text
You are my senior cross-platform desktop/mobile engineer, LAN networking engineer, and product UX engineer. Read docs/WIFI_DROP_BUILD_SPEC.md completely and use reference/searching-devices.png as the authoritative UI reference. My priority is a REAL Windows 11 WiFi Drop EXE, later an Android APK. DO NOT replace the user's blue radar with a dashboard. Build a fullscreen/large-window vivid-blue radar with white "Searching Devices" title, subtle circular rings, centered my-device node, color-coded live nearby laptop/phone icons with device names, scanning status and bottom my-device pill. Device positions are UI layout only.

Start by auditing any existing project and listing reusable code, then implement in phases: (1) faithful responsive radar UI, (2) actual LAN discovery for independent Windows peers (no hardcoded mock devices), (3) secure peer authentication and offer/accept streaming transfer with progress/checksum, (4) Settings > Received Files Location native folder picker + persistence, (5) compile and package the ACTUAL Windows release EXE on a Windows runner, (6) Android app with the same UI, independent discovery and APK, and (7) cross-platform LAN QA. Do not require a hub PC or IP entry in the happy path. Require receiver permission. Keep data entirely on local network.

Deliver changed source files, commands, tests and results. Provide actual Windows release artifact (EXE together with required runtime/assets, or installer) and Android APK ONLY after they are truly compiled. If no Windows build environment is available, explicitly report that blocker and set up Windows CI workflow rather than claiming an EXE exists. Real 3-Windows + 2-Android discovery must be verified physically, or marked untested. Follow the entire spec without silently dropping requirements. Preserve custom save-folder settings on every receiver device.
```

---

## 13. Existing prototype migration notes

If I supply the earlier **WiFi Drop v0.3 Python source**, treat it as a **reference prototype**:

- It already explores Windows local UDP discovery, a browser-centric radar, accept/reject and the Windows host save folder.
- It is NOT a native Android app, does NOT have an independently compiled Windows EXE, and its host-to-host traffic is not sufficiently authenticated or encrypted.
- Reuse only useful discovery ideas, UI visual assets, or tests. Do **not** keep the browser hub architecture as the final multi-peer product.
- If source not supplied, create a fresh Flutter project and implement this document independently.

**Definition of done:** On three Windows 11 laptops and two Android phones, opening the installed WiFi Drop app on the same compatible Wi-Fi produces an accurate live blue radar of the four OTHER running instances, supports secure approval-based file sharing in any direction, and reliably saves incoming files to a per-device destination chosen in Settings. A verified Windows build artifact and later Android APK are delivered with honest test evidence.
