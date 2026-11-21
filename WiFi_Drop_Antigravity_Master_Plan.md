# WiFi Drop — Antigravity Master Development Plan

**Version:** 1.0 · **Date:** 21 November 2026  
**Document type:** Product Requirements Document (PRD) + UX Specification + Technical Architecture + Development Tasks + QA Acceptance Tests  
**Primary target:** Windows 11 and Android; iOS as a validated follow-up target  
**Builder:** Google Antigravity IDE  
**Status:** Design specification, not an implemented or verified application

---

## 0. READ THIS FIRST — NON-NEGOTIABLE REQUIREMENTS

Build a REAL working, native-feeling, local Wi-Fi file-sharing app—not just a UI mockup. Use the user's provided **“Searching Devices” blue radar screenshot** as the primary visual reference. Core user story:

> Laptop 1, Laptop 2, Laptop 3, Phone 1 and Phone 2 are all connected to the same Wi-Fi. When WiFi Drop is open and discovery is enabled on those devices, each user sees icons and friendly device names for the OTHER four devices on a radar-style discovery screen. Tapping/clicking an icon allows secure, direct file transfer. New devices appear and offline devices disappear automatically. No account, no internet upload, no manual IP entry.

**Build integrity rules**
1. Actual discovery, connectivity, sending and receiving must function on real devices; do not replace them with hardcoded names or timers.
2. UI demo data may be shown ONLY in an explicitly marked preview/demo mode. Never show fake devices in production discovery.
3. No cloud storage, external relay, or mandatory internet; use device-to-device communication on a compatible LAN.
4. Discovery must show ONLY running WiFi Drop instances, not every phone or computer connected to the router.
5. File transfer requires sender intent and receiver consent (or an explicitly configured trusted-device rule). Never auto-accept untrusted transfers.
6. Keep the desktop UI faithful to the reference: saturated blue background, concentric radar circles, centered self-device icon, distinct colorful peer icons and names, clean white type, scanning status.
7. Production release must not claim guaranteed speeds, unlimited file sizes, flawless background discovery, or support for all Wi-Fi networks.
8. Build/test in stages, with real devices and documented results. Never mark a stage complete based only on unit tests or screenshots.

## 1. Product Vision

**Name (working):** WiFi Drop  
**Tagline:** Open. Find. Send.  
**Core value:** effortless sharing between multiple Windows laptops and phones on the same local network.  
**Key difference:** radar-centric one-tap discovery screen; no technical configuration required during normal operation.

### In scope, v1
- Windows 11 desktop application (`.exe` installer or signed distributable packaging)
- Android application (`.apk` test build; production package later)
- Automatically advertise and discover running app instances on the same LAN
- Device radar with live peer icons, friendly names, online status and refresh
- Tap/click peer → choose files → send request → receiver Accept/Decline
- Stream selected files over LAN with progress, cancellation, integrity checking and completion confirmation
- Windows multi-file/folder sending; Android file selection including multi-select through platform pickers
- Save received files with safe naming and user-visible destination
- First-run setup, permission guidance, dark/light supporting screens and transfer history metadata
- Simple pairing / verification for trust and authenticated, encrypted connections
- QR/manual-connect fallback for discovery failures (optional for MVP; required before stable release)

### Later / v2
- iOS native app (feature parity after entitlement, local-network permission and file-provider testing)
- Advanced resume after app restart, transfers across many recipients, batch sending
- Background receiving within OS constraints; trusted device controls; persistent pairing
- macOS/Linux; shared-folder sync; web browser companion; transfer queue optimization

### Explicitly out of scope for v1
- Arbitrary devices lacking WiFi Drop installed/running appearing as peers
- Remote/internet sharing across different networks
- Automatic transfer without consent
- Full access to another computer's disk
- Automatic background operation on iOS as a guarantee
- Bluetooth-only transfer or AirDrop protocol interoperability

## 2. Reference Screenshot — Pixel and UX Direction

The user supplied a tall mobile mockup showing:
- Large heading **Searching Devices** above the phone mockup.
- Subtitle explaining discovery for files/media/data.
- Inner app screen with vivid bright blue background (approximation `#0784F7` — sample during design review).
- Top app title **Searching Devices**, white and bold.
- Large radar field with **3–4 fine concentric rings**, softly tinted inner blue area, central circular self-device icon.
- Four scattered peer circles in contrasting accent colors: cyan, gold, violet and pink; tiny white mobile icons and labels.
- Bottom scanning status row and device-name capsule.
- Clean minimal styling with lots of negative space; no cluttered device cards over radar.

