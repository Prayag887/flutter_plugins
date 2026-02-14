mod frb_generated;

use aes_gcm::{Aes256Gcm, Key, Nonce};
use aes_gcm::aead::{Aead, Payload, KeyInit};
use hmac::{Hmac, Mac};
use md5::Md5;
use sha1::Sha1;
use sha2::{Sha224, Sha256, Sha384, Sha512, Sha512_224, Sha512_256, Digest};
use rand::Rng;

type HmacMd5 = Hmac<Md5>;
type HmacSha1 = Hmac<Sha1>;
type HmacSha224 = Hmac<Sha224>;
type HmacSha256 = Hmac<Sha256>;
type HmacSha384 = Hmac<Sha384>;
type HmacSha512 = Hmac<Sha512>;

// ============================================================================
// INTERNAL HELPER FUNCTIONS (for zero-copy operations)
// ============================================================================

#[inline(always)]
fn sha256_internal(data: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn sha512_internal(data: &[u8]) -> [u8; 64] {
    let mut hasher = Sha512::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn sha1_internal(data: &[u8]) -> [u8; 20] {
    let mut hasher = Sha1::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn sha384_internal(data: &[u8]) -> [u8; 48] {
    let mut hasher = Sha384::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn sha224_internal(data: &[u8]) -> [u8; 28] {
    let mut hasher = Sha224::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn md5_internal(data: &[u8]) -> [u8; 16] {
    let mut hasher = Md5::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn sha512_256_internal(data: &[u8]) -> [u8; 32] {
    let mut hasher = Sha512_256::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn sha512_224_internal(data: &[u8]) -> [u8; 28] {
    let mut hasher = Sha512_224::new();
    hasher.update(data);
    hasher.finalize().into()
}

#[inline(always)]
fn hmac_sha256_internal(key: &[u8], data: &[u8]) -> [u8; 32] {
    let mut mac = <HmacSha256 as Mac>::new_from_slice(key).unwrap();
    mac.update(data);
    mac.finalize().into_bytes().into()
}

#[inline(always)]
fn hmac_sha512_internal(key: &[u8], data: &[u8]) -> [u8; 64] {
    let mut mac = <HmacSha512 as Mac>::new_from_slice(key).unwrap();
    mac.update(data);
    mac.finalize().into_bytes().into()
}

#[inline(always)]
fn hmac_sha1_internal(key: &[u8], data: &[u8]) -> [u8; 20] {
    let mut mac = <HmacSha1 as Mac>::new_from_slice(key).unwrap();
    mac.update(data);
    mac.finalize().into_bytes().into()
}

#[inline(always)]
fn hmac_sha384_internal(key: &[u8], data: &[u8]) -> [u8; 48] {
    let mut mac = <HmacSha384 as Mac>::new_from_slice(key).unwrap();
    mac.update(data);
    mac.finalize().into_bytes().into()
}

#[inline(always)]
fn hmac_sha224_internal(key: &[u8], data: &[u8]) -> [u8; 28] {
    let mut mac = <HmacSha224 as Mac>::new_from_slice(key).unwrap();
    mac.update(data);
    mac.finalize().into_bytes().into()
}

#[inline(always)]
fn hmac_md5_internal(key: &[u8], data: &[u8]) -> [u8; 16] {
    let mut mac = <HmacMd5 as Mac>::new_from_slice(key).unwrap();
    mac.update(data);
    mac.finalize().into_bytes().into()
}

// ============================================================================
// SHA-256 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha256(data: Vec<u8>) -> [u8; 32] {
    sha256_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha256_async(data: Vec<u8>) -> [u8; 32] {
    sha256_internal(&data)
}

// ============================================================================
// SHA-512 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha512(data: Vec<u8>) -> [u8; 64] {
    sha512_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha512_async(data: Vec<u8>) -> [u8; 64] {
    sha512_internal(&data)
}

// ============================================================================
// SHA-1 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha1(data: Vec<u8>) -> [u8; 20] {
    sha1_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha1_async(data: Vec<u8>) -> [u8; 20] {
    sha1_internal(&data)
}

// ============================================================================
// SHA-384 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha384(data: Vec<u8>) -> [u8; 48] {
    sha384_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha384_async(data: Vec<u8>) -> [u8; 48] {
    sha384_internal(&data)
}

// ============================================================================
// SHA-224 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha224(data: Vec<u8>) -> [u8; 28] {
    sha224_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha224_async(data: Vec<u8>) -> [u8; 28] {
    sha224_internal(&data)
}

// ============================================================================
// MD5 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn md5(data: Vec<u8>) -> [u8; 16] {
    md5_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn md5_async(data: Vec<u8>) -> [u8; 16] {
    md5_internal(&data)
}

// ============================================================================
// SHA-512/256 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha512_256(data: Vec<u8>) -> [u8; 32] {
    sha512_256_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha512_256_async(data: Vec<u8>) -> [u8; 32] {
    sha512_256_internal(&data)
}

// ============================================================================
// SHA-512/224 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn sha512_224(data: Vec<u8>) -> [u8; 28] {
    sha512_224_internal(&data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha512_224_async(data: Vec<u8>) -> [u8; 28] {
    sha512_224_internal(&data)
}

// ============================================================================
// HMAC-SHA256 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha256(key: Vec<u8>, data: Vec<u8>) -> [u8; 32] {
    hmac_sha256_internal(&key, &data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_sha256_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 32] {
    hmac_sha256_internal(&key, &data)
}

// ============================================================================
// HMAC-SHA512 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha512(key: Vec<u8>, data: Vec<u8>) -> [u8; 64] {
    hmac_sha512_internal(&key, &data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_sha512_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 64] {
    hmac_sha512_internal(&key, &data)
}

// ============================================================================
// HMAC-SHA1 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha1(key: Vec<u8>, data: Vec<u8>) -> [u8; 20] {
    hmac_sha1_internal(&key, &data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_sha1_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 20] {
    hmac_sha1_internal(&key, &data)
}

// ============================================================================
// HMAC-SHA384 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha384(key: Vec<u8>, data: Vec<u8>) -> [u8; 48] {
    hmac_sha384_internal(&key, &data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_sha384_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 48] {
    hmac_sha384_internal(&key, &data)
}

// ============================================================================
// HMAC-SHA224 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_sha224(key: Vec<u8>, data: Vec<u8>) -> [u8; 28] {
    hmac_sha224_internal(&key, &data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_sha224_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 28] {
    hmac_sha224_internal(&key, &data)
}

// ============================================================================
// HMAC-MD5 (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn hmac_md5(key: Vec<u8>, data: Vec<u8>) -> [u8; 16] {
    hmac_md5_internal(&key, &data)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_md5_async(key: Vec<u8>, data: Vec<u8>) -> [u8; 16] {
    hmac_md5_internal(&key, &data)
}

// ============================================================================
// AES-256-GCM ENCRYPTION (SYNC & ASYNC)
// Nonce is automatically generated and prepended to ciphertext
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn aes256_encrypt(plaintext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    if key.len() != 32 { return None; }

    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&key));

    // Generate random nonce (CRITICAL for security)
    let mut nonce_bytes = [0u8; 12];
    rand::rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    // Encrypt
    let ciphertext = cipher.encrypt(nonce, Payload::from(&plaintext[..])).ok()?;

    // Prepend nonce to ciphertext so decryption can extract it
    let mut result = nonce_bytes.to_vec();
    result.extend_from_slice(&ciphertext);
    Some(result)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn aes256_encrypt_async(plaintext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    aes256_encrypt(plaintext, key)
}

// ============================================================================
// AES-256-GCM DECRYPTION (SYNC & ASYNC)
// Nonce is extracted from first 12 bytes of ciphertext
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn aes256_decrypt(ciphertext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    if key.len() != 32 || ciphertext.len() < 12 { return None; }

    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&key));

    // Extract nonce from ciphertext (first 12 bytes)
    let nonce = Nonce::from_slice(&ciphertext[..12]);

    // Decrypt remaining bytes
    cipher.decrypt(nonce, Payload::from(&ciphertext[12..])).ok()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn aes256_decrypt_async(ciphertext: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    aes256_decrypt(ciphertext, key)
}

// ============================================================================
// BATCH OPERATIONS (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
pub fn sha256_batch(inputs: Vec<Vec<u8>>) -> Vec<[u8; 32]> {
    inputs.into_iter().map(|input| sha256_internal(&input)).collect()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha256_batch_async(inputs: Vec<Vec<u8>>) -> Vec<[u8; 32]> {
    inputs.into_iter().map(|input| sha256_internal(&input)).collect()
}

#[flutter_rust_bridge::frb(sync)]
pub fn sha512_batch(inputs: Vec<Vec<u8>>) -> Vec<[u8; 64]> {
    inputs.into_iter().map(|input| sha512_internal(&input)).collect()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn sha512_batch_async(inputs: Vec<Vec<u8>>) -> Vec<[u8; 64]> {
    inputs.into_iter().map(|input| sha512_internal(&input)).collect()
}

#[flutter_rust_bridge::frb(sync)]
pub fn hmac_sha256_batch(key: Vec<u8>, messages: Vec<Vec<u8>>) -> Vec<[u8; 32]> {
    // OPTIMIZED: No key cloning
    messages.into_iter()
        .map(|msg| hmac_sha256_internal(&key, &msg))
        .collect()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_sha256_batch_async(key: Vec<u8>, messages: Vec<Vec<u8>>) -> Vec<[u8; 32]> {
    // OPTIMIZED: No key cloning
    messages.into_iter()
        .map(|msg| hmac_sha256_internal(&key, &msg))
        .collect()
}

#[flutter_rust_bridge::frb(sync)]
pub fn hmac_sha512_batch(key: Vec<u8>, messages: Vec<Vec<u8>>) -> Vec<[u8; 64]> {
    messages.into_iter()
        .map(|msg| hmac_sha512_internal(&key, &msg))
        .collect()
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hmac_sha512_batch_async(key: Vec<u8>, messages: Vec<Vec<u8>>) -> Vec<[u8; 64]> {
    messages.into_iter()
        .map(|msg| hmac_sha512_internal(&key, &msg))
        .collect()
}

// ============================================================================
// COMBINED OPERATIONS (SYNC & ASYNC)
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
pub fn hash_then_encrypt(data: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    let hash = sha256_internal(&data);
    aes256_encrypt(hash.to_vec(), key)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn hash_then_encrypt_async(data: Vec<u8>, key: Vec<u8>) -> Option<Vec<u8>> {
    let hash = sha256_internal(&data);
    aes256_encrypt(hash.to_vec(), key)
}

#[flutter_rust_bridge::frb(sync)]
pub fn encrypt_then_hmac(
    plaintext: Vec<u8>,
    enc_key: Vec<u8>,
    mac_key: Vec<u8>,
) -> Option<(Vec<u8>, [u8; 32])> {
    let ciphertext = aes256_encrypt(plaintext, enc_key)?;
    let mac = hmac_sha256_internal(&mac_key, &ciphertext);
    Some((ciphertext, mac))
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn encrypt_then_hmac_async(
    plaintext: Vec<u8>,
    enc_key: Vec<u8>,
    mac_key: Vec<u8>,
) -> Option<(Vec<u8>, [u8; 32])> {
    let ciphertext = aes256_encrypt(plaintext, enc_key)?;
    let mac = hmac_sha256_internal(&mac_key, &ciphertext);
    Some((ciphertext, mac))
}

#[flutter_rust_bridge::frb(sync)]
pub fn verify_hmac_then_decrypt(
    ciphertext: Vec<u8>,
    mac: Vec<u8>,
    enc_key: Vec<u8>,
    mac_key: Vec<u8>,
) -> Option<Vec<u8>> {
    // OPTIMIZED: No unnecessary clones
    let computed = hmac_sha256_internal(&mac_key, &ciphertext);
    if computed.as_slice() != mac.as_slice() { return None; }
    aes256_decrypt(ciphertext, enc_key)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn verify_hmac_then_decrypt_async(
    ciphertext: Vec<u8>,
    mac: Vec<u8>,
    enc_key: Vec<u8>,
    mac_key: Vec<u8>,
) -> Option<Vec<u8>> {
    let computed = hmac_sha256_internal(&mac_key, &ciphertext);
    if computed.as_slice() != mac.as_slice() { return None; }
    aes256_decrypt(ciphertext, enc_key)
}

// ============================================================================
// STATEFUL HASHERS (SYNC ONLY - required by Flutter)
// ============================================================================

pub struct Sha256Hasher { inner: Sha256 }

impl Sha256Hasher {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new() -> Self {
        Self { inner: Sha256::new() }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn update(&mut self, data: Vec<u8>) {
        self.inner.update(&data);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize(self) -> [u8; 32] {
        self.inner.finalize().into()
    }
}

pub struct Sha512Hasher { inner: Sha512 }

impl Sha512Hasher {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new() -> Self {
        Self { inner: Sha512::new() }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn update(&mut self, data: Vec<u8>) {
        self.inner.update(&data);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize(self) -> [u8; 64] {
        self.inner.finalize().into()
    }
}

pub struct Sha1Hasher { inner: Sha1 }

impl Sha1Hasher {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new() -> Self {
        Self { inner: Sha1::new() }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn update(&mut self, data: Vec<u8>) {
        self.inner.update(&data);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize(self) -> [u8; 20] {
        self.inner.finalize().into()
    }
}

pub struct Sha256HmacHasher { inner: HmacSha256 }

impl Sha256HmacHasher {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new(key: Vec<u8>) -> Option<Self> {
        <HmacSha256 as Mac>::new_from_slice(&key)
            .ok()
            .map(|inner| Self { inner })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn update(&mut self, data: Vec<u8>) {
        self.inner.update(&data);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize(self) -> [u8; 32] {
        self.inner.finalize().into_bytes().into()
    }
}

// ============================================================================
// UTILITIES
// ============================================================================

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn to_hex(bytes: Vec<u8>) -> String {
    hex::encode(bytes)
}

#[flutter_rust_bridge::frb(sync)]
#[inline(always)]
pub fn from_hex(hex_string: String) -> Option<Vec<u8>> {
    hex::decode(hex_string).ok()
}

#[flutter_rust_bridge::frb(sync)]
pub fn hash_size(algorithm: String) -> usize {
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

#[flutter_rust_bridge::frb(sync)]
pub fn get_all_algorithms() -> Vec<String> {
    vec![
        "sha1".to_string(),
        "sha224".to_string(),
        "sha256".to_string(),
        "sha384".to_string(),
        "sha512".to_string(),
        "sha512_224".to_string(),
        "sha512_256".to_string(),
        "md5".to_string(),
    ]
}