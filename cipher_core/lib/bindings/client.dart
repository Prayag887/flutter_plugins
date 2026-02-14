// client.dart - Public API exposed to Flutter UI
// Compatible with the 'crypto' package API style

import 'dart:convert';
import 'dart:typed_data';
import '../generated_bindings.dart/lib.dart' as ffi;
import 'binding.dart';


// ============================================================================
// HASH ALGORITHMS (crypto package compatible)
// ============================================================================

/// SHA-256 hash algorithm (hardware accelerated)
///
/// Usage:
/// ```dart
/// final digest = sha256.convert(utf8.encode('hello'));
/// print(digest); // Prints: 2cf24dba5fb0a30e26e8...
/// ```
const Hash sha256 = _Sha256();

/// SHA-512 hash algorithm
const Hash sha512 = _Sha512();

/// SHA-1 hash algorithm (deprecated for security)
const Hash sha1 = _Sha1();

/// SHA-384 hash algorithm
const Hash sha384 = _Sha384();

/// SHA-224 hash algorithm
const Hash sha224 = _Sha224();

/// MD5 hash algorithm (deprecated for security)
const Hash md5 = _Md5();

/// SHA-512/256 hash algorithm
const Hash sha512_256 = _Sha512_256();

/// SHA-512/224 hash algorithm
const Hash sha512_224 = _Sha512_224();

// ============================================================================
// HASH INTERFACE (crypto package compatible)
// ============================================================================

/// Hash algorithm interface compatible with package:crypto
abstract class Hash {
  const Hash();

  /// Name of the hash algorithm
  String get name;

  /// Size of the hash output in bytes
  int get blockSize;

  /// Convert data to a hash digest
  ///
  /// This is the main method - ultra-fast, hardware accelerated.
  /// Use this for most cases.
  Digest convert(List<int> input);

  /// Convert data to hash asynchronously (for large data)
  ///
  /// Use this for data > 100KB to avoid blocking the UI
  Future<Digest> convertAsync(List<int> input);

  /// Start a chunked conversion for streaming data
  ///
  /// Use this for large files that don't fit in memory
  ByteConversionSink startChunkedConversion(Sink<Digest> sink);

  /// Create a new hasher for incremental updates
  Hasher newHasher();
}

/// Hash digest result (crypto package compatible)
class Digest {
  final Uint8List bytes;

  const Digest._(this.bytes);

  @override
  String toString() => RustCryptoBindings.toHex(bytes);

  @override
  bool operator ==(Object other) {
    if (other is! Digest) return false;
    if (bytes.length != other.bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (var i = 0; i < bytes.length; i++) {
      hash = (hash ^ bytes[i]) * 16777619;
    }
    return hash;
  }
}

// ============================================================================
// HASH IMPLEMENTATIONS
// ============================================================================

class _Sha256 extends Hash {
  const _Sha256();

  @override
  String get name => 'sha256';

  @override
  int get blockSize => 32;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.sha256(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = await RustCryptoBindings.sha256Async(data);
    return Digest._(hash);
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    return _HashSink(sink, ffi.Sha256Hasher());
  }

  @override
  Hasher newHasher() => _Sha256Hasher();
}

class _Sha512 extends Hash {
  const _Sha512();

  @override
  String get name => 'sha512';

  @override
  int get blockSize => 64;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.sha512(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = await RustCryptoBindings.sha512Async(data);
    return Digest._(hash);
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    return _HashSink(sink, ffi.Sha512Hasher());
  }

  @override
  Hasher newHasher() => _Sha512Hasher();
}

class _Sha1 extends Hash {
  const _Sha1();

  @override
  String get name => 'sha1';

  @override
  int get blockSize => 20;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.sha1(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = await RustCryptoBindings.sha1Async(data);
    return Digest._(hash);
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    throw UnimplementedError('Chunked SHA-1 not implemented yet');
  }

  @override
  Hasher newHasher() => throw UnimplementedError('SHA-1 hasher not implemented yet');
}

class _Sha384 extends Hash {
  const _Sha384();

  @override
  String get name => 'sha384';

  @override
  int get blockSize => 48;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.sha384(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = await RustCryptoBindings.sha384Async(data);
    return Digest._(hash);
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    throw UnimplementedError('Chunked SHA-384 not implemented yet');
  }

  @override
  Hasher newHasher() => throw UnimplementedError('SHA-384 hasher not implemented yet');
}

class _Sha224 extends Hash {
  const _Sha224();

