import 'package:flutter/material.dart';
import '../screens/json_formater/json_formatter_screen.dart';
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
    },
    {
      'id': 'xml_formatter',
      'icon': Icons.code,
      'title': 'XML Formatter',
      'description': 'Format, validate, minify, and beautify XML data with attribute sorting',
    },
    {
      'id': 'yaml_formatter',
      'icon': Icons.description,
      'title': 'YAML Formatter',
      'description': 'Format and validate YAML data',
    },
    {
      'id': 'csv_to_json',
      'icon': Icons.transform,
      'title': 'CSV to JSON Converter',
      'description': 'Convert CSV data to JSON format',
    },
    {
      'id': 'csv_explorer',
      'icon': Icons.table_view,
      'title': 'CSV Explorer',
      'description': 'Explore and analyze CSV data in a table view with export capabilities',
    },
    {
      'id': 'xml_to_json',
      'icon': Icons.swap_horiz,
      'title': 'XML to JSON Converter',
      'description': 'Convert between XML and JSON formats with attribute support',
    },
    {
      'id': 'yaml_to_json',
      'icon': Icons.swap_horiz,
      'title': 'YAML to JSON Converter',
      'description': 'Convert between YAML and JSON formats',
    },
    {
      'id': 'json_explorer',
      'icon': Icons.explore,
      'title': 'JSON Explorer',
      'description': 'Explore JSON data in a tree view',
    },
    {
      'id': 'base64_encoder',
      'icon': Icons.lock_outline,
      'title': 'Base64 Encoder/Decoder',
      'description': 'Encode and decode Base64 strings',
    },
    {
      'id': 'hex_to_ascii',
      'icon': Icons.transform,
      'title': 'Hex ↔ ASCII Converter',
      'description': 'Convert between hexadecimal and ASCII text with advanced formatting options',
    },
    {
      'id': 'gpg_encryption',
      'icon': Icons.security,
      'title': 'GPG Encrypt/Decrypt',
      'description': 'Encrypt and decrypt text using GPG-style encryption',
    },
    {
      'id': 'symmetric_encryption',
      'icon': Icons.lock,
      'title': 'Symmetric Encryption',
      'description': 'Encrypt and decrypt text using AES symmetric encryption',
    },
    {
      'id': 'jwt_decoder',
      'icon': Icons.token,
      'title': 'JWT Decoder',
      'description': 'Decode and analyze JSON Web Tokens (JWT)',
    },
    {
      'id': 'dns_scanner',
      'icon': Icons.dns,
      'title': 'DNS Scanner',
      'description': 'Scan and lookup DNS records for domains',
    },
    {
      'id': 'host_scanner',
      'icon': Icons.router,
      'title': 'Host Scanner',
      'description': 'Scan network for active hosts and open ports using network discovery',
    },
    {
      'id': 'redis_client',
      'icon': Icons.storage,
      'title': 'Redis Client',
      'description': 'Connect to Redis servers, browse keys, execute commands, and manage data with multiple connection support',
    },
    // {
    //   'id': 'kafka_client',
    //   'icon': Icons.stream,
    //   'title': 'Kafka Client',
    //   'description': 'Connect to Kafka brokers, manage topics, produce and consume messages with real-time monitoring',
    // },
    {
      'id': 'unit_converter',
      'icon': Icons.straighten,
      'title': 'Unit Converter',
      'description': 'Convert between different units of measurement',
    },
    {
      'id': 'uuid_generator',
      'icon': Icons.fingerprint,
      'title': 'UUID Generator/Validator',
      'description': 'Generate and validate UUIDs (v1 and v4)',
    },
    {
      'id': 'url_parser',
      'icon': Icons.link,
      'title': 'URL Parser',
      'description': 'Parse URLs into a tree view structure with detailed analysis',
    },
    {
      'id': 'cron_expression',
      'icon': Icons.schedule,
      'title': 'CRON Expression Parser',
      'description': 'Parse CRON expressions into English and calculate next occurrences',
    },
    {
      'id': 'color_picker',
      'icon': Icons.colorize,
      'title': 'Color Picker',
      'description': 'Pick colors from screen and convert between color formats',
    },
    {
      'id': 'diff_checker',
      'icon': Icons.compare_arrows,
      'title': 'Diff Checker',
      'description': 'Compare two texts and highlight differences line by line',
    },
    {
      'id': 'hash_generator',
      'icon': Icons.tag,
      'title': 'Hash Generator',
      'description': 'Generate various string hashes (MD5, SHA-1, SHA-256, SHA-512, etc.)',
    },
    {
      'id': 'regex_tester',
      'icon': Icons.search,
      'title': 'Regex Tester',
      'description': 'Test regular expressions with pattern matching, groups, and replacement',
    },
    {
      'id': 'screenshot',
      'icon': Icons.screenshot,
      'title': 'Screenshot Tool',
      'description': 'Take screenshots with text annotation, drawing shapes, and cropping features',
      'screen': ScreenshotScreen(),
    },
    {
      'id': 'basic_auth_generator',
      'icon': Icons.key,
      'title': 'Basic Auth Generator',
      'description': 'Generate Basic Authentication headers for HTTP requests',
    },
    {
      'id': 'chmod_calculator',
      'icon': Icons.security,
      'title': 'Chmod Calculator',
      'description': 'Calculate Unix file permissions in numeric and symbolic formats',
    },
    {
      'id': 'unix_time_converter',
      'icon': Icons.access_time,
      'title': 'Unix Time Converter',
      'description': 'Convert between Unix timestamps and human-readable dates with timezone support',
    },
    {
      'id': 'string_inspector',
      'icon': Icons.text_fields,
      'title': 'String Inspector',
      'description': 'Get detailed information on strings and texts',
    },
    {
      'id': 'uri_encoder',
      'icon': Icons.link,
      'title': 'URI Encoder/Decoder',
      'description': 'Encode and decode URI (Uniform Resource Identifier) components',
    },
    {
      'id': 'string_replace',
      'icon': Icons.find_replace,
      'title': 'String Replace Tool',
      'description': 'Advanced find and replace with regex support, case sensitivity, and bulk operations',
    },
    {
      'id': 'image_base64',
      'icon': Icons.image,
      'title': 'Image ↔ Base64 Converter',
      'description': 'Convert images to Base64 and vice versa with preview and save functionality',
    },
    {
      'id': 'json_to_go',
      'icon': Icons.code_outlined,
      'title': 'JSON to Go Struct',
      'description': 'Convert JSON to Go struct with customizable options and field naming conventions',
    },
    {
      'id': 'html_viewer',
      'icon': Icons.web,
      'title': 'HTML Viewer',
      'description': 'View and render HTML content with JavaScript and CSS support',
    },
    {
      'id': 'websocket_tester',
      'icon': Icons.swap_horizontal_circle,
      'title': 'WebSocket Tester',
      'description': 'Test WebSocket connections with real-time messaging, auto-reconnect, and message history',
    },
  ];

  static Widget createScreen(String toolId, String? toolParam) {
    switch (toolId) {
      case 'json_formatter':
        return const JsonFormatterScreen();
      case 'xml_formatter':
        return const XmlFormatterScreen();
      case 'yaml_formatter':
        return const YamlFormatterScreen();
      case 'csv_to_json':
        return const CsvToJsonScreen();
      case 'csv_explorer':
        return const CsvExplorerScreen();
      case 'xml_to_json':
        return const XmlToJsonScreen();
      case 'yaml_to_json':
        return const YamlToJsonScreen();
      case 'json_explorer':
        return const JsonExplorerScreen(); 
      case 'base64_encoder':
        return const Base64Screen();
      case 'hex_to_ascii':
        return const HexToAsciiScreen();
      case 'gpg_encryption':
        return const GpgScreen();
      case 'symmetric_encryption':
        return const SymmetricEncryptionScreen();
      case 'jwt_decoder':
        return const JwtDecoderScreen();
      case 'dns_scanner':
        return const DnsScannerScreen();
      case 'host_scanner':
        return const HostScannerScreen();
      case 'redis_client':
        return const RedisClientScreen();
      case 'kafka_client':
        return const KafkaClientScreen();
      case 'unit_converter':
        return const UnitConverterScreen();
      case 'uuid_generator':
        return const UuidScreen();
      case 'url_parser':
        return const UrlParserScreen();
      case 'cron_expression':
        return const CronExpressionScreen();
      case 'color_picker':
        return const ColorPickerScreen();
      case 'diff_checker':
        return const DiffCheckerScreen();
      case 'hash_generator':
        return const HashScreen();
      case 'regex_tester':
        return const RegexTesterScreen();
      case 'screenshot':
        return ScreenshotScreen(toolParam: toolParam, key: UniqueKey());
      case 'basic_auth_generator':
        return const BasicAuthScreen();
      case 'chmod_calculator':
        return const ChmodCalculatorScreen();
      case 'unix_time_converter':
        return const UnixTimeScreen();
      case 'string_inspector':
        return const StringInspectorScreen();
      case 'uri_encoder':
        return const UriEncoderScreen();
      case 'string_replace':
        return const StringReplaceScreen();
      case 'image_base64':
        return const ImageBase64Screen();
      case 'html_viewer':
        return const HtmlViewerScreen();
      case 'websocket_tester':
        return const WebSocketTesterScreen();
      default:
        final tool = allTools.firstWhere((tool) => tool['id'] == toolId);
        return tool['screen'];
    }
  }
}