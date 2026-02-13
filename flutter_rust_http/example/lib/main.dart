import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_ffi/image_ffi.dart';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ImageClient.initialize();
  runApp(const ImageBenchmarkApp());
}

// ---------------------------------------------------------------------
// 1. Operation definition - EXPANDED
// ---------------------------------------------------------------------
enum Operation {
  resize,
  resizeToFit,
  crop,
  rotate90,
  rotate180,
  flipHorizontal,
  flipVertical,
  grayscale,
  blur,
  sharpen,
  brightness,
  contrast,
  saturation;

  String get displayName {
    switch (this) {
      case Operation.resize:
        return 'Resize to 400x400';
      case Operation.resizeToFit:
        return 'Resize to fit 400x400';
      case Operation.crop:
        return 'Crop 100x100@50,50';
      case Operation.rotate90:
        return 'Rotate 90°';
      case Operation.rotate180:
        return 'Rotate 180°';
      case Operation.flipHorizontal:
        return 'Flip Horizontal';
      case Operation.flipVertical:
        return 'Flip Vertical';
      case Operation.grayscale:
        return 'Grayscale';
      case Operation.blur:
        return 'Blur (sigma=2.0)';
      case Operation.sharpen:
        return 'Sharpen (amount=1.5)';
      case Operation.brightness:
        return 'Brightness (+30)';
      case Operation.contrast:
        return 'Contrast (+20)';
      case Operation.saturation:
        return 'Saturation (+25)';
    }
  }

  String get category {
    switch (this) {
      case Operation.resize:
      case Operation.resizeToFit:
      case Operation.crop:
        return 'Transform';
      case Operation.rotate90:
      case Operation.rotate180:
      case Operation.flipHorizontal:
      case Operation.flipVertical:
        return 'Orientation';
      case Operation.grayscale:
      case Operation.blur:
      case Operation.sharpen:
        return 'Filters';
      case Operation.brightness:
      case Operation.contrast:
      case Operation.saturation:
        return 'Adjustments';
    }
  }
}

// ---------------------------------------------------------------------
// 2. Plugin adapter interface
// ---------------------------------------------------------------------
abstract class PluginAdapter {
  String get name;
  String get description;
  Future<void> initialize();
  Future<void> loadImage(Uint8List bytes);
  Future<void> applyOperation(Operation op);
  Future<Uint8List?> getRenderedImage();
  Future<void> reset();
  Future<void> dispose();
  bool supports(Operation op);
}

// ---------------------------------------------------------------------
// 3. Rust plugin adapter
// ---------------------------------------------------------------------
class RustImageClientAdapter implements PluginAdapter {
  ImageClient? _client;
  Uint8List? _originalBytes;
  Uint8List? _currentBytes;

  @override
  String get name => 'My Plugin';

  @override
  String get description => 'Your custom Rust-based plugin';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadImage(Uint8List bytes) async {
    try {
      _originalBytes = bytes;
      // Don't dispose here - just create fresh if needed
      _client ??= ImageClient();
      await _client!.loadFromBytes(bytes);
      _currentBytes = bytes;
      print('RustImageClientAdapter: Image loaded successfully, size: ${bytes.length} bytes');
    } catch (e) {
      print('RustImageClientAdapter: Error loading image: $e');
      rethrow;
    }
  }

