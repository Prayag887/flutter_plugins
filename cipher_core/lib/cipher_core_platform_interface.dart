import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cipher_core_method_channel.dart';

abstract class CipherCorePlatform extends PlatformInterface {
  /// Constructs a CipherCorePlatform.
  CipherCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static CipherCorePlatform _instance = MethodChannelCipherCore();

  /// The default instance of [CipherCorePlatform] to use.
  ///
  /// Defaults to [MethodChannelCipherCore].
  static CipherCorePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CipherCorePlatform] when
  /// they register themselves.
  static set instance(CipherCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
