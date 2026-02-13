use std::collections::{HashMap, VecDeque};
use std::io::Cursor;
use std::num::NonZeroU32;
use image::{DynamicImage, ImageFormat as ImgFormat, GenericImageView, ImageBuffer};
use fast_image_resize as fr;
use std::sync::atomic::{AtomicU32, Ordering};

// ============================================================================
// TYPES AND ENUMS (unchanged)
// ============================================================================

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ImageFormat {
    Png,
    Jpeg,
    WebP,
    Gif,
    Bmp,
}

impl ImageFormat {
    fn to_image_format(&self) -> ImgFormat {
        match self {
            ImageFormat::Png => ImgFormat::Png,
            ImageFormat::Jpeg => ImgFormat::Jpeg,
            ImageFormat::WebP => ImgFormat::WebP,
            ImageFormat::Gif => ImgFormat::Gif,
            ImageFormat::Bmp => ImgFormat::Bmp,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ResizeFilter {
    Nearest,
    Bilinear,
    CatmullRom,
    Lanczos3,
}

impl ResizeFilter {
    fn to_fr_filter(&self) -> fr::FilterType {
        match self {
            ResizeFilter::Nearest => fr::FilterType::Box,
            ResizeFilter::Bilinear => fr::FilterType::Bilinear,
            ResizeFilter::CatmullRom => fr::FilterType::CatmullRom,
            ResizeFilter::Lanczos3 => fr::FilterType::Lanczos3,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FilterType {
    Grayscale,
    Sepia,
    Invert,
    Blur,
    Sharpen,
    EdgeDetect,
    Emboss,
}

#[derive(Debug, Clone)]
pub struct CropParams {
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}

#[derive(Debug, Clone)]
pub struct AdjustmentParams {
    pub brightness: i32,  // -100 to 100
    pub contrast: i32,    // -100 to 100
    pub saturation: i32,  // -100 to 100
    pub hue: i32,         // 0 to 360
}

impl Default for AdjustmentParams {
    fn default() -> Self {
        Self {
            brightness: 0,
            contrast: 0,
            saturation: 0,
            hue: 0,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Position {
    TopLeft,
    TopCenter,
    TopRight,
    CenterLeft,
    Center,
    CenterRight,
    BottomLeft,
    BottomCenter,
    BottomRight,
    Custom(i32, i32),
}

#[derive(Debug, Clone)]
pub struct WatermarkParams {
    pub position: Position,
    pub opacity: f32,  // 0.0 to 1.0
    pub scale: f32,    // Scale watermark (1.0 = original size)
}

impl Default for WatermarkParams {
    fn default() -> Self {
        Self {
            position: Position::BottomRight,
            opacity: 0.5,
            scale: 1.0,
        }
    }
}

// ============================================================================
// MOBILE-OPTIMIZED IMAGE CACHE (NO WASTEFUL CONVERSIONS)
// ============================================================================

pub struct ImageCache {
    images: HashMap<u32, DynamicImage>,
    next_id: AtomicU32,
    access_order: VecDeque<u32>,
    max_memory_bytes: usize,
    current_memory_bytes: usize,
    dimensions_cache: HashMap<u32, (u32, u32)>,
}

impl ImageCache {
    pub fn new() -> Self {
        Self::with_memory_limit(usize::MAX)
    }

    pub fn with_memory_limit(max_memory_bytes: usize) -> Self {
        Self {
            images: HashMap::new(),
            next_id: AtomicU32::new(1),
            access_order: VecDeque::new(),
            max_memory_bytes,
            current_memory_bytes: 0,
            dimensions_cache: HashMap::new(),
        }
    }

    fn generate_id(&self) -> u32 {
        self.next_id.fetch_add(1, Ordering::SeqCst)
    }

    #[inline]
    fn image_memory(img: &DynamicImage) -> usize {
        let (w, h) = img.dimensions();
        w as usize * h as usize * match img {
            DynamicImage::ImageLuma8(_) => 1,
            DynamicImage::ImageRgb8(_) => 3,
            DynamicImage::ImageRgba8(_) => 4,
            _ => 4,
        }
    }

    fn touch(&mut self, handle: u32) {
        if let Some(pos) = self.access_order.iter().position(|&h| h == handle) {
            self.access_order.remove(pos);
            self.access_order.push_back(handle);
        }
    }

    fn evict_if_needed(&mut self) {
        while self.current_memory_bytes > self.max_memory_bytes && !self.images.is_empty() {
            if let Some(oldest) = self.access_order.pop_front() {
                if let Some(img) = self.images.remove(&oldest) {
                    self.current_memory_bytes -= Self::image_memory(&img);
                    self.dimensions_cache.remove(&oldest);
                }
            }
        }
    }

    // ====== LOADING ======

    pub async fn load_from_bytes(&mut self, bytes: Vec<u8>) -> anyhow::Result<u32> {
        let img = tokio::task::spawn_blocking(move || image::load_from_memory(&bytes)).await??;
        let id = self.generate_id();
        let dims = img.dimensions();
        let mem = Self::image_memory(&img);

        self.dimensions_cache.insert(id, dims);
        self.current_memory_bytes += mem;
        self.images.insert(id, img);
        self.access_order.push_back(id);
        self.evict_if_needed();
        Ok(id)
    }

    pub async fn load_from_path(&mut self, path: String) -> anyhow::Result<u32> {
        let img = tokio::task::spawn_blocking(move || image::open(&path)).await??;
        let id = self.generate_id();
        let dims = img.dimensions();
        let mem = Self::image_memory(&img);

        self.dimensions_cache.insert(id, dims);
        self.current_memory_bytes += mem;
        self.images.insert(id, img);
        self.access_order.push_back(id);
        self.evict_if_needed();
        Ok(id)
    }

    pub async fn get_bytes(&self, handle: u32, format: ImageFormat) -> anyhow::Result<Vec<u8>> {
        let img = self.images.get(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let fmt = format.to_image_format();
        let mut bytes = Vec::new();
        let mut cursor = Cursor::new(&mut bytes);
        img.write_to(&mut cursor, fmt)?;
        Ok(bytes)
    }

    #[inline]
    pub fn get_dimensions(&self, handle: u32) -> anyhow::Result<(u32, u32)> {
        self.dimensions_cache.get(&handle)
            .copied()
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))
    }

    pub fn remove(&mut self, handle: u32) -> anyhow::Result<()> {
        if let Some(img) = self.images.remove(&handle) {
            self.current_memory_bytes -= Self::image_memory(&img);
            if let Some(pos) = self.access_order.iter().position(|&h| h == handle) {
                self.access_order.remove(pos);
            }
            self.dimensions_cache.remove(&handle);
            Ok(())
        } else {
            Err(anyhow::anyhow!("Image handle {} not found", handle))
        }
    }

    pub fn clear_all(&mut self) {
        self.images.clear();
        self.access_order.clear();
        self.dimensions_cache.clear();
        self.current_memory_bytes = 0;
    }

    pub fn get_stats(&self) -> super::CacheStats {
        let image_count = self.images.len();
        let total_memory_bytes = self.current_memory_bytes;
        let average_memory_per_image = if image_count > 0 {
            total_memory_bytes / image_count
        } else {
            0
        };
        super::CacheStats {
            image_count,
            total_memory_bytes,
            average_memory_per_image,
        }
    }

    // ====== TRANSFORMATIONS ======

    pub async fn resize(
        &mut self,
        handle: u32,
        width: u32,
        height: u32,
        filter: ResizeFilter,
    ) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let old_mem = Self::image_memory(img);
        let owned = std::mem::take(img);
        let filter_type = filter.to_fr_filter();

        let resized = tokio::task::spawn_blocking(move || {
            Self::resize_simd(owned, width, height, filter_type)
        }).await??;

        let new_mem = Self::image_memory(&resized);
        let dims = resized.dimensions();

        self.current_memory_bytes = self.current_memory_bytes - old_mem + new_mem;
        self.dimensions_cache.insert(handle, dims);
        *img = resized;
        self.touch(handle);
        self.evict_if_needed();
        Ok(())
    }

    fn resize_simd(
        img: DynamicImage,
        width: u32,
        height: u32,
        filter: fr::FilterType,
    ) -> anyhow::Result<DynamicImage> {
        let src_image = img.to_rgba8();
        let (src_width, src_height) = src_image.dimensions();

        let src_width_nz = NonZeroU32::new(src_width)
            .ok_or_else(|| anyhow::anyhow!("Source width cannot be zero"))?;
        let src_height_nz = NonZeroU32::new(src_height)
            .ok_or_else(|| anyhow::anyhow!("Source height cannot be zero"))?;
        let width_nz = NonZeroU32::new(width)
            .ok_or_else(|| anyhow::anyhow!("Width cannot be zero"))?;
        let height_nz = NonZeroU32::new(height)
            .ok_or_else(|| anyhow::anyhow!("Height cannot be zero"))?;

        let src_fr = fr::Image::from_vec_u8(
            src_width_nz,
            src_height_nz,
            src_image.into_raw(),
            fr::PixelType::U8x4,
        )?;

        let mut dst_fr = fr::Image::new(width_nz, height_nz, fr::PixelType::U8x4);
        let mut resizer = fr::Resizer::new(fr::ResizeAlg::Convolution(filter));
        resizer.resize(&src_fr.view(), &mut dst_fr.view_mut())?;

        let buffer = ImageBuffer::from_raw(width, height, dst_fr.into_vec())
            .ok_or_else(|| anyhow::anyhow!("Failed to create image buffer"))?;
        Ok(DynamicImage::ImageRgba8(buffer))
    }

    pub async fn resize_to_fit(
        &mut self,
        handle: u32,
        max_width: u32,
        max_height: u32,
        filter: ResizeFilter,
    ) -> anyhow::Result<()> {
        let (current_width, current_height) = self.get_dimensions(handle)?;
        let ratio = ((max_width as f32 / current_width as f32)
            .min(max_height as f32 / current_height as f32))
            .min(1.0);
        let new_width = (current_width as f32 * ratio) as u32;
        let new_height = (current_height as f32 * ratio) as u32;
        self.resize(handle, new_width, new_height, filter).await
    }

    pub async fn resize_to_fill(
        &mut self,
        handle: u32,
        width: u32,
        height: u32,
        filter: ResizeFilter,
    ) -> anyhow::Result<()> {
        let (current_width, current_height) = self.get_dimensions(handle)?;
        let ratio = (width as f32 / current_width as f32)
            .max(height as f32 / current_height as f32);
        let new_width = (current_width as f32 * ratio) as u32;
        let new_height = (current_height as f32 * ratio) as u32;
        self.resize(handle, new_width, new_height, filter).await?;
        let x = (new_width - width) / 2;
        let y = (new_height - height) / 2;
        self.crop(handle, CropParams { x, y, width, height }).await
    }

    pub async fn crop(&mut self, handle: u32, params: CropParams) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let old_mem = Self::image_memory(img);
        let owned = std::mem::take(img);
        let cropped = tokio::task::spawn_blocking(move || {
            owned.crop_imm(params.x, params.y, params.width, params.height)
        }).await?;

        let new_mem = Self::image_memory(&cropped);
        let dims = cropped.dimensions();

        self.current_memory_bytes = self.current_memory_bytes - old_mem + new_mem;
        self.dimensions_cache.insert(handle, dims);
        *img = cropped;
        self.touch(handle);
        self.evict_if_needed();
        Ok(())
    }

    /// Rotate image (90, 180, 270 degrees)
    pub async fn rotate(&mut self, handle: u32, degrees: i32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let owned = std::mem::take(img);
        let rotated = tokio::task::spawn_blocking(move || {
            match degrees % 360 {
                90 | -270 => owned.rotate90(),
                180 | -180 => owned.rotate180(),
                270 | -90 => owned.rotate270(),
                _ => owned,
            }
        }).await?;

        // Rotation does not change dimensions, so memory stays the same.
        *img = rotated;
        self.touch(handle);
        Ok(())
    }

    /// Flip horizontal
    pub async fn flip_horizontal(&mut self, handle: u32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let owned = std::mem::take(img);
        let flipped = tokio::task::spawn_blocking(move || owned.fliph()).await?;
        *img = flipped;
        self.touch(handle);
        Ok(())
    }

    /// Flip vertical
    pub async fn flip_vertical(&mut self, handle: u32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let owned = std::mem::take(img);
        let flipped = tokio::task::spawn_blocking(move || owned.flipv()).await?;
        *img = flipped;
        self.touch(handle);
        Ok(())
    }

    // ------------------------------------------------------------------------
    // FILTER OPERATIONS
    // ------------------------------------------------------------------------

    /// Apply filter
    pub async fn apply_filter(&mut self, handle: u32, filter: FilterType) -> anyhow::Result<()> {
        match filter {
            FilterType::Grayscale => self.grayscale(handle).await,
            FilterType::Sepia => self.sepia(handle).await,
            FilterType::Invert => self.invert(handle).await,
            FilterType::Blur => self.blur(handle, 2.0).await,
            FilterType::Sharpen => self.sharpen(handle, 1.0).await,
            FilterType::EdgeDetect => self.edge_detect(handle).await,
            FilterType::Emboss => self.emboss(handle).await,
        }
    }

    /// Convert to grayscale (memory changes from RGBA → Luma)
    pub async fn grayscale(&mut self, handle: u32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let old_mem = Self::image_memory(img);
        let owned = std::mem::take(img);
        let gray = tokio::task::spawn_blocking(move || {
            DynamicImage::ImageLuma8(owned.to_luma8())
        }).await?;

        let new_mem = Self::image_memory(&gray);
        self.current_memory_bytes = self.current_memory_bytes - old_mem + new_mem;
        *img = gray;
        self.touch(handle);
        self.evict_if_needed();
        Ok(())
    }

    /// Invert colors (memory unchanged)
    pub async fn invert(&mut self, handle: u32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let mut owned = std::mem::take(img);
        owned = tokio::task::spawn_blocking(move || {
            owned.invert();
            owned
        }).await?;
        *img = owned;
        self.touch(handle);
        Ok(())
    }

    /// Apply Gaussian blur (memory unchanged)
    pub async fn blur(&mut self, handle: u32, sigma: f32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let owned = std::mem::take(img);
        let blurred = tokio::task::spawn_blocking(move || owned.blur(sigma)).await?;
        *img = blurred;
        self.touch(handle);
        Ok(())
    }

    /// Sharpen image (memory unchanged)
    pub async fn sharpen(&mut self, handle: u32, amount: f32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let owned = std::mem::take(img);
        let sharpened = tokio::task::spawn_blocking(move || {
            Self::apply_sharpen(owned, amount)
        }).await?;
        *img = sharpened;
        self.touch(handle);
        Ok(())
    }

    // Work in native format, only convert to RGBA once
    fn apply_sharpen(img: DynamicImage, amount: f32) -> DynamicImage {
        match img {
            DynamicImage::ImageLuma8(luma) => {
                let (width, height) = luma.dimensions();
                let data = luma.as_raw();
                let stride = width as usize;
                let mut result = vec![0u8; data.len()];

                for y in 1..height - 1 {
                    for x in 1..width - 1 {
                        let center_idx = (y as usize * stride + x as usize) as usize;
                        let mut sum = 0.0_f32;

                        for dy in [-1, 0, 1].iter() {
                            for dx in [-1, 0, 1].iter() {
                                let ny = (y as i32 + dy) as u32;
                                let nx = (x as i32 + dx) as u32;
                                let neighbor_idx = (ny as usize * stride + nx as usize) as usize;
                                let weight = if *dx == 0 && *dy == 0 { 8.0 } else { -1.0 };
                                sum += data[neighbor_idx] as f32 * weight;
                            }
                        }

                        let orig = data[center_idx] as f32;
                        let sharpened = orig + (sum * amount * 0.125);
                        result[center_idx] = sharpened.clamp(0.0, 255.0) as u8;
                    }
                }

                DynamicImage::ImageLuma8(ImageBuffer::from_raw(width, height, result)
                    .expect("Failed to create sharpened image"))
            }
            DynamicImage::ImageRgb8(rgb) => {
                let (width, height) = rgb.dimensions();
                let data = rgb.as_raw();
                let stride = (width * 3) as usize;
                let mut result = vec![0u8; data.len()];

                for y in 1..height - 1 {
                    for x in 1..width - 1 {
                        for c in 0..3 {
                            let center_idx = (y as usize * stride + x as usize * 3 + c) as usize;
                            let mut sum = 0.0_f32;

                            for dy in [-1, 0, 1].iter() {
                                for dx in [-1, 0, 1].iter() {
                                    let ny = (y as i32 + dy) as u32;
                                    let nx = (x as i32 + dx) as u32;
                                    let neighbor_idx = (ny as usize * stride + nx as usize * 3 + c) as usize;
                                    let weight = if *dx == 0 && *dy == 0 { 8.0 } else { -1.0 };
                                    sum += data[neighbor_idx] as f32 * weight;
                                }
                            }

                            let orig = data[center_idx] as f32;
                            let sharpened = orig + (sum * amount * 0.125);
                            result[center_idx] = sharpened.clamp(0.0, 255.0) as u8;
                        }
                    }
                }

                DynamicImage::ImageRgb8(ImageBuffer::from_raw(width, height, result)
                    .expect("Failed to create sharpened image"))
            }
            _ => {
                // Fallback to RGBA only if needed
                let mut rgba = img.to_rgba8();
                let (width, height) = rgba.dimensions();
                let data = rgba.as_mut();

                for y in 1..height - 1 {
                    for x in 1..width - 1 {
                        for c in 0..3 {
                            let center_idx = (y as usize * width as usize * 4 + x as usize * 4 + c) as usize;
                            let mut sum = 0.0_f32;

                            for dy in [-1, 0, 1].iter() {
                                for dx in [-1, 0, 1].iter() {
                                    let ny = (y as i32 + dy) as u32;
                                    let nx = (x as i32 + dx) as u32;
                                    let neighbor_idx = (ny as usize * width as usize * 4 + nx as usize * 4 + c) as usize;
                                    let weight = if *dx == 0 && *dy == 0 { 8.0 } else { -1.0 };
                                    sum += data[neighbor_idx] as f32 * weight;
                                }
                            }

                            let orig = data[center_idx] as f32;
                            let sharpened = orig + (sum * amount * 0.125);
                            data[center_idx] = sharpened.clamp(0.0, 255.0) as u8;
                        }
                    }
                }

                DynamicImage::ImageRgba8(rgba)
            }
        }
    }

    async fn sepia(&mut self, handle: u32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let owned = std::mem::take(img);
        let sepia = tokio::task::spawn_blocking(move || {
            Self::apply_sepia_native(owned)
        }).await?;
        *img = sepia;
        self.touch(handle);
        Ok(())
    }

    // Apply sepia in native format
    fn apply_sepia_native(img: DynamicImage) -> DynamicImage {
        match img {
            DynamicImage::ImageRgb8(mut rgb) => {
                for pixel in rgb.pixels_mut() {
                    let r = pixel[0] as f32;
                    let g = pixel[1] as f32;
                    let b = pixel[2] as f32;
                    pixel[0] = ((r * 0.393) + (g * 0.769) + (b * 0.189)).min(255.0) as u8;
                    pixel[1] = ((r * 0.349) + (g * 0.686) + (b * 0.168)).min(255.0) as u8;
                    pixel[2] = ((r * 0.272) + (g * 0.534) + (b * 0.131)).min(255.0) as u8;
                }
                DynamicImage::ImageRgb8(rgb)
            }
            DynamicImage::ImageRgba8(mut rgba) => {
                for pixel in rgba.pixels_mut() {
                    let r = pixel[0] as f32;
                    let g = pixel[1] as f32;
                    let b = pixel[2] as f32;
                    pixel[0] = ((r * 0.393) + (g * 0.769) + (b * 0.189)).min(255.0) as u8;
                    pixel[1] = ((r * 0.349) + (g * 0.686) + (b * 0.168)).min(255.0) as u8;
                    pixel[2] = ((r * 0.272) + (g * 0.534) + (b * 0.131)).min(255.0) as u8;
                }
                DynamicImage::ImageRgba8(rgba)
            }
            _ => {
                // Only convert if absolutely necessary
                let mut rgba = img.to_rgba8();
                for pixel in rgba.pixels_mut() {
                    let r = pixel[0] as f32;
                    let g = pixel[1] as f32;
                    let b = pixel[2] as f32;
                    pixel[0] = ((r * 0.393) + (g * 0.769) + (b * 0.189)).min(255.0) as u8;
                    pixel[1] = ((r * 0.349) + (g * 0.686) + (b * 0.168)).min(255.0) as u8;
                    pixel[2] = ((r * 0.272) + (g * 0.534) + (b * 0.131)).min(255.0) as u8;
                }
                DynamicImage::ImageRgba8(rgba)
            }
        }
    }

    async fn edge_detect(&mut self, handle: u32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let old_mem = Self::image_memory(img);
        let owned = std::mem::take(img);
        let edges = tokio::task::spawn_blocking(move || {
            Self::apply_sobel_edge_detection(owned)
        }).await?;

        let new_mem = Self::image_memory(&edges);
        self.current_memory_bytes = self.current_memory_bytes - old_mem + new_mem;
        *img = edges;
        self.touch(handle);
        self.evict_if_needed();
        Ok(())
    }

    // Convert once at the start, process in Luma8
    fn apply_sobel_edge_detection(img: DynamicImage) -> DynamicImage {
        let gray = img.to_luma8();
        let (width, height) = gray.dimensions();
        let data = gray.as_raw();
        let stride = width as usize;

        let mut result = vec![0u8; data.len()];

        for y in 1..height - 1 {
            let row_start = (y as usize - 1) * stride;
            for x in 1..width - 1 {
                let center = y as usize * stride + x as usize;

                let tl = data[row_start + x as usize - 1] as f32;
                let t  = data[row_start + x as usize] as f32;
                let tr = data[row_start + x as usize + 1] as f32;
                let l  = data[center - 1] as f32;
                let r  = data[center + 1] as f32;
                let bl = data[center + stride - 1] as f32;
                let b  = data[center + stride] as f32;
                let br = data[center + stride + 1] as f32;

                let gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
                let gy = -tl - 2.0*t - tr + bl + 2.0*b + br;

                let magnitude = (gx * gx + gy * gy).sqrt().min(255.0) as u8;
                result[center] = magnitude;
            }
        }

        ImageBuffer::from_raw(width, height, result)
            .map(DynamicImage::ImageLuma8)
            .expect("Failed to create edge detection result")
    }

    async fn emboss(&mut self, handle: u32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let old_mem = Self::image_memory(img);
        let owned = std::mem::take(img);
        let embossed = tokio::task::spawn_blocking(move || {
            Self::apply_emboss(owned)
        }).await?;

        let new_mem = Self::image_memory(&embossed);
        self.current_memory_bytes = self.current_memory_bytes - old_mem + new_mem;
        *img = embossed;
        self.touch(handle);
        self.evict_if_needed();
        Ok(())
    }

    fn apply_emboss(img: DynamicImage) -> DynamicImage {
        let gray = img.to_luma8();
        let (width, height) = gray.dimensions();
        let data = gray.as_raw();
        let stride = width as usize;

        let mut result = vec![0u8; data.len()];

        for y in 1..height - 1 {
            let row_start = (y as usize - 1) * stride;
            for x in 1..width - 1 {
                let center = y as usize * stride + x as usize;

                let tl = data[row_start + x as usize - 1] as f32;
                let t  = data[row_start + x as usize] as f32;
                let tr = data[row_start + x as usize + 1] as f32;
                let l  = data[center - 1] as f32;
                let c  = data[center] as f32;
                let r  = data[center + 1] as f32;
                let bl = data[center + stride - 1] as f32;
                let b  = data[center + stride] as f32;
                let br = data[center + stride + 1] as f32;

                let sum = -2.0*tl - t + tr - l + c + r + bl + b + 2.0*br;
                result[center] = (sum + 128.0).clamp(0.0, 255.0) as u8;
            }
        }

        ImageBuffer::from_raw(width, height, result)
            .map(DynamicImage::ImageLuma8)
            .expect("Failed to create emboss result")
    }

    // ====== ADJUSTMENTS ======

    pub async fn adjust_brightness(&mut self, handle: u32, value: i32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let mut owned = std::mem::take(img);
        owned = tokio::task::spawn_blocking(move || owned.brighten(value)).await?;
        *img = owned;
        self.touch(handle);
        Ok(())
    }

    pub async fn adjust_contrast(&mut self, handle: u32, value: i32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let contrast_factor = (value as f32 / 100.0) + 1.0;
        let owned = std::mem::take(img);
        let adjusted = tokio::task::spawn_blocking(move || {
            Self::adjust_contrast_impl(owned, contrast_factor)
        }).await?;
        *img = adjusted;
        self.touch(handle);
        Ok(())
    }

    pub async fn adjust_saturation(&mut self, handle: u32, value: i32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let saturation_factor = (value as f32 / 100.0) + 1.0;
        let owned = std::mem::take(img);
        let adjusted = tokio::task::spawn_blocking(move || {
            Self::adjust_saturation_impl(owned, saturation_factor)
        }).await?;
        *img = adjusted;
        self.touch(handle);
        Ok(())
    }

    pub async fn adjust_hue(&mut self, handle: u32, value: i32) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let hue_shift = value as f32;
        let owned = std::mem::take(img);
        let adjusted = tokio::task::spawn_blocking(move || {
            Self::adjust_hue_impl(owned, hue_shift)
        }).await?;
        *img = adjusted;
        self.touch(handle);
        Ok(())
    }

    pub async fn adjust_all(&mut self, handle: u32, params: AdjustmentParams) -> anyhow::Result<()> {
        let img = self.images.get_mut(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;

        let owned = std::mem::take(img);
        let adjusted = tokio::task::spawn_blocking(move || {
            let mut result = owned;
            if params.brightness != 0 {
                result = result.brighten(params.brightness);
            }
            if params.contrast != 0 {
                let contrast_factor = (params.contrast as f32 / 100.0) + 1.0;
                result = Self::adjust_contrast_impl(result, contrast_factor);
            }
            if params.saturation != 0 {
                let saturation_factor = (params.saturation as f32 / 100.0) + 1.0;
                result = Self::adjust_saturation_impl(result, saturation_factor);
            }
            if params.hue != 0 {
                result = Self::adjust_hue_impl(result, params.hue as f32);
            }
            result
        }).await?;
        *img = adjusted;
        self.touch(handle);
        Ok(())
    }

    // Work in native format to avoid conversions
    fn adjust_contrast_impl(img: DynamicImage, factor: f32) -> DynamicImage {
        match img {
            DynamicImage::ImageLuma8(mut luma) => {
                for pixel in luma.pixels_mut() {
                    let value = pixel[0] as f32;
                    let adjusted = ((value - 128.0) * factor + 128.0).clamp(0.0, 255.0);
                    pixel[0] = adjusted as u8;
                }
                DynamicImage::ImageLuma8(luma)
            }
            DynamicImage::ImageRgb8(mut rgb) => {
                for pixel in rgb.pixels_mut() {
                    for channel in 0..3 {
                        let value = pixel[channel] as f32;
                        let adjusted = ((value - 128.0) * factor + 128.0).clamp(0.0, 255.0);
                        pixel[channel] = adjusted as u8;
                    }
                }
                DynamicImage::ImageRgb8(rgb)
            }
            DynamicImage::ImageRgba8(mut rgba) => {
                for pixel in rgba.pixels_mut() {
                    for channel in 0..3 {
                        let value = pixel[channel] as f32;
                        let adjusted = ((value - 128.0) * factor + 128.0).clamp(0.0, 255.0);
                        pixel[channel] = adjusted as u8;
                    }
                }
                DynamicImage::ImageRgba8(rgba)
            }
            _ => {
                let mut rgba = img.to_rgba8();
                for pixel in rgba.pixels_mut() {
                    for channel in 0..3 {
                        let value = pixel[channel] as f32;
                        let adjusted = ((value - 128.0) * factor + 128.0).clamp(0.0, 255.0);
                        pixel[channel] = adjusted as u8;
                    }
                }
                DynamicImage::ImageRgba8(rgba)
            }
        }
    }

    fn adjust_saturation_impl(img: DynamicImage, factor: f32) -> DynamicImage {
        match img {
            DynamicImage::ImageRgb8(mut rgb) => {
                for pixel in rgb.pixels_mut() {
                    let (h, s, l) = Self::rgb_to_hsl(pixel[0], pixel[1], pixel[2]);
                    let new_s = (s * factor).clamp(0.0, 1.0);
                    let (r, g, b) = Self::hsl_to_rgb(h, new_s, l);
                    pixel[0] = r;
                    pixel[1] = g;
                    pixel[2] = b;
                }
                DynamicImage::ImageRgb8(rgb)
            }
            DynamicImage::ImageRgba8(mut rgba) => {
                for pixel in rgba.pixels_mut() {
                    let (h, s, l) = Self::rgb_to_hsl(pixel[0], pixel[1], pixel[2]);
                    let new_s = (s * factor).clamp(0.0, 1.0);
                    let (r, g, b) = Self::hsl_to_rgb(h, new_s, l);
                    pixel[0] = r;
                    pixel[1] = g;
                    pixel[2] = b;
                }
                DynamicImage::ImageRgba8(rgba)
            }
            _ => {
                let mut rgba = img.to_rgba8();
                for pixel in rgba.pixels_mut() {
                    let (h, s, l) = Self::rgb_to_hsl(pixel[0], pixel[1], pixel[2]);
                    let new_s = (s * factor).clamp(0.0, 1.0);
                    let (r, g, b) = Self::hsl_to_rgb(h, new_s, l);
                    pixel[0] = r;
                    pixel[1] = g;
                    pixel[2] = b;
                }
                DynamicImage::ImageRgba8(rgba)
            }
        }
    }

    fn adjust_hue_impl(img: DynamicImage, shift: f32) -> DynamicImage {
        match img {
            DynamicImage::ImageRgb8(mut rgb) => {
                for pixel in rgb.pixels_mut() {
                    let (h, s, l) = Self::rgb_to_hsl(pixel[0], pixel[1], pixel[2]);
                    let new_h = (h + shift) % 360.0;
                    let (r, g, b) = Self::hsl_to_rgb(new_h, s, l);
                    pixel[0] = r;
                    pixel[1] = g;
                    pixel[2] = b;
                }
                DynamicImage::ImageRgb8(rgb)
            }
            DynamicImage::ImageRgba8(mut rgba) => {
                for pixel in rgba.pixels_mut() {
                    let (h, s, l) = Self::rgb_to_hsl(pixel[0], pixel[1], pixel[2]);
                    let new_h = (h + shift) % 360.0;
                    let (r, g, b) = Self::hsl_to_rgb(new_h, s, l);
                    pixel[0] = r;
                    pixel[1] = g;
                    pixel[2] = b;
                }
                DynamicImage::ImageRgba8(rgba)
            }
            _ => {
                let mut rgba = img.to_rgba8();
                for pixel in rgba.pixels_mut() {
                    let (h, s, l) = Self::rgb_to_hsl(pixel[0], pixel[1], pixel[2]);
                    let new_h = (h + shift) % 360.0;
                    let (r, g, b) = Self::hsl_to_rgb(new_h, s, l);
                    pixel[0] = r;
                    pixel[1] = g;
                    pixel[2] = b;
                }
                DynamicImage::ImageRgba8(rgba)
            }
        }
    }

    #[inline]
    fn rgb_to_hsl(r: u8, g: u8, b: u8) -> (f32, f32, f32) {
        let r = r as f32 / 255.0;
        let g = g as f32 / 255.0;
        let b = b as f32 / 255.0;
        let max = r.max(g).max(b);
        let min = r.min(g).min(b);
        let delta = max - min;
        let l = (max + min) / 2.0;
        if delta == 0.0 {
            return (0.0, 0.0, l);
        }
        let s = if l < 0.5 {
            delta / (max + min)
        } else {
            delta / (2.0 - max - min)
        };
        let h = if max == r {
            60.0 * (((g - b) / delta) % 6.0)
        } else if max == g {
            60.0 * (((b - r) / delta) + 2.0)
        } else {
            60.0 * (((r - g) / delta) + 4.0)
        };
        let h = if h < 0.0 { h + 360.0 } else { h };
        (h, s, l)
    }

    #[inline]
    fn hsl_to_rgb(h: f32, s: f32, l: f32) -> (u8, u8, u8) {
        let c = (1.0 - (2.0 * l - 1.0).abs()) * s;
        let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
        let m = l - c / 2.0;
        let (r, g, b) = if h < 60.0 {
            (c, x, 0.0)
        } else if h < 120.0 {
            (x, c, 0.0)
        } else if h < 180.0 {
            (0.0, c, x)
        } else if h < 240.0 {
            (0.0, x, c)
        } else if h < 300.0 {
            (x, 0.0, c)
        } else {
            (c, 0.0, x)
        };
        (
            ((r + m) * 255.0) as u8,
            ((g + m) * 255.0) as u8,
            ((b + m) * 255.0) as u8,
        )
    }

    // ====== COMPOSITE OPERATIONS ======

    pub async fn add_watermark(
        &mut self,
        handle: u32,
        watermark_handle: u32,
        params: WatermarkParams,
    ) -> anyhow::Result<()> {
        let base = self.images.remove(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;
        let old_mem = Self::image_memory(&base);
        if let Some(pos) = self.access_order.iter().position(|&h| h == handle) {
            self.access_order.remove(pos);
        }

        let watermark = self.images.get(&watermark_handle)
            .ok_or_else(|| anyhow::anyhow!("Watermark handle {} not found", watermark_handle))?
            .clone();

        let result = tokio::task::spawn_blocking(move || {
            Self::composite_watermark(base, watermark, params)
        }).await??;

        let new_mem = Self::image_memory(&result);
        let dims = result.dimensions();

        self.current_memory_bytes = self.current_memory_bytes - old_mem + new_mem;
        self.dimensions_cache.insert(handle, dims);
        self.images.insert(handle, result);
        self.access_order.push_back(handle);
        self.evict_if_needed();
        Ok(())
    }

    pub async fn overlay(
        &mut self,
        handle: u32,
        overlay_handle: u32,
        x: i32,
        y: i32,
        opacity: f32,
    ) -> anyhow::Result<()> {
        let base = self.images.remove(&handle)
            .ok_or_else(|| anyhow::anyhow!("Image handle {} not found", handle))?;
        let old_mem = Self::image_memory(&base);
        if let Some(pos) = self.access_order.iter().position(|&h| h == handle) {
            self.access_order.remove(pos);
        }

        let overlay = self.images.get(&overlay_handle)
            .ok_or_else(|| anyhow::anyhow!("Overlay handle {} not found", overlay_handle))?
            .clone();

        let result = tokio::task::spawn_blocking(move || {
            Self::composite_overlay(base, overlay, x, y, opacity)
        }).await??;

        let new_mem = Self::image_memory(&result);
        let dims = result.dimensions();

        self.current_memory_bytes = self.current_memory_bytes - old_mem + new_mem;
        self.dimensions_cache.insert(handle, dims);
        self.images.insert(handle, result);
        self.access_order.push_back(handle);
        self.evict_if_needed();
        Ok(())
    }

    fn composite_watermark(
        base: DynamicImage,
        watermark: DynamicImage,
        params: WatermarkParams,
    ) -> anyhow::Result<DynamicImage> {
        let (base_width, base_height) = base.dimensions();
        let (wm_width, wm_height) = watermark.dimensions();

        let scaled_watermark = if (params.scale - 1.0).abs() > 0.001 {
            let new_width = (wm_width as f32 * params.scale) as u32;
            let new_height = (wm_height as f32 * params.scale) as u32;
            watermark.resize(new_width, new_height, image::imageops::FilterType::Triangle)
        } else {
            watermark
        };

        let (wm_width, wm_height) = scaled_watermark.dimensions();
        let (x, y) = match params.position {
            Position::TopLeft => (0, 0),
            Position::TopCenter => ((base_width.saturating_sub(wm_width)) / 2, 0),
            Position::TopRight => (base_width.saturating_sub(wm_width), 0),
            Position::CenterLeft => (0, (base_height.saturating_sub(wm_height)) / 2),
            Position::Center => ((base_width.saturating_sub(wm_width)) / 2, (base_height.saturating_sub(wm_height)) / 2),
            Position::CenterRight => (base_width.saturating_sub(wm_width), (base_height.saturating_sub(wm_height)) / 2),
            Position::BottomLeft => (0, base_height.saturating_sub(wm_height)),
            Position::BottomCenter => ((base_width.saturating_sub(wm_width)) / 2, base_height.saturating_sub(wm_height)),
            Position::BottomRight => (base_width.saturating_sub(wm_width), base_height.saturating_sub(wm_height)),
            Position::Custom(cx, cy) => (cx as u32, cy as u32),
        };

        // Convert both to RGBA only once
        let wm_rgba = scaled_watermark.to_rgba8();
        let mut base_rgba = base.to_rgba8();
        let base_data = base_rgba.as_mut();
        let wm_data = wm_rgba.as_raw();

        let base_stride = (base_width * 4) as usize;
        let wm_stride = (wm_width * 4) as usize;

        for dy in 0..wm_height {
            let py = y + dy;
            if py >= base_height {
                break;
            }

            let base_row = (py as usize * base_stride) as usize;
            let wm_row = (dy as usize * wm_stride) as usize;

            for dx in 0..wm_width {
                let px = x + dx;
                if px >= base_width {
                    break;
                }

                let base_idx = base_row + (px as usize * 4);
                let wm_idx = wm_row + (dx as usize * 4);

                let alpha = (wm_data[wm_idx + 3] as f32 / 255.0) * params.opacity;
                for i in 0..3 {
                    let fg = wm_data[wm_idx + i] as f32;
                    let bg = base_data[base_idx + i] as f32;
                    base_data[base_idx + i] = ((fg * alpha) + (bg * (1.0 - alpha))) as u8;
                }
            }
        }
        Ok(DynamicImage::ImageRgba8(base_rgba))
    }

    fn composite_overlay(
        base: DynamicImage,
        overlay: DynamicImage,
        x: i32,
        y: i32,
        opacity: f32,
    ) -> anyhow::Result<DynamicImage> {
        let (base_width, base_height) = base.dimensions();
        let (overlay_width, overlay_height) = overlay.dimensions();

        // Convert both to RGBA only once
        let mut base_rgba = base.to_rgba8();
        let overlay_rgba = overlay.to_rgba8();

        let base_data = base_rgba.as_mut();
        let overlay_data = overlay_rgba.as_raw();

        let base_stride = (base_width * 4) as usize;
        let overlay_stride = (overlay_width * 4) as usize;

        for dy in 0..overlay_height {
            let py = y + dy as i32;
            if py < 0 || py >= base_height as i32 {
                continue;
            }

            let base_row = (py as usize * base_stride) as usize;
            let overlay_row = (dy as usize * overlay_stride) as usize;

            for dx in 0..overlay_width {
                let px = x + dx as i32;
                if px < 0 || px >= base_width as i32 {
                    continue;
                }

                let base_idx = base_row + (px as usize * 4);
                let overlay_idx = overlay_row + (dx as usize * 4);

                let alpha = (overlay_data[overlay_idx + 3] as f32 / 255.0) * opacity;
                for i in 0..3 {
                    let fg = overlay_data[overlay_idx + i] as f32;
                    let bg = base_data[base_idx + i] as f32;
                    base_data[base_idx + i] = ((fg * alpha) + (bg * (1.0 - alpha))) as u8;
                }
            }
        }
        Ok(DynamicImage::ImageRgba8(base_rgba))
    }
}