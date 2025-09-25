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
import 'screens/hex_to_ascii_screen.dart';
import 'screens/gpg_screen.dart';
import 'screens/symmetric_encryption_screen.dart';
import 'screens/dns_scanner_screen.dart';
import 'screens/host_scanner_screen.dart';
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
import 'screens/yaml_to_json_screen.dart';
import 'screens/string_replace_screen.dart';
import 'screens/image_base64_screen.dart';
import 'screens/html_viewer_screen.dart';
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
    title: 'Dev Tools',
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
      home: const MyHomePage(),
    );
  }
}

class TabData {
  final String id;
  final String title;
  final IconData icon;
  final Widget screen;
  final Map<String, dynamic>? sessionData;

  TabData({
    required this.id,
    required this.title,
    required this.icon,
    required this.screen,
    this.sessionData,
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SystemTrayManager _systemTrayManager = SystemTrayManager();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _searchQuery = '';
  List<Map<String, dynamic>> _recentlyUsedTools = [];
  List<TabData> _openTabs = [];
  
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
      'id': 'html_viewer',
      'icon': Icons.web,
      'title': 'HTML Viewer',
      'description': 'View and render HTML content with JavaScript and CSS support',
      'screen': const HtmlViewerScreen(),
    },
  ];
  Widget createScreen(String toolId) {
    final tool = _allTools.firstWhere((tool) => tool['id'] == toolId);
    // Remove const to create new instances that can maintain state
    switch (toolId) {
      case 'json_formatter':
        return JsonFormatterScreen();
      case 'xml_formatter':
        return XmlFormatterScreen();
      case 'yaml_formatter':
        return YamlFormatterScreen();
      case 'csv_to_json':
        return CsvToJsonScreen();
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
      case 'screenshot_tool':
        return ScreenshotScreen();
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
      default:
        return tool['screen'];
    }
  }
  @override
  void initState() {
    super.initState();
    // Add 1 to length for the plus button tab
    _tabController = TabController(length: _openTabs.length + 1, vsync: this);
    _tabController.addListener(_handleTabChange);
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

  void _handleTabChange() {
    // If the plus button tab is selected, open drawer and switch back to previous tab
    // if (_tabController.index == _openTabs.length) {
    //   // Switch back to the last actual tab
    //   if (_openTabs.isNotEmpty) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       _tabController.animateTo(_openTabs.length - 1);
    //     });
    //   }
    // }
  }

  void _handleSystemTrayToolSelection(String toolId) {
    final tool = _allTools.firstWhere(
      (tool) => tool['id'] == toolId,
      orElse: () => {},
    );
    
    if (tool.isNotEmpty) {
      _openToolInTab(tool);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
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

  void _openToolInTab(Map<String, dynamic> tool, {Map<String, dynamic>? sessionData}) {
    // Create new tab
    final newTab = TabData(
      id: tool['id'],
      title: tool['title'],
      icon: tool['icon'],
      screen: createScreen(tool['id']),
      sessionData: sessionData,
    );
    
    setState(() {
      _openTabs.add(newTab);
    });
    
    // Update tab controller - add 1 for plus button
    _tabController.dispose();
    _tabController = TabController(length: _openTabs.length + 1, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Switch to the new tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController.animateTo(_openTabs.length - 1);
    });
    
    _addToRecentlyUsed(tool['id'], sessionData: sessionData);
  }

  Future<void> _closeTab(int index) async {
    if (_openTabs.length <= 1) return; // Don't close the last tab
    
    // Show confirmation dialog
    final bool? shouldClose = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Close Tab'),
          content: Text('Are you sure you want to close "${_openTabs[index].title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    
    // Only close if user confirmed
    if (shouldClose == true) {
      setState(() {
        _openTabs.removeAt(index);
      });
      
      // Update tab controller - add 1 for plus button
      final currentIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: _openTabs.length + 1, vsync: this);
      _tabController.addListener(_handleTabChange);
      
      // Adjust current tab index if necessary
      if (currentIndex >= _openTabs.length) {
        _tabController.index = _openTabs.length - 1;
      } else if (currentIndex > index) {
        _tabController.index = currentIndex - 1;
      } else {
        _tabController.index = currentIndex;
      }
    }
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
      _openToolInTab(tool, sessionData: historyItem['sessionData']);
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
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(
            height: 48.0,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              onTap: (index) {
                // If the plus button tab is tapped, open drawer
                if (index == _openTabs.length) {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
              tabs: [
                ..._openTabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 16),
                        const SizedBox(width: 8),
                        Text(tab.title),
                        if (_openTabs.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async => await _closeTab(index),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                // Plus button tab
                const Tab(
                  child: Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
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
                            _openToolInTab(tool);
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
          ..._openTabs.map((tab) => 
            // Wrap each screen in AutomaticKeepAliveClientMixin to preserve state
            KeepAliveWrapper(child: tab.screen)
          ).toList(),
          // Empty container for the plus button tab
          const SizedBox.shrink(),
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

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  
  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);
  
  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
