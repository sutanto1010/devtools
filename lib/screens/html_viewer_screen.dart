import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/htmlbars.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:flutter_highlight/themes/github.dart';

class HtmlViewerScreen extends StatefulWidget {
  const HtmlViewerScreen({super.key});

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
  final CodeController _htmlController = CodeController(
    language: htmlbars,
  );
  late final WebViewController _webViewController;
  bool _isWebViewVisible = false;
  String _errorMessage = '';
  bool _javascriptEnabled = true;
  
  final String _defaultHtml = '''<!DOCTYPE html>
<html>
<head>
    <title>HTML Viewer</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background: linear-gradient(45deg, #f0f0f0, #e0e0e0);
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .demo-button {
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin: 10px;
        }
        .demo-button:hover {
            background: #0056b3;
        }
        #output {
            margin-top: 20px;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
            min-height: 50px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>HTML Viewer with JavaScript & CSS</h1>
        <p>This is a sample HTML page with CSS styling and JavaScript functionality.</p>
        
        <button class="demo-button" onclick="showMessage()">Click Me!</button>
        <button class="demo-button" onclick="changeColor()">Change Color</button>
        <button class="demo-button" onclick="addContent()">Add Content</button>
        
        <div id="output">
            <p>Click the buttons above to see JavaScript in action!</p>
        </div>
    </div>
    
    <script>
        function showMessage() {
            document.getElementById('output').innerHTML = 
                '<p style="color: green; font-weight: bold;">Hello from JavaScript! Time: ' + new Date().toLocaleTimeString() + '</p>';
        }
        
        function changeColor() {
            const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57'];
            const randomColor = colors[Math.floor(Math.random() * colors.length)];
            document.body.style.background = `linear-gradient(45deg, `+randomColor+`, #f0f0f0)`;
            document.getElementById('output').innerHTML = 
                `<p>Background color changed to: `+randomColor+`</p>`;
        }
        
        function addContent() {
            const content = document.getElementById('output');
            const newElement = document.createElement('div');
            newElement.innerHTML = `<p style="margin: 5px 0; padding: 5px; background: #e9ecef; border-radius: 3px;">Dynamic content added at `+new Date().toLocaleTimeString()+`</p>`;
            content.appendChild(newElement);
        }
        
        // Auto-update time every second
        setInterval(() => {
            const timeElement = document.getElementById('current-time');
            if (timeElement) {
                timeElement.textContent = new Date().toLocaleTimeString();
            }
        }, 1000);
    </script>
</body>
</html>''';

  @override
  void initState() {
    super.initState();
    _htmlController.text = _defaultHtml;
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(_javascriptEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _errorMessage = '';
            });
          },
          onPageFinished: (String url) {
            // Page loaded successfully
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Error loading page: ${error.description}';
            });
          },
        ),
      );
  }

  void _renderHtml() {
    setState(() {
      _errorMessage = '';
    });

    try {
      final htmlContent = _htmlController.fullText.trim();
      if (htmlContent.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter HTML content to render';
        });
        return;
      }

      _webViewController.loadHtmlString(htmlContent);
      setState(() {
        _isWebViewVisible = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error rendering HTML: ${e.toString()}';
      });
    }
  }

  void _pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        setState(() {
          _htmlController.text = data.text!;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error pasting from clipboard: ${e.toString()}';
      });
    }
  }

  void _clearAll() {
    setState(() {
      _htmlController.clear();
      _isWebViewVisible = false;
      _errorMessage = '';
    });
  }

  void _loadSample() {
    setState(() {
      _htmlController.text = _defaultHtml;
      _errorMessage = '';
    });
  }

  void _toggleJavaScript() {
    setState(() {
      _javascriptEnabled = !_javascriptEnabled;
    });
    _webViewController.setJavaScriptMode(
      _javascriptEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled
    );
    
    // Re-render if content is already loaded
    if (_isWebViewVisible) {
      _renderHtml();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Controls Panel
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Switch(
                            value: _javascriptEnabled,
                            onChanged: (value) => _toggleJavaScript(),
                          ),
                          const SizedBox(width: 8),
                          const Text('Enable JavaScript'),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _loadSample,
                      icon: const Icon(Icons.code),
                      label: const Text('Load Sample'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _renderHtml,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Render HTML'),
                    ),
                  ],
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: Row(
              children: [
                // HTML Editor
                Expanded(
                  flex: _isWebViewVisible ? 1 : 2,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'HTML Code:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (_isWebViewVisible)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isWebViewVisible = false;
                                  });
                                },
                                icon: const Icon(Icons.fullscreen),
                                label: const Text('Expand Editor'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: CodeTheme(
                              data: CodeThemeData(styles: githubTheme),
                              child: CodeField(controller: _htmlController),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // WebView Preview
                if (_isWebViewVisible)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Preview:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isWebViewVisible = false;
                                  });
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Hide Preview'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: WebViewWidget(
                                  controller: _webViewController,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }
}