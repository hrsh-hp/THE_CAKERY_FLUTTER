# The Cakery

The Cakery is a Flutter-based mobile application designed for a cake shop business. This app allows customers to browse, order, and customize cakes while providing administration features for shop owners and delivery tracking for delivery personnel.

## Features

- **User authentication** (login/signup)
- **Role-based access** (customer, admin, delivery person)
- **Browse cake catalog**
- **Create custom cakes**
- **Add cakes to favorites**
- **Shopping cart functionality**
- **Order tracking**
- **Admin dashboard** for order management
- **Delivery person interface** for order delivery
- **Profile management**
- **Google Maps integration** for delivery tracking

## Installation Guide

### Prerequisites

Ensure you have the following installed before proceeding:

- [Flutter](https://flutter.dev/docs/get-started/install) 3.0.0 or higher
- [Dart](https://dart.dev/get-dart) 2.17.0 or higher
- [Git](https://git-scm.com/downloads)

### Windows Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/the_cakery.git
   cd the_cakery
   ```

2. **Create a .env file** in the root directory and add your Google Maps API key:
   ```sh
   GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

3. **Install dependencies:**
   ```sh
   flutter pub get
   ```

4. **Run the app:**
   ```sh
   flutter run
   ```

### macOS Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/the_cakery.git
   cd the_cakery
   ```

2. **Create a .env file** in the root directory and add your Google Maps API key:
   ```sh
   GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

3. **Install dependencies:**
   ```sh
   flutter pub get
   ```

4. **Run the app:**
   ```sh
   flutter run
   ```

5. **For iOS development, install CocoaPods:**
   ```sh
   cd ios
   pod install
   cd ..
   ```

### Linux Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/hrsh-hp/THE_CAKERY_FLUTTER.git
   cd THE_CAKERY_FLUTTER
   ```

2. **Create a .env file** in the root directory and add your Google Maps API key:
   ```sh
   GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

3. **Install dependencies:**
   ```sh
   flutter pub get
   ```

4. **Install Linux dependencies:**
   ```sh
   sudo apt-get update
   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
   ```

5. **Run the app:**
   ```sh
   flutter run
   ```

## Configuration

### Environment Variables

The application uses environment variables for configuration. Create a `.env` file in the root directory with the following variable:

```sh
GOOGLE_MAPS_API_KEY=your_api_key_here
```

### Backend URL Configuration

You must set the API base URL to point to your backend server. Open `lib/utils/Constants.dart` and update the `baseUrl` variable:

```dart
// Example configuration for API URL
class Constants {
  static const String baseUrl = "https://your-backend-server.com";
}
```

## Building for Production

### Android Build

```sh
flutter build apk --release
```

### iOS Build

```sh
flutter build ios --release
```

### Web Build

```sh
flutter build web --release
```

## Project Structure

- **lib/** - Contains all the Dart code for the application
  - **Screens/** - UI screens for different parts of the app
  - **utils/** - Utility functions and constants, including `Constants.dart`

## Dependencies

The project uses several Flutter packages:

- **flutter_dotenv** - For environment variable management
- **google_maps_flutter** - For map integration
- **provider** - For state management
- **http** - For API communication
- Other Flutter standard libraries for UI, navigation, and animations

For a complete list of dependencies, check the `pubspec.yaml` file.

## Contributing

If you'd like to contribute, feel free to submit a pull request or open an issue!



