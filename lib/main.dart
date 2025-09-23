import 'package:flutter/material.dart';
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

void main() {
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

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allTools = [
    {
      'icon': Icons.code,
      'title': 'JSON Formatter',
      'description': 'Format and validate JSON data',
      'screen': const JsonFormatterScreen(),
    },
    {
      'icon': Icons.description,
      'title': 'YAML Formatter',
      'description': 'Format and validate YAML files',
      'screen': const YamlFormatterScreen(),
    },
    {
      'icon': Icons.transform,
      'title': 'CSV to JSON',
      'description': 'Convert CSV data to JSON format',
      'screen': const CsvToJsonScreen(),
    },
    {
      'icon': Icons.explore,
      'title': 'JSON Explorer',
      'description': 'Interactive JSON tree explorer with search and analysis',
      'screen': const JsonExplorerScreen(),
    },
    {
      'icon': Icons.security,
      'title': 'Base64 Encoder/Decoder',
      'description': 'Encode and decode Base64 strings',
      'screen': const Base64Screen(),
    },
    {
      'icon': Icons.enhanced_encryption,
      'title': 'GPG Encrypt/Decrypt',
      'description': 'Encrypt and decrypt text using GPG-style encryption',
      'screen': const GpgScreen(),
    },
    {
      'icon': Icons.lock,
      'title': 'Symmetric Encryption',
      'description': 'Encrypt and decrypt text using AES symmetric encryption',
      'screen': const SymmetricEncryptionScreen(),
    },
    {
      'icon': Icons.token,
      'title': 'JWT Decoder',
      'description': 'Decode and analyze JSON Web Tokens (JWT)',
      'screen': const JwtDecoderScreen(),
    },
    {
      'icon': Icons.dns,
      'title': 'DNS Scanner',
      'description': 'Scan and lookup DNS records for domains',
      'screen': const DnsScannerScreen(),
    },
    {
      'icon': Icons.straighten,
      'title': 'Unit Converter',
      'description': 'Convert between different units of measurement',
      'screen': const UnitConverterScreen(),
    },
    {
      'icon': Icons.fingerprint,
      'title': 'UUID Generator/Validator',
      'description': 'Generate and validate UUIDs (v1 and v4)',
      'screen': const UuidScreen(),
    },
    {
      'icon': Icons.link,
      'title': 'URL Parser',
      'description': 'Parse URLs into a tree view structure with detailed analysis',
      'screen': const UrlParserScreen(),
    },
    {
      'icon': Icons.schedule,
      'title': 'CRON Expression Parser',
      'description': 'Parse CRON expressions into English and calculate next occurrences',
      'screen': const CronExpressionScreen(),
    },
    {
      'icon': Icons.colorize,
      'title': 'Color Picker',
      'description': 'Pick colors from screen and convert between color formats',
      'screen': const ColorPickerScreen(),
    },
    {
      'icon': Icons.compare_arrows,
      'title': 'Diff Checker',
      'description': 'Compare two texts and highlight differences line by line',
      'screen': const DiffCheckerScreen(),
    },
  ];

  List<Map<String, dynamic>> get _filteredTools {
    if (_searchQuery.isEmpty) {
      return _allTools;
    }
    return _allTools.where((tool) {
      return tool['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             tool['description'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _navigateToTool(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: Column(
          children: [
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
                            _navigateToTool(tool['screen']);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      body: Center(
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
                'Use the menu to access various formatting and conversion tools:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildToolCard(
                        context,
                        Icons.code,
                        'JSON Formatter',
                        'Format and validate JSON data',
                        () => _navigateToTool(const JsonFormatterScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.description,
                        'YAML Formatter',
                        'Format and validate YAML files',
                        () => _navigateToTool(const YamlFormatterScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.transform,
                        'CSV to JSON Converter',
                        'Convert CSV data to JSON format',
                        () => _navigateToTool(const CsvToJsonScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.explore,
                        'JSON Explorer',
                        'Interactive JSON tree explorer with search and analysis',
                        () => _navigateToTool(const JsonExplorerScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.security,
                        'Base64 Encoder/Decoder',
                        'Encode and decode Base64 strings',
                        () => _navigateToTool(const Base64Screen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.enhanced_encryption,
                        'GPG Encrypt/Decrypt',
                        'Encrypt and decrypt text using GPG-style encryption',
                        () => _navigateToTool(const GpgScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.lock,
                        'Symmetric Encryption',
                        'Encrypt and decrypt text using AES symmetric encryption',
                        () => _navigateToTool(const SymmetricEncryptionScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.token,
                        'JWT Decoder',
                        'Decode and analyze JSON Web Tokens (JWT)',
                        () => _navigateToTool(const JwtDecoderScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.dns,
                        'DNS Scanner',
                        'Scan and lookup DNS records for domains',
                        () => _navigateToTool(const DnsScannerScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.straighten,
                        'Unit Converter',
                        'Convert between different units of measurement',
                        () => _navigateToTool(const UnitConverterScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.fingerprint,
                        'UUID Generator/Validator',
                        'Generate and validate UUIDs (v1 and v4)',
                        () => _navigateToTool(const UuidScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.link,
                        'URL Parser',
                        'Parse URLs into a tree view structure with detailed analysis',
                        () => _navigateToTool(const UrlParserScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.schedule,
                        'CRON Expression Parser',
                        'Parse CRON expressions into English and calculate next occurrences',
                        () => _navigateToTool(const CronExpressionScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.colorize,
                        'Color Picker',
                        'Pick colors from screen and convert between color formats',
                        () => _navigateToTool(const ColorPickerScreen()),
                      ),
                      const Divider(),
                      _buildToolCard(
                        context,
                        Icons.compare_arrows,
                        'Diff Checker',
                        'Compare two texts and highlight differences line by line',
                        () => _navigateToTool(const DiffCheckerScreen()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
