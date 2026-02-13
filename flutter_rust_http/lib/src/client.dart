import 'dart:typed_data';
import '../generated_bindings.dart/image_manipulation.dart' show ImageFormat, ResizeFilter, FilterType;
import '../generated_bindings.dart/lib.dart';
import 'bindings.dart';


/// Main client for image manipulation operations
///
/// This class provides a fluent, easy-to-use API for loading, processing,
/// and exporting images. It manages the underlying image handle and ensures
/// proper resource cleanup.
class ImageClient {
  ImageHandle? _handle;
  bool _isDisposed = false;

  /// Initialize the image manipulation library
  ///
  /// This must be called once before creating any ImageClient instances.
  /// Typically called in main() or app initialization.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await ImageClient.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    await initializeImageLibrary();
  }

  /// Get cache statistics
  ///
  /// Returns information about memory usage and number of cached images
  static Future<CacheStats> getCacheStats() async {
    return await ImageCache.getStats();
  }

  /// Clear all cached images from memory
  ///
  /// Useful for freeing up memory when needed
  static Future<void> clearCache() async {
    await ImageCache.clearAll();
  }

  // ============================================================================
  // Loading Methods
  // ============================================================================

  /// Load an image from byte data
  ///
  /// If this client already has an image loaded, it will be disposed first.
  ///
  /// Example:
  /// ```dart
  /// final bytes = await File('image.jpg').readAsBytes();
  /// await client.loadFromBytes(bytes);
  /// ```
  Future<void> loadFromBytes(List<int> bytes) async {
    _checkNotDisposed();
    await _disposeCurrentHandle();
    _handle = await ImageLoader.fromBytes(bytes);
  }

  /// Load an image from a file path
  ///
  /// If this client already has an image loaded, it will be disposed first.
  ///
  /// Example:
  /// ```dart
  /// await client.loadFromPath('/path/to/image.jpg');
  /// ```
  Future<void> loadFromPath(String path) async {
    _checkNotDisposed();
    await _disposeCurrentHandle();
    _handle = await ImageLoader.fromPath(path);
  }

  // ============================================================================
  // Export Methods
  // ============================================================================

  /// Get the processed image as bytes
  ///
  /// [format] specifies the output format (PNG, JPEG, WebP, or BMP)
  ///
  /// Example:
  /// ```dart
  /// final pngBytes = await client.getBytes(ImageFormat.png);
  /// final jpegBytes = await client.getBytes(ImageFormat.jpeg);
  /// ```
  Future<Uint8List> getBytes(ImageFormat format) async {
    _checkNotDisposed();
    _ensureLoaded();
    return await ImageExporter.toBytes(_handle!, format);
  }

  /// Get the current image dimensions
  ///
  /// Returns a record (width, height)
  ///
  /// Example:
  /// ```dart
  /// final (width, height) = await client.getDimensions();
  /// print('Image is ${width}x$height');
  /// ```
  Future<(int, int)> getDimensions() async {
    _checkNotDisposed();
    _ensureLoaded();
    return await ImageExporter.getDimensions(_handle!);
  }

  // ============================================================================
  // Transform Methods
  // ============================================================================

  /// Resize image to exact dimensions
  ///
  /// [filter] determines the quality of the resize operation.
  /// Lanczos3 provides the best quality for downscaling.
  ///
  /// Example:
  /// ```dart
  /// await client.resize(
  ///   width: 800,
  ///   height: 600,
  ///   filter: ResizeFilter.lanczos3,
  /// );
  /// ```
  Future<void> resize({
    required int width,
    required int height,
    ResizeFilter filter = ResizeFilter.lanczos3,
  }) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageTransform.resize(
      _handle!,
      width: width,
      height: height,
      filter: filter,
    );
  }

  /// Resize image to fit within bounds
  ///
  /// Maintains aspect ratio. The image will be scaled to fit within
  /// the specified bounds without cropping.
  ///
  /// Example:
  /// ```dart
  /// // Image will fit within 800x600, maintaining aspect ratio
  /// await client.resizeToFit(maxWidth: 800, maxHeight: 600);
  /// ```
  Future<void> resizeToFit({
    required int maxWidth,
    required int maxHeight,
    ResizeFilter filter = ResizeFilter.lanczos3,
  }) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageTransform.resizeToFit(
      _handle!,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      filter: filter,
    );
  }

  /// Resize image to fill bounds
  ///
  /// Maintains aspect ratio. The image will be scaled to fill
  /// the specified bounds, potentially cropping the edges.
  ///
  /// Example:
  /// ```dart
  /// // Image will fill 800x600, cropping if necessary
  /// await client.resizeToFill(width: 800, height: 600);
  /// ```
  Future<void> resizeToFill({
    required int width,
    required int height,
    ResizeFilter filter = ResizeFilter.lanczos3,
  }) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageTransform.resizeToFill(
      _handle!,
      width: width,
      height: height,
      filter: filter,
    );
  }

  /// Crop image to specified rectangle
  ///
  /// Example:
  /// ```dart
  /// await client.crop(x: 100, y: 100, width: 400, height: 300);
  /// ```
  Future<void> crop({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageTransform.crop(
      _handle!,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  /// Rotate image clockwise
  ///
  /// [degrees] must be 90, 180, or 270
  ///
  /// Example:
  /// ```dart
  /// await client.rotate(90);  // Rotate 90° clockwise
  /// ```
  Future<void> rotate(int degrees) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageTransform.rotate(_handle!, degrees);
  }

  /// Flip image horizontally (mirror)
  Future<void> flipHorizontal() async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageTransform.flipHorizontal(_handle!);
  }

  /// Flip image vertically
  Future<void> flipVertical() async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageTransform.flipVertical(_handle!);
  }

  // ============================================================================
  // Filter Methods
  // ============================================================================

  /// Apply a predefined filter
  ///
  /// Available filters:
  /// - FilterType.sepia
  /// - FilterType.vintage
  /// - FilterType.cool
  /// - FilterType.warm
  /// - FilterType.dramatic
  /// - FilterType.edgeDetect
  /// - FilterType.emboss
  /// - FilterType.posterize
  /// - FilterType.solarize
  ///
  /// Example:
  /// ```dart
  /// await client.applyFilter(FilterType.sepia);
  /// ```
  Future<void> applyFilter(FilterType filter) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageFilters.applyFilter(_handle!, filter);
  }

  /// Convert image to grayscale
  Future<void> grayscale() async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageFilters.grayscale(_handle!);
  }

  /// Invert image colors (negative)
  Future<void> invert() async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageFilters.invert(_handle!);
  }

  /// Apply Gaussian blur
  ///
  /// [sigma] controls the blur amount. Typical values:
  /// - 0.5 to 2.0: Slight blur
  /// - 2.0 to 5.0: Medium blur
  /// - 5.0 to 10.0: Heavy blur
  ///
  /// Example:
  /// ```dart
  /// await client.blur(3.0);
  /// ```
  Future<void> blur(double sigma) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageFilters.blur(_handle!, sigma);
  }

  /// Sharpen image
  ///
  /// [amount] controls the sharpening intensity. Typical values:
  /// - 0.5 to 1.5: Subtle sharpening
  /// - 1.5 to 3.0: Medium sharpening
  /// - 3.0 to 5.0: Heavy sharpening
  ///
  /// Example:
  /// ```dart
  /// await client.sharpen(1.5);
  /// ```
  Future<void> sharpen(double amount) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageFilters.sharpen(_handle!, amount);
  }

  // ============================================================================
  // Adjustment Methods
  // ============================================================================

  /// Adjust brightness
  ///
  /// [value] ranges from -100 (darker) to 100 (brighter)
  ///
  /// Example:
  /// ```dart
  /// await client.adjustBrightness(20);  // Make brighter
  /// await client.adjustBrightness(-20); // Make darker
  /// ```
  Future<void> adjustBrightness(int value) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageAdjustments.brightness(_handle!, value);
  }

  /// Adjust contrast
  ///
  /// [value] ranges from -100 (less contrast) to 100 (more contrast)
  ///
  /// Example:
  /// ```dart
  /// await client.adjustContrast(30);
  /// ```
  Future<void> adjustContrast(int value) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageAdjustments.contrast(_handle!, value);
  }

  /// Adjust saturation
  ///
  /// [value] ranges from -100 (desaturated/grayscale) to 100 (saturated)
  ///
  /// Example:
  /// ```dart
  /// await client.adjustSaturation(-50); // Desaturate
  /// await client.adjustSaturation(50);  // Saturate
  /// ```
  Future<void> adjustSaturation(int value) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageAdjustments.saturation(_handle!, value);
  }

  /// Adjust hue
  ///
  /// [value] ranges from 0 to 360 degrees
  ///
  /// Example:
  /// ```dart
  /// await client.adjustHue(180); // Shift hue by 180°
  /// ```
  Future<void> adjustHue(int value) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageAdjustments.hue(_handle!, value);
  }

  /// Apply multiple adjustments at once
  ///
  /// More efficient than calling individual adjustment methods.
  ///
  /// Example:
  /// ```dart
  /// await client.adjustAll(
  ///   brightness: 20,
  ///   contrast: 10,
  ///   saturation: 15,
  ///   hue: 5,
  /// );
  /// ```
  Future<void> adjustAll({
    int brightness = 0,
    int contrast = 0,
    int saturation = 0,
    int hue = 0,
  }) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageAdjustments.adjustAll(
      _handle!,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      hue: hue,
    );
  }

  // ============================================================================
  // Composition Methods
  // ============================================================================

  /// Add a watermark to the image
  ///
  /// [watermark] is another ImageClient containing the watermark image
  ///
  /// Example:
  /// ```dart
  /// final watermark = ImageClient();
  /// await watermark.loadFromPath('watermark.png');
  ///
  /// await client.addWatermark(
  ///   watermark,
  ///   x: 10,
  ///   y: 10,
  ///   opacity: 0.5,
  ///   scale: 0.3,
  /// );
  ///
  /// watermark.dispose();
  /// ```
  Future<void> addWatermark(
      ImageClient watermark, {
        required int x,
        required int y,
        double opacity = 1.0,
        double scale = 1.0,
      }) async {
    _checkNotDisposed();
    _ensureLoaded();
    watermark._ensureLoaded();

    await ImageComposition.addWatermark(
      _handle!,
      watermark._handle!,
      x: x,
      y: y,
      opacity: opacity,
      scale: scale,
    );
  }

  /// Overlay another image on top of this image
  ///
  /// [overlay] is another ImageClient containing the overlay image
  ///
  /// Example:
  /// ```dart
  /// final overlay = ImageClient();
  /// await overlay.loadFromPath('overlay.png');
  ///
  /// await client.overlay(
  ///   overlay,
  ///   x: 100,
  ///   y: 100,
  ///   opacity: 0.7,
  /// );
  ///
  /// overlay.dispose();
  /// ```
  Future<void> overlay(
      ImageClient overlayImage, {
        required int x,
        required int y,
        double opacity = 1.0,
      }) async {
    _checkNotDisposed();
    _ensureLoaded();
    overlayImage._ensureLoaded();

    await ImageComposition.overlay(
      _handle!,
      overlayImage._handle!,
      x: x,
      y: y,
      opacity: opacity,
    );
  }

  // ============================================================================
  // Batch Operations (Performance Optimized)
  // ============================================================================

  /// Resize and apply filter in a single optimized operation
  ///
  /// More efficient than calling resize() and applyFilter() separately
  Future<void> resizeAndFilter({
    required int width,
    required int height,
    required FilterType filter,
    ResizeFilter resizeFilter = ResizeFilter.lanczos3,
  }) async {
    _checkNotDisposed();
    _ensureLoaded();
    await ImageBatch.resizeAndFilter(
      _handle!,
      width: width,
      height: height,
      resizeFilter: resizeFilter,
      imageFilter: filter,
    );
  }

  /// Crop, resize, and adjust in a single optimized operation
  ///
  /// More efficient than calling methods separately
  Future<void> cropResizeAndAdjust({
    required int cropX,
    required int cropY,
    required int cropWidth,
    required int cropHeight,
    required int resizeWidth,
    required int resizeHeight,
    ResizeFilter resizeFilter = ResizeFilter.lanczos3,
    int brightness = 0,
    int contrast = 0,
    int saturation = 0,
    int hue = 0,
  }) async {
    _checkNotDisposed();
    _ensureLoaded();

    await ImageBatch.cropResizeAdjust(
      _handle!,
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropWidth,
      cropHeight: cropHeight,
      resizeWidth: resizeWidth,
      resizeHeight: resizeHeight,
      resizeFilter: resizeFilter,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      hue: hue,
    );
  }

  // ============================================================================
  // Resource Management
  // ============================================================================

  /// Check if this client has been disposed
  bool get isDisposed => _isDisposed;

  /// Check if this client has an image loaded
  bool get hasImage => _handle != null && !_handle!.isDisposed;

  /// Dispose of this client and free associated memory
  ///
  /// IMPORTANT: Always call dispose() when done with an ImageClient
  /// to prevent memory leaks. Consider using a try-finally block:
  ///
  /// ```dart
  /// final client = ImageClient();
  /// try {
  ///   await client.loadFromBytes(bytes);
  ///   // ... process image ...
  /// } finally {
  ///   client.dispose();
  /// }
  /// ```
  Future<void> dispose() async {
    if (_isDisposed) return;

    await _disposeCurrentHandle();
    _isDisposed = true;
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('ImageClient has been disposed');
    }
  }

  void _ensureLoaded() {
    if (_handle == null || _handle!.isDisposed) {
      throw StateError('No image loaded. Call loadFromBytes() or loadFromPath() first.');
    }
  }

  Future<void> _disposeCurrentHandle() async {
    if (_handle != null && !_handle!.isDisposed) {
      await ImageCache.dispose(_handle!);
      _handle = null;
    }
  }
}

