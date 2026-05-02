# 🌤️ ATMOS — Weather Intelligence App

A beautiful, modern, and fully functional Flutter weather application with blue-shade UI, yellow temperature display, and a complete 5-tab navigation experience.

---

## 📱 Screenshots & Features

### Navigation Tabs
| Home | Map | Location | Alerts | Settings |
|------|-----|----------|--------|----------|
| Current weather, hourly & 7-day forecast | Interactive weather map layers | Saved locations management | Weather alert tracking | Units, notifications, display |

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK **3.13+**
- Dart **3.1+**
- Android SDK 21+ / iOS 13+
- Xcode 14+ (iOS)

### 1. Clone & Install
```bash
cd atmos
flutter pub get
```

### 2. Configure API Keys (Optional — app works without them!)

Edit `lib/core/constants/app_constants.dart`:

```dart
// FREE — No key required (default data source)
// Open-Meteo: https://open-meteo.com

// OPTIONAL — For weather map tile overlays
static const String openWeatherApiKey = 'YOUR_KEY'; 
// Get free key at: https://openweathermap.org/api

// OPTIONAL — For Mapbox tiles
static const String mapboxToken = 'YOUR_TOKEN';
// Get free token at: https://mapbox.com
```

> **✅ The app runs 100% without API keys** using Open-Meteo (completely free, no registration).

### 3. Run the App
```bash
# Debug
flutter run

# Release (Android)
flutter build apk --release

# Release (iOS)
flutter build ipa --release
```

---

## 📁 Project Structure

```
atmos/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart          # API keys, URLs, config
│   │   ├── theme/
│   │   │   └── app_theme.dart              # Blue palette, yellow temp, typography
│   │   └── utils/
│   │       └── weather_utils.dart          # WMO codes, unit conversions, colors
│   ├── data/
│   │   ├── models/
│   │   │   └── weather_model.dart          # All data models (OpenMeteo, OWM, etc.)
│   │   └── repositories/
│   │       └── weather_repository.dart     # API calls, caching, CRUD for locations
│   └── presentation/
│       ├── bloc/
│       │   └── weather/
│       │       └── weather_bloc.dart       # BLoC state management
│       ├── screens/
│       │   ├── splash_screen.dart          # Animated splash
│       │   ├── main_shell.dart             # Bottom nav bar shell (5 tabs)
│       │   ├── home/
│       │   │   └── home_screen.dart        # Current weather + forecasts
│       │   ├── map/
│       │   │   └── map_screen.dart         # Interactive map with weather layers
│       │   ├── location/
│       │   │   └── location_screen.dart    # Saved locations management
│       │   ├── alerts/
│       │   │   └── alerts_screen.dart      # Weather alerts tracking
│       │   └── settings/
│       │       └── settings_screen.dart    # App preferences
│       └── widgets/
│           ├── common/
│           │   └── glass_card.dart         # Reusable glass UI components
│           └── weather/
│               ├── current_weather_card.dart
│               ├── hourly_forecast_widget.dart
│               ├── daily_forecast_widget.dart
│               ├── weather_details_grid.dart
│               ├── air_quality_card.dart
│               └── search_overlay.dart
├── android/
│   └── app/
│       ├── build.gradle
│       └── src/main/AndroidManifest.xml
├── ios/
│   └── Runner/
│       └── Info.plist
├── assets/
│   ├── icons/
│   ├── images/
│   └── animations/          # Add Lottie JSON files here
└── pubspec.yaml
```

---

## 🌐 APIs Used

| API | Purpose | Key Required | Cost |
|-----|---------|--------------|------|
| [Open-Meteo](https://open-meteo.com) | Weather forecast, current conditions | ❌ No | Free |
| [Open-Meteo Air Quality](https://air-quality-api.open-meteo.com) | AQI, PM2.5, PM10, O₃ | ❌ No | Free |
| [Open-Meteo Geocoding](https://geocoding-api.open-meteo.com) | City search | ❌ No | Free |
| [OpenWeatherMap](https://openweathermap.org/api) | Map tile overlays | ✅ Yes | Free tier available |
| [CartoDB](https://carto.com/basemaps/) | Map base tiles (dark) | ❌ No | Free |
| [OpenStreetMap](https://www.openstreetmap.org) | Alternative map tiles | ❌ No | Free |

---

## 🎨 Design System

### Color Palette
```dart
// Blues (primary)
primaryDeep:   #0A1628   // App background
primaryDark:   #0D2137   // Cards, nav bar
primary:       #0F3460   // Surface
primaryAccent: #2196F3   // Interactive elements

// Yellow (temperature)
tempYellow:    #FFD600   // Main temperature display
tempYellowWarm:#FFC107   // Warm weather accent
```

### Typography
- Font: **Rajdhani** (Google Fonts)
- Temperature display: 110px Bold
- Section headers: 12px SemiBold, letter-spacing 1.5

---

## ⚡ Features

### Home Screen
- Live current weather with animated emoji
- Large yellow temperature display with gradient
- Real-time humidity, wind, pressure quick stats
- Horizontal 24-hour forecast scroll
- 7-day daily forecast with temp range bars
- Detailed weather grid (6 metrics)
- Air Quality Index with pollutants breakdown
- Pull-to-refresh
- City search with popular city shortcuts

### Map Screen
- Interactive flutter_map with dark CartoDB tiles
- 5 weather layer overlays: Temperature, Precipitation, Clouds, Wind, Pressure
- Layer opacity control slider
- Location pin with city name
- Center-to-location button

### Location Screen
- Save/remove multiple cities
- Set home city
- Live temperature per saved location
- Quick-navigate to any city's weather
- Population counter

### Alerts Screen
- Active vs Past alerts tab filter
- Severity filter chips (Extreme/Severe/Moderate/Minor)
- Expandable alert cards with full description
- Start/End time display
- Unread badge on nav tab
- Mark all read

### Settings Screen
- Temperature unit (°C / °F)
- Wind speed (km/h, mph, m/s, knots)
- Pressure (hPa, inHg, mmHg)
- Visibility (km, mi)
- 24-hour time format toggle
- AQI / UV Index display toggles
- Map style selector
- Notification toggles per alert type
- API configuration status display
- Cache clear + settings reset

---

## 📦 Key Dependencies

```yaml
flutter_bloc: ^8.1.3        # State management
flutter_map: ^6.1.0         # Interactive maps
geolocator: ^10.1.0         # Device location
fl_chart: ^0.65.0           # Charts
flutter_animate: ^4.3.0     # Animations
dio: ^5.3.3                 # HTTP client
shared_preferences: ^2.2.2  # Local storage
```

---

## 🔧 Deployment

### Android
```bash
# Generate signed APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Generate App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Archive for App Store
flutter build ipa --release

# Open in Xcode for signing
open ios/Runner.xcworkspace
```

### Required before deployment
1. Update `applicationId` in `android/app/build.gradle`
2. Update `CFBundleIdentifier` in `ios/Runner/Info.plist`
3. Add app signing certificates
4. Add real Lottie animation files to `assets/animations/`
5. Add app icon to `assets/icons/`

---

## 📝 License

MIT License — Free to use and modify.
