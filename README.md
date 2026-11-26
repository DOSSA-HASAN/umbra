# Umbra

Umbra is an Android utility application built with Flutter that displays floating overlays above other applications. It is designed to help reduce prolonged exposure to static screen elements on OLED displays by allowing users to position and resize overlays.

## Download

**[Download Umbra for Android](https://github.com/DOSSA-HASAN/umbra/releases/latest/download/umbra.apk)**

Download the latest APK and install it on your Android device. On first launch, grant Umbra the required **Display over other apps** permission to create floating overlays.

[View all releases](https://github.com/DOSSA-HASAN/umbra/releases)

## Features

- **Floating overlays** – Display customizable floating rectangles above other applications.
- **Native dragging** – Move overlays around the screen using Android's native window handling.
- **Custom resizing** – Resize overlays by dragging their edges.
- **Minimum and maximum dimensions** – Prevent overlays from becoming too small or excessively large.
- **Responsive resize handles** – Keep edge controls usable even when an overlay is small.
- **Multiple overlays** – Designed to support multiple independently managed floating overlays.
- **Custom launcher icon and splash screen** – Umbra branding throughout the application.

## Tech Stack

- **Flutter & Dart** – Application interface and overlay resizing logic.
- **flutter_floatwing** – Floating window management and native dragging.
- **Android WindowManager** – Native display, positioning and sizing of floating windows.
- **Kotlin** – Native Android integration provided by the floating-window package.

## How It Works

Umbra uses Flutter for its overlay interface and custom resizing interactions, while `flutter_floatwing` manages the floating window lifecycle and native dragging.

### Floating Window Management

The `flutter_floatwing` package integrates Flutter with Android's native window system.

Android's WindowManager is responsible for displaying the floating window above other applications and applying its position and dimensions.

### Dragging

Dragging is handled natively by `flutter_floatwing`.

When an overlay is configured with `draggable: true`, the package handles touch movement and updates the floating window's screen position. This avoids implementing continuous position calculations and updates in Flutter.

### Resizing

Umbra implements its own edge-based resizing logic in Flutter.

Each overlay has four resize handles:

- Left edge
- Right edge
- Top edge
- Bottom edge

When a user interacts with a resize handle:

1. Flutter detects the drag gesture.
2. The application calculates the change in width or height.
3. The new dimensions are constrained by minimum and maximum limits.
4. The updated dimensions are sent to `flutter_floatwing` through `Window.update()`.
5. The package applies the new dimensions to the native Android window.

Native dragging is temporarily disabled while resizing to prevent the two interactions from interfering with each other.

### Window Update Management

Umbra queues window configuration updates to prevent multiple asynchronous updates from accumulating unnecessarily.

This helps coordinate frequent dimension changes during resizing.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or another Android development environment
- Android device or emulator
- Android permission to display over other applications

### Clone the Repository

```bash
git clone https://github.com/DOSSA-HASAN/umbra.git
cd umbra
```

### Install Dependencies

```bash
flutter pub get
```

**Important:** Umbra uses a modified version of `flutter_floatwing`. The dependency is maintained in a separate GitHub repository rather than relying on locally modified Pub cache files.

Make sure the dependency in `pubspec.yaml` points to the maintained fork before running the application.

### Run the Application

```bash
flutter run
```

## Android Permissions

Umbra requires permission to display over other applications.

On Android, this permission is commonly referred to as **Display over other apps** or **Appear on top**.

Users must grant this permission before floating overlays can be displayed.

## Building the APK

To build a release APK:

```bash
flutter build apk --release
```

The generated APK can be found at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Modified Dependency

### flutter_floatwing

Umbra uses a maintained fork of [`flutter_floatwing`](https://github.com/jiusanzhou/flutter_floatwing), originally published on [pub.dev](https://pub.dev/packages/flutter_floatwing).

The package provides the underlying floating-window functionality. A couple of changes were made during Umbra's development to address issues encountered while managing overlay windows:

- **Flutter engine cache cleanup:** Improved engine cache handling when a Flutter engine detaches, preventing stale main-engine references from causing `MissingPluginException` errors when reopening the application.
- **Window size update optimization:** Added a size comparison to avoid unnecessary native window updates when the measured dimensions have not changed.

The modified dependency is maintained separately so that anyone cloning Umbra can retrieve the same package changes.