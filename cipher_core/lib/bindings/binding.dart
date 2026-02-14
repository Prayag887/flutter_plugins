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
    return ffi.sha256(data: data).inner;
  }

  static Uint8List sha512(Uint8List data) {
    return ffi.sha512(data: data).inner;
  }

  static Uint8List sha1(Uint8List data) {
    return ffi.sha1(data: data).inner;
  }

  static Uint8List sha384(Uint8List data) {
    return ffi.sha384(data: data).inner;
  }

  static Uint8List sha224(Uint8List data) {
    return ffi.sha224(data: data).inner;
  }

  static Uint8List md5(Uint8List data) {
    return ffi.md5(data: data).inner;
  }

  static Uint8List sha512_256(Uint8List data) {
    return ffi.sha512256(data: data).inner;
  }

  static Uint8List sha512_224(Uint8List data) {
    return ffi.sha512224(data: data).inner;
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
    return ffi.hmacSha256(key: key, data: data).inner;
  }

  static Uint8List hmacSha512(Uint8List key, Uint8List data) {
    return ffi.hmacSha512(key: key, data: data).inner;
  }

  static Uint8List hmacSha1(Uint8List key, Uint8List data) {
    return ffi.hmacSha1(key: key, data: data).inner;
  }

  static Uint8List hmacSha384(Uint8List key, Uint8List data) {
    return ffi.hmacSha384(key: key, data: data).inner;
  }

  static Uint8List hmacSha224(Uint8List key, Uint8List data) {
    return ffi.hmacSha224(key: key, data: data).inner;
  }

  static Uint8List hmacMd5(Uint8List key, Uint8List data) {
    return ffi.hmacMd5(key: key, data: data).inner;
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
    return ffi.aes256Encrypt(plaintext: plaintext, key: key);
  }

  static Uint8List? aes256Decrypt(Uint8List ciphertext, Uint8List key) {
    return ffi.aes256Decrypt(ciphertext: ciphertext, key: key);
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
    final results = ffi.sha256Batch(inputs: inputs);
    return results.map((r) => r.inner).toList();
  }

  static List<Uint8List> hmacSha256Batch(Uint8List key, List<Uint8List> messages) {
    final results = ffi.hmacSha256Batch(key: key, messages: messages);
    return results.map((r) => r.inner).toList();
  }

  // =========================================================================
  // COMBINED OPERATIONS
  // =========================================================================

  static Uint8List? hashThenEncrypt(Uint8List data, Uint8List key) {
    return ffi.hashThenEncrypt(data: data, key: key);
  }

  static (Uint8List, Uint8List)? encryptThenMac({
    required Uint8List plaintext,
    required Uint8List encKey,
    required Uint8List macKey,
  }) {
    final result = ffi.encryptThenHmac(
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
    return ffi.verifyHmacThenDecrypt(
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
    return ffi.toHex(bytes: bytes);
  }

  static Uint8List? fromHex(String hexString) {
    return ffi.fromHex(hexString: hexString);
  }

  static int hashSize(String algorithm) {
    return ffi.hashSize(algorithm: algorithm).toInt();
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

  static ffi.Sha256HmacHasher createSha256HmacHasher(Uint8List key) {
    return ffi.Sha256HmacHasher(key: key);
  }
}