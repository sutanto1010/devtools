import 'package:flutter/material.dart';
import '../screens/json_formatter_screen.dart';
import '../screens/yaml_formatter_screen.dart';
import '../screens/csv_to_json_screen.dart';
import '../screens/csv_explorer_screen.dart';
import '../screens/json_explorer_screen.dart';
import '../screens/base64_screen.dart';
import '../screens/hex_to_ascii_screen.dart';
import '../screens/gpg_screen.dart';
import '../screens/symmetric_encryption_screen.dart';
import '../screens/dns_scanner_screen.dart';
import '../screens/host_scanner_screen.dart';
import '../screens/unit_converter_screen.dart';
import '../screens/uuid_screen.dart';
import '../screens/url_parser_screen.dart';
import '../screens/jwt_decoder_screen.dart';
import '../screens/cron_expression_screen.dart';
import '../screens/color_picker_screen.dart';
import '../screens/diff_checker_screen.dart';
import '../screens/hash_screen.dart';
import '../screens/regex_tester_screen.dart';
import '../screens/screenshot_screen.dart';
import '../screens/basic_auth_screen.dart';
import '../screens/chmod_calculator_screen.dart';
import '../screens/unix_time_screen.dart';
import '../screens/string_inspector_screen.dart';
import '../screens/xml_formatter_screen.dart';
import '../screens/uri_encoder_screen.dart';
import '../screens/xml_to_json_screen.dart';
import '../screens/yaml_to_json_screen.dart';
import '../screens/string_replace_screen.dart';
import '../screens/image_base64_screen.dart';
import '../screens/html_viewer_screen.dart';
import '../screens/json_to_go_screen.dart';
import '../screens/redis_client_screen.dart';
import '../screens/websocket_tester_screen.dart';
import '../screens/kafka_client_screen.dart';