**Preserve layout and interaction language—not exact dimensions of the phone illustration.** Adapt for desktop while keeping the same visual hierarchy. Replace sample phone names with real discovered device names and appropriate laptop/phone icons. Avoid copying the screenshot's fake spatial meaning: peer positions are stable UI layout positions, **not physical distance**; do not claim radar indicates meters/proximity.

### Desktop layout (recommended, 1280×800 reference canvas)
- Desktop app min size approx 900×650; responsive down to feasible window size.
- Top bar (height 68–80): WiFi Drop mark + title at left, network readiness status, settings and minimize/close at right.
- Main hero: title “Searching Devices” and subtitle “Devices with WiFi Drop open on this Wi-Fi”.
- Radar area central (~550 px diameter where space allows), blue gradient or flat brand blue, thin circular strokes, central **This Device** node.
- Peers arranged around rings with colorful 44–56 px icon chips; label centered below; if 5–12 devices use collision-avoiding deterministic positions and optionally scrollable list/grid overlay. Do not stack labels.
- Bottom status bar: “Searching on local Wi-Fi…” or “4 devices available”, Scan Again link, my device name.
- Lightweight Receive/Activity panel accessed via tab or side panel; no unnecessary navigation required to send.

### Mobile layout (360×800 / 390×844 reference)
- Full blue radar screen as in supplied screenshot.
- Header title, compact back/settings button only when needed.
- Self-device at radar center, peers distributed by available space without overlap.
- Bottom status, current device name capsule and a small Transfers entry.
- On tiny screens: shrink radar, not text below legibility; consider an accessible list view toggle.

### Visual design tokens (starting values; tune to screenshot)
| Token | Value | Use |
|---|---|---|
| primaryBlue | `#0784F7` | full radar background |
| deepBlue | `#0070DD` | status capsule / active surfaces |
| ringStroke | `#FFFFFF` at 20–32% alpha | radar circles |
| innerRadarFill | `#FFFFFF` at 9–16% alpha | central field |
| onBlue | `#FFFFFF` | headers and peer labels |
| mutedOnBlue | `#D9EEFF` | helper text |
| peerCyan | `#11CAD6` | first peer |
| peerAmber | `#FFC107` | second peer |
| peerPurple | `#9D35F5` | third peer |
| peerPink | `#EB2ABF` | fourth peer |
| peerGreen | `#17BD91` | fifth peer |
| cardRadius | 16–20 px | non-radar dialogs |
| animationDuration | 180–300 ms | ordinary transitions |

Typography: system UI font with good Windows/Android rendering; desktop hero ~28–34 sp, mobile ~24–30 sp; peer names 12–14 sp, readable/high-contrast. Respect accessibility text scaling. Use vector icons for Windows/laptop, desktop monitor, Android/iPhone and generic unknown.

### States to design and implement
1. First run / permission education
2. Scanning — subtle pulsing ring, no misleading fake device dots
3. 1 peer found, 5 peers found, crowded radar 12+ peers
4. No peers — “No devices found. Open WiFi Drop on another device connected to the same Wi-Fi.” + Refresh + Help
5. Network unavailable / mobile data instead of Wi-Fi / Wi-Fi connected but local access denied
6. Permission denied
7. Selected peer bottom sheet / side sheet
8. File-picker state
9. Outgoing request waiting for approval
10. Incoming request with files, sender identity, size and Accept/Decline
11. Transferring with progress/speed/ETA and Cancel
12. Completed / Open Folder or View File
13. Declined / connection lost / storage full / filename conflict / unsupported permission
14. Settings / Rename My Device / Save Location / Trusted Devices / History

## 3. Exact User Journey — No Instructions Needed

### A. First launch (Windows)
1. Install and open WiFi Drop.
2. Suggest human-friendly name from OS, e.g. “Office Laptop”; editable immediately and later.
3. Explain: “Devices on the same Wi-Fi can see your device while the app is open.”
4. Ask/guide Windows firewall access for private networks if prompted; do not silently disable firewall.
5. Start discovery and service advertisement, showing the blue radar.
6. Status text confirms “Looking for devices on this Wi-Fi”.

