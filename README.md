AutiCare: Autism Care Management Mobile Application Using Geolocation and Geofencing

In order to help our autism centre and parents managing children better, Registration, Searching the place using Geolocation and Geofencing, Firebase Database and Authentication and OpenRouter Ai for gaining autism information. 

Something need to know, how to setup, run the app, release the app and the database come from firebase(no need to know), USE IT AT YOUR OWN RISK.

How to setup

Flutter App Installation & Setup Guide
1. Prerequisites

Before starting, make sure you have the following installed:

Flutter SDK
 (latest stable version)

Dart SDK
 (comes with Flutter)

Android Studio
 or Visual Studio Code

Android SDK & Emulator (via Android Studio)

Java JDK (for Gradle build)

Verify your setup:

flutter doctor

This will show if there are any missing dependencies.

2. Clone the Project

Clone this repository to your local machine:

git clone https://github.com/your-username/your-flutter-app.git
cd your-flutter-app

3. Install Dependencies

Run the following command inside the project directory:

flutter pub get

4. Run the App (Debug Mode)

Connect a physical device or start an emulator, then run:

flutter run


You can also run it on a specific device:

flutter devices       # list available devices
flutter run -d <device_id>

5. Build a Release APK

To generate a release APK:

flutter build apk --release


The generated APK will be located at:

build/app/outputs/flutter-apk/app-release.apk