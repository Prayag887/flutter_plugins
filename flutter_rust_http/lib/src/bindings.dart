/// Core binding layer for image manipulation operations
///
/// This file wraps the auto-generated FFI code to provide:
/// - Better error handling
/// - Null safety guarantees
/// - Documentation
/// - Type safety improvements

import 'dart:typed_data';

import '../generated_bindings.dart/frb_generated.dart';
import '../generated_bindings.dart/image_manipulation.dart';
import '../generated_bindings.dart/lib.dart' as frb;

/// Initialize the Rust library
/// Must be called before any other operations
Future<void> initializeImageLibrary() async {
  await RustLib.init();
  await frb.initializeCache();
}

/// Image handle manager for tracking and cleanup
class ImageHandle {
  final int _handle;
  bool _disposed = false;

  ImageHandle._(this._handle);

  int get handle {
    if (_disposed) {
      throw StateError('ImageHandle has been disposed');
    }
    return _handle;
  }

  bool get isDisposed => _disposed;

  /// Mark this handle as disposed (internal use)
  void _markDisposed() {
    _disposed = true;
  }

  @override
  String toString() => 'ImageHandle($_handle${_disposed ? ', disposed' : ''})';
}

/// Image loading operations
class ImageLoader {
  /// Load an image from byte data
  ///
  /// Returns an [ImageHandle] that must be disposed when no longer needed
  ///
  /// Example:
  /// ```dart
  /// final bytes = await File('image.jpg').readAsBytes();
  /// final handle = await ImageLoader.fromBytes(bytes);
  /// ```
  static Future<ImageHandle> fromBytes(List<int> bytes) async {
    final handle = await frb.loadImageFromBytes(bytes: bytes);
    return ImageHandle._(handle);
  }

  /// Load an image from a file path
  ///
  /// Returns an [ImageHandle] that must be disposed when no longer needed
  ///
  /// Example:
  /// ```dart
  /// final handle = await ImageLoader.fromPath('/path/to/image.jpg');
  /// ```
  static Future<ImageHandle> fromPath(String path) async {
    final handle = await frb.loadImageFromPath(path: path);
    return ImageHandle._(handle);
  }
}

/// Image export operations
class ImageExporter {
  /// Get image as bytes in the specified format
  ///
  /// Supported formats: PNG, JPEG, WebP, BMP
  static Future<Uint8List> toBytes(
      ImageHandle handle,
      ImageFormat format,
      ) async {
    return await frb.getImageBytes(handle: handle.handle, format: format);
  }

  /// Get image dimensions (width, height)
  static Future<(int, int)> getDimensions(ImageHandle handle) async {
    return await frb.getImageDimensions(handle: handle.handle);
  }
}

/// Image transformation operations
class ImageTransform {
  /// Resize image to exact dimensions
  static Future<void> resize(
      ImageHandle handle, {
        required int width,
        required int height,
        ResizeFilter filter = ResizeFilter.lanczos3,
      }) async {
    await frb.resize(
      handle: handle.handle,
      width: width,
      height: height,
      filter: filter,
    );
  }

  /// Resize image to fit within bounds (maintains aspect ratio)
  static Future<void> resizeToFit(
      ImageHandle handle, {
        required int maxWidth,
        required int maxHeight,
        ResizeFilter filter = ResizeFilter.lanczos3,
      }) async {
    await frb.resizeToFit(
      handle: handle.handle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      filter: filter,
    );
  }

  /// Resize image to fill bounds (maintains aspect ratio, may crop)
  static Future<void> resizeToFill(
      ImageHandle handle, {
        required int width,
        required int height,
        ResizeFilter filter = ResizeFilter.lanczos3,
      }) async {
    await frb.resizeToFill(
      handle: handle.handle,
      width: width,
      height: height,
      filter: filter,
    );
  }

  /// Crop image to specified rectangle
  static Future<void> crop(
      ImageHandle handle, {
        required int x,
        required int y,
        required int width,
        required int height,
      }) async {
    await frb.crop(
      handle: handle.handle,
      params: CropParams(x: x, y: y, width: width, height: height),
    );
  }

  /// Rotate image by degrees (90, 180, or 270)
  static Future<void> rotate(
      ImageHandle handle,
      int degrees,
      ) async {
    if (degrees != 90 && degrees != 180 && degrees != 270) {
      throw ArgumentError('Degrees must be 90, 180, or 270');
    }
    await frb.rotate(handle: handle.handle, degrees: degrees);
  }

  /// Flip image horizontally
  static Future<void> flipHorizontal(ImageHandle handle) async {
    await frb.flipHorizontal(handle: handle.handle);
  }

  /// Flip image vertically
  static Future<void> flipVertical(ImageHandle handle) async {
    await frb.flipVertical(handle: handle.handle);
  }
}

/// Image filter operations
class ImageFilters {
  /// Apply a predefined filter
  static Future<void> applyFilter(
      ImageHandle handle,
      FilterType filter,
      ) async {
    await frb.applyFilter(handle: handle.handle, filter: filter);
  }

  /// Convert to grayscale
  static Future<void> grayscale(ImageHandle handle) async {
    await frb.grayscale(handle: handle.handle);
  }

  /// Invert colors
  static Future<void> invert(ImageHandle handle) async {
    await frb.invert(handle: handle.handle);
  }

