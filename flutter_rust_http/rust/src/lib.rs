mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
use std::sync::Arc;
use tokio::sync::RwLock;

mod image_manipulation;

use image_manipulation::{
    ImageCache, FilterType, ResizeFilter, ImageFormat,
    CropParams, AdjustmentParams, WatermarkParams
};

// ============================================================================
// GLOBAL CACHE – now with a sensible default memory limit (100 MB)
// ============================================================================
lazy_static::lazy_static! {
    static ref CACHE: Arc<RwLock<ImageCache>> = Arc::new(RwLock::new(
        ImageCache::with_memory_limit(100 * 1024 * 1024) // 100 MB default
    ));
}

/// Initialise the cache with a custom memory limit.
/// Should be called once when the plugin starts.
pub async fn init_cache(max_memory_mb: usize) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    *cache = ImageCache::with_memory_limit(max_memory_mb * 1024 * 1024);
    Ok(())
}

// ============================================================================
// PUBLIC API - All functions are async and return Results
// ============================================================================

/// Load an image from bytes and return a handle (receipt) to it
/// This is the "deposit" operation - stores image in native heap
pub async fn load_image_from_bytes(bytes: Vec<u8>) -> anyhow::Result<u32> {
    let mut cache = CACHE.write().await;
    cache.load_from_bytes(bytes).await
}

/// Load an image from a file path
pub async fn load_image_from_path(path: String) -> anyhow::Result<u32> {
    let mut cache = CACHE.write().await;
    cache.load_from_path(path).await
}

/// Get the final processed image as bytes
/// This is the "withdrawal" operation - retrieves image from vault
pub async fn get_image_bytes(handle: u32, format: ImageFormat) -> anyhow::Result<Vec<u8>> {
    let cache = CACHE.read().await;
    cache.get_bytes(handle, format).await
}

/// Get image dimensions (read‑only, does not affect LRU order)
pub async fn get_image_dimensions(handle: u32) -> anyhow::Result<(u32, u32)> {
    let cache = CACHE.read().await;
    cache.get_dimensions(handle) // ← now an immutable method!
}

/// Dispose of an image to free memory
/// CRITICAL: Must be called from Flutter's dispose() methods
pub async fn dispose_image(handle: u32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.remove(handle)
}

/// Dispose of multiple images at once
pub async fn dispose_images(handles: Vec<u32>) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    for handle in handles {
        let _ = cache.remove(handle);
    }
    Ok(())
}

/// Clear all cached images - useful for memory cleanup
pub async fn clear_all_images() -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.clear_all();
    Ok(())
}

// ============================================================================
// TRANSFORMATION OPERATIONS
// All operations modify the image in-place in the cache
// ============================================================================

/// Resize image to exact dimensions
pub async fn resize(handle: u32, width: u32, height: u32, filter: ResizeFilter) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.resize(handle, width, height, filter).await
}

/// Resize image maintaining aspect ratio (fit within bounds)
pub async fn resize_to_fit(handle: u32, max_width: u32, max_height: u32, filter: ResizeFilter) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.resize_to_fit(handle, max_width, max_height, filter).await
}

/// Resize image maintaining aspect ratio (fill bounds, may crop)
pub async fn resize_to_fill(handle: u32, width: u32, height: u32, filter: ResizeFilter) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.resize_to_fill(handle, width, height, filter).await
}

/// Crop image to specified rectangle
pub async fn crop(handle: u32, params: CropParams) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.crop(handle, params).await
}

/// Rotate image by 90, 180, or 270 degrees
pub async fn rotate(handle: u32, degrees: i32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.rotate(handle, degrees).await
}

/// Flip image horizontally
pub async fn flip_horizontal(handle: u32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.flip_horizontal(handle).await
}

/// Flip image vertically
pub async fn flip_vertical(handle: u32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.flip_vertical(handle).await
}

// ============================================================================
// FILTER OPERATIONS
// ============================================================================

/// Apply a filter to the image
pub async fn apply_filter(handle: u32, filter: FilterType) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.apply_filter(handle, filter).await
}

/// Convert image to grayscale
pub async fn grayscale(handle: u32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.grayscale(handle).await
}

/// Invert image colors
pub async fn invert(handle: u32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.invert(handle).await
}

/// Apply Gaussian blur
pub async fn blur(handle: u32, sigma: f32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.blur(handle, sigma).await
}

/// Sharpen image
pub async fn sharpen(handle: u32, amount: f32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.sharpen(handle, amount).await
}

// ============================================================================
// ADJUSTMENT OPERATIONS
// ============================================================================

/// Adjust brightness (-100 to 100)
pub async fn adjust_brightness(handle: u32, value: i32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.adjust_brightness(handle, value).await
}

/// Adjust contrast (-100 to 100)
pub async fn adjust_contrast(handle: u32, value: i32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.adjust_contrast(handle, value).await
}

/// Adjust saturation (-100 to 100)
pub async fn adjust_saturation(handle: u32, value: i32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.adjust_saturation(handle, value).await
}

/// Adjust hue (0 to 360 degrees)
pub async fn adjust_hue(handle: u32, value: i32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.adjust_hue(handle, value).await
}

/// Apply multiple adjustments at once (more efficient)
pub async fn adjust_all(handle: u32, params: AdjustmentParams) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.adjust_all(handle, params).await
}

// ============================================================================
// COMPOSITE OPERATIONS
// ============================================================================

/// Add watermark to image
pub async fn add_watermark(handle: u32, watermark_handle: u32, params: WatermarkParams) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.add_watermark(handle, watermark_handle, params).await
}

/// Overlay one image on top of another
pub async fn overlay(handle: u32, overlay_handle: u32, x: i32, y: i32, opacity: f32) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.overlay(handle, overlay_handle, x, y, opacity).await
}

// ============================================================================
// BATCH OPERATIONS
// Apply multiple operations in a single call - more efficient
// ============================================================================

/// Batch operation: Resize and apply filter
pub async fn batch_resize_and_filter(
    handle: u32,
    width: u32,
    height: u32,
    filter: ResizeFilter,
    image_filter: FilterType,
) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.resize(handle, width, height, filter).await?;
    cache.apply_filter(handle, image_filter).await
}

/// Batch operation: Crop, resize, and adjust
pub async fn batch_crop_resize_adjust(
    handle: u32,
    crop_params: CropParams,
    width: u32,
    height: u32,
    resize_filter: ResizeFilter,
    adjustments: AdjustmentParams,
) -> anyhow::Result<()> {
    let mut cache = CACHE.write().await;
    cache.crop(handle, crop_params).await?;
    cache.resize(handle, width, height, resize_filter).await?;
    cache.adjust_all(handle, adjustments).await
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Get memory usage statistics
pub async fn get_cache_stats() -> anyhow::Result<CacheStats> {
    let cache = CACHE.read().await;
    Ok(cache.get_stats())
}

/// Pre-warm the cache with common operations (optional optimization)
pub async fn initialize_cache() -> anyhow::Result<()> {
    // Initialize any SIMD or threading pools
    Ok(())
}

// ============================================================================
// TYPES FOR STATISTICS
// ============================================================================

#[derive(Debug, Clone)]
pub struct CacheStats {
    pub image_count: usize,
    pub total_memory_bytes: usize,
    pub average_memory_per_image: usize,
}