  @override
  String get name => 'sha224';

  @override
  int get blockSize => 28;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.sha224(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    throw UnimplementedError('Async SHA-224 not implemented yet');
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    throw UnimplementedError('Chunked SHA-224 not implemented yet');
  }

  @override
  Hasher newHasher() => throw UnimplementedError('SHA-224 hasher not implemented yet');
}

class _Md5 extends Hash {
  const _Md5();

  @override
  String get name => 'md5';

  @override
  int get blockSize => 16;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.md5(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = await RustCryptoBindings.md5Async(data);
    return Digest._(hash);
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    throw UnimplementedError('Chunked MD5 not implemented yet');
  }

  @override
  Hasher newHasher() => throw UnimplementedError('MD5 hasher not implemented yet');
}

class _Sha512_256 extends Hash {
  const _Sha512_256();

  @override
  String get name => 'sha512/256';

  @override
  int get blockSize => 32;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.sha512_256(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    throw UnimplementedError('Async SHA-512/256 not implemented yet');
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    throw UnimplementedError('Chunked SHA-512/256 not implemented yet');
  }

  @override
  Hasher newHasher() => throw UnimplementedError('SHA-512/256 hasher not implemented yet');
}

class _Sha512_224 extends Hash {
  const _Sha512_224();

  @override
  String get name => 'sha512/224';

  @override
  int get blockSize => 28;

  @override
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);
    final hash = RustCryptoBindings.sha512_224(data);
    return Digest._(hash);
  }

  @override
  Future<Digest> convertAsync(List<int> input) async {
    throw UnimplementedError('Async SHA-512/224 not implemented yet');
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    throw UnimplementedError('Chunked SHA-512/224 not implemented yet');
  }

  @override
  Hasher newHasher() => throw UnimplementedError('SHA-512/224 hasher not implemented yet');
}

// ============================================================================
// HMAC SUPPORT (crypto package compatible)
// ============================================================================

/// HMAC (Hash-based Message Authentication Code)
///
/// Usage:
/// ```dart
/// final key = utf8.encode('secret-key');
/// final hmac = Hmac(sha256, key);
/// final digest = hmac.convert(utf8.encode('message'));
/// ```
class Hmac {
  final Hash _hash;
  final Uint8List _key;

  Hmac(this._hash, List<int> key)
      : _key = key is Uint8List ? key : Uint8List.fromList(key);

  /// Compute HMAC digest
  Digest convert(List<int> input) {
    final data = input is Uint8List ? input : Uint8List.fromList(input);

    // Route to appropriate HMAC implementation
    final Uint8List hash;
    if (_hash == sha256) {
      hash = RustCryptoBindings.hmacSha256(_key, data);
    } else if (_hash == sha512) {
      hash = RustCryptoBindings.hmacSha512(_key, data);
    } else if (_hash == sha1) {
      hash = RustCryptoBindings.hmacSha1(_key, data);
    } else if (_hash == sha384) {
      hash = RustCryptoBindings.hmacSha384(_key, data);
    } else if (_hash == sha224) {
      hash = RustCryptoBindings.hmacSha224(_key, data);
    } else if (_hash == md5) {
      hash = RustCryptoBindings.hmacMd5(_key, data);
    } else {
      throw UnsupportedError('HMAC not supported for ${_hash.name}');
    }

    return Digest._(hash);
  }

  /// Compute HMAC digest asynchronously
  Future<Digest> convertAsync(List<int> input) async {
    final data = input is Uint8List ? input : Uint8List.fromList(input);

    final Uint8List hash;
    if (_hash == sha256) {
      hash = await RustCryptoBindings.hmacSha256Async(_key, data);
    } else if (_hash == sha512) {
      hash = await RustCryptoBindings.hmacSha512Async(_key, data);
    } else {
      throw UnsupportedError('Async HMAC not supported for ${_hash.name}');
    }

    return Digest._(hash);
  }

  /// Start chunked conversion for streaming
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) {
    if (_hash == sha256) {
      return _HmacSink(sink, ffi.Sha256HmacHasher(key: _key));
    }
    throw UnimplementedError('Chunked HMAC not implemented for ${_hash.name}');
  }

  /// Create a new HMAC hasher for incremental updates
  HmacHasher newHasher() {
    if (_hash == sha256) {
      return _HmacSha256Hasher(_key);
    }
    throw UnimplementedError('HMAC hasher not implemented for ${_hash.name}');
  }
}