  /// Apply Gaussian blur
  ///
  /// [sigma] controls the blur amount (typically 0.5 to 10.0)
  static Future<void> blur(ImageHandle handle, double sigma) async {
    await frb.blur(handle: handle.handle, sigma: sigma);
  }

  /// Sharpen image
  ///
  /// [amount] controls the sharpening intensity (typically 0.0 to 5.0)
  static Future<void> sharpen(ImageHandle handle, double amount) async {
    await frb.sharpen(handle: handle.handle, amount: amount);
  }
}

/// Image adjustment operations
class ImageAdjustments {
  /// Adjust brightness
  ///
  /// [value] ranges from -100 (darker) to 100 (brighter)
  static Future<void> brightness(ImageHandle handle, int value) async {
    if (value < -100 || value > 100) {
      throw ArgumentError('Brightness value must be between -100 and 100');
    }
    await frb.adjustBrightness(handle: handle.handle, value: value);
  }

  /// Adjust contrast
  ///
  /// [value] ranges from -100 (less contrast) to 100 (more contrast)
  static Future<void> contrast(ImageHandle handle, int value) async {
    if (value < -100 || value > 100) {
      throw ArgumentError('Contrast value must be between -100 and 100');
    }
    await frb.adjustContrast(handle: handle.handle, value: value);
  }

  /// Adjust saturation
  ///
  /// [value] ranges from -100 (desaturated) to 100 (saturated)
  static Future<void> saturation(ImageHandle handle, int value) async {
    if (value < -100 || value > 100) {
      throw ArgumentError('Saturation value must be between -100 and 100');
    }
    await frb.adjustSaturation(handle: handle.handle, value: value);
  }

  /// Adjust hue
  ///
  /// [value] ranges from 0 to 360 degrees
  static Future<void> hue(ImageHandle handle, int value) async {
    if (value < 0 || value > 360) {
      throw ArgumentError('Hue value must be between 0 and 360');
    }
    await frb.adjustHue(handle: handle.handle, value: value);
  }

  /// Apply multiple adjustments at once (more efficient)
  static Future<void> adjustAll(
      ImageHandle handle, {
        int brightness = 0,
        int contrast = 0,
        int saturation = 0,
        int hue = 0,
      }) async {
    await frb.adjustAll(
      handle: handle.handle,
      params: AdjustmentParams(
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        hue: hue,
      ),
    );
  }
}

/// Image composition operations
class ImageComposition {
  /// Add watermark to image
  static Future<void> addWatermark(
      ImageHandle handle,
      ImageHandle watermarkHandle, {
        required int x,
        required int y,
        double opacity = 1.0,
        double scale = 1.0,
      }) async {
    await frb.addWatermark(
      handle: handle.handle,
      watermarkHandle: watermarkHandle.handle,
      params: WatermarkParams(
        position: Position.custom(x, y),
        opacity: opacity,
        scale: scale,
      ),
    );
  }

  /// Overlay one image on top of another
  static Future<void> overlay(
      ImageHandle handle,
      ImageHandle overlayHandle, {
        required int x,
        required int y,
        double opacity = 1.0,
      }) async {
    await frb.overlay(
      handle: handle.handle,
      overlayHandle: overlayHandle.handle,
      x: x,
      y: y,
      opacity: opacity,
    );
  }
}

/// Batch operations for performance
class ImageBatch {
  /// Resize and apply filter in one operation
  static Future<void> resizeAndFilter(
      ImageHandle handle, {
        required int width,
        required int height,
        required ResizeFilter resizeFilter,
        required FilterType imageFilter,
      }) async {
    await frb.batchResizeAndFilter(
      handle: handle.handle,
      width: width,
      height: height,
      filter: resizeFilter,
      imageFilter: imageFilter,
    );
  }

  /// Crop, resize, and adjust in one operation
  static Future<void> cropResizeAdjust(
      ImageHandle handle, {
        required int cropX,
        required int cropY,
        required int cropWidth,
        required int cropHeight,
        required int resizeWidth,
        required int resizeHeight,
        required ResizeFilter resizeFilter,
        int brightness = 0,
        int contrast = 0,
        int saturation = 0,
        int hue = 0,
      }) async {
    await frb.batchCropResizeAdjust(
      handle: handle.handle,
      cropParams: CropParams(
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      ),
      width: resizeWidth,
      height: resizeHeight,
      resizeFilter: resizeFilter,
      adjustments: AdjustmentParams(
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        hue: hue,
      ),
    );
  }
}

/// Memory and cache management
class ImageCache {
  /// Dispose a single image handle
  static Future<void> dispose(ImageHandle handle) async {
    if (handle.isDisposed) return;
    await frb.disposeImage(handle: handle.handle);
    handle._markDisposed();
  }

  /// Dispose multiple image handles at once
  static Future<void> disposeAll(List<ImageHandle> handles) async {
    final activeHandles = handles
        .where((h) => !h.isDisposed)
        .map((h) => h.handle)
        .toList();

    if (activeHandles.isEmpty) return;

    await frb.disposeImages(handles: activeHandles);

    for (final handle in handles) {
      handle._markDisposed();
    }
  }

  /// Clear all cached images
  static Future<void> clearAll() async {
    await frb.clearAllImages();
  }

  /// Get cache statistics
  static Future<frb.CacheStats> getStats() async {
    return await frb.getCacheStats();
  }
}