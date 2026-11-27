# Somnia

Somnia is a sleep-monitoring system that uses a Samsung Galaxy Watch7 and a mobile application to record a night's sleep, estimate sleep stages (Wake, Light, Deep and REM) with a machine-learning model, and present the results to the user. It also offers Tranquil Tones, a Smart Alarm, and a short Rest Review after waking.

> Somnia provides wearable-based estimates for personal sleep monitoring. It is not a medical device and does not provide a diagnosis.

IT 496 Graduation Project, King Saud University.

## Repository structure

| Folder | Content |
|---|---|
| `lib/` | Flutter mobile application (screens in `lib/features/`, data models in `lib/models/`, Firebase and watch services in `lib/services/`) |
| `watch/` | Galaxy Watch7 application (Kotlin, Wear OS), which collects the sensor data during a sleep session |
| `functions/` | Firebase Cloud Functions (Python 3.12) |
| `hosting/` | Firebase Hosting page used for password reset |
| `android/`, `ios/` | Platform projects for the mobile application |

The sleep-stage model (training and evaluation on the DREAMT dataset) is developed in Google Colab:
https://colab.research.google.com/drive/1rLuzaglqF0LEBrBRbt049MBZRPKKVEZ3?usp=sharing

## Requirements

- Flutter SDK with Dart 3.13 or later
- Android Studio (with the Android SDK and the Wear OS emulator or a physical watch)
- An Android phone or emulator for the mobile application
- A Samsung Galaxy Watch7 paired with the phone through the Galaxy Wearable app (needed to record sleep sessions)
- Samsung Health Sensor SDK 1.4.1 (`samsung-health-sensor-api-1.4.1.aar`), downloaded from https://developer.samsung.com/health/sensor
- Firebase CLI (only to deploy the Cloud Functions or the hosting page)

## Setup and running

### 1. Mobile application

```bash
git clone https://github.com/JuriThamer/2026_GP_G23_Somnia.git
cd 2026_GP_G23_Somnia
flutter pub get
flutter run
```

The Firebase configuration of the project is already included (`android/app/google-services.json`), so the application connects to the project's Firebase backend without further setup.

### 2. Watch application

1. Download the Samsung Health Sensor SDK and place `samsung-health-sensor-api-1.4.1.aar` in `watch/app/libs/`.
2. Open the `watch` folder in Android Studio.
3. Connect the Galaxy Watch7 (with developer mode and debugging enabled) and run the `app` configuration.
4. On the watch, allow the requested permissions (body sensors and activity recognition).

### 3. Firebase Cloud Functions and hosting (optional)

```bash
firebase login
firebase deploy --only functions
firebase deploy --only hosting
```

## Using the application

1. Create an account in the mobile application and verify the email address.
2. Connect the Galaxy Watch7 from **Watch** on the home screen.
3. Set the Smart Alarm (optional) and choose a Tranquil Tone (optional).
4. Start a sleep session before sleeping and end it after waking.
5. Answer the Rest Review and view the results on the Sleep Dashboard and in Sleep History.

## Team

- Lama Alhamed
- Lana Almulhem
- Juri Alanazi
- Najla Alhusaini

Supervised by Dr. Nouf Alrumaih and Dr. Mashael Aldayel.
