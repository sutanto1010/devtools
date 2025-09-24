import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:window_manager/window_manager.dart';  // Add this import
import 'package:package_info_plus/package_info_plus.dart';
import 'database_helper.dart';
import 'screens/json_formatter_screen.dart';
import 'screens/yaml_formatter_screen.dart';
import 'screens/csv_to_json_screen.dart';
import 'screens/json_explorer_screen.dart';
import 'screens/base64_screen.dart';
import 'screens/gpg_screen.dart';
import 'screens/symmetric_encryption_screen.dart';
import 'screens/dns_scanner_screen.dart';
import 'screens/unit_converter_screen.dart';
import 'screens/uuid_screen.dart';
import 'screens/url_parser_screen.dart';
import 'screens/jwt_decoder_screen.dart';
import 'screens/cron_expression_screen.dart';
import 'screens/color_picker_screen.dart';
import 'screens/diff_checker_screen.dart';
import 'screens/hash_screen.dart';
import 'screens/regex_tester_screen.dart';
import 'screens/screenshot_screen.dart';
import 'screens/basic_auth_screen.dart';
import 'screens/chmod_calculator_screen.dart';
import 'screens/unix_time_screen.dart';
import 'screens/string_inspector_screen.dart';
import 'screens/xml_formatter_screen.dart';
import 'screens/uri_encoder_screen.dart';
import 'screens/xml_to_json_screen.dart';
import 'system_tray_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev Tools',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Developer Tools'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SystemTrayManager _systemTrayManager = SystemTrayManager();
  
  String _searchQuery = '';
  List<Map<String, dynamic>> _recentlyUsedTools = [];

  final List<Map<String, dynamic>> _allTools = [
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
      'id': 'xml_to_json',
      'icon': Icons.swap_horiz,
      'title': 'XML to JSON Converter',
      'description': 'Convert between XML and JSON formats with attribute support',
      'screen': const XmlToJsonScreen(),
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
      'id': 'screenshot_tool',
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
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecentlyUsedTools();
    // init system tray
    _systemTrayManager.initSystemTray();
    // Set up system tray callback
    _systemTrayManager.onToolSelected = _handleSystemTrayToolSelection;
    _systemTrayManager.onExitApp = () {
      dispose();
      exit(0);
    };
    _systemTrayManager.onShowApp = () async {
      // Show and focus the main window
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setAlwaysOnTop(false); // Remove always on top after focusing
    };
  }

  void _handleSystemTrayToolSelection(String toolId) {
    final tool = _allTools.firstWhere(
      (tool) => tool['id'] == toolId,
      orElse: () => {},
    );
    
    if (tool.isNotEmpty) {
      _navigateToTool(tool);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentlyUsedTools() async {
    final recentTools = await _dbHelper.getRecentTools(limit: 10);
    setState(() {
      _recentlyUsedTools = recentTools;
    });
  }

  Future<void> _addToRecentlyUsed(String toolId, {Map<String, dynamic>? sessionData}) async {
    final tool = _allTools.firstWhere((tool) => tool['id'] == toolId);
    
    await _dbHelper.addToolUsage(
      toolId: toolId,
      toolTitle: tool['title'],
      toolDescription: tool['description'],
      iconCodePoint: (tool['icon'] as IconData).codePoint,
      sessionData: sessionData,
    );
    
    await _loadRecentlyUsedTools();
    
    // Update system tray menu with new recent tools
    await _systemTrayManager.updateRecentTools();
  }

  List<Map<String, dynamic>> get _recentTools {
    return _recentlyUsedTools.take(5).toList();
  }

  List<Map<String, dynamic>> get _historyTools {
    return _recentlyUsedTools;
  }

  List<Map<String, dynamic>> get _filteredTools {
    if (_searchQuery.isEmpty) {
      return _allTools;
    }
    return _allTools.where((tool) {
      return tool['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             tool['description'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _navigateToTool(Map<String, dynamic> tool, {Map<String, dynamic>? sessionData}) {
    _addToRecentlyUsed(tool['id'], sessionData: sessionData);
    
    // If this is from history and has session data, pass it to the screen
    Widget screen = tool['screen'];
    if (sessionData != null) {
      // You'll need to modify each screen to accept session data
      // For now, just navigate normally
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _clearHistory() async {
    await _dbHelper.clearHistory();
    await _loadRecentlyUsedTools();
  }

  Future<void> _navigateToHistoryItem(Map<String, dynamic> historyItem) async {
    // Find the corresponding tool from _allTools
    final tool = _allTools.firstWhere(
      (tool) => tool['id'] == historyItem['id'],
      orElse: () => {},
    );
    
    if (tool.isNotEmpty) {
      _navigateToTool(tool, sessionData: historyItem['sessionData']);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Dev Tools',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            'v${snapshot.data!.version}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tools...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: _filteredTools.isEmpty
                  ? const Center(
                      child: Text(
                        'No tools found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = _filteredTools[index];
                        return ListTile(
                          leading: Icon(tool['icon']),
                          title: Text(tool['title']),
                          subtitle: Text(tool['description']),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToTool(tool);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.developer_mode,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Developer Tools!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _recentTools.isEmpty
                  ? 'Use the menu to access various formatting and conversion tools'
                  : 'Recently used tools:',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_recentTools.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _recentTools
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final tool = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const Divider(),
                          _buildToolCard(
                            context,
                            IconData(tool['iconCodePoint']),
                            tool['title'],
                            tool['description'],
                            () => _navigateToTool(tool),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            if (_recentTools.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'No recent tools',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open the menu to browse all available tools',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usage History',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (_historyTools.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear History'),
                        content: const Text('Are you sure you want to clear all usage history?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _clearHistory();
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _historyTools.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No usage history',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tools you use will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _historyTools.length,
                    itemBuilder: (context, index) {
                      final historyItem = _historyTools[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: Icon(
                            IconData(historyItem['iconCodePoint']),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(historyItem['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(historyItem['description']),
                              if (historyItem['sessionData'] != null)
                                Text(
                                  'Has saved session data',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              Text(
                                _formatTimestamp(historyItem['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete History Item'),
                                      content: const Text('Are you sure you want to delete this history item?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await _dbHelper.deleteHistoryItem(historyItem['historyId']);
                                            await _loadRecentlyUsedTools();
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                          onTap: () => _navigateToHistoryItem(historyItem),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
