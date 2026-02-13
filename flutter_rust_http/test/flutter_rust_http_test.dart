// import 'package:flutter_test/flutter_test.dart';
// import 'package:image_ffi/image_ffi.dart';
// import 'package:image_ffi/image_ffi_platform_interface.dart';
// import 'package:image_ffi/image_ffi_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockFlutterRustHttpPlatform
//     with MockPlatformInterfaceMixin
//     implements FlutterRustHttpPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final FlutterRustHttpPlatform initialPlatform = FlutterRustHttpPlatform.instance;
//
//   test('$MethodChannelFlutterRustHttp is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelFlutterRustHttp>());
//   });
//
//   test('getPlatformVersion', () async {
//     FlutterRustHttp flutterRustHttpPlugin = FlutterRustHttp();
//     MockFlutterRustHttpPlatform fakePlatform = MockFlutterRustHttpPlatform();
//     FlutterRustHttpPlatform.instance = fakePlatform;
//
//     expect(await flutterRustHttpPlugin.getPlatformVersion(), '42');
//   });
// }
