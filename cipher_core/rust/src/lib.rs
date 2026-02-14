mod frb_generated;

use sha2::{Sha224, Sha256, Sha384, Sha512, Digest};
use sha1::Sha1;
use md5::Md5;
use hmac::{Hmac, Mac};
use aes_gcm::{Aes256Gcm, Key, Nonce};
use aes_gcm::aead::{Aead, Payload, KeyInit};

// Type aliases for HMAC variants
type HmacMd5 = Hmac<Md5>;
type HmacSha1 = Hmac<Sha1>;
type HmacSha224 = Hmac<Sha224>;
type HmacSha256 = Hmac<Sha256>;
type HmacSha384 = Hmac<Sha384>;
type HmacSha512 = Hmac<Sha512>;

// ============================================================================
// ULTRA-FAST SYNC HASH FUNCTIONS (Zero overhead, <5µs)
// ============================================================================
// Use these for small data (<100KB) - they're 10-50x faster than async!

/// SHA-256 SYNC - Use for hot paths and small data
/// ~1-5µs for typical inputs
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha256_sync(data: Vec<u8>) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 32];
    output.copy_from_slice(&result);
    output
}

/// SHA-512 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha512_sync(data: Vec<u8>) -> [u8; 64] {
    let mut hasher = Sha512::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 64];
    output.copy_from_slice(&result);
    output
}

/// SHA-1 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha1_sync(data: Vec<u8>) -> [u8; 20] {
    let mut hasher = Sha1::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 20];
    output.copy_from_slice(&result);
    output
}

/// SHA-384 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha384_sync(data: Vec<u8>) -> [u8; 48] {
    let mut hasher = Sha384::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 48];
    output.copy_from_slice(&result);
    output
}

/// SHA-224 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha224_sync(data: Vec<u8>) -> [u8; 28] {
    let mut hasher = Sha224::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 28];
    output.copy_from_slice(&result);
    output
}

/// MD5 SYNC - WARNING: Cryptographically broken
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn md5_sync(data: Vec<u8>) -> [u8; 16] {
    let mut hasher = Md5::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 16];
    output.copy_from_slice(&result);
    output
}

/// SHA-512/256 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha512_256_sync(data: Vec<u8>) -> [u8; 32] {
    use sha2::Sha512_256;
    let mut hasher = Sha512_256::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 32];
    output.copy_from_slice(&result);
    output
}

/// SHA-512/224 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha512_224_sync(data: Vec<u8>) -> [u8; 28] {
    use sha2::Sha512_224;
    let mut hasher = Sha512_224::new();
    hasher.update(&data);
    let result = hasher.finalize();
    let mut output = [0u8; 28];
    output.copy_from_slice(&result);
    output
}

// ============================================================================
// ASYNC HASH FUNCTIONS (For large data or non-blocking)
// ============================================================================
// Use these for large files (>100KB) to avoid blocking the UI

/// SHA-256 ASYNC - Use for large data to avoid UI blocking
pub fn sha256_async(data: Vec<u8>) -> [u8; 32] {
    sha256_sync(data)
}

pub fn sha512_async(data: Vec<u8>) -> [u8; 64] {
    sha512_sync(data)
}

pub fn sha1_async(data: Vec<u8>) -> [u8; 20] {
    sha1_sync(data)
}

pub fn sha384_async(data: Vec<u8>) -> [u8; 48] {
    sha384_sync(data)
}

pub fn md5_async(data: Vec<u8>) -> [u8; 16] {
    md5_sync(data)
}

// ============================================================================
// ULTRA-FAST SYNC HMAC FUNCTIONS
// ============================================================================

/// HMAC-SHA256 SYNC - Hardware accelerated, ~2-8µs
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha256_sync(key: Vec<u8>, data: Vec<u8>) -> [u8; 32] {
    let mut mac = <HmacSha256 as Mac>::new_from_slice(&key)
        .expect("HMAC can take key of any size");
    mac.update(&data);
    let result = mac.finalize().into_bytes();
    let mut output = [0u8; 32];
    output.copy_from_slice(&result);
    output
}

/// HMAC-SHA512 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha512_sync(key: Vec<u8>, data: Vec<u8>) -> [u8; 64] {
    let mut mac = <HmacSha512 as Mac>::new_from_slice(&key)
        .expect("HMAC can take key of any size");
    mac.update(&data);
    let result = mac.finalize().into_bytes();
    let mut output = [0u8; 64];
    output.copy_from_slice(&result);
    output
}

