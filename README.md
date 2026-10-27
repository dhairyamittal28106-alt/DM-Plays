# DM Plays

DM Plays is a Flutter streaming client with a catalogue organized from an M3U playlist. It groups channels by category, highlights featured and Indian channels, and provides search, playback, settings, and dark/light themes. Playback is handled with `media_kit`.

## Run locally

Install the Flutter SDK with Dart 3.1 or newer, then run:

    flutter pub get
    flutter run

The app fetches its playlist over the network. The playlist URL is defined in `lib/main.dart`; use sources that you are authorized to access.

## Project layout

- `lib/main.dart`: app startup, channel catalogue, navigation, search, settings, and player
- `assets/`: app artwork and bundled media assets
- `android/`, `ios/`, `windows/`, `linux/`, and `macos/`: Flutter platform projects

Platform playback support depends on the media libraries available for the selected Flutter target.
