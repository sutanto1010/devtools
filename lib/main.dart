import 'package:flutter/material.dart';
import 'screens/json_formatter_screen.dart';
import 'screens/yaml_formatter_screen.dart';
import 'screens/csv_to_json_screen.dart';
import 'screens/json_explorer_screen.dart';
import 'screens/base64_screen.dart';
import 'screens/gpg_screen.dart';

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
