Build a complete, production-ready Flutter Android application called "FocusGuard" (a student productivity/focus app). Follow every requirement below exactly and do not skip, simplify, or defer any core feature. Work through the entire build autonomously in a single pass — do not pause to ask the user clarifying questions or wait for approval on layouts/structure at any point; where a decision is ambiguous, make the most sensible choice yourself, note it briefly in a comment, and continue straight to complete code.

## CORE PURPOSE
A focus app for students that blocks distracting apps and all notifications during focus sessions, while allowing study/productivity apps to remain usable, and builds an honest, evidence-backed history of study sessions.

## FUNCTIONAL REQUIREMENTS

### 1. App List & Blocking (not a manual "add app" list — show ALL installed apps)
- On launch, fetch every installed user-facing app on the device (exclude system apps with no launcher icon) using `device_apps` or platform channels querying `PackageManager`.
- Display them in a searchable, alphabetically sorted list with app icon, name, and a toggle switch per app to mark it as "Blocked".
- Persist blocked state locally (use `sqflite` or `hive` — pick one and be consistent throughout).
- Auto-categorize each app (Social Media, Games, Entertainment, Study/Productivity, Utilities, Other) using package name heuristics/known category lists, and let the user override the category manually.
- Apps categorized as "Study/Productivity" are excluded from blocking by default, but the user can manually block them if desired.
- Category filter chips/tabs at the top of the app list.
- When adding an app to the block list, let the user optionally write a short personal note ("why am I blocking this") — shown briefly on the block overlay when they try to open that app during a session, so the block feels like their own decision.

### 2. Real-time App Blocking (must actually work, not just UI)
- Implement a foreground Android `AccessibilityService` (or `UsageStatsManager` + overlay approach — choose the more reliable one and justify briefly in a comment) that detects when a blocked app comes to the foreground.
- When triggered, show a full-screen system overlay (`SYSTEM_ALERT_WINDOW`) blocking interaction with the underlying app, redirecting to home/FocusGuard, showing remaining session time and the user's personal blocking note for that app.
- Log every blocked-app attempt during a session as an "escape attempt" (timestamp + app), stored with the session record.
- Track phone pickups / screen-on events during a session as a restlessness proxy, stored with the session record, and shown in both History (per session) and the Stats dashboard (aggregate trend).
- Clean onboarding/permission flow (Accessibility Service, Display over other apps, Usage Access, Notification Access, Battery optimization exemption, Camera) explaining each permission before requesting it.

### 3. Notification Blocking
- `NotificationListenerService` suppresses notifications from blocked apps during an active session.
- Whitelist system for calls/messaging so those always come through even in strict sessions.

### 4. Timer & Pomodoro
- Pomodoro mode: configurable focus duration, short break, long break, sessions before long break.
- "Deep Focus" custom-duration/stopwatch mode as an alternative.
- Saveable/reusable session templates (e.g., "Homework – 45 min", "Revision – 90 min").
- Subject/tag field per session (Math, Physics, Revision, etc.) for later filtering.
- Optional short task/intention text per session (e.g., "Finish calculus homework").
- Persistent foreground notification with live countdown during an active session.
- Auto-transition focus/break with sound/vibration alerts.

### 5. Mandatory End-of-Session Proof (applies to EVERY session — early exit or natural completion)
- No session may be marked "closed" without the user submitting: (a) a photo of their work, and (b) a self-rating of session productivity (e.g., 1–5 or Poor/Okay/Good/Great scale), with an optional short note.
- Photo must be captured live via in-app camera. Camera access failure (permission denied, camera in use, hardware/plugin error) shows an explicit error screen with a "Retry Camera" option. Only if the retry also fails does the app allow a gallery picker as a last resort — any photo submitted this way is tagged "gallery fallback used" and displayed as a visible badge on that session in History (never silently treated as equivalent to a live capture). Gallery-fallback sessions are excluded from streak-building by default, with a Settings toggle to change this behavior.
- If the user backgrounds the app without submitting the photo/rating, show a persistent notification/reminder until it's completed. The session stays in a "pending closure" state until then.
- **Early ending is not blocked outright** — the OS makes a true hard-lock unenforceable anyway (user can force-stop from Settings), so instead: ending early requires the same mandatory photo + rating step, and is explicitly logged as "ended early" in history, which negatively affects the streak/stats (framed as a completed-but-flagged session, not silently hidden).
- Duplicate/unchanged-photo detection: compare each submitted photo against recent ones (simple perceptual hash / byte comparison is sufficient) and tag matches as "same photo as a previous session" in history — visible to the student, not blocking submission. This is an honesty nudge, not an automated grader.
- Do NOT implement AI/vision-based grading of whether the work is "good" or "effective" — this is unreliable and out of scope. All qualitative judgment stays with the student via self-rating.

### 6. History
- Full chronological list of all sessions: date, duration, subject/tag, task/intention, photo thumbnail, self-rating, note, escape-attempt count, phone-pickup count, "ended early" flag, "duplicate photo" flag, "gallery fallback used" flag.
- Tapping a session opens full detail view with full-size photo.
- Self-rating and note must be editable retrospectively (student can re-evaluate later, e.g. "I said Good yesterday but I was actually distracted").
- Filter/search history by subject, date range, or rating.

