// bindings.dart - Internal bindings layer
// This provides a cleaner interface over the generated FFI code

import 'dart:typed_data';
import '../generated_bindings.dart/lib.dart' as ffi;

/// Internal bindings - wraps the raw FFI calls with better types
class RustCryptoBindings {
  const RustCryptoBindings._();

  // =========================================================================
  // HASH FUNCTIONS - Sync
  // =========================================================================

  static Uint8List sha256(Uint8List data) {
    return ffi.sha256Sync(data: data).inner;
  }

  static Uint8List sha512(Uint8List data) {
    return ffi.sha512Sync(data: data).inner;
  }

  static Uint8List sha1(Uint8List data) {
    return ffi.sha1Sync(data: data).inner;
  }

  static Uint8List sha384(Uint8List data) {
    return ffi.sha384Sync(data: data).inner;
  }

  static Uint8List sha224(Uint8List data) {
    return ffi.sha224Sync(data: data).inner;
  }

  static Uint8List md5(Uint8List data) {
    return ffi.md5Sync(data: data).inner;
  }

  static Uint8List sha512_256(Uint8List data) {
    return ffi.sha512256Sync(data: data).inner;
  }

  static Uint8List sha512_224(Uint8List data) {
    return ffi.sha512224Sync(data: data).inner;
  }

  // =========================================================================
  // HASH FUNCTIONS - Async (for large data)
  // =========================================================================

  static Future<Uint8List> sha256Async(Uint8List data) async {
    final result = await ffi.sha256Async(data: data);
    return result.inner;
  }

  static Future<Uint8List> sha512Async(Uint8List data) async {
    final result = await ffi.sha512Async(data: data);
    return result.inner;
  }

  static Future<Uint8List> sha1Async(Uint8List data) async {
    final result = await ffi.sha1Async(data: data);
    return result.inner;
  }

  static Future<Uint8List> sha384Async(Uint8List data) async {
    final result = await ffi.sha384Async(data: data);
    return result.inner;
  }

  static Future<Uint8List> md5Async(Uint8List data) async {
    final result = await ffi.md5Async(data: data);
    return result.inner;
  }

  // =========================================================================
  // HMAC FUNCTIONS - Sync
  // =========================================================================

  static Uint8List hmacSha256(Uint8List key, Uint8List data) {
    return ffi.hmacSha256Sync(key: key, data: data).inner;
  }

  static Uint8List hmacSha512(Uint8List key, Uint8List data) {
    return ffi.hmacSha512Sync(key: key, data: data).inner;
  }

  static Uint8List hmacSha1(Uint8List key, Uint8List data) {
    return ffi.hmacSha1Sync(key: key, data: data).inner;
  }

  static Uint8List hmacSha384(Uint8List key, Uint8List data) {
    return ffi.hmacSha384Sync(key: key, data: data).inner;
  }

  static Uint8List hmacSha224(Uint8List key, Uint8List data) {
    return ffi.hmacSha224Sync(key: key, data: data).inner;
  }

  static Uint8List hmacMd5(Uint8List key, Uint8List data) {
    return ffi.hmacMd5Sync(key: key, data: data).inner;
  }

  // =========================================================================
  // HMAC FUNCTIONS - Async
  // =========================================================================

  static Future<Uint8List> hmacSha256Async(Uint8List key, Uint8List data) async {
    final result = await ffi.hmacSha256Async(key: key, data: data);
    return result.inner;
  }

  static Future<Uint8List> hmacSha512Async(Uint8List key, Uint8List data) async {
    final result = await ffi.hmacSha512Async(key: key, data: data);
    return result.inner;
  }

  // =========================================================================
  // AES-256-GCM ENCRYPTION
  // =========================================================================

  static Uint8List? aes256Encrypt(Uint8List plaintext, Uint8List key) {
    return ffi.aes256EncryptSync(plaintext: plaintext, key: key);
  }

  static Uint8List? aes256Decrypt(Uint8List ciphertext, Uint8List key) {
    return ffi.aes256DecryptSync(ciphertext: ciphertext, key: key);
  }

  static Future<Uint8List?> aes256EncryptAsync(Uint8List plaintext, Uint8List key) {
    return ffi.aes256EncryptAsync(plaintext: plaintext, key: key);
  }

  static Future<Uint8List?> aes256DecryptAsync(Uint8List ciphertext, Uint8List key) {
    return ffi.aes256DecryptAsync(ciphertext: ciphertext, key: key);
  }

  // =========================================================================
  // BATCH OPERATIONS
  // =========================================================================

  static List<Uint8List> sha256Batch(List<Uint8List> inputs) {
    final results = ffi.sha256BatchSync(inputs: inputs);
    return results.map((r) => r.inner).toList();
  }

  static List<Uint8List> hmacSha256Batch(Uint8List key, List<Uint8List> messages) {
    final results = ffi.hmacSha256BatchSync(key: key, messages: messages);
    return results.map((r) => r.inner).toList();
  }

  // =========================================================================
  // COMBINED OPERATIONS
  // =========================================================================

  static Uint8List? hashThenEncrypt(Uint8List data, Uint8List key) {
    return ffi.hashThenEncryptSync(data: data, key: key);
  }

  static (Uint8List, Uint8List)? encryptThenMac({
    required Uint8List plaintext,
    required Uint8List encKey,
    required Uint8List macKey,
  }) {
    final result = ffi.encryptThenMacSync(
      plaintext: plaintext,
      encKey: encKey,
      macKey: macKey,
    );

    if (result == null) return null;
    return (result.$1, result.$2.inner);
  }

  static Uint8List? verifyThenDecrypt({
    required Uint8List ciphertext,
    required Uint8List mac,
    required Uint8List encKey,
    required Uint8List macKey,
  }) {
    return ffi.verifyThenDecryptSync(
      ciphertext: ciphertext,
      mac: mac,
      encKey: encKey,
      macKey: macKey,
    );
  }

  // =========================================================================
  // UTILITIES
  // =========================================================================

  static String toHex(Uint8List bytes) {
    return ffi.toHexSync(bytes: bytes);
  }

  static Uint8List? fromHex(String hexString) {
    return ffi.fromHexSync(hexString: hexString);
  }

  static int hashSize(String algorithm) {
    return ffi.hashSizeSync(algorithm: algorithm).toInt();
  }

  // =========================================================================
  // STATEFUL HASHERS
  // =========================================================================

  static ffi.Sha256Hasher createSha256Hasher() {
    return ffi.Sha256Hasher();
  }

  static ffi.Sha512Hasher createSha512Hasher() {
    return ffi.Sha512Hasher();
  }

  static ffi.HmacSha256State createHmacSha256State(Uint8List key) {
    return ffi.HmacSha256State(key: key);
  }
}