### B. First launch (Android)
1. Install and open app; show short explanation.
2. Request only permissions necessary for network discovery and user-selected files under target Android SDK/version.
3. Use OS system file picker; avoid broad/all-files storage permissions.
4. Launch the same blue radar; central self icon = phone.
5. Local-network/multicast permission and lock behavior must be tested by OS version.

### C. 3 laptops + 2 phones running app
- Each device should see 4 **other** peers; it is centered as **My Device**, not duplicated in peer list.
- Example device naming: `Laptop 1`, `Laptop 2`, `Laptop 3`, `Mobile 1`, `Mobile 2` (only fixture names in tests/demo).
- If Android phone joins later, its icon should arrive without manual Refresh when discovery works.
- If a laptop disconnects, mark it stale and remove after heartbeat/TTL; do not leave a ghost icon indefinitely.
- Stable per-install device ID prevents duplicates when IP changes or service re-announces.

### D. Android → Windows (example)
1. Open apps on both devices, same Wi-Fi.
2. Android taps the Windows peer icon.
3. Sheet displays name, device type, “Send Files”, optional “View Device Info”.
4. Tap Send Files → Android system picker; choose 3 photos or a video.
5. Request appears on Windows: “Mobile 1 wants to send 3 files · 1.2 GB” + Accept/Decline.
6. Windows accepts; streaming begins with progress and clear cancellation.
7. Completion UI on both devices; Windows “Open Folder”.

### E. Windows → Android
Same steps, but Windows chooses from Explorer drag/drop or file dialog; Android shows consent and stores via its supported destination picker/app-managed storage. On Android, allow “Open” and “Share” using OS content URI; do not promise a universal download-folder path without implementing platform APIs.

### F. Windows ↔ Windows
Drag files onto selected device, or choose file/folder. Receiver decides save location (or uses configured folder) and confirms. Handle duplicate filenames safely.

### G. Android ↔ Android
Use same native picker and accept sheet; verify foreground transfers. Transfers when one phone is locked/backgrounded need explicit limitations and testing.

## 4. Technical Recommendation

**Recommended shared stack:** Flutter (Dart) for Windows + Android + eventual iOS. Use custom painter/Canvas to implement radar and vector rings. Use Dart networking plus platform-specific plugins/native bridge where needed; keep discovery/transport behind interfaces.

**Why:** consistent screenshot-like UI across desktop and mobile, one UI codebase, native app permissions, manageable APK + Windows build. Flutter officially supports Windows, Android and iOS targets; the chosen specific plugin's support must still be verified independently.

### Layered architecture
```text
UI (Radar / Peer Sheet / Incoming / Progress / Settings)
                 |
       State Management (Riverpod or Bloc)
                 |
 App Services: DeviceRegistry / Pairing / TransferManager / History
                 |
 Interfaces: DiscoveryAdapter / TransportAdapter / PlatformFiles
                 |
 Discovery: DNS-SD/mDNS + targeted fallback (QR/manual IP)
 Transport: TCP over LAN with authenticated encrypted channel
                 |
       Platform: Windows / Android / iOS (later)
```

### Discovery — how peer icons actually appear
- Each running app publishes a DNS-SD service, e.g. `_wifidrop._tcp.local` (working name, confirm collision-free registration).
- Advertise ephemeral service port and minimal TXT metadata: protocol version, non-secret public stable peer identifier and display name/type. Never advertise passwords, access tokens, file names or user paths.
- Other instances browse the specific service type, resolve LAN addresses/ports and verify they speak the app's supported protocol.
- Maintain a registry keyed by stable installation ID + validated public key, not IP alone; deduplicate Wi-Fi/IP changes.
- Each peer has `lastSeen`, endpoint(s), verification state and availability.
- Refresh liveness periodically; peers should disappear on expiration or on a trustworthy goodbye event. Initial target: discover within 3–10 seconds in normal LAN conditions, stale remove within ~10–30 seconds; these are acceptance targets, **not guarantees**.
- For large device counts use a stable peer positioning algorithm so icons do not jump wildly on every advertisement.
- Services on separate VLANs, blocked multicast, AP/client isolation or certain hotspots might not be discoverable automatically; show fallback QR / Enter Code / manual host.