/// Builder pattern for chaining image operations
///
/// Provides a fluent API for applying multiple operations in sequence.
///
/// Example:
/// ```dart
/// final result = await ImageBuilder()
///   .loadFromBytes(imageBytes)
///   .resize(width: 800, height: 600)
///   .adjustBrightness(20)
///   .applyFilter(FilterType.sepia)
///   .blur(1.5)
///   .build(ImageFormat.jpeg);
/// ```
class ImageBuilder {
  final ImageClient _client = ImageClient();
  bool _built = false;

  ImageBuilder();

  /// Load image from bytes
  ImageBuilder loadFromBytes(List<int> bytes) {
    _checkNotBuilt();
    _client.loadFromBytes(bytes);
    return this;
  }

  /// Load image from path
  ImageBuilder loadFromPath(String path) {
    _checkNotBuilt();
    _client.loadFromPath(path);
    return this;
  }

  /// Resize to exact dimensions
  ImageBuilder resize({
    required int width,
    required int height,
    ResizeFilter filter = ResizeFilter.lanczos3,
  }) {
    _checkNotBuilt();
    _client.resize(width: width, height: height, filter: filter);
    return this;
  }

  /// Resize to fit within bounds
  ImageBuilder resizeToFit({
    required int maxWidth,
    required int maxHeight,
    ResizeFilter filter = ResizeFilter.lanczos3,
  }) {
    _checkNotBuilt();
    _client.resizeToFit(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      filter: filter,
    );
    return this;
  }

