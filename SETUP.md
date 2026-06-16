# FitPulse — Supabase Setup Guide

## Free tier used
| Service | Supabase Free Limit | Usage |
|---------|--------------------|----|
| Database (PostgreSQL) | 500 MB | Workouts, logs, posts, profiles |
| Storage | 1 GB | Avatars + post images |
| Auth | Unlimited | Email/password |
| Realtime | 200 concurrent | Live feed, leaderboard, comments |
| Bandwidth | 5 GB/mo | All reads/writes |

---

## Prerequisites
- Flutter SDK 3.x+
- A free account at [supabase.com](https://supabase.com)

---

## Step 1 — Create a Supabase Project

1. Go to [app.supabase.com](https://app.supabase.com) → **New project**
2. Choose your org, name it `fitpulse`, pick a region, set a DB password
3. Wait ~2 minutes for provisioning

---

## Step 2 — Run the SQL Schema

1. In the Supabase Dashboard → **SQL Editor** → **New query**
2. Paste the entire contents of `supabase_schema.sql`
3. Click **Run** — all tables, RLS policies, and helper functions are created

---

## Step 3 — Create Storage Buckets

In Supabase Dashboard → **Storage** → **New bucket**:

| Bucket name  | Public? |
|-------------|---------|
| `avatars`   | ✅ Yes  |
| `post-images` | ✅ Yes |

Then for each bucket add these policies (Storage → [bucket] → Policies):

**avatars** — Add policy:
- `SELECT`: `true` (public read)
- `INSERT`: `(auth.uid()::text) = (storage.foldername(name))[1]`
- `UPDATE`: `(auth.uid()::text) = (storage.foldername(name))[1]`

**post-images** — Add policy:
- `SELECT`: `true`
- `INSERT`: `auth.role() = 'authenticated'`

---

## Step 4 — Get Your Keys

Supabase Dashboard → **Settings** → **API**:

| Key | Where to use |
|-----|-------------|
| **Project URL** | `_supabaseUrl` in `lib/main.dart` |
| **anon / public** key | `_supabaseAnonKey` in `lib/main.dart` |

Edit `lib/main.dart`:
```dart
const _supabaseUrl    = 'https://YOUR_PROJECT_REF.supabase.co';
const _supabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
```

---

## Step 5 — Android Setup

In `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 21   // required for Supabase
    targetSdkVersion 34
}
```

In `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

---

## Step 6 — iOS Setup

In `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>FitPulse needs photos for your profile picture and posts.</string>
<key>NSCameraUsageDescription</key>
<string>FitPulse needs camera access for profile photos.</string>
```

Minimum deployment target iOS **13.0** in `ios/Podfile`:
```ruby
platform :ios, '13.0'
```

---

## Step 7 — Install & Run

```bash
flutter pub get
flutter run
```

On first signup, workouts and challenges are seeded automatically.

---

## App Screens

| Screen | Description |
|--------|-------------|
| Onboarding | 3-page animated intro |
| Login / Signup | Supabase Auth (email+password) |
| Forgot Password | Reset email via Supabase |
| Home | Streak, XP, stats, workouts + challenge carousels |
| Workouts | Searchable grid, category filter |
| Workout Detail | Exercise list, start button |
| Active Workout | Timer, set tracker, rest countdown, completion |
| Nutrition | Calorie ring, macro bars, weekly chart, meal logger |
| Community Feed | Realtime posts, likes, comments |
| Challenges | Join challenges, leaderboard |
| Leaderboard | Top users sorted by calories |
| Create Post | Text + photo with type tag |
| Post Detail | Full post + realtime comments |
| Profile | Avatar upload, stats grid, history chart, edit |
| Settings | Toggles, sign out |

---

## Architecture

```
lib/
├── main.dart                    ← Supabase.initialize() here
├── theme/app_theme.dart
├── models/models.dart           ← Pure Dart, snake_case columns
├── services/supabase_service.dart ← All DB/Auth/Storage calls (SB.*)
├── providers/auth_provider.dart ← AuthProvider listens to SB.authStream
├── utils/router.dart            ← GoRouter + auth redirect
├── widgets/common_widgets.dart
└── screens/
    ├── auth/          onboarding, login, signup, forgot_password
    ├── home/          home_screen, main_shell
    ├── workout/       workouts, detail, active
    ├── nutrition/     nutrition (3 tabs)
    ├── community/     feed + challenges + leaderboard, create_post, post_detail
    └── profile/       profile, settings
```

---

## Troubleshooting

**"Invalid API key"** → Double-check `_supabaseAnonKey` — use the `anon/public` key, not `service_role`.

**Realtime not updating** → In Supabase Dashboard → **Database** → **Replication**, enable replication for `posts`, `comments`, `challenges`, `profiles`.

**Storage upload fails** → Make sure the bucket exists and is **public**, and the INSERT policy is set.

**minSdkVersion error** → Set `minSdkVersion 21` in `android/app/build.gradle`.