// ============================================================================
// HASHER INTERFACE (for incremental hashing)
// ============================================================================

/// Incremental hasher interface
abstract class Hasher {
  /// Add data to the hash
  void add(List<int> data);

  /// Finalize and get the digest
  Digest close();
}

/// Incremental HMAC hasher interface
abstract class HmacHasher {
  /// Add data to the HMAC
  void add(List<int> data);

  /// Finalize and get the digest
  Digest close();
}

class _Sha256Hasher implements Hasher {
  final ffi.Sha256Hasher _hasher = ffi.Sha256Hasher();
  bool _closed = false;

  @override
  void add(List<int> data) {
    if (_closed) throw StateError('Hasher already closed');
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    _hasher.update(data: bytes);
  }

  @override
  Digest close() {
    if (_closed) throw StateError('Hasher already closed');
    _closed = true;
    final hash = _hasher.finalize();
    return Digest._(hash.inner);
  }
}

class _Sha512Hasher implements Hasher {
  final ffi.Sha512Hasher _hasher = ffi.Sha512Hasher();
  bool _closed = false;

  @override
  void add(List<int> data) {
    if (_closed) throw StateError('Hasher already closed');
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    _hasher.update(data: bytes);
  }

  @override
  Digest close() {
    if (_closed) throw StateError('Hasher already closed');
    _closed = true;
    final hash = _hasher.finalize();
    return Digest._(hash.inner);
  }
}

class _HmacSha256Hasher implements HmacHasher {
  final ffi.Sha256HmacHasher _hasher;
  bool _closed = false;

  _HmacSha256Hasher(Uint8List key) : _hasher = ffi.Sha256HmacHasher(key: key);

  @override
  void add(List<int> data) {
    if (_closed) throw StateError('Hasher already closed');
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    _hasher.update(data: bytes);
  }

  @override
  Digest close() {
    if (_closed) throw StateError('Hasher already closed');
    _closed = true;
    final hash = _hasher.finalize();
    return Digest._(hash.inner);
  }
}

// ============================================================================
// CHUNKED CONVERSION SINKS
// ============================================================================

class _HashSink extends ByteConversionSink {
  final Sink<Digest> _sink;
  final dynamic _hasher; // ffi.Sha256Hasher or ffi.Sha512Hasher
  bool _closed = false;

  _HashSink(this._sink, this._hasher);

  @override
  void add(List<int> chunk) {
    if (_closed) throw StateError('Sink already closed');
    final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    _hasher.update(data: bytes);
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;

    final hash = _hasher.finalize();
    final digest = Digest._(hash.inner as Uint8List);
    _sink.add(digest);
    _sink.close();
  }
}

class _HmacSink extends ByteConversionSink {
  final Sink<Digest> _sink;
  final ffi.Sha256HmacHasher _hasher;
  bool _closed = false;

  _HmacSink(this._sink, this._hasher);

  @override
  void add(List<int> chunk) {
    if (_closed) throw StateError('Sink already closed');
    final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    _hasher.update(data: bytes);
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;

    final hash = _hasher.finalize();
    final digest = Digest._(hash.inner);
    _sink.add(digest);
    _sink.close();
  }
}

// ============================================================================
// BATCH OPERATIONS (Rust-specific optimizations)
// ============================================================================

/// Batch hash multiple inputs in one call (10-20x faster than individual)
class Batch {
  const Batch._();

  /// Hash multiple inputs with SHA-256
  ///
  /// Example:
  /// ```dart
  /// final inputs = [data1, data2, data3];
  /// final digests = Batch.sha256(inputs);
  /// ```
  static List<Digest> sha256(List<List<int>> inputs) {
    final uintInputs = inputs
        .map((i) => i is Uint8List ? i : Uint8List.fromList(i))
        .toList();
    final hashes = RustCryptoBindings.sha256Batch(uintInputs);
    return hashes.map((h) => Digest._(h)).toList();
  }

  /// HMAC multiple messages with same key
  static List<Digest> hmacSha256(List<int> key, List<List<int>> messages) {
    final keyBytes = key is Uint8List ? key : Uint8List.fromList(key);
    final uintMessages = messages
        .map((m) => m is Uint8List ? m : Uint8List.fromList(m))
        .toList();
    final hashes = RustCryptoBindings.hmacSha256Batch(keyBytes, uintMessages);
    return hashes.map((h) => Digest._(h)).toList();
  }
}

