# 🛡️ Safety Guardian — AI-Powered Women's Safety & Emergency Response Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.44.6-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Design-Material_3-6750A4?style=for-the-badge&logo=material-design&logoColor=white)](https://m3.material.io)
[![Google Maps](https://img.shields.io/badge/Maps-Google_Maps_SDK-4285F4?style=for-the-badge&logo=google-maps&logoColor=white)](https://cloud.google.com/maps-platform)
[![OpenStreetMap](https://img.shields.io/badge/Geospatial-OSM_&_Nominatim-7EBC6F?style=for-the-badge&logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org)
[![OSRM](https://img.shields.io/badge/Routing-Project_OSRM-4285F4?style=for-the-badge)](https://project-osrm.org)
[![Overpass API](https://img.shields.io/badge/Overpass_API-Spatial_Radar-FF9800?style=for-the-badge)](https://overpass-api.de)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

---

## 📖 Executive Summary

**Safety Guardian** is a production-grade, full-featured Flutter Android mobile application designed to protect women and vulnerable citizens through real-time spatio-temporal AI crime risk prediction, proactive safe routing, and high-priority emergency response mechanisms.

Built with **Material 3 accessible design tokens**, **Clean Layered Architecture**, and a **100% Free & Open-Source Geospatial Stack** (*OpenStreetMap*, *Nominatim Geocoding*, *Overpass Spatial Radar*, and *Project OSRM Driving Engine*), the application operates without Google Maps API keys or third-party tracking dependencies.

---

## 🏛️ System Architecture

```
                                +--------------------------------------+
                                |      Safety Guardian Mobile App      |
                                |     (Flutter 3.44.6 / Material 3)    |
                                +------------------+-------------------+
                                                   |
                     +-----------------------------+-----------------------------+
                     |                             |                             |
                     v                             v                             v
        +-------------------------+   +-------------------------+   +-------------------------+
        |   Laravel 11 REST API   |   |   OpenStreetMap Stack   |   |    Local System Engine  |
        |    (Sanctum Bearer)     |   |   (Zero API Key Req.)   |   |    (Offline Resilient)  |
        +-------------------------+   +-------------------------+   +-------------------------+
        | - Auth & Registration   |   | - OSM Tile Server       |   | - Secure Token Storage  |
        | - Emergency Contacts    |   | - Nominatim Geocoding   |   | - Local Notification    |
        | - SOS Trigger & Track   |   | - Overpass 5km Radar    |   | - SharedPref Cache      |
        | - Safe Route AI Engine  |   | - OSRM Routing Engine   |   | - GPS Location Stream   |
        | - Incident Reporting    |   +-------------------------+   +-------------------------+
        | - Push Notifications    |
        +-------------------------+
                     |
                     v
        +-------------------------+
        |  Python Flask ML Engine |
        | (Spatio-Temporal Risk)  |
        +-------------------------+
```

---

## ✨ Core Features & Modules

### 1. 🚨 High-Priority Emergency SOS Broadcast
* **3-Second Cancellation Buffer**: Prevents accidental false alarms with heavy haptic vibration countdown pulses.
* **Continuous GPS Streamer**: Automatically transmits updated latitude, longitude, and speed telemetry to `/api/sos/{id}/track`.
* **One-Tap Emergency Direct Dialers**:
  * 📞 `112` — National Unified Emergency Number
  * 📞 `1091` — National Women Safety Helpline
  * 📞 `100` — Police Control Room
  * 📞 `108` — Emergency Medical & Ambulance
* **Direct SMS Broadcast**: Auto-populates SMS with live OpenStreetMap coordinates link to the primary emergency contact.
* **PIN Deactivation**: Securely closes emergency state via verification PIN.

### 2. 🗺️ OpenStreetMap & Nominatim Search Engine
* **Pure Open-Source Map Engine**: Powered by `flutter_map` with OSM Standard Tile layers.
* **Live GPS Indicator**: Renders current user position with pulsing accuracy circle.
* **Debounced Location Search**: Real-time address and landmark auto-complete powered by the Nominatim Search API (600ms debounce).
* **Interactive Map Controls**: Recenter camera, Zoom In (+), Zoom Out (-).

### 3. 🚓 5km Overpass Spatial Amenity Radar
* **Nearby Police Stations**: Automatically queries Overpass QL within a 5,000m radius (`amenity=police`), calculates distances, and provides 1-tap call & directions.
* **Nearby 24/7 Hospitals & Clinics**: Scans surrounding emergency clinics, trauma centers, and medical hospitals (`amenity=hospital`).
* **Map Layer Markers**: Interactive Blue Police and Teal Hospital map markers with callout info cards.

### 4. 🧭 OSRM Safe Route Recommendation & Polyline Engine
* **Turn-by-Turn Driving & Walking Geometry**: Fetches full road geometries from OSRM (`/route/v1/driving`).
* **AI Safety Evaluation**: Intersects routes with crime density datasets, calculating distance (`km`), duration (`min`), and safety score (`/100`).
* **Interactive Polyline Rendering**: Draws the recommended safe pathway in emerald green, with alternative route comparison cards.

### 5. 🧠 Spatio-Temporal AI Crime Risk Prediction
* **24-Hour Temporal Risk Simulator**: Interactive slider demonstrating how crime probability changes from morning to midnight.
* **Incident Category Focus**: Analyzes risk levels for *Harassment*, *Stalking*, *Eve Teasing*, *Theft*, and *Assault*.
* **Vicinity Environment Selector**: Adapts predictions to *Downtown*, *Commercial*, *Park/Isolation*, *Residential*, and *Industrial* areas.
* **Translucent Heatmap Circles**: Visualizes high-risk (Crimson), medium-risk (Amber), and low-risk (Teal) zones on OpenStreetMap.

### 6. 📸 Photo Incident Reporting
* **Multi-Source Photo Evidence**: Attach photos directly from device Camera or Gallery using `image_picker`.
* **Automatic GPS Tagging**: Captures exact reverse-geocoded location of the observed hazard.
* **Historical Tracking**: Dedicated tab monitoring report resolution status (`PENDING`, `VERIFIED`, `RESOLVED`).

### 7. 👥 Emergency Contacts & Offline Resilience
* **Full CRUD Management**: Link parents, siblings, and guardians with `is_primary` priority flagging.
* **Offline Caching**: Instant access to emergency numbers and profile data via encrypted local storage when disconnected.
* **Top Connection Banner**: Real-time warning bar alerting the user when network connectivity is lost.

### 8. ⚙️ App Customization & Material 3 Theme
* **Theme Modes**: Full support for `System Default`, `Light Mode`, and sleek `Dark Mode`.
* **SOS Countdown Config**: Customizable 3-second or 5-second countdown intervals.
* **Local Notifications**: Android notification channels configured with `Importance.max` for emergency broadcasts.

---

## 📡 API Endpoints Matrix

| HTTP Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `POST` | `/api/register` | User account registration | No |
| `POST` | `/api/login` | User login & token generation | No |
| `POST` | `/api/verify-otp` | 6-digit OTP verification | No |
| `POST` | `/api/logout` | Revoke Sanctum Bearer token | Yes |
| `GET` | `/api/profile` | Fetch authenticated user profile | Yes |
| `PUT` | `/api/profile` | Update phone & emergency meta | Yes |
| `GET` | `/api/contacts` | List user emergency contacts | Yes |
| `POST` | `/api/contacts` | Add new emergency contact | Yes |
| `PUT` | `/api/contacts/{id}` | Update existing contact | Yes |
| `DELETE`| `/api/contacts/{id}` | Remove emergency contact | Yes |
| `POST` | `/api/sos/trigger` | Activate SOS broadcast & alert contacts | Yes |
| `POST` | `/api/sos/{id}/track` | Stream live GPS coordinate updates | Yes |
| `POST` | `/api/sos/{id}/resolve`| Deactivate SOS with verification code | Yes |
| `POST` | `/api/predict-risk` | AI crime risk spatio-temporal score | Yes |
| `POST` | `/api/routes/safe-recommendation`| AI recommended safe route & polyline | Yes |
| `GET` | `/api/incidents` | List submitted incident reports | Yes |
| `POST` | `/api/incidents` | Submit incident with photo (multipart) | Yes |
| `GET` | `/api/notifications`| Fetch safety alerts & SOS broadcasts | Yes |
| `PUT` | `/api/notifications/{id}/read` | Mark notification as read | Yes |

---

## 🛠️ Setup & Installation Guide

### Prerequisites
* **Flutter SDK**: `^3.44.6`
* **Dart SDK**: `^3.12.2`
* **Android Studio / VS Code / Antigravity IDE**
* **Android SDK**: `minSdkVersion 21`, `targetSdkVersion 34+`

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/safety_guardian.git
cd safety_guardian/mobile_app
```

### 2. Install Flutter Packages
```bash
flutter pub get
```

### 3. Configure Google Maps API Key (Optional)
To provide your custom Google Maps API Key:
1. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyYourActualGoogleMapsKeyHere" />
   ```
2. Or pass it dynamically via `--dart-define`:
   ```bash
   flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIzaSyYourActualGoogleMapsKeyHere
   ```

### 4. Configure Backend Base URL
The application auto-detects the host environment, but you can override the API URL via `--dart-define`:

* **Android Emulator (Default)**:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/
  ```

* **Physical Android Device (LAN IP)**:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api/
  ```

---

## 🧪 Testing & Code Quality

Run static analysis and the automated test suite:

```bash
# Run Flutter Static Analysis
flutter analyze

# Run Complete Unit & Widget Test Suite
flutter test
```

### Verification Highlights:
* ✅ **Static Analysis**: `0 issues found` (Clean compilation under `flutter_lints ^6.0.0`).
* ✅ **Unit Tests**: Full coverage across User, EmergencyContact, SOSAlert, IncidentReport, CrimeRisk, Place, and Route models.
* ✅ **Provider State Tests**: Comprehensive validation of `AuthProvider`, `ContactProvider`, `LocationProvider`, `MapProvider`, `AmenityProvider`, `RouteProvider`, `CrimeRiskProvider`, `SosProvider`, `IncidentProvider`, `ConnectivityProvider`, and `SettingsProvider`.

---

## 🔒 Security & Privacy Practices

* **Sanctum Authentication**: Stored using `flutter_secure_storage` with hardware-backed Keystore encryption.
* **Zero Telemetry Leakage**: No Google Maps API Key or external advertising trackers required.
* **Granular Permission Handling**: Never silently requests permissions; includes direct deep links to Android system settings when permissions are permanently denied.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