  /// Crop the image
  ImageBuilder crop({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    _checkNotBuilt();
    _client.crop(x: x, y: y, width: width, height: height);
    return this;
  }

  /// Rotate the image
  ImageBuilder rotate(int degrees) {
    _checkNotBuilt();
    _client.rotate(degrees);
    return this;
  }

  /// Flip horizontally
  ImageBuilder flipHorizontal() {
    _checkNotBuilt();
    _client.flipHorizontal();
    return this;
  }

  /// Flip vertically
  ImageBuilder flipVertical() {
    _checkNotBuilt();
    _client.flipVertical();
    return this;
  }

  /// Apply a filter
  ImageBuilder applyFilter(FilterType filter) {
    _checkNotBuilt();
    _client.applyFilter(filter);
    return this;
  }

  /// Convert to grayscale
  ImageBuilder grayscale() {
    _checkNotBuilt();
    _client.grayscale();
    return this;
  }

  /// Invert colors
  ImageBuilder invert() {
    _checkNotBuilt();
    _client.invert();
    return this;
  }

  /// Apply blur
  ImageBuilder blur(double sigma) {
    _checkNotBuilt();
    _client.blur(sigma);
    return this;
  }

  /// Sharpen image
  ImageBuilder sharpen(double amount) {
    _checkNotBuilt();
    _client.sharpen(amount);
    return this;
  }

  /// Adjust brightness
  ImageBuilder adjustBrightness(int value) {
    _checkNotBuilt();
    _client.adjustBrightness(value);
    return this;
  }

  /// Adjust contrast
  ImageBuilder adjustContrast(int value) {
    _checkNotBuilt();
    _client.adjustContrast(value);
    return this;
  }

  /// Adjust saturation
  ImageBuilder adjustSaturation(int value) {
    _checkNotBuilt();
    _client.adjustSaturation(value);
    return this;
  }

  /// Adjust hue
  ImageBuilder adjustHue(int value) {
    _checkNotBuilt();
    _client.adjustHue(value);
    return this;
  }

  /// Apply multiple adjustments
  ImageBuilder adjustAll({
    int brightness = 0,
    int contrast = 0,
    int saturation = 0,
    int hue = 0,
  }) {
    _checkNotBuilt();
    _client.adjustAll(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      hue: hue,
    );
    return this;
  }

  /// Build and return the final image as bytes
  ///
  /// Disposes the internal client after building
  Future<Uint8List> build(ImageFormat format) async {
    _checkNotBuilt();
    _built = true;

    try {
      return await _client.getBytes(format);
    } finally {
      await _client.dispose();
    }
  }

  /// Build and return the client for further operations
  ///
  /// WARNING: You must manually dispose() the returned client
  ImageClient buildClient() {
    _checkNotBuilt();
    _built = true;
    return _client;
  }

  void _checkNotBuilt() {
    if (_built) {
      throw StateError('ImageBuilder has already been built');
    }
  }
}