**Important:** Radar is a visualization of discovered app instances. The rings do **not** represent GPS, BLE distance, signal strength or transfer speed.

### Security and encryption
The required user experience is “select peer → request approval → encrypted send”. Design an actual cryptographic protocol, not a checkbox. Recommended path:
- Each installation generates its own long-lived Ed25519 identity keypair in OS secure storage where available; peer display names are **not** authentication.
- A peer's first connection may require verification via a 6-digit confirmation code shown on both screens or QR pairing that conveys authenticated key fingerprint; ensure MITM-resistant pairing design.
- Establish an authenticated encrypted session with a well-reviewed protocol/library (mutual TLS with certificate pinning or a properly reviewed Noise-based handshake). **Do not invent custom encryption.**
- The file-transfer protocol uses the same authenticated encrypted channel. Receiver sees display name, file list, total size, and authenticated peer identity before accepting.
- Receiver imposes max in-flight sessions, size/disk-space checks, file count/name limits, denial of path traversal, safe temp storage and checksums.
- Never trust a filename that contains separators, `..`, device names or special reserved paths. Use safe basename + collision suffix and atomic final rename after checksum/size validation.
- QR/manual connect must still complete identity verification; no auto-trust based solely on shared Wi-Fi.
- Trusted devices, if implemented, must be explicit, revocable and scoped; default is Ask Every Time.

### Transfer protocol (conceptual)
```text
DISCOVER → CONNECT → AUTHENTICATE/PAIR → OFFER(metadata)
→ ACCEPT/DECLINE → PREPARE_STORAGE → STREAM(chunks)
→ VERIFY(checksum/size) → COMMIT_FILE → COMPLETE
```

Recommended message envelope (design, not final schema):
```json
{
  "version": 1,
  "type": "transfer_offer",
  "requestId": "uuid",
  "senderPeerId": "public-installation-id",
  "files": [{"displayName": "clip.mp4", "sizeBytes": 123456789}],
  "totalBytes": 123456789
}
```
Never send absolute private filesystem paths. Constrain JSON sizes and schema. Separate control messages from binary frame payloads. Stream bytes with backpressure; do not load entire 10 GB files into RAM. Use temporary part files and durable per-transfer bookkeeping. Incremental SHA-256 for integrity. Limit concurrency (start one active peer transfer per device; configurable later), handle cancellation and clean partials.

### File size and performance policy
- Target streaming of files larger than RAM; test 1 MB, 100 MB, 2 GB, 10 GB where file-system/storage permits.
- Resume after brief network disconnection is a **phase-2** feature unless explicitly built and tested with offset/chunk hashing.
- Display measured throughput, not inflated claims; ETA is approximate.
- Handle Android URI stream APIs, unavailable filenames/sizes, SAF provider behavior and destination restrictions.
- No fixed “up to 100 MB/s” promise. Throughput depends on Wi-Fi hardware/router/security/file I/O.

### Storage and history
- History stores only local metadata (peer, filenames, timestamps, byte count, status); no file bytes or cloud upload.
- Incoming storage chosen per OS, accessible to user; temp `.part` files in managed temp area.
- Clear history action deletes metadata only, not user files.
- Log structured, privacy-conscious errors. Never log keys, QR secrets, file contents or tokens.

## 5. Data Models / States

```text
DevicePeer:
  peerId: String
  publicKeyFingerprint: String?
  displayName: String
  platform: windows | android | ios | unknown
  iconType: laptop | phone | desktop | unknown
  serviceInstanceId: String
  endpoints: List<Endpoint>
  lastSeen: DateTime
  state: discovering | available | connecting | offline | incompatible
  trustState: unknown | verifying | paired | blocked

TransferJob:
  transferId: UUID
  direction: send | receive
  peerId: String
  files: List<TransferFile>
  totalBytes: int64
  bytesCompleted: int64
  state: offering | pendingConsent | connecting | transferring |
         verifying | complete | declined | cancelled | failed
  startedAt: DateTime
  errorCode?: String

TransferFile:
  displayName: String
  declaredBytes?: int64
  safeDestination?: String
  sha256?: String
```

Use explicit state-machine transitions; prevent simultaneous contradictory states (e.g. complete then cancelled). Persist only fields needed for history and recovery.

## 6. Detailed UI Components

