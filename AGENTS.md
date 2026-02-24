# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Flutter/Dart order management app (`controle_pedidos`) that persists data locally in an `.xlsx` file via `path_provider` and the `excel` package. No backend, no database, no Docker. See `pubspec.yaml` for dependencies.

### Environment prerequisites

- **Flutter SDK 3.38.x** (Dart SDK ^3.10.3) must be installed at `/opt/flutter` and on `PATH`.
- **Linux desktop build** requires: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libstdc++-14-dev`.
- **`xdg-user-dirs`** must be installed — `path_provider` on Linux uses `xdg-user-dir DOCUMENTS` to locate the documents directory. Without it, the app crashes on startup with `MissingPlatformDirectoryException`.

### Running the app

Build and run on the Linux desktop target (preferred for this cloud environment):

```
flutter build linux --debug
DISPLAY=:1 ./build/linux/x64/debug/bundle/controle_pedidos
```

### Lint / Analyze

```
flutter analyze
```

Pre-existing info/warning-level lint issues exist in the codebase (11 as of the initial commit). These are not errors and do not block the build.

### Testing

```
flutter test test/widget_test.dart
```

**Known issue:** Tests that call `ExcelService().init()` followed by `pumpAndSettle()` (i.e., `validation_test.dart`, `pedidos_page_test.dart`, `solicitar_page_test.dart`, `uniqueness_test.dart`) hang indefinitely. This is a pre-existing issue where the async Excel file I/O never settles within the Flutter test framework. Only `widget_test.dart` runs to completion. Running `flutter test` without specifying a file will hang.

### Web target caveat

The app uses `dart:io` and `path_provider` for local file storage, which are not available on web. `flutter build web` compiles successfully, but the app crashes at runtime when `ExcelService.init()` tries to access the documents directory. The Linux desktop target is the correct development target for this cloud VM.