  @override
  Future<void> applyOperation(Operation op) async {
    if (_client == null) {
      print('RustImageClientAdapter: Client is null, reinitializing');
      await loadImage(_originalBytes!);
    }


    (int, int) dimension = await _client!.getDimensions();
    print("DIMENSION = $dimension");


    try {
      print('RustImageClientAdapter: Applying operation: ${op.displayName}');

      switch (op) {
        case Operation.resize:
          await _client!.resize(width: 400, height: 400, filter: ResizeFilter.catmullRom);
          break;
        case Operation.resizeToFit:
          await _client!.resizeToFit(maxWidth: 400, maxHeight: 400, filter: ResizeFilter.catmullRom);
          break;
        case Operation.crop:
          await _client!.crop(x: 50, y: 50, width: 100, height: 100);
          break;
        case Operation.rotate90:
          await _client!.rotate(90);
          break;
        case Operation.rotate180:
          await _client!.rotate(180);
          break;
        case Operation.flipHorizontal:
          await _client!.flipHorizontal();
          break;
        case Operation.flipVertical:
          await _client!.flipVertical();
          break;
        case Operation.grayscale:
          await _client!.grayscale();
          break;
        case Operation.blur:
          await _client!.blur(2.0);
          break;
        case Operation.sharpen:
          await _client!.sharpen(1.5);
          break;
        case Operation.brightness:
          await _client!.adjustBrightness(30);
          break;
        case Operation.contrast:
          await _client!.adjustContrast(20);
          break;
        case Operation.saturation:
          await _client!.adjustSaturation(25);
          break;
      }

      // Get the bytes AFTER the operation
      final resultBytes = await _client!.getBytes(ImageFormat.bmp);
      if (resultBytes.isEmpty) {
        throw StateError('Operation returned empty result');
      }

      _currentBytes = resultBytes;
      print('RustImageClientAdapter: Operation completed, result size: ${resultBytes.length} bytes');

    } catch (e) {
      print('RustImageClientAdapter: Error applying operation ${op.displayName}: $e');
      // Try to recover by reloading
      try {
        print('RustImageClientAdapter: Attempting to recover by reloading image');
        await loadImage(_originalBytes!);
      } catch (recoveryError) {
        print('RustImageClientAdapter: Recovery failed: $recoveryError');
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List?> getRenderedImage() async {
    print('RustImageClientAdapter: Getting rendered image, size: ${_currentBytes?.length ?? 0} bytes');
    return _currentBytes;
  }

  @override
  Future<void> reset() async {
    try {
      print('RustImageClientAdapter: Resetting to original image');

      // CRITICAL FIX: Don't dispose and recreate, just reload the original bytes
      // into the existing client, or create a fresh client without disposing
      if (_client != null) {
        try {
          // Try to dispose the old client cleanly
          await _client!.dispose();
        } catch (e) {
          print('RustImageClientAdapter: Warning during dispose (ignoring): $e');
        }
      }

      // Always create a fresh client for reset
      _client = ImageClient();
      await _client!.loadFromBytes(_originalBytes!);
      _currentBytes = _originalBytes;
      print('RustImageClientAdapter: Reset complete');

    } catch (e) {
      print('RustImageClientAdapter: Error during reset: $e');
      // Even if reset fails, ensure we have a valid client
      try {
        _client = ImageClient();
        await _client!.loadFromBytes(_originalBytes!);
        _currentBytes = _originalBytes;
        print('RustImageClientAdapter: Recovered from reset error');
      } catch (recoveryError) {
        print('RustImageClientAdapter: Recovery failed: $recoveryError');
        rethrow;
      }
    }
  }

  @override
  Future<void> dispose() async {
    try {
      print('RustImageClientAdapter: Disposing client');
      if (_client != null) {
        await _client!.dispose();
        _client = null;
      }
    } catch (e) {
      print('RustImageClientAdapter: Error during dispose: $e');
      // Force null even if dispose fails
      _client = null;
    }
  }

  @override
  bool supports(Operation op) => true;
}

// ---------------------------------------------------------------------
// 4. flutter_image_compress adapter
// ---------------------------------------------------------------------
class FlutterImageCompressAdapter implements PluginAdapter {
  Uint8List? _originalBytes;
  Uint8List? _currentBytes;

  @override
  String get name => '    image compress';

  @override
  String get description => '~5.2M downloads - Compression focused';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadImage(Uint8List bytes) async {
    _originalBytes = bytes;
    _currentBytes = bytes;
  }

  @override
  Future<void> applyOperation(Operation op) async {
    if (_currentBytes == null) return;
    switch (op) {
      case Operation.resize:
      case Operation.resizeToFit:
        _currentBytes = await FlutterImageCompress.compressWithList(
          _currentBytes!,
          minWidth: 400,
          minHeight: 400,
          format: CompressFormat.webp,
        );
        break;
      default:
        break;
    }
  }

  @override
  Future<Uint8List?> getRenderedImage() async => _currentBytes;

  @override
  Future<void> reset() async {
    _currentBytes = _originalBytes;
  }

  @override
  Future<void> dispose() async {}

  @override
  bool supports(Operation op) {
    return op == Operation.resize || op == Operation.resizeToFit;
  }
}

// Isolate worker functions (must be top-level)
Future<img.Image?> _decodeImageIsolate(Uint8List bytes) async {
  return img.decodeImage(bytes);
}

class _OperationParams {
  final img.Image image;
  final Operation op;
  _OperationParams(this.image, this.op);
}

Future<img.Image> _applyOperationIsolate(_OperationParams params) async {
  final image = params.image;
  final op = params.op;

  switch (op) {
    case Operation.resize:
      return img.copyResize(image, width: 400, height: 400, interpolation: img.Interpolation.average);
    case Operation.resizeToFit:
      final scale = min(400 / image.width, 400 / image.height);
      final newWidth = (image.width * scale).round();
      final newHeight = (image.height * scale).round();
      return img.copyResize(image, width: newWidth, height: newHeight, interpolation: img.Interpolation.cubic);
    case Operation.crop:
      return img.copyCrop(image, x: 50, y: 50, width: 100, height: 100);
    case Operation.rotate90:
      return img.copyRotate(image, angle: 90);
    case Operation.rotate180:
      return img.copyRotate(image, angle: 180);
    case Operation.flipHorizontal:
      return img.flipHorizontal(image);
    case Operation.flipVertical:
      return img.flipVertical(image);
    case Operation.grayscale:
      return img.grayscale(image);
    case Operation.blur:
      return img.gaussianBlur(image, radius: 2);
    case Operation.sharpen:
      return img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
    case Operation.brightness:
      return image;
    case Operation.contrast:
      return img.contrast(image, contrast: 120);
    case Operation.saturation:
      return img.adjustColor(image, saturation: 1.25);
  }
}

// ---------------------------------------------------------------------
// 5. image package adapter (MOST POPULAR - Dart-based)
// ---------------------------------------------------------------------
class ImagePackageAdapter implements PluginAdapter {
  img.Image? _originalImage;
  img.Image? _currentImage;

  @override
  String get name => 'image (Dart)';

  @override
  String get description => '~15M downloads - Pure Dart, full-featured';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadImage(Uint8List bytes) async {
    _originalImage = await compute(_decodeImageIsolate, bytes);
    _currentImage = _originalImage?.clone();
  }

  @override
  Future<void> applyOperation(Operation op) async {
    if (_currentImage == null) return;

    _currentImage = await compute(_applyOperationIsolate, _OperationParams(_currentImage!, op));
  }

  @override
  Future<Uint8List?> getRenderedImage() async {
    if (_currentImage == null) return null;
    return Uint8List.fromList(img.encodePng(_currentImage!));
  }

  @override
  Future<void> reset() async {
    _currentImage = _originalImage?.clone();
  }

  @override
  Future<void> dispose() async {}

  @override
  bool supports(Operation op) => true;
}

// ---------------------------------------------------------------------
// 6. Root app with enhanced UI
// ---------------------------------------------------------------------
class ImageBenchmarkApp extends StatefulWidget {
  const ImageBenchmarkApp({super.key});

  @override
  State<ImageBenchmarkApp> createState() => _ImageBenchmarkAppState();
}

class _ImageBenchmarkAppState extends State<ImageBenchmarkApp> {
  Uint8List? _testImageBytes;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTestImage();
  }

  Future<void> _loadTestImage() async {
    final data = await rootBundle.load('assets/test_image.jpg');
    setState(() {
      _testImageBytes = data.buffer.asUint8List();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Processing Benchmark',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: _testImageBytes == null
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
          index: _selectedIndex,
          children: [
            SingleOperationScreen(imageBytes: _testImageBytes!),
            BenchmarkScreen(imageBytes: _testImageBytes!),
            ComparisonScreen(imageBytes: _testImageBytes!),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.edit),
              label: 'Single Op',
            ),
            NavigationDestination(
              icon: Icon(Icons.speed),
              label: 'Benchmark',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics),
              label: 'Comparison',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 7. Single Operation Screen – NOW FULLY SCROLLABLE
// ---------------------------------------------------------------------
class SingleOperationScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const SingleOperationScreen({super.key, required this.imageBytes});

  @override
  State<SingleOperationScreen> createState() => _SingleOperationScreenState();
}

class _SingleOperationScreenState extends State<SingleOperationScreen> {
  late final List<PluginAdapter> _plugins;
  PluginAdapter? _selectedPlugin;
  Operation _selectedOperation = Operation.resize;
  Uint8List? _resultBytes;
  Duration? _lastDuration;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _plugins = [
      RustImageClientAdapter(),
      ImagePackageAdapter(),
      FlutterImageCompressAdapter(),
    ];
    _initializePlugins();
  }

  Future<void> _initializePlugins() async {
    for (final plugin in _plugins) {
      await plugin.initialize();
      await plugin.loadImage(widget.imageBytes);
    }
    setState(() {
      _selectedPlugin = _plugins.first;
    });
  }

  Future<void> _applyOperation() async {
    final plugin = _selectedPlugin;
    if (plugin == null) return;

    if (!plugin.supports(_selectedOperation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plugin.name} doesn\'t support ${_selectedOperation.displayName}')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _resultBytes = null;
      _lastDuration = null;
    });

    try {
      await plugin.reset();
      final stopwatch = Stopwatch()..start();
      await plugin.applyOperation(_selectedOperation);
      stopwatch.stop();
      final result = await plugin.getRenderedImage();
      setState(() {
        _resultBytes = result;
        _lastDuration = stopwatch.elapsed;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Single Operation Test')),
      body: SafeArea(
        // FIX: Wrap entire content in a scroll view
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _imageCard('Original', widget.imageBytes)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageCard(
                      'Result',
                      _resultBytes,
                      placeholder: 'No result yet',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<PluginAdapter>(
                        value: _selectedPlugin,
                        decoration: const InputDecoration(
                          labelText: 'Plugin',
                          border: OutlineInputBorder(),
                        ),
                        items: _plugins.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(p.description, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPlugin = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Operation>(
                        value: _selectedOperation,
                        decoration: const InputDecoration(
                          labelText: 'Operation',
                          border: OutlineInputBorder(),
                        ),
                        items: Operation.values.map((op) {
                          final supported = _selectedPlugin?.supports(op) ?? false;
                          return DropdownMenuItem(
                            value: op,
                            child: Row(
                              children: [
                                Icon(
                                  supported ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: supported ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(op.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedOperation = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _applyOperation,
                              icon: _isProcessing
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.play_arrow),
                              label: const Text('Apply'),
                            ),
                          ),
                          if (_lastDuration != null) ...[
                            const SizedBox(width: 16),
                            Chip(
                              label: Text(
                                '${_lastDuration!.inMilliseconds} ms',
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.cyan.withOpacity(0.2),
                            ),
                          ],
                        ],
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

  Widget _imageCard(String label, dynamic imageData, {String placeholder = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageSurface(imageData, placeholder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSurface(dynamic data, String placeholder) {
    if (data == null) {
      return Center(
        child: Text(placeholder, style: const TextStyle(color: Colors.grey)),
      );
    }

    if (data is ui.Image) {
      // This is the fastest path.
      // RawImage bypasses the decoder entirely and sends the image handle to the GPU.
      return RawImage(
        image: data,
        fit: BoxFit.contain,
      );
    } else {
      return Image.memory(
        data as Uint8List,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  void dispose() {
    for (final plugin in _plugins) {
      plugin.dispose();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------
// 8. Benchmark Screen – runs all operations – NOW FULLY SCROLLABLE
// ---------------------------------------------------------------------
class BenchmarkScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const BenchmarkScreen({super.key, required this.imageBytes});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  late final List<PluginAdapter> _plugins;
  PluginAdapter? _selectedPlugin;
  int _iterations = 10;
  bool _isBenchmarking = false;
  Uint8List? _lastResultBytes;
  Map<Operation, BenchmarkResult> _results = {};
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _plugins = [
      RustImageClientAdapter(),
      ImagePackageAdapter(),
      FlutterImageCompressAdapter(),
    ];
    _initializePlugins();
  }

  Future<void> _initializePlugins() async {
    for (final plugin in _plugins) {
      await plugin.initialize();
      await plugin.loadImage(widget.imageBytes);
    }
    setState(() {
      _selectedPlugin = _plugins.first;
    });
  }

  Future<void> _runBenchmark() async {
    if (_selectedPlugin == null) return;
    setState(() {
      _isBenchmarking = true;
      _results = {};
      _lastResultBytes = null;
      _progress = 0.0;
    });

    final plugin = _selectedPlugin!;
    final ops = Operation.values;
    final totalSteps = ops.length;

    for (int opIndex = 0; opIndex < ops.length; opIndex++) {
      final op = ops[opIndex];

      if (!plugin.supports(op)) {
        setState(() {
          _results[op] = BenchmarkResult.notSupported();
          _progress = (opIndex + 1) / totalSteps;
        });
        continue;
      }

      final durations = <int>[];
      Uint8List? lastImage;

      for (int i = 0; i < _iterations; i++) {
        await plugin.reset();
        final sw = Stopwatch()..start();
        await plugin.applyOperation(op);
        sw.stop();
        durations.add(sw.elapsedMicroseconds);
        if (i == _iterations - 1) {
          lastImage = await plugin.getRenderedImage();
        }
      }

      final avg = durations.reduce((a, b) => a + b) / _iterations;
      final variance = durations.map((d) => pow(d - avg, 2)).reduce((a, b) => a + b) / _iterations;
      final std = sqrt(variance);
      final min = durations.reduce((a, b) => a < b ? a : b);
      final max = durations.reduce((a, b) => a > b ? a : b);

      setState(() {
        _results[op] = BenchmarkResult(
          avgMicros: avg,
          stdMicros: std,
          minMicros: min.toDouble(),
          maxMicros: max.toDouble(),
        );
        _lastResultBytes = lastImage;
        _progress = (opIndex + 1) / totalSteps;
      });
    }

    setState(() => _isBenchmarking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Benchmark'),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareResults,
              tooltip: 'Share Results',
            ),
        ],
      ),
      body: SafeArea(
        // FIX: Wrap entire content in a scroll view
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _imageCard('Original', widget.imageBytes)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageCard(
                      'Last Result',
                      _lastResultBytes,
                      placeholder: _isBenchmarking ? 'Processing...' : 'Run benchmark',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<PluginAdapter>(
                        value: _selectedPlugin,
                        decoration: const InputDecoration(
                          labelText: 'Plugin',
                          border: OutlineInputBorder(),
                        ),
                        items: _plugins.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(p.description, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isBenchmarking ? null : (v) => setState(() => _selectedPlugin = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _iterations.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Iterations',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_isBenchmarking,
                              onChanged: (v) => _iterations = int.tryParse(v) ?? 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isBenchmarking ? null : _runBenchmark,
                              icon: _isBenchmarking
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.speed),
                              label: const Text('Start'),
                            ),
                          ),
                        ],
                      ),
                      if (_isBenchmarking) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: _progress),
                        const SizedBox(height: 4),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}% complete',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // FIX: Replace Expanded with a ListView that uses shrinkWrap
              // and no independent scrolling (parent scroll view handles it)
              Card(
                child: _results.isEmpty
                    ? const Center(child: Text('Press Start to run benchmark'))
                    : _buildResultsTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageCard(String label, Uint8List? bytes, {String placeholder = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: bytes == null
                  ? Center(child: Text(placeholder, style: const TextStyle(color: Colors.grey)))
                  : Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTable() {
    final grouped = <String, List<Operation>>{};
    for (final op in Operation.values) {
      grouped.putIfAbsent(op.category, () => []).add(op);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      // FIX: Use shrinkWrap and no physics to let parent scroll
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final category in grouped.keys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
          ),
          ...grouped[category]!.map((op) => _buildResultRow(op)),
        ],
      ],
    );
  }

  Widget _buildResultRow(Operation op) {
    final res = _results[op];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(op.displayName),
          ),
          Expanded(
            flex: 3,
            child: res == null
                ? const Text('Pending...', style: TextStyle(color: Colors.orange))
                : !res.supported
                ? const Text('Not supported', style: TextStyle(color: Colors.grey))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avg: ${(res.avgMicros! / 1000).toStringAsFixed(2)} ms',
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                Text(
                  'Min: ${(res.minMicros! / 1000).toStringAsFixed(2)} ms  Max: ${(res.maxMicros! / 1000).toStringAsFixed(2)} ms',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey[400]),
                ),
                Text(
                  '± ${(res.stdMicros! / 1000).toStringAsFixed(2)} ms',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results sharing coming soon!')),
    );
  }

  @override
  void dispose() {
    for (final plugin in _plugins) {
      plugin.dispose();
    }
    super.dispose();
  }
}

// =====================================================================
// 9. UPDATED: Comparison Screen - All plugins side-by-side with Chart
//    NOW FULLY SCROLLABLE + TAP TO ZOOM
// =====================================================================
class ComparisonScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const ComparisonScreen({super.key, required this.imageBytes});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  late final List<PluginAdapter> _plugins;
  Operation _selectedOperation = Operation.resize;
  int _iterations = 10;
  bool _isBenchmarking = false;
  Map<PluginAdapter, ComparisonResult> _results = {};

  @override
  void initState() {
    super.initState();
    _plugins = [
      RustImageClientAdapter(),
      ImagePackageAdapter(),
      FlutterImageCompressAdapter(),
    ];
    _initializePlugins();
  }

  Future<void> _initializePlugins() async {
    for (final plugin in _plugins) {
      await plugin.initialize();
      await plugin.loadImage(widget.imageBytes);
    }
  }

  Future<void> _runComparison() async {
    setState(() {
      _isBenchmarking = true;
      _results = {};
    });

    for (final plugin in _plugins) {
      if (!plugin.supports(_selectedOperation)) {
        setState(() {
          _results[plugin] = ComparisonResult.notSupported();
        });
        continue;
      }

      final durations = <int>[];
      Uint8List? resultImage;

      for (int i = 0; i < _iterations; i++) {
        await plugin.reset();
        final sw = Stopwatch()..start();
        await plugin.applyOperation(_selectedOperation);
        sw.stop();
        durations.add(sw.elapsedMicroseconds);
        if (i == _iterations - 1) {
          resultImage = await plugin.getRenderedImage();
        }
      }

      final avg = durations.reduce((a, b) => a + b) / _iterations;
      final variance = durations.map((d) => pow(d - avg, 2)).reduce((a, b) => a + b) / _iterations;
      final std = sqrt(variance);

      setState(() {
        _results[plugin] = ComparisonResult(
          avgMicros: avg,
          stdMicros: std,
          resultImage: resultImage,
        );
      });
    }

    setState(() => _isBenchmarking = false);
  }

  // FIX: Full-screen image viewer with zoom & pan
  void _showFullScreenImage(Uint8List bytes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.memory(bytes),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    PluginAdapter? fastest;
    double? fastestTime;
    if (_results.isNotEmpty) {
      for (final entry in _results.entries) {
        if (entry.value.supported && entry.value.avgMicros != null) {
          if (fastestTime == null || entry.value.avgMicros! < fastestTime) {
            fastestTime = entry.value.avgMicros;
            fastest = entry.key;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Plugin Comparison')),
      body: SafeArea(
        // FIX: Wrap entire content in a scroll view
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Control Panel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<Operation>(
                        value: _selectedOperation,
                        decoration: const InputDecoration(
                          labelText: 'Operation to Compare',
                          border: OutlineInputBorder(),
                        ),
                        items: Operation.values.map((op) {
                          return DropdownMenuItem(
                            value: op,
                            child: Text(op.displayName),
                          );
                        }).toList(),
                        onChanged: _isBenchmarking ? null : (v) => setState(() => _selectedOperation = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _iterations.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Iterations',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_isBenchmarking,
                              onChanged: (v) => _iterations = int.tryParse(v) ?? 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isBenchmarking ? null : _runComparison,
                              icon: _isBenchmarking
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.compare),
                              label: const Text('Compare All'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Performance Chart
              if (_results.isNotEmpty && fastest != null)
                SizedBox(
                  height: 280,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildPerformanceChart(fastest, fastestTime),
                    ),
                  ),
                ),
              if (_results.isNotEmpty && fastest != null)
                const SizedBox(height: 12),

              // FIX: Replace Expanded with a GridView that uses shrinkWrap
              // and no independent scrolling (parent scroll view handles it)
              _results.isEmpty
                  ? const Center(child: Text('Select an operation and press Compare All'))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                // FIX: Important for nested scrolling
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _plugins.length,
                itemBuilder: (context, index) {
                  final plugin = _plugins[index];
                  final result = _results[plugin];
                  final isFastest = plugin == fastest;

                  return Card(
                    color: isFastest ? Colors.cyan.withOpacity(0.1) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plugin.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFastest)
                                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                            ],
                          ),
                          Text(
                            plugin.description,
                            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: result?.resultImage != null
                                ? GestureDetector(
                              // FIX: Tap to zoom
                              onTap: () => _showFullScreenImage(result!.resultImage!),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  result!.resultImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                                : Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: result == null
                                    ? const Text('Pending...')
                                    : !result.supported
                                    ? const Text('Not supported', style: TextStyle(color: Colors.grey))
                                    : const CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (result != null && result.supported) ...[
                            Text(
                              '${(result.avgMicros! / 1000).toStringAsFixed(2)} ms',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '± ${(result.stdMicros! / 1000).toStringAsFixed(2)} ms',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (fastest != null && plugin != fastest) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${((result.avgMicros! / fastestTime! - 1) * 100).toStringAsFixed(0)}% slower',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(PluginAdapter? fastest, double? fastestTime) {
    final chartData = _plugins.asMap().entries.map((entry) {
      final index = entry.key;
      final plugin = entry.value;
      final result = _results[plugin];
      final isFastest = plugin == fastest;
      final timeMs = (result?.avgMicros ?? 0) / 1000;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: timeMs,
            color: isFastest
                ? Colors.cyan
                : Colors.blue.withOpacity(0.7),
            width: 32,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance: ${_selectedOperation.displayName}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: chartData,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < _plugins.length) {
                        final result = _results[_plugins[index]];
                        final isFastest = _plugins[index] == fastest;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _plugins[index].name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isFastest ? FontWeight.bold : FontWeight.normal,
                                  color: isFastest ? Colors.cyan : Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (result?.supported == true)
                                Text(
                                  '${(result!.avgMicros! / 1000).toStringAsFixed(1)}ms',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[400],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 50,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: _calculateGridInterval(),
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 0.8,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              groupsSpace: 18,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.grey[900]!,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final plugin = _plugins[groupIndex];
                    final result = _results[plugin];
                    return BarTooltipItem(
                      '${plugin.name}\n${(rod.toY).toStringAsFixed(2)}ms\n±${(result?.stdMicros ?? 0 / 1000).toStringAsFixed(2)}ms',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateGridInterval() {
    final results = _results.values
        .where((r) => r.supported && r.avgMicros != null)
        .map((r) => r.avgMicros! / 1000)
        .toList();

    if (results.isEmpty) return 10;

    final maxTime = results.reduce((a, b) => a > b ? a : b);
    if (maxTime < 10) return 1;
    if (maxTime < 100) return 10;
    if (maxTime < 1000) return 50;
    return 100;
  }

  @override
  void dispose() {
    for (final plugin in _plugins) {
      plugin.dispose();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------
// 10. Data models
// ---------------------------------------------------------------------
class BenchmarkResult {
  final double? avgMicros;
  final double? stdMicros;
  final double? minMicros;
  final double? maxMicros;
  final bool supported;

  BenchmarkResult({
    required this.avgMicros,
    required this.stdMicros,
    required this.minMicros,
    required this.maxMicros,
  }) : supported = true;

  BenchmarkResult.notSupported()
      : avgMicros = null,
        stdMicros = null,
        minMicros = null,
        maxMicros = null,
        supported = false;
}

class ComparisonResult {
  final double? avgMicros;
  final double? stdMicros;
  final Uint8List? resultImage;
  final bool supported;

  ComparisonResult({
    required this.avgMicros,
    required this.stdMicros,
    required this.resultImage,
  }) : supported = true;

  ComparisonResult.notSupported()
      : avgMicros = null,
        stdMicros = null,
        resultImage = null,
        supported = false;
}