### `RadarScreen`
- Solid blue responsive full-bleed main area
- `RadarHeader` with heading and subordinate status
- `RadarCanvas` CustomPainter concentric rings and subtle pulse; low CPU use
- `SelfDeviceNode` center, distinct ring and always-visible “My Device” label
- `PeerNode` separate colored circular icon, friendly name, interaction highlight, status
- `RadarStatusBar` searching / found count / connection help
- `MyDevicePill` bottom friendly name and rename action
- `TransferActivityEntry` accessible control, with unread badge for pending transfers
- Scan Again, Settings and optional List View affordance

### `PeerActionsSheet`
- Peer name / platform icon / connected status
- Big primary **Send Files**
- Optional **Send Folder** only on platforms where supported
- Cancel / Back

### `IncomingTransferDialog`
- Authenticated sender label + first-time trust verification if necessary
- File count, filenames (truncate safely), aggregate byte size
- **Accept** and **Decline** buttons
- If space insufficient, show exact required/available if retrievable
- Do not accept automatically when app is foregrounded unless previously trusted and enabled

### `TransferProgressScreen`
- Peer name + direction + status
- Progress bar / completed bytes / total bytes / measured speed / ETA
- File-by-file detail and Cancel
- Completion open destination or open via OS, Retry failed transfer
- Unexpected disconnect gets honest error and next-action guidance

### `SettingsScreen`
- My device name (default derived from OS, user editable)
- Saved incoming files destination
- Incoming approval: Ask Every Time (default)
- Trusted / blocked devices
- Light/dark preference for non-radar surfaces
- Reduce motion / accessibility list view
- Diagnostics: network, local discovery enabled/blocked, firewall guidance
- About / app version / privacy note

### Accessibility + responsiveness
- 44×44 px minimum interactive target (or platform equivalent)
- Semantic peer labels (“Send to Office Laptop, Windows device”)
- Keyboard navigation/tab order/Enter, Esc on Windows
- Screen reader accessible peer list as fallback to 2D radar spatial UI
- Reduced motion removes pulsing and endless scanning animation
- Support resizing and system DPI scaling; no hardcoded mobile-only coordinates

## 7. Connection Failures — UX MUST HANDLE

| Failure | Expected user-facing behavior |
|---|---|
| No Wi-Fi | “Connect to Wi-Fi to find devices.” |
| Wi-Fi but zero peers | “Open WiFi Drop on another device connected to this Wi-Fi.” + Refresh |
| Guest Wi-Fi / isolation | Show “This Wi-Fi may block device-to-device connections.” + QR/manual fallback (may still fail) |
| Multicast blocked | QR/manual IP fallback with authentication; diagnostics |
| Windows Firewall blocks inbound service | Explain Private Network firewall allowance; never request disabling whole firewall |
| Android local network permission denied | Permission steps and Settings link when appropriate |
| App backgrounded/killed | Mark offline; no false guarantee of continued discovery |
| Peer changes IP | Re-resolve service, invalidate stale endpoint, retry authenticated session |
| Peer icon tapped but unreachable | Timeout, clear “Could not connect”, Retry |
| Incoming offer ignored | Sender pending state, configurable timeout and cancellation |
| Receiver declines | “Transfer declined” with safe retry option |
| Not enough storage | Reject before streaming when detectable; clean temp files |
| Filename collision | Create `filename (1).ext`, never overwrite silently |
| Network lost during transfer | Pause/fail gracefully; cleanup or preserve resumable temp only if supported |
| Wrong key / impostor | Refuse connection and warn; do not auto-repair silently |
| Unsupported app protocol version | Compatibility message and update action |
| Large peer count | Stable collision-free placement, accessible list view |

## 8. Build Structure (Proposed Flutter Repository)

```text
wifi_drop/
  README.md
  docs/
    MASTER_PLAN.md
    IMPLEMENTATION_PLAN.md
    PROTOCOL.md
    SECURITY_MODEL.md
    TEST_MATRIX.md
  lib/
    main.dart
    app.dart
    core/
      theme/app_colors.dart
      routing/app_router.dart
      models/device_peer.dart
      models/transfer_job.dart
      errors/app_error.dart
    features/
      discovery/
        data/discovery_adapter.dart
        data/mdns_discovery_adapter.dart
        application/peer_registry.dart
        presentation/radar_screen.dart
        presentation/widgets/radar_canvas.dart
        presentation/widgets/peer_node.dart
      pairing/
        application/pairing_service.dart
        presentation/pairing_sheet.dart
      transfer/
        data/transfer_transport.dart
        data/secure_transport.dart
        application/transfer_manager.dart
        presentation/send_sheet.dart
        presentation/incoming_offer_dialog.dart
        presentation/transfer_progress_screen.dart
      settings/
        presentation/settings_screen.dart
      activity/
        presentation/activity_screen.dart
    platform/
      local_files.dart
      permissions.dart
      device_identity.dart
  test/
    radar_layout_test.dart
    peer_registry_test.dart
    transfer_state_machine_test.dart
    filename_safety_test.dart
  integration_test/
    transfer_smoke_test.dart
  windows/
  android/
  ios/  # only when iOS phase starts
```

This is a proposed structure; adapt to current compatible Flutter packages after checking maintenance/platform support. Do not commit to a discovery package until real Windows + Android tests pass.

## 9. Development Phases & Gates (Antigravity Must Follow)

### Phase 0 — Environment and dependency validation
- Install/validate Flutter SDK, Dart, Visual Studio C++ desktop build workload, Android SDK, build tools.
- Verify Windows debug build and Android debug APK launch.
- Research/select current cross-platform DNS-SD/mDNS library; verify Windows+Android service publishing and browsing and local permissions.
- Select production-ready authenticated encryption approach and key storage implementation; document threat model.
- **Gate:** both targets run and dependency decisions documented.

### Phase 1 — Screenshot-faithful UI, real-state-ready
- Implement responsive radar painter and node placement.
- Use explicit sample-fixture mode ONLY in widget tests/preview, not in runtime.
- Implement all UI states with state model and accessibility list option.
- Test 1/4/12 peer fixtures, desktop/window resize and Android screen sizes.
- **Gate:** visual review against user's screenshot, no overlapping labels, no production mock peers.

### Phase 2 — Genuine discovery
- Announce real service while application runs and discovery is enabled.
- Browse services, resolve endpoints, register/deregister devices, handle duplicate IDs and leave.
- Add heartbeat/TTL and Refresh and diagnostics.
- **Gate:** 2 real Windows PCs detect each other, then Windows+Android discover each other on a normal non-isolated private Wi-Fi. Capture logs/screen recording.

### Phase 3 — Authenticated connection and consent
- Implement identity/key generation, verification/pairing flow and authenticated secure connection.
- Receiver Accept/Decline (no automatic acceptance by default).
- Integrate with peer actions.
- **Gate:** wrong peer credentials rejected; malicious/invalid requests rejected; manual consent proven on both OSes.

### Phase 4 — Streaming files
- Multi-file offer and source file picker.
- Streaming bytes, no whole-file buffering; temp file, checksum, atomic completion.
- Progress/cancel/decline/retry error states, sender and receiver confirmation.
- **Gate:** real 100 MB and 2 GB transfer both Windows↔Windows and Android↔Windows with checksum validation; 10 GB where storage allows.

### Phase 5 — Five-device real-world test
- Open same installed app on 3 Windows laptops + 2 Android phones (or simulated mix for test coverage, clearly documented).
- Verify each sees four distinct peers, correct platform icons/names; simultaneous join/leave, duplicate prevention.
- Exchange files in all feasible combinations and test multiple queued requests.
- Test firewall/permission denial, isolated guest Wi-Fi, sleep, network switch and app closure.
- **Gate:** documented results with screenshots and known limitations.

### Phase 6 — Packaging and polish
- Windows distributable installer including prerequisites and sane firewall guidance.
- Android signed release build for controlled installation; no broad storage permission.
- First-run onboarding, settings, logs/diagnostics, privacy copy, accessible screen.
- **Gate:** clean install on fresh Windows/Android target and complete end-to-end transfer without developer tools.

### Phase 7 — iOS feasibility and deployment (separate release)
- Prepare iOS signing, developer account, native network permissions, Bonjour service declarations.
- Audit any multicast entitlement requirement according to concrete discovery API; iOS background behavior/entitlements may limit functionality.
- Build/test on real iPhone using Apple toolchain; TestFlight/app distribution workflow.
- **Gate:** real iPhone sees Windows/Android and bidirectionally shares using foreground app; document restrictions honestly.

