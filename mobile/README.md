# Nina Dental Care — Mobile App (Flutter)

Flutter 3.44.8, scaffolded for Android + iOS. See `docs/architecture.md` §9
for the full architecture/feature plan.

## What's here

```
lib/
  core/
    theme/app_theme.dart      Nina Dental Care blue brand theme (light+dark)
    network/api_client.dart   Dio client (Provider), base URL via --dart-define
    router/app_router.dart    go_router routes
    widgets/coming_soon_page.dart
  features/
    home/presentation/home_page.dart      Quick-menu grid + bottom nav
    auth/presentation/login_page.dart     UI only, not wired to core-api yet
    auth/presentation/register_page.dart  UI only, not wired to core-api yet
```

Routes not built yet (`/reservations`, `/pricelist`, `/branches`,
`/payments/history`, `/doctors`, `/profile`) render `ComingSoonPage` stating
which roadmap phase implements them — mirrors the admin panel's placeholder
pages so both apps communicate status the same way.

State management: Riverpod (`flutter_riverpod`). Networking: `dio`. Codegen
available (`build_runner` + `freezed` + `json_serializable`) for DTOs once
real API models are needed — not used yet since there's nothing to model.

`riverpod_generator`/`riverpod_lint` were deliberately left out: their
current published versions have a dependency conflict with
`json_serializable`/`freezed` in this Flutter/Dart SDK combination. Classic
`Provider`/`StateNotifierProvider` style (no `@riverpod` annotation) avoids
needing them; revisit once the ecosystem catches up.

## Verified in this environment

- `flutter analyze` — no issues
- `flutter test` — passes (smoke test mounts the full app: router + theme + Riverpod)

**Not verified here** (would need extra toolchain not installed on this
machine): actual Android APK / iOS IPA builds. Android needs the Android
SDK (Android Studio); iOS needs CocoaPods + a Simulator runtime. Both are
one-time local setup or handled by CI (see `.github/workflows/mobile.yml`
and `docs/architecture.md` §10 for the Codemagic/Fastlane plan).

## Running locally

```bash
cd mobile
flutter pub get
flutter run -d chrome   # or -d macos — fastest way to see the UI without Android/iOS toolchains
```

To point at a real backend instead of `http://localhost:8080/api/v1`:

```bash
flutter run --dart-define=API_BASE_URL=https://api.ninadentalcare.com/api/v1
```

Note for Android emulator specifically: `localhost` refers to the emulator
itself, not your host machine — use `http://10.0.2.2:8080/api/v1` instead
when running against a locally-running `core-api`.

## Next steps (Fase 1)

1. Wire `login_page.dart` / `register_page.dart` to `POST /api/v1/auth/login`
   and `/register` once those endpoints exist in `core-api`.
2. Add `flutter_secure_storage`-backed token storage + an auth-aware
   `go_router` redirect guard.
3. Build out `/branches`, `/doctors`, `/pricelist` as read-only screens first
   (no auth required), then the reservation flow.
