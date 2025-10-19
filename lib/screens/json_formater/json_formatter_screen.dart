import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devtools/blocs/json_formatter/json_formatter_bloc.dart';
import 'package:devtools/blocs/json_formatter/json_formatter_event.dart';
import 'package:devtools/blocs/json_formatter/json_formatter_state.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';



class JsonFormatterScreen extends StatelessWidget {
  const JsonFormatterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JsonFormatterBloc(),
      child: const JsonFormatterView(),
    );
  }
}

class JsonFormatterView extends StatefulWidget {
  const JsonFormatterView({super.key});
  
  @override
  State<JsonFormatterView> createState() => _JsonFormatterViewState();
}

class _JsonFormatterViewState extends State<JsonFormatterView> {
  bool _wrap = false;

  final CodeLineEditingController _inputCodeController = CodeLineEditingController();
  final CodeLineEditingController _outputCodeController = CodeLineEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _formatJson() {
    final input = _inputCodeController.text;
    context.read<JsonFormatterBloc>().add(FormatJsonEvent(input));
  }

  void _minifyJson() {
    final input = _inputCodeController.text;
    _outputCodeController.text = '';
    context.read<JsonFormatterBloc>().add(MinifyJsonEvent(input));
  }

  void _pasteFromClipboard() {
    context.read<JsonFormatterBloc>().add(const PasteFromClipboardEvent());
  }

  void _clearAll() {
    context.read<JsonFormatterBloc>().add(const ClearAllEvent());
  }

  void _copyToClipboard() {
    final output = _outputCodeController.text;
    context.read<JsonFormatterBloc>().add(CopyToClipboardEvent(output));
  }

  void _loadSampleJson() {
    context.read<JsonFormatterBloc>().add(const LoadSampleJsonEvent());
  }

  void _toggleFullscreen(bool isInput) {
    context.read<JsonFormatterBloc>().add(ToggleFullscreenEvent(isInput));
  }

  Widget _buildCodeEditor({
    required String hintText,
    bool readOnly = false,
    bool isInput = true,
    required JsonFormatterState state,
  }) {
      var textField = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  child: CodeEditor(
                          indicatorBuilder: (context, editingController, chunkController, notifier) {
                            return Row(
                              children: [
                                DefaultCodeLineNumber(
                                  controller: editingController,
                                  notifier: notifier,
                                ),
                                DefaultCodeChunkIndicator(
                                  width: 20,
                                  controller: chunkController,
                                  notifier: notifier
                                )
                              ],
                            );
                          },
                          wordWrap: _wrap,
                          findController: CodeFindController(_outputCodeController),
                          controller: isInput ? _inputCodeController : _outputCodeController,
                          style: CodeEditorStyle(
                            fontSize: 18,
                            codeTheme: CodeHighlightTheme(
                              languages: {
                                'json': CodeHighlightThemeMode(
                                  mode: langJson,
                                )
                              },
                              theme: atomOneLightTheme
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      );

    // Wrap in Stack to add overlay buttons
    return Stack(
      children: [
        textField,
        // Overlay buttons in top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _toggleFullscreen(isInput),
                icon: (state is JsonFormatterLoaded && (state.isFullscreenInput || state.isFullscreenOutput)) ? const Icon(Icons.fullscreen_exit, size: 16) : const Icon(Icons.fullscreen, size: 16),
                iconSize: 16,
                padding: const EdgeInsets.all(4),
                tooltip: (state is JsonFormatterLoaded && (state.isFullscreenInput || state.isFullscreenOutput)) ?  'Exit full window' : 'Full window',
              ),
              if (isInput) ...[
                // Paste button for input field
                IconButton(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste, size: 16),
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Paste from clipboard',
                ),
              ] else ...[
                // Copy button for output field
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 16),
                  iconSize: 16,
                  tooltip: 'Copy to clipboard',
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildView(JsonFormatterState state) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top - Input
            if(!(state is JsonFormatterLoaded && state.isFullscreenOutput))
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Input JSON:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildCodeEditor(
                      hintText: 'Paste your JSON here...',
                      isInput: true,
                      state: state,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Center - Buttons and Error
            if(!(state is JsonFormatterLoaded && (state.isFullscreenInput || state.isFullscreenOutput)))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _formatJson,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Format'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _minifyJson,
                  icon: const Icon(Icons.compress),
                  label: const Text('Minify'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadSampleJson,
                  icon: const Icon(Icons.science),
                  label: const Text('Sample'),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _wrap = !_wrap;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _wrap,
                        onChanged: (value) {
                          setState(() {
                            _wrap = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      const Text('Wrap'),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ],
            ),
            if (state is JsonFormatterError) ...[
               const SizedBox(height: 16),
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Colors.red.shade100,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   state.errorMessage,
                   style: const TextStyle(color: Colors.red),
                   textAlign: TextAlign.center,
                 ),
               ),
             ],
            // Bottom - Output
            if(!(state is JsonFormatterLoaded && state.isFullscreenInput))
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Formatted Output:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildCodeEditor(
                      hintText: 'Formatted JSON will appear here...',
                      readOnly: true,
                      isInput: false,
                      state: state,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JsonFormatterBloc, JsonFormatterState>(
      listener: (context, state) {
        if (state is JsonFormatterLoaded) {
          // Update controllers based on state
          if (state.inputText != _inputCodeController.text) {
            _inputCodeController.text = state.inputText;
          }
          if (state.outputText != _outputCodeController.text) {
            _outputCodeController.text = state.outputText;
          }
        } else if (state is JsonFormatterClipboardSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: BlocBuilder<JsonFormatterBloc, JsonFormatterState>(
        builder: (context, state) {          
          return _buildView(state);
        },
      ),
    );
  }

  @override
  void dispose() {
    _inputCodeController.dispose();
    _outputCodeController.dispose();
    super.dispose();
  }
}