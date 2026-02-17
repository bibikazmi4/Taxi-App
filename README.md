# SwiftRide Taxi App (Flutter)

This project is designed for **Android/iOS**.  
**Note:** `google_maps_flutter` does **not** support Windows desktop, so run on an **Android emulator/device** (recommended) or **Chrome (web)**.

## Run

```bash
flutter pub get
flutter run
```

## If you see: “No Android/iOS project configured”
This ZIP focuses on the **assignment source code**. If your platform folders are missing, generate them:

```bash
# inside swiftride_taxi_project
flutter create .
flutter pub get
flutter run
```

## Google Maps API key
Set your key in:

- `lib/utils/constants.dart` → `Constants.googleMapsApiKey`

Then configure:
- Android: `android/app/src/main/AndroidManifest.xml` meta-data `com.google.android.geo.API_KEY`
- iOS: `ios/Runner/Info.plist`

If you do **not** add a key, the app will still run using **fallback routing** (straight-line polyline + estimated distance/time).