/// Expose batch operations
const Batch batch = Batch._();

// ============================================================================
// AES-256-GCM ENCRYPTION (Rust-specific)
// ============================================================================

/// AES-256-GCM encryption utilities
class AES256GCM {
  const AES256GCM._();

  /// Encrypt data with AES-256-GCM
  ///
  /// Key must be exactly 32 bytes. Returns null on error.
  /// WARNING: Uses a fixed nonce - only for testing!
  static Uint8List? encrypt(List<int> plaintext, List<int> key) {
    final plaintextBytes = plaintext is Uint8List
        ? plaintext
        : Uint8List.fromList(plaintext);
    final keyBytes = key is Uint8List ? key : Uint8List.fromList(key);

    return RustCryptoBindings.aes256Encrypt(plaintextBytes, keyBytes);
  }

  /// Decrypt data with AES-256-GCM
  ///
  /// Key must be exactly 32 bytes. Returns null on error.
  static Uint8List? decrypt(List<int> ciphertext, List<int> key) {
    final ciphertextBytes = ciphertext is Uint8List
        ? ciphertext
        : Uint8List.fromList(ciphertext);
    final keyBytes = key is Uint8List ? key : Uint8List.fromList(key);

    return RustCryptoBindings.aes256Decrypt(ciphertextBytes, keyBytes);
  }

  /// Encrypt data asynchronously (for large data)
  static Future<Uint8List?> encryptAsync(List<int> plaintext, List<int> key) {
    final plaintextBytes = plaintext is Uint8List
        ? plaintext
        : Uint8List.fromList(plaintext);
    final keyBytes = key is Uint8List ? key : Uint8List.fromList(key);

    return RustCryptoBindings.aes256EncryptAsync(plaintextBytes, keyBytes);
  }

  /// Decrypt data asynchronously (for large data)
  static Future<Uint8List?> decryptAsync(List<int> ciphertext, List<int> key) {
    final ciphertextBytes = ciphertext is Uint8List
        ? ciphertext
        : Uint8List.fromList(ciphertext);
    final keyBytes = key is Uint8List ? key : Uint8List.fromList(key);

    return RustCryptoBindings.aes256DecryptAsync(ciphertextBytes, keyBytes);
  }

  /// Encrypt then MAC (authenticated encryption)
  static (Uint8List, Digest)? encryptThenMac({
    required List<int> plaintext,
    required List<int> encKey,
    required List<int> macKey,
  }) {
    final plaintextBytes = plaintext is Uint8List
        ? plaintext
        : Uint8List.fromList(plaintext);
    final encKeyBytes = encKey is Uint8List ? encKey : Uint8List.fromList(encKey);
    final macKeyBytes = macKey is Uint8List ? macKey : Uint8List.fromList(macKey);

    final result = RustCryptoBindings.encryptThenMac(
      plaintext: plaintextBytes,
      encKey: encKeyBytes,
      macKey: macKeyBytes,
    );

    if (result == null) return null;
    return (result.$1, Digest._(result.$2));
  }

  /// Verify MAC then decrypt (authenticated decryption)
  static Uint8List? verifyThenDecrypt({
    required List<int> ciphertext,
    required List<int> mac,
    required List<int> encKey,
    required List<int> macKey,
  }) {
    final ciphertextBytes = ciphertext is Uint8List
        ? ciphertext
        : Uint8List.fromList(ciphertext);
    final macBytes = mac is Uint8List ? mac : Uint8List.fromList(mac);
    final encKeyBytes = encKey is Uint8List ? encKey : Uint8List.fromList(encKey);
    final macKeyBytes = macKey is Uint8List ? macKey : Uint8List.fromList(macKey);

    return RustCryptoBindings.verifyThenDecrypt(
      ciphertext: ciphertextBytes,
      mac: macBytes,
      encKey: encKeyBytes,
      macKey: macKeyBytes,
    );
  }
}

/// Expose AES encryption
const AES256GCM aes256gcm = AES256GCM._();

// ============================================================================
// UTILITIES
// ============================================================================

/// Convert bytes to hex string (faster than Dart's hex package)
String bytesToHex(List<int> bytes) {
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  return RustCryptoBindings.toHex(data);
}

/// Convert hex string to bytes
Uint8List? hexToBytes(String hex) {
  return RustCryptoBindings.fromHex(hex);
}