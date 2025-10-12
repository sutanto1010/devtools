# devtools

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# Required Tools

1. appdmg, install using the following command:
   ```
   npm install -g appdmg
   ```

# Generate macOS app installer
1. Run the following command to build the app:
   ```
   flutter build macos --no-tree-shake-icons
   ```
2. Run the following command to generate the app installer:
   ```
   appdmg appdmg.json DevTools.app
   ```