import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_core/cipher_core.dart';
import 'package:cipher_core/cipher_core_platform_interface.dart';
import 'package:cipher_core/cipher_core_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCipherCorePlatform
    with MockPlatformInterfaceMixin
    implements CipherCorePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CipherCorePlatform initialPlatform = CipherCorePlatform.instance;

  test('$MethodChannelCipherCore is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCipherCore>());
  });

  test('getPlatformVersion', () async {
    CipherCore cipherCorePlugin = CipherCore();
    MockCipherCorePlatform fakePlatform = MockCipherCorePlatform();
    CipherCorePlatform.instance = fakePlatform;

    expect(await cipherCorePlugin.getPlatformVersion(), '42');
  });
}