class ToolsConfig {
  static final List<Map<String, dynamic>> allTools = [
    {
      'id': 'json_formatter',
      'icon': Icons.code,
      'title': 'JSON Formatter',
      'description': 'Format, validate, and beautify JSON data',
      'screen': const JsonFormatterScreen(),
    },
    {
      'id': 'xml_formatter',
      'icon': Icons.code,
      'title': 'XML Formatter',
      'description': 'Format, validate, minify, and beautify XML data with attribute sorting',
      'screen': const XmlFormatterScreen(),
    },
    {
      'id': 'yaml_formatter',
      'icon': Icons.description,
      'title': 'YAML Formatter',
      'description': 'Format and validate YAML data',
      'screen': const YamlFormatterScreen(),
    },
    {
      'id': 'csv_to_json',
      'icon': Icons.transform,
      'title': 'CSV to JSON Converter',
      'description': 'Convert CSV data to JSON format',
      'screen': const CsvToJsonScreen(),
    },
    {
      'id': 'csv_explorer',
      'icon': Icons.table_view,
      'title': 'CSV Explorer',
      'description': 'Explore and analyze CSV data in a table view with export capabilities',
      'screen': const CsvExplorerScreen(),
    },
    {
      'id': 'xml_to_json',
      'icon': Icons.swap_horiz,
      'title': 'XML to JSON Converter',
      'description': 'Convert between XML and JSON formats with attribute support',
      'screen': const XmlToJsonScreen(),
    },
    {
      'id': 'yaml_to_json',
      'icon': Icons.swap_horiz,
      'title': 'YAML to JSON Converter',
      'description': 'Convert between YAML and JSON formats',
      'screen': const YamlToJsonScreen(),
    },
    {
      'id': 'json_explorer',
      'icon': Icons.explore,
      'title': 'JSON Explorer',
      'description': 'Explore JSON data in a tree view',
      'screen': const JsonExplorerScreen(),
    },
    {
      'id': 'base64_encoder',
      'icon': Icons.lock_outline,
      'title': 'Base64 Encoder/Decoder',
      'description': 'Encode and decode Base64 strings',
      'screen': const Base64Screen(),
    },
    {
      'id': 'hex_to_ascii',
      'icon': Icons.transform,
      'title': 'Hex ↔ ASCII Converter',
      'description': 'Convert between hexadecimal and ASCII text with advanced formatting options',
      'screen': const HexToAsciiScreen(),
    },
    {
      'id': 'gpg_encryption',
      'icon': Icons.security,
      'title': 'GPG Encrypt/Decrypt',
      'description': 'Encrypt and decrypt text using GPG-style encryption',
      'screen': const GpgScreen(),
    },
    {
      'id': 'symmetric_encryption',
      'icon': Icons.lock,
      'title': 'Symmetric Encryption',
      'description': 'Encrypt and decrypt text using AES symmetric encryption',
      'screen': const SymmetricEncryptionScreen(),
    },
    {
      'id': 'jwt_decoder',
      'icon': Icons.token,
      'title': 'JWT Decoder',
      'description': 'Decode and analyze JSON Web Tokens (JWT)',
      'screen': const JwtDecoderScreen(),
    },
    {
      'id': 'dns_scanner',
      'icon': Icons.dns,
      'title': 'DNS Scanner',
      'description': 'Scan and lookup DNS records for domains',
      'screen': const DnsScannerScreen(),
    },
    {
      'id': 'host_scanner',
      'icon': Icons.router,
      'title': 'Host Scanner',
      'description': 'Scan network for active hosts and open ports using network discovery',
      'screen': const HostScannerScreen(),
    },
    {
      'id': 'redis_client',
      'icon': Icons.storage,
      'title': 'Redis Client',
      'description': 'Connect to Redis servers, browse keys, execute commands, and manage data with multiple connection support',
      'screen': const RedisClientScreen(),
    },
    // {
    //   'id': 'kafka_client',
    //   'icon': Icons.stream,
    //   'title': 'Kafka Client',
    //   'description': 'Connect to Kafka brokers, manage topics, produce and consume messages with real-time monitoring',
    //   'screen': const KafkaClientScreen(),
    // },
    {
      'id': 'unit_converter',
      'icon': Icons.straighten,
      'title': 'Unit Converter',
      'description': 'Convert between different units of measurement',
      'screen': const UnitConverterScreen(),
    },
    {
      'id': 'uuid_generator',
      'icon': Icons.fingerprint,
      'title': 'UUID Generator/Validator',
      'description': 'Generate and validate UUIDs (v1 and v4)',
      'screen': const UuidScreen(),
    },
    {
      'id': 'url_parser',
      'icon': Icons.link,
      'title': 'URL Parser',
      'description': 'Parse URLs into a tree view structure with detailed analysis',
      'screen': const UrlParserScreen(),
    },
    {
      'id': 'cron_expression',
      'icon': Icons.schedule,
      'title': 'CRON Expression Parser',
      'description': 'Parse CRON expressions into English and calculate next occurrences',
      'screen': const CronExpressionScreen(),
    },
    {
      'id': 'color_picker',
      'icon': Icons.colorize,
      'title': 'Color Picker',
      'description': 'Pick colors from screen and convert between color formats',
      'screen': const ColorPickerScreen(),
    },
    {
      'id': 'diff_checker',
      'icon': Icons.compare_arrows,
      'title': 'Diff Checker',
      'description': 'Compare two texts and highlight differences line by line',
      'screen': const DiffCheckerScreen(),
    },
    {
      'id': 'hash_generator',
      'icon': Icons.tag,
      'title': 'Hash Generator',
      'description': 'Generate various string hashes (MD5, SHA-1, SHA-256, SHA-512, etc.)',
      'screen': const HashScreen(),
    },
    {
      'id': 'regex_tester',
      'icon': Icons.search,
      'title': 'Regex Tester',
      'description': 'Test regular expressions with pattern matching, groups, and replacement',
      'screen': const RegexTesterScreen(),
    },
    {
      'id': 'screenshot',
      'icon': Icons.screenshot,
      'title': 'Screenshot Tool',
      'description': 'Take screenshots with text annotation, drawing shapes, and cropping features',
      'screen': const ScreenshotScreen(),
    },
    {
      'id': 'basic_auth_generator',
      'icon': Icons.key,
      'title': 'Basic Auth Generator',
      'description': 'Generate Basic Authentication headers for HTTP requests',
      'screen': const BasicAuthScreen(),
    },
    {
      'id': 'chmod_calculator',
      'icon': Icons.security,
      'title': 'Chmod Calculator',
      'description': 'Calculate Unix file permissions in numeric and symbolic formats',
      'screen': const ChmodCalculatorScreen(),
    },
    {
      'id': 'unix_time_converter',
      'icon': Icons.access_time,
      'title': 'Unix Time Converter',
      'description': 'Convert between Unix timestamps and human-readable dates with timezone support',
      'screen': const UnixTimeScreen(),
    },
    {
      'id': 'string_inspector',
      'icon': Icons.text_fields,
      'title': 'String Inspector',
      'description': 'Get detailed information on strings and texts',
      'screen': const StringInspectorScreen(),
    },
    {
      'id': 'uri_encoder',
      'icon': Icons.link,
      'title': 'URI Encoder/Decoder',
      'description': 'Encode and decode URI (Uniform Resource Identifier) components',
      'screen': const UriEncoderScreen(),
    },
    {
      'id': 'string_replace',
      'icon': Icons.find_replace,
      'title': 'String Replace Tool',
      'description': 'Advanced find and replace with regex support, case sensitivity, and bulk operations',
      'screen': const StringReplaceScreen(),
    },
    {
      'id': 'image_base64',
      'icon': Icons.image,
      'title': 'Image ↔ Base64 Converter',
      'description': 'Convert images to Base64 and vice versa with preview and save functionality',
      'screen': const ImageBase64Screen(),
    },
    {
      'id': 'json_to_go',
      'icon': Icons.code_outlined,
      'title': 'JSON to Go Struct',
      'description': 'Convert JSON to Go struct with customizable options and field naming conventions',
      'screen': const JsonToGoScreen(),
    },
    {
      'id': 'html_viewer',
      'icon': Icons.web,
      'title': 'HTML Viewer',
      'description': 'View and render HTML content with JavaScript and CSS support',
      'screen': const HtmlViewerScreen(),
    },
    {
      'id': 'websocket_tester',
      'icon': Icons.swap_horizontal_circle,
      'title': 'WebSocket Tester',
      'description': 'Test WebSocket connections with real-time messaging, auto-reconnect, and message history',
      'screen': const WebSocketTesterScreen(),
    },
  ];

