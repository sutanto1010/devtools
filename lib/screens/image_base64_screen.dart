import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ImageBase64Screen extends StatefulWidget {
  const ImageBase64Screen({super.key});

  @override
  State<ImageBase64Screen> createState() => _ImageBase64ScreenState();
}

class _ImageBase64ScreenState extends State<ImageBase64Screen> {
  final TextEditingController _base64Controller = TextEditingController();
  String _errorMessage = '';
  String _successMessage = '';
  File? _selectedImage;
  Uint8List? _imageBytes;
  String _imageInfo = '';
  bool _isImageToBase64 = true;

  @override
  void dispose() {
    _base64Controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        
        setState(() {
          _selectedImage = file;
          _imageBytes = bytes;
          _errorMessage = '';
          _successMessage = '';
          
          // Get image info
          final fileName = path.basename(file.path);
          final fileSize = (bytes.length / 1024).toStringAsFixed(2);
          final extension = path.extension(file.path).toLowerCase();
          
          _imageInfo = 'File: $fileName\nSize: ${fileSize} KB\nType: $extension';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: ${e.toString()}';
        _successMessage = '';
      });
    }
  }

  void _convertImageToBase64() {
    if (_imageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
        _successMessage = '';
      });
      return;
    }

    try {
      final base64String = base64Encode(_imageBytes!);
      final extension = path.extension(_selectedImage!.path).toLowerCase();
      
      // Create data URL format
      String mimeType;
      switch (extension) {
        case '.png':
          mimeType = 'image/png';
          break;
        case '.jpg':
        case '.jpeg':
          mimeType = 'image/jpeg';
          break;
        case '.gif':
          mimeType = 'image/gif';
          break;
        case '.webp':
          mimeType = 'image/webp';
          break;
        case '.bmp':
          mimeType = 'image/bmp';
          break;
        default:
          mimeType = 'image/png';
      }
      
      final dataUrl = 'data:$mimeType;base64,$base64String';
      
      setState(() {
        _base64Controller.text = dataUrl;
        _errorMessage = '';
        _successMessage = 'Image converted to Base64 successfully!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error converting image: ${e.toString()}';
        _successMessage = '';
      });
    }
  }

  void _convertBase64ToImage() {
    final input = _base64Controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter Base64 data';
        _successMessage = '';
      });
      return;
    }

    try {
      String base64Data = input;
      
      // Handle data URL format
      if (input.startsWith('data:')) {
        final commaIndex = input.indexOf(',');
        if (commaIndex != -1) {
          base64Data = input.substring(commaIndex + 1);
        }
      }
      
      final bytes = base64Decode(base64Data);
      
      setState(() {
        _imageBytes = bytes;
        _selectedImage = null;
        _errorMessage = '';
        _successMessage = 'Base64 converted to image successfully!';
        
        final fileSize = (bytes.length / 1024).toStringAsFixed(2);
        _imageInfo = 'Decoded Image\nSize: ${fileSize} KB';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error decoding Base64: ${e.toString()}';
        _successMessage = '';
        _imageBytes = null;
        _imageInfo = '';
      });
    }
  }

  Future<void> _saveImage() async {
    if (_imageBytes == null) {
      setState(() {
        _errorMessage = 'No image to save';
        _successMessage = '';
      });
      return;
    }

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Image',
        fileName: 'converted_image.png',
        type: FileType.image,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(_imageBytes!);
        
        setState(() {
          _successMessage = 'Image saved successfully to: $outputFile';
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving image: ${e.toString()}';
        _successMessage = '';
      });
    }
  }

  void _copyToClipboard() {
    if (_base64Controller.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _base64Controller.text));
      setState(() {
        _successMessage = 'Base64 data copied to clipboard!';
        _errorMessage = '';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        setState(() {
          _base64Controller.text = clipboardData.text!;
          _errorMessage = '';
          _successMessage = 'Data pasted from clipboard!';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error pasting from clipboard: ${e.toString()}';
        _successMessage = '';
      });
    }
  }

  void _clearAll() {
    setState(() {
      _base64Controller.clear();
      _selectedImage = null;
      _imageBytes = null;
      _imageInfo = '';
      _errorMessage = '';
      _successMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Toggle
            Column(
              children: [
                ToggleButtons(
                  isSelected: [_isImageToBase64, !_isImageToBase64],
                  onPressed: (index) {
                    setState(() {
                      _isImageToBase64 = index == 0;
                      _clearAll();
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Image → Base64'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Base64 → Image'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Image to Base64 Mode
            if (_isImageToBase64) ...
              _buildImageToBase64Section(),
            
            // Base64 to Image Mode
            if (!_isImageToBase64) ...
              _buildBase64ToImageSection(),
            
            // Messages
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_successMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: TextStyle(color: Colors.green.shade700),
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

  List<Widget> _buildImageToBase64Section() {
    return [
      // Image Selection
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Choose Image File'),
              ),
              if (_imageInfo.isNotEmpty) ...
                [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _imageInfo,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      
      // Image Preview
      if (_imageBytes != null)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Image Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      
      if (_imageBytes != null) const SizedBox(height: 16),
      
      // Convert Button
      ElevatedButton.icon(
        onPressed: _selectedImage != null ? _convertImageToBase64 : null,
        icon: const Icon(Icons.transform),
        label: const Text('Convert to Base64'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
      const SizedBox(height: 16),
      
      // Base64 Output
      Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Base64 Output',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      TextField(
                        controller: _base64Controller,
                        maxLines: null,
                        expands: true,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Base64 output will appear here...',
                        ),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      if (_base64Controller.text.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _copyToClipboard,
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: 'Copy to Clipboard',
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildBase64ToImageSection() {
    return [
      // Base64 Input
      Expanded(
        flex: 2,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Base64 Input',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      TextField(
                        controller: _base64Controller,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Paste Base64 data here (with or without data URL prefix)...',
                        ),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _pasteFromClipboard,
                                icon: const Icon(Icons.paste, size: 16),
                                tooltip: 'Paste from Clipboard',
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: const EdgeInsets.all(4),
                              ),
                              if (_base64Controller.text.isNotEmpty)
                                IconButton(
                                  onPressed: _copyToClipboard,
                                  icon: const Icon(Icons.copy, size: 16),
                                  tooltip: 'Copy to Clipboard',
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: const EdgeInsets.all(4),
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
          ),
        ),
      ),
      const SizedBox(height: 16),
      
      // Convert Button
      ElevatedButton.icon(
        onPressed: _convertBase64ToImage,
        icon: const Icon(Icons.transform),
        label: const Text('Convert to Image'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
      const SizedBox(height: 16),
      
      // Image Preview and Info
      if (_imageBytes != null)
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Converted Image',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveImage,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_imageInfo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _imageInfo,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}