/// HMAC-SHA1 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha1_sync(key: Vec<u8>, data: Vec<u8>) -> [u8; 20] {
    let mut mac = <HmacSha1 as Mac>::new_from_slice(&key)
        .expect("HMAC can take key of any size");
    mac.update(&data);
    let result = mac.finalize().into_bytes();
    let mut output = [0u8; 20];
    output.copy_from_slice(&result);
    output
}

/// HMAC-SHA384 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha384_sync(key: Vec<u8>, data: Vec<u8>) -> [u8; 48] {
    let mut mac = <HmacSha384 as Mac>::new_from_slice(&key)
        .expect("HMAC can take key of any size");
    mac.update(&data);
    let result = mac.finalize().into_bytes();
    let mut output = [0u8; 48];
    output.copy_from_slice(&result);
    output
}

/// HMAC-SHA224 SYNC
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha224_sync(key: Vec<u8>, data: Vec<u8>) -> [u8; 28] {
    let mut mac = <HmacSha224 as Mac>::new_from_slice(&key)
        .expect("HMAC can take key of any size");
    mac.update(&data);
    let result = mac.finalize().into_bytes();
    let mut output = [0u8; 28];
    output.copy_from_slice(&result);
    output
}

/// HMAC-MD5 SYNC - WARNING: Cryptographically broken
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_md5_sync(key: Vec<u8>, data: Vec<u8>) -> [u8; 16] {
    let mut mac = <HmacMd5 as Mac>::new_from_slice(&key)
        .expect("HMAC can take key of any size");
    mac.update(&data);
    let result = mac.finalize().into_bytes();
    let mut output = [0u8; 16];
    output.copy_from_slice(&result);
    output
}

// ASYNC HMAC wrappers
pub fn hmac_sha256_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 32] {
    hmac_sha256_sync(key, data)
}

pub fn hmac_sha512_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 64] {
    hmac_sha512_sync(key, data)
}

// ============================================================================
// ULTRA-FAST SYNC AES-256-GCM (Returns raw bytes, not String)
// ============================================================================

/// AES-256-GCM SYNC Encryption - Returns raw ciphertext bytes
/// ~50-150µs for <2KB data
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn aes256_encrypt_sync(plaintext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    if key.len() != 32 {
        return None;
    }

    let key = Key::<Aes256Gcm>::from_slice(&key);
    let cipher = Aes256Gcm::new(key);
    let nonce = Nonce::from_slice(&[0u8; 12]);

    cipher.encrypt(nonce, Payload::from(&plaintext[..])).ok()
}

/// AES-256-GCM SYNC Decryption - Takes raw ciphertext bytes
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn aes256_decrypt_sync(ciphertext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    if key.len() != 32 {
        return None;
    }

    let key = Key::<Aes256Gcm>::from_slice(&key);
    let cipher = Aes256Gcm::new(key);
    let nonce = Nonce::from_slice(&[0u8; 12]);

    cipher.decrypt(nonce, Payload::from(&ciphertext[..])).ok()
}

// ASYNC AES wrappers
pub fn aes256_encrypt_async(plaintext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    aes256_encrypt_sync(plaintext, key)
}

pub fn aes256_decrypt_async(ciphertext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    aes256_decrypt_sync(ciphertext, key)
}

// ============================================================================
// BATCH OPERATIONS (Process multiple at once - saves FFI overhead)
// ============================================================================

/// Hash multiple inputs in one FFI call - HUGE performance win
/// Example: 1000 hashes in ~5ms instead of ~50ms
#[flutter_rust_bridge::frb(sync)]
pub fn sha256_batch_sync(inputs: Vec<Vec<u8>>) -> Vec<[u8; 32]> {
    inputs.iter()
        .map(|data| sha256_sync(data.clone()))
        .collect()
}

/// HMAC batch processing
#[flutter_rust_bridge::frb(sync)]
pub fn hmac_sha256_batch_sync(key: Vec<u8>, messages: Vec<Vec<u8>>) -> Vec<[u8; 32]> {
    messages.iter()
        .map(|msg| hmac_sha256_sync(key.clone(), msg.clone()))
        .collect()
}

// ============================================================================
// COMBINED OPERATIONS (Single FFI call)
// ============================================================================

/// Hash then encrypt in one operation - saves FFI roundtrip
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hash_then_encrypt_sync(data: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    if key.len() != 32 {
        return None;
    }

    let hash = sha256_sync(data);
    let key_slice = Key::<Aes256Gcm>::from_slice(&key);
    let cipher = Aes256Gcm::new(key_slice);
    let nonce = Nonce::from_slice(&[0u8; 12]);

    cipher.encrypt(nonce, Payload::from(&hash[..])).ok()
}

