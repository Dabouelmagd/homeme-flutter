# Remaining setup — FCM + Deep Linking

Code for both is committed. These are the pieces that require *your*
credentials/keys, which I can't generate on your behalf.

## 1. Firebase / Push Notifications (FCM)

1. In the [Firebase console](https://console.firebase.google.com), create a
   project (or link an existing Google Cloud project), then add an Android
   app with package name `net.homemeapp.app`.
2. Download the generated `google-services.json` and place it at
   `android/app/google-services.json` (this repo's `.gitignore` should
   exclude it — don't commit it to a public repo).
3. Add this single line to the **bottom** of `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
   (Do this *only* after the json file exists — otherwise the build fails
   immediately with "File google-services.json is missing".)
4. Backend side: generate a Firebase service-account key (Project Settings →
   Service Accounts → Generate new private key) and add it to the FastAPI
   backend's `.env` (something like `FIREBASE_SERVICE_ACCOUNT_JSON=...`) so
   `server.py` can call the FCM HTTP v1 API to actually send pushes. The
   `_setupPushNotifications()` function in `main.dart` logs the device's FCM
   token — you'll want a `POST /api/devices/register` endpoint on the
   backend to store `{user_id, fcm_token}` so you know who to send to.

## 2. Android App Links (deep linking)

The manifest now declares `https://homemeapp.net/...` as a verified App
Link. For Android to actually trust it, `homemeapp.net` must serve a
signed statement at:

```
https://homemeapp.net/.well-known/assetlinks.json
```

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "net.homemeapp.app",
    "sha256_cert_fingerprints": ["<YOUR_RELEASE_KEY_SHA256>"]
  }
}]
```

**Important:** the release build is currently signed with the **debug
keystore** (`android/app/build.gradle` → `release { signingConfig
signingConfigs.debug }`). This works for testing but:
- Play Store will reject an AAB signed with the debug key.
- App Links verification will fail if you later switch to a real release
  key without updating `assetlinks.json` to match.

To fix properly:
```bash
keytool -genkey -v -keystore homeme-release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias homeme
keytool -list -v -keystore homeme-release.jks -alias homeme | grep SHA256
```
Add a real `signingConfigs.release` block in `android/app/build.gradle`
pointing at that keystore (via `key.properties`, kept out of git), and use
that same SHA-256 fingerprint in `assetlinks.json`.

Once both files line up, `adb shell pm get-app-links net.homemeapp.app`
will show `verified` and links open the app directly instead of the
browser.
