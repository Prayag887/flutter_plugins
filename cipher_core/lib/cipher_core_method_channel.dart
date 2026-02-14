import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cipher_core_platform_interface.dart';

/// An implementation of [CipherCorePlatform] that uses method channels.
class MethodChannelCipherCore extends CipherCorePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cipher_core');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