/// Encrypt then HMAC (Encrypt-then-MAC pattern)
#[flutter_rust_bridge::frb(sync)]
pub fn encrypt_then_mac_sync(
    plaintext: Vec<u8>,
    enc_key: Vec<u8>,
    mac_key: Vec<u8>,
) -> Option<(Vec<u8>, [u8; 32])> {
    let ciphertext = aes256_encrypt_sync(plaintext, enc_key)?;
    let mac = hmac_sha256_sync(mac_key, ciphertext.clone());
    Some((ciphertext, mac))
}

/// Verify MAC then decrypt
#[flutter_rust_bridge::frb(sync)]
pub fn verify_then_decrypt_sync(
    ciphertext: Vec<u8>,
    mac: Vec<u8>,
    enc_key: Vec<u8>,
    mac_key: Vec<u8>,
) -> Option<Vec<u8>> {
    // Verify MAC first
    let computed_mac = hmac_sha256_sync(mac_key, ciphertext.clone());
    if computed_mac.as_slice() != mac.as_slice() {
        return None; // MAC mismatch
    }

    // MAC valid, decrypt
    aes256_decrypt_sync(ciphertext, enc_key)
}

// ============================================================================
// STATEFUL HASHERS (For streaming/chunked data)
// ============================================================================

pub struct Sha256Hasher {
    inner: Sha256,
}

impl Sha256Hasher {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new() -> Self {
        Sha256Hasher {
            inner: Sha256::new(),
        }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn update(&mut self, data: Vec<u8>) {
        self.inner.update(&data);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize(self) -> [u8; 32] {
        let result = self.inner.finalize();
        let mut output = [0u8; 32];
        output.copy_from_slice(&result);
        output
    }
}

pub struct Sha512Hasher {
    inner: Sha512,
}

impl Sha512Hasher {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new() -> Self {
        Sha512Hasher {
            inner: Sha512::new(),
        }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn update(&mut self, data: Vec<u8>) {
        self.inner.update(&data);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize(self) -> [u8; 64] {
        let result = self.inner.finalize();
        let mut output = [0u8; 64];
        output.copy_from_slice(&result);
        output
    }
}

pub struct HmacSha256State {
    inner: HmacSha256,
}

impl HmacSha256State {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new(key: Vec<u8>) -> Self {
        HmacSha256State {
            inner: <HmacSha256 as Mac>::new_from_slice(&key)
                .expect("HMAC can take key of any size"),
        }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn update(&mut self, data: Vec<u8>) {
        self.inner.update(&data);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize(self) -> [u8; 32] {
        let result = self.inner.finalize().into_bytes();
        let mut output = [0u8; 32];
        output.copy_from_slice(&result);
        output
    }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Convert bytes to hex string - do this in Rust to avoid Dart overhead
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn to_hex_sync(bytes: Vec<u8>) -> String {
    hex::encode(bytes)
}

/// Convert hex string to bytes
#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn from_hex_sync(hex_string: String) -> Option<Vec<u8>> {
    hex::decode(hex_string).ok()
}

/// Get hash output size in bytes
#[flutter_rust_bridge::frb(sync)]
pub fn hash_size_sync(algorithm: String) -> usize {
    match algorithm.as_str() {
        "sha1" => 20,
        "sha224" => 28,
        "sha256" => 32,
        "sha384" => 48,
        "sha512" => 64,
        "sha512_224" => 28,
        "sha512_256" => 32,
        "md5" => 16,
        _ => 0,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha256_sync() {
        let data = b"hello world".to_vec();
        let hash = sha256_sync(data);
        let expected = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
        assert_eq!(hex::encode(hash), expected);
    }

    #[test]
    fn test_hmac_sha256_sync() {
        let key = b"secret".to_vec();
        let data = b"message".to_vec();
        let hash = hmac_sha256_sync(key, data);
        assert_eq!(hash.len(), 32);
    }

    #[test]
    fn test_aes256_sync() {
        let key = vec![1u8; 32];
        let plaintext = b"Hello World!".to_vec();

        let encrypted = aes256_encrypt_sync(plaintext.clone(), key.clone()).unwrap();
        let decrypted = aes256_decrypt_sync(encrypted, key).unwrap();

        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_batch() {
        let inputs = vec![
            b"test1".to_vec(),
            b"test2".to_vec(),
            b"test3".to_vec(),
        ];

        let hashes = sha256_batch_sync(inputs);
        assert_eq!(hashes.len(), 3);
    }

    #[test]
    fn test_streaming() {
        let mut hasher = Sha256Hasher::new();
        hasher.update(b"hello ".to_vec());
        hasher.update(b"world".to_vec());
        let hash = hasher.finalize();

        let expected = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
        assert_eq!(hex::encode(hash), expected);
    }
}