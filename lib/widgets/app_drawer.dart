import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppDrawer extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<Map<String, dynamic>> filteredTools;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(Map<String, dynamic>, String?) onToolSelected;

  const AppDrawer({
    Key? key,
    required this.searchController,
    required this.searchQuery,
    required this.filteredTools,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToolSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search tools...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
            child: filteredTools.isEmpty
                ? const Center(
                    child: Text(
                      'No tools found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTools.length,
                    itemBuilder: (context, index) {
                      final tool = filteredTools[index];
                      return ListTile(
                        leading: Icon(tool['icon']),
                        title: Text(tool['title']),
                        subtitle: Text(tool['description']),
                        onTap: () {
                          Navigator.pop(context);
                          onToolSelected(tool,"");
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}