### 7. Stats & Motivation
- Daily/weekly dashboard: total focused time, sessions completed, streak counter, average self-rating trend, most-blocked app attempts, phone-pickup trend.
- Auto-generated weekly review screen (no manual input required): total time, best day, most-used subject tag, streak — computed entirely from history data.
- Streak freeze: one automatic "streak protection" per week for a single missed day, so one bad day doesn't wipe out a longer streak.
- End-of-day summary notification (once daily, not spammy): total focused time, sessions completed, average self-rating for the day.
- Achievement badges for consistency milestones.

### 8. Other Utilities
- Distraction-free in-app scratchpad for quick notes during a session (so the student doesn't reach for another app "just to jot something down").
- "Strict Mode" toggle for the block list itself (once a session starts, the block list can't be edited without a delay/cooldown, e.g. 10-second hold-to-confirm).
- Quick "Focus Now" one-tap button with a default duration for spontaneous sessions.
- App usage insights: today's screen time per app via `UsageStatsManager`.
- Light and dark theme support.

## UI/UX & DESIGN DISCIPLINE REQUIREMENTS
- Choose ONE cohesive color scheme (define it as a single set of Dart color constants/tokens: primary, secondary, background, surface, accent, textPrimary, textSecondary) and apply it identically across every screen — no screen should introduce its own one-off colors. Both the light and dark theme variants must be built from this same token system (i.e., one design language, two brightness modes), not two unrelated palettes.
- Consistent spacing system: strict 8dp scale for all padding/margins/gaps (multiples of 8 — 8, 16, 24, 32, 40, 48). No arbitrary spacing values.
- Consistent typography: use Material `TextTheme` hierarchy (`headlineMedium`, `titleLarge`, `bodyLarge`, `bodyMedium`, etc.) with explicit `FontWeight` and `letterSpacing`, applied the same way on every screen — don't mix ad hoc `TextStyle`s per screen.
- Consistent component styling: one shared border radius value, one shared elevation/shadow style, one shared button style (`ElevatedButton`/`OutlinedButton` themes defined once in the app's `ThemeData` and reused everywhere, not restyled per screen).
- Extract every reusable UI piece (cards, list tiles, buttons, badges, chips) into its own `StatelessWidget`/`StatefulWidget` in `lib/widgets`, and reuse those components across screens rather than duplicating layout code.
- All tappable elements use `InkWell` or a themed button with explicit visual press/disabled states.
- Bottom navigation: Home (timer/session control), Apps (block list), History, Stats, Settings.
- Home screen surfaces the primary action (start focus session) prominently, minimal clutter.
- Smooth onboarding flow (3–4 screens) explaining the app and requesting permissions step by step, not all at once.
- Post-session flow (camera capture → self-rating → note → save) should feel quick and lightweight, not like a chore — no more than a few taps/screens, with a clear, non-alarming error state if the camera retry/fallback path is triggered.
- No screen should feel dense or overwhelming — favor progressive disclosure over cramming.

## TECHNICAL REQUIREMENTS
- Flutter (latest stable), Android-only (don't break iOS compilation if trivially avoidable, but no iOS-specific feature work needed).
- Use `provider` or `riverpod` for state management (pick one, be consistent throughout).
- Use platform channels (`MethodChannel`/`EventChannel`) cleanly for all native Android functionality (AccessibilityService, NotificationListenerService, UsageStatsManager, overlay window, installed apps query, screen-on detection). Write the necessary Kotlin code under `android/app/src/main/kotlin/...`, not just the Dart side.
- Local image storage (app's private storage directory) for submitted photos, referenced by path in the local database.
- Proper null safety, no deprecated APIs, no unused imports, no analyzer warnings.
- Structure the Dart code cleanly: `lib/models`, `lib/services`, `lib/providers` (or riverpod controllers), `lib/screens`, `lib/widgets`, `lib/utils`, plus a single `lib/theme` (or similar) file holding all design tokens, `ThemeData`, and shared styles described above.
- Include all necessary `AndroidManifest.xml` entries (services, permissions, overlay activity) and `build.gradle` dependencies.
- Ensure the app builds and runs with zero errors — double-check imports, provider wiring, and platform channel method names match exactly between Dart and Kotlin.
- Do not leave any TODO comments, stub functions (functions that exist but return fake/hardcoded/empty data instead of doing the real work), or placeholder logic (fake hardcoded state instead of real computed/checked state) anywhere in the codebase — every feature listed above must be fully implemented end-to-end, including realistic mock/seed data only where genuinely needed for first-launch UI (never as a substitute for real logic).

## DELIVERABLE FORMAT
1. Brief architecture overview (a few sentences) of how the native blocking mechanism and the mandatory-photo session-closure flow (including the camera-retry/gallery-fallback path) work.
2. Full `lib/` folder contents, file by file, complete code, no omissions.
3. Required native Android additions: `AndroidManifest.xml` changes, Kotlin service files under `android/app/src/main/kotlin/...`, and `android/app/build.gradle` dependency changes — clearly labeled by file path.
4. Every exact terminal command needed to set up and run the project from scratch (creating the Flutter project, `flutter pub add` for each dependency, `flutter pub get`, etc.).
5. A short checklist of manual steps the user must do on their own device (e.g., enabling Accessibility Service, granting overlay/camera permission) since these can't be automated from code.

Do not summarize or truncate any file. Prioritize correctness and completeness over brevity. If a feature is genuinely infeasible without a paid API or violates Play Store policy, note it clearly but still implement the best possible working alternative rather than skipping it. Complete the entire build in this one response without requesting further input.
