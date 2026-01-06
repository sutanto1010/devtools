# devtools

A new Flutter project.

## Features

- **JSON Formatter**: Format, validate, and beautify JSON data
- **XML Formatter**: Format, validate, minify, and beautify XML data with attribute sorting
- **YAML Formatter**: Format and validate YAML data
- **CSV to JSON Converter**: Convert CSV data to JSON format
- **CSV Explorer**: Explore and analyze CSV data in a table view with export capabilities
- **XML to JSON Converter**: Convert between XML and JSON formats with attribute support
- **YAML to JSON Converter**: Convert between YAML and JSON formats
- **JSON Explorer**: Explore JSON data in a tree view
- **Base64 Encoder/Decoder**: Encode and decode Base64 strings
- **Hex ↔ ASCII Converter**: Convert between hexadecimal and ASCII text with advanced formatting options
- **GPG Encrypt/Decrypt**: Encrypt and decrypt text using GPG-style encryption
- **Symmetric Encryption**: Encrypt and decrypt text using AES symmetric encryption
- **JWT Decoder**: Decode and analyze JSON Web Tokens (JWT)
- **DNS Scanner**: Scan and lookup DNS records for domains
- **Host Scanner**: Scan network for active hosts and open ports using network discovery
- **Redis Client**: Connect to Redis servers, browse keys, execute commands, and manage data with multiple connection support
- **Unit Converter**: Convert between different units of measurement
- **UUID Generator/Validator**: Generate and validate UUIDs (v1 and v4)
- **URL Parser**: Parse URLs into a tree view structure with detailed analysis
- **CRON Expression Parser**: Parse CRON expressions into English and calculate next occurrences
- **Color Picker**: Pick colors from screen and convert between color formats
- **Diff Checker**: Compare two texts and highlight differences line by line
- **Hash Generator**: Generate various string hashes (MD5, SHA-1, SHA-256, SHA-512, etc.)
- **Regex Tester**: Test regular expressions with pattern matching, groups, and replacement
- **Screenshot Tool**: Take screenshots with text annotation, drawing shapes, and cropping features
- **Basic Auth Generator**: Generate Basic Authentication headers for HTTP requests
- **Chmod Calculator**: Calculate Unix file permissions in numeric and symbolic formats
- **Unix Time Converter**: Convert between Unix timestamps and human-readable dates with timezone support
- **String Inspector**: Get detailed information on strings and texts
- **URI Encoder/Decoder**: Encode and decode URI (Uniform Resource Identifier) components
- **String Replace Tool**: Advanced find and replace with regex support, case sensitivity, and bulk operations
- **Image ↔ Base64 Converter**: Convert images to Base64 and vice versa with preview and save functionality
- **JSON to Go Struct**: Convert JSON to Go struct with customizable options and field naming conventions
- **HTML Viewer**: View and render HTML content with JavaScript and CSS support
- **WebSocket Tester**: Test WebSocket connections with real-time messaging, auto-reconnect, and message history

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