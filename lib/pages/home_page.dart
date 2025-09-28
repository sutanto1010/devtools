import 'dart:io';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../database_helper.dart';
import '../system_tray_manager.dart';
import '../models/tab_data.dart';
import '../config/tools_config.dart';
import '../widgets/keep_alive_wrapper.dart';
import '../widgets/welcome_screen.dart';
import '../widgets/app_drawer.dart';
import '../utils/text_type_detector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, ClipboardListener {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SystemTrayManager _systemTrayManager = SystemTrayManager();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _searchQuery = '';
  List<Map<String, dynamic>> _recentlyUsedTools = [];
  List<TabData> _openTabs = [];

   @override
  void onClipboardChanged() async {
    ClipboardData? newClipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    String clipboardText = newClipboardData?.text ?? "";
    
    if (clipboardText.isNotEmpty) {
      String detectedType = TextTypeDetector.detectTextType(clipboardText);
      String typeDescription = TextTypeDetector.getTypeDescription(detectedType);
      
      print("Clipboard content detected as: $typeDescription ($detectedType)");
      
      // Optional: Show a notification or suggest relevant tools
      if (detectedType != 'unknown') {
        _suggestRelevantTool(detectedType, clipboardText);
      }
    }
  }

  void _suggestRelevantTool(String detectedType, String content) {
    String? suggestedTool = TextTypeDetector.getRelevantToolId(detectedType);
    
    if (suggestedTool != null) {
      String typeDescription = TextTypeDetector.getTypeDescription(detectedType);
      print("Suggested tool: $suggestedTool for $typeDescription");
      // Here you could show a notification or automatically open the relevant tool
      // _showToolSuggestion(suggestedTool, detectedType);
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
    clipboardWatcher.addListener(this);
    // start watch
    clipboardWatcher.start();
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
    final temp = toolId.split(';');
    final tool = ToolsConfig.allTools.firstWhere(
      (tool) => tool['id'] == temp[0],
      orElse: () => {},
    );
    final toolParam = temp.length > 1 ? temp[1] : null;
    if (tool.isNotEmpty) {
      _openToolInTab(tool, toolParam);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    clipboardWatcher.removeListener(this);
    // stop watch
    clipboardWatcher.stop();
    super.dispose();
  }

  Future<void> _loadRecentlyUsedTools() async {
    final recentTools = await _dbHelper.getRecentTools(limit: 10);
    setState(() {
      _recentlyUsedTools = recentTools;
    });
  }

  Future<void> _addToRecentlyUsed(String toolId, {Map<String, dynamic>? sessionData}) async {
    final tool = ToolsConfig.allTools.firstWhere((tool) => tool['id'] == toolId);
    
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
      return ToolsConfig.allTools;
    }
    return ToolsConfig.allTools.where((tool) {
      return tool['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             tool['description'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openToolInTab(Map<String, dynamic> tool, String? toolParam) {
    // Create new tab
    final newTab = TabData(
      id: tool['id'],
      title: tool['title'],
      icon: tool['icon'],
      screen: ToolsConfig.createScreen(tool['id'], toolParam),
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
    
    _addToRecentlyUsed(tool['id']);
  }

  Future<void> _closeTab(int index) async {
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
      if (currentIndex > _openTabs.length) {
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
    // Find the corresponding tool from ToolsConfig.allTools
    final tool = ToolsConfig.allTools.firstWhere(
      (tool) => tool['id'] == historyItem['id'],
      orElse: () => {},
    );
    
    if (tool.isNotEmpty) {
      _openToolInTab(tool, historyItem['toolParam']);
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
                        ...[
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
      drawer: AppDrawer(
        searchController: _searchController,
        searchQuery: _searchQuery,
        filteredTools: _filteredTools,
        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onClearSearch: () {
          setState(() {
            _searchController.clear();
            _searchQuery = '';
          });
        },
        onToolSelected: _openToolInTab,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ..._openTabs.map((tab) => 
            // Wrap each screen in AutomaticKeepAliveClientMixin to preserve state
            KeepAliveWrapper(child: tab.screen)
          ).toList(),
          // Welcome screen for the plus button tab or when no tabs are open
          WelcomeScreen(
            toolsCount: ToolsConfig.allTools.length,
            recentTools: _recentTools,
            onBrowseTools: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            onNavigateToHistoryItem: _navigateToHistoryItem,
          ),
        ],
      ),
    );
  }
}