## 10. Real Device Test Matrix

Minimum test cases:

| ID | Test | Expected |
|---|---|---|
| D01 | 2 Windows laptops, same private Wi-Fi | 1 remote peer per laptop |
| D02 | Windows + Android foreground | mutual discovery, correct icons |
| D03 | 3 Windows + 2 Android | 4 peers each, no self duplicate |
| D04 | New device joins | appears automatically |
| D05 | Device closes app | expires / disappears |
| D06 | Reconnect with changed IP | one peer, fresh endpoint |
| D07 | Same display name on two devices | two distinct IDs, not merged |
| D08 | Isolated guest Wi-Fi | no false 'connected'; helpful error |
| T01 | Android → Windows 3 photos | correct name/content, consent |
| T02 | Windows → Android one 2 GB video | full bytes match SHA-256 |
| T03 | Windows → Windows folder | structure safely preserved where supported |
| T04 | Android → Android file | correct destination and readable content |
| T05 | Recipient declines | no file written, visible rejection |
| T06 | Sender cancels | stops stream, safe temp cleanup |
| T07 | Receiver lacks storage | safe failure, no false success |
| T08 | Same filename twice | no silent overwrite |
| T09 | Disconnect during stream | clear partial/failure state |
| S01 | Forged/malformed offer | rejected, no crash |
| S02 | Unpaired attacker on LAN | cannot read file stream/impersonate trusted peer |
| S03 | Traversal filename `../../x` | confined safe basename |
| S04 | Multiple spam requests | rate limits and no UI freeze |
| UX01 | Keyboard-only Windows operation | all primary actions possible |
| UX02 | Screen reader peer list | accessible peer selection |
| UX03 | Resize window/mobile rotate | icons/labels do not overlap |
| UX04 | Reduced motion | no continuous radar pulse |

**Success metrics (targets, not guarantees):** normal discovery within ~10 seconds; stale peer removed within ~30 seconds; file checksums pass; zero silent overwrites; no unapproved inbound file writes; no unintended network/cloud uploads.

## 11. Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| Multicast blocked by router/AP isolation | High | Explain limits, QR/manual endpoint fallback, real hardware tests |
| Windows firewall blocks server | High | Private-network rule guidance, installer behavior and diagnostics |
| Different Android versions restrict discovery | High | Test permissions, networking plugin, foreground runtime |
| Identity spoofing on LAN | High | Authenticated pairing and encrypted transport; display names not trusted |
| Large file RAM pressure | High | Streaming with bounded buffers, backpressure |
| Android file access complexities | Medium | SAF/system pickers, URI streaming, scoped storage APIs |
| iOS local-network policy and background restrictions | High | Separate iOS gate and device tests, no unconditional promises |
| Radar labels overlap | Medium | Deterministic collision-aware layout, max peers/list view |
| Misleading 'nearby' interpretation | Medium | State 'same local Wi-Fi', not physical distance |

## 12. What NOT to Build

- Do not build a browser-only local auto-discovery system as the primary platform for this exact UX.
- Do not build a UI-only HTML prototype and call the project complete.
- Do not use a public relay or upload user files to a third-party API.
- Do not indiscriminately scan all LAN hosts/IPs to populate icons.
- Do not show devices merely because they are connected to Wi-Fi; only discover WiFi Drop services.
- Do not silently grant broad Android file system permissions or turn off firewall.
- Do not assume all Flutter DNS-SD packages work identically on Windows, Android and iOS.
- Do not claim radar positions show physical distance or accurate proximity.
- Do not silently overwrite files or auto-download from strangers.

## 13. Antigravity Execution Prompt (COPY THIS TO ANTIGRAVITY)

```text
You are the senior cross-platform Flutter engineer, systems/network engineer, secure file-transfer engineer, UX designer and QA owner for WiFi Drop.

READ THE ATTACHED MASTER_PLAN.md IN FULL before changing code.

Goal: Produce a real, fully tested local Wi-Fi file-sharing app with the blue concentric-radar discovery UI from the reference screenshot. On one Wi-Fi, each of 3 Windows laptops and 2 Android phones running the app should show the 4 other app-running peers with live icons/names; tapping a peer initiates authenticated, approved and encrypted local file transfer. Do not use internet/cloud relay or fake devices.

Follow phases 0 through 6 in order. Begin by inspecting tools, constraints, libraries and missing hardware. Write a clear implementation plan and task checklist first. Use the Plan/review workflow. For each phase, produce working files, run applicable tests, capture evidence and report failures/limitations. Do not skip phase gates or claim a hardware test passed if the devices were unavailable.

Stack preference: Flutter/Dart with responsive CustomPainter UI; verify Windows and Android DNS-SD service advertisement/browsing, platform permissions, secure transport and file-picker plugins before committing to dependencies. Implement modular discovery, pairing, transfer, persistence and platform adapters. Choose vetted cryptographic protocols/libraries; do not invent cryptography. Use OS-native file pickers and streaming to support large files without loading them into RAM.

UI fidelity requirements: bright saturated blue background, subtle concentric radar rings, center My Device icon, scattered colored laptop/mobile peer icons with labels, live scanning status and self-device name pill. Use actual peer state, accurate online/offline handling, deterministic collision-safe placement, desktop/mobile responsiveness and accessible list fallback. Device positions do not indicate physical distance.

Definition of done: Windows executable/installer + Android test APK, source code, onboarding, network permissions, live discovery, peer selection, transfer offer Accept/Decline, authenticated encrypted streaming, integrity verification, progress/cancel/error states, tests, build instructions and a factual test report. iOS is a separate follow-up phase unless specifically requested.

Immediately start with PHASE 0: audit development environment and compatible dependencies, produce IMPLEMENTATION_PLAN.md, SECURITY_MODEL.md and initial TASKS.md. Do not pretend real multi-device tests happened without hardware access. If hardware is missing, implement test harnesses and explain precisely what remains to verify.
```

### Antigravity step-by-step operation
1. Create `wifi_drop` workspace/project.
2. Place this file into `docs/MASTER_PLAN.md`; provide the original radar screenshot as `docs/reference_radar.png` if possible.
3. In Antigravity open the project, attach/refer to the master plan, then paste the execution prompt above. Use its plan/review workflow before authorizing broader changes.
4. Review Phase 0 dependency choices/security model. Ask the agent to work phase by phase, not generate thousands of untested lines at once.
5. After UI gate, verify live discovery on **two physical devices** before transferring files.
6. Use screenshots, logs and actual checksums to validate each phase. Preserve a known-good commit at every gate.
7. Packaging can begin only after Windows↔Android transfer works repeatedly.

### Suggested individual follow-up prompts
- `Implement Phase 1 from docs/MASTER_PLAN.md; keep demo devices only in widget tests; provide Windows and Android screenshots.`
- `Implement and verify Phase 2 on real Windows and Android; show mDNS publish/browse logs; fix duplicate and offline state handling.`
- `Implement Phase 3 pairing, authenticated encrypted sessions and Accept/Decline according to SECURITY_MODEL.md; include adversarial tests.`
- `Implement Phase 4 streaming transfers, file pickers, checksum, progress, cancellation and error handling; verify 2 GB file.`
- `Run full Phase 5 matrix and generate TEST_REPORT.md with pass/fail/unverified classification and evidence.`
- `Package stable Windows and Android builds with installation and firewall/permission instructions.`

## 14. Official Background References (verify current SDK/platform requirements)

- Flutter desktop: https://docs.flutter.dev/platform-integration/desktop
- Flutter platform FAQ: https://docs.flutter.dev/resources/faq
- Android local-network permissions: https://developer.android.com/privacy-and-security/local-network-permission
- Apple local network privacy / Bonjour: https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy
- Google Antigravity codelab: https://codelabs.developers.google.com/getting-started-google-antigravity
- Google Antigravity implementation planning: https://antigravity.google/docs/ide/implementation-plan

**Reference note:** UI layout originates from the user's supplied blue “Searching Devices” screenshot. Architecture, UX behavior, encryption, phases and acceptance criteria are design recommendations—not claims about an existing implementation.

---

## 15. Final Acceptance Definition

A first-time Windows/Android user can install the app, open the same Wi-Fi, see other running WiFi Drop instances appear as colored laptop/phone icons around a blue radar, tap one device, select a file, obtain receiver approval, securely transfer it over LAN, see verified completion and open the received file—without entering IP addresses or creating an account. If a network/OS prevents this, the app reports an actionable reason instead of pretending a connection succeeded.
