# Password Manager

Flutter application connected to the provided Node/Express backend. The app now performs real authentication, category and item management, and user settings synchronization via the backend APIs.

## Prerequisites

- MongoDB instance accessible to the backend
- Node.js 18+
- Flutter SDK 3.8+ (install locally; the CLI is not bundled in this repo)

## Backend Setup

```bash
cd backend
npm install
npm start
```

Environment variables:

| Name | Description |
| --- | --- |
| `MONGO_URI` | Mongo connection string |
| `JWT_SECRET` | Secret used to sign auth tokens |
| `ENCRYPTION_KEY` | 32-byte base64/hex key for item encryption |
| `RESET_TOKEN_EXPIRES_MIN` | (optional) reset token TTL minutes |

The backend exposes routes under `http://localhost:4000/api`.

## Flutter App Setup

1. Install Flutter SDK locally and ensure `flutter` is on your `PATH`.
2. Fetch dependencies (run inside the repo root):

   ```bash
   flutter pub get
   ```

3. Launch the app (adjust the API base URL when not using localhost):

   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
   ```

   - Default base URL assumes Android emulator (`10.0.2.2`). Override via `--dart-define`.

## Features

- Email/password login & registration backed by `/api/auth/*`
- Secure storage of vault items and categories pulled from `/api/items` & `/api/categories`
- Add/delete vault entries with automatic encryption handled server-side
- Password recovery workflow hitting `/api/auth/forgot-password` and `/api/auth/reset-password`
- Settings screen synchronised with `/api/settings` (dark mode, large fonts, logout)
- Local persistence of JWT/user info via `shared_preferences`

## Testing Notes

- Use `flutter run -d chrome` or an emulator/device.
- The app automatically refreshes data when logging in or pulling down within the vault list.
- If you change backend URLs or ports, update `API_BASE_URL`.