  static Widget createScreen(String toolId, String? toolParam) {
    switch (toolId) {
      case 'json_formatter':
        return JsonFormatterScreen();
      case 'xml_formatter':
        return XmlFormatterScreen();
      case 'yaml_formatter':
        return YamlFormatterScreen();
      case 'csv_to_json':
        return CsvToJsonScreen();
      case 'csv_explorer':
        return CsvExplorerScreen();
      case 'xml_to_json':
        return XmlToJsonScreen();
      case 'yaml_to_json':
        return YamlToJsonScreen();
      case 'json_explorer':
        return JsonExplorerScreen();
      case 'base64_encoder':
        return Base64Screen();
      case 'hex_to_ascii':
        return HexToAsciiScreen();
      case 'gpg_encryption':
        return GpgScreen();
      case 'symmetric_encryption':
        return SymmetricEncryptionScreen();
      case 'jwt_decoder':
        return JwtDecoderScreen();
      case 'dns_scanner':
        return DnsScannerScreen();
      case 'host_scanner':
        return HostScannerScreen();
      case 'redis_client':
        return RedisClientScreen();
      case 'kafka_client':
        return KafkaClientScreen();
      case 'unit_converter':
        return UnitConverterScreen();
      case 'uuid_generator':
        return UuidScreen();
      case 'url_parser':
        return UrlParserScreen();
      case 'cron_expression':
        return CronExpressionScreen();
      case 'color_picker':
        return ColorPickerScreen();
      case 'diff_checker':
        return DiffCheckerScreen();
      case 'hash_generator':
        return HashScreen();
      case 'regex_tester':
        return RegexTesterScreen();
      case 'screenshot':
        return ScreenshotScreen(toolParam: toolParam);
      case 'basic_auth_generator':
        return BasicAuthScreen();
      case 'chmod_calculator':
        return ChmodCalculatorScreen();
      case 'unix_time_converter':
        return UnixTimeScreen();
      case 'string_inspector':
        return StringInspectorScreen();
      case 'uri_encoder':
        return UriEncoderScreen();
      case 'string_replace':
        return StringReplaceScreen();
      case 'image_base64':
        return ImageBase64Screen();
      case 'html_viewer':
        return HtmlViewerScreen();
      case 'websocket_tester':
        return WebSocketTesterScreen();
      case 'kafka_client':
        return KafkaClientScreen();
      default:
        final tool = allTools.firstWhere((tool) => tool['id'] == toolId);
        return tool['screen'];
    }
  }
}