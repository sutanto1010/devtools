rm -f DevTools.dmg
flutter clean
flutter build macos --no-tree-shake-icons
appdmg appdmg.json DevTools.dmg