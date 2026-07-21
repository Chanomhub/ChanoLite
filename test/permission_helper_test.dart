// test/permission_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chanolite/utils/permission_helper.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

// ---------------------------
// MOCKS
// ---------------------------

class MockDeviceInfoPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements DeviceInfoPlatform {
  MockAndroidDeviceInfo androidInfoMock = MockAndroidDeviceInfo();

  @override
  Future<AndroidDeviceInfo> get androidInfo async => androidInfoMock;

  @override
  Future<BaseDeviceInfo> deviceInfo() async => BaseDeviceInfo(androidInfoMock.data);
}

class MockAndroidDeviceInfo extends Fake implements AndroidDeviceInfo {
  int _sdkInt = 30;

  @override
  AndroidBuildVersion get version => MockAndroidBuildVersion(sdkInt: _sdkInt);

  @override
  Map<String, dynamic> get data => {
    'version': {
      'sdkInt': _sdkInt,
      'baseOS': 'Android',
      'codename': 'REL',
      'incremental': '1',
      'previewSdkInt': 0,
      'release': '10',
      'resourcesCodename': 'REL',
      'securityPatch': '2023-01-01',
    },
    'board': 'board',
    'bootloader': 'bootloader',
    'brand': 'brand',
    'device': 'device',
    'display': 'display',
    'fingerprint': 'fingerprint',
    'hardware': 'hardware',
    'host': 'host',
    'id': 'id',
    'manufacturer': 'manufacturer',
    'model': 'model',
    'product': 'product',
    'supported32BitAbis': <String>['armeabi-v7a'],
    'supported64BitAbis': <String>['arm64-v8a'],
    'supportedAbis': <String>['arm64-v8a'],
    'tags': 'release-keys',
    'type': 'user',
    'isPhysicalDevice': true,
    'systemFeatures': <String>[],
    'serialNumber': 'unknown',
    'sdkInt': _sdkInt,
    'isLowRamDevice': false,
  };

  set sdkInt(int value) => _sdkInt = value;
}

class MockAndroidBuildVersion extends Fake implements AndroidBuildVersion {
  MockAndroidBuildVersion({required this.sdkInt});
  @override
  final int sdkInt;
}

class MockPermissionHandlerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PermissionHandlerPlatform {
  PermissionStatus requestedStatus = PermissionStatus.granted;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) async {
    print('DEBUG: requestPermissions called with requestedStatus=$requestedStatus for permissions=$permissions');
    return {
      for (final p in permissions) p: requestedStatus,
    };
  }

  PermissionStatus statusToReturn = PermissionStatus.denied;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return statusToReturn;
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) {
    return super.noSuchMethod(
      Invocation.method(#shouldShowRequestPermissionRationale, [permission]),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }

  @override
  Future<bool> openAppSettings() {
    return super.noSuchMethod(
      Invocation.method(#openAppSettings, []),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }

  // @override removed
  Future<bool> requestPermission(Permission permission) {
    return super.noSuchMethod(
      Invocation.method(#requestPermission, [permission]),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }

  // @override removed
  Future<PermissionStatus> requestPermissionsExtend(List<Permission> permissions) {
    return super.noSuchMethod(
      Invocation.method(#requestPermissionsExtend, [permissions]),
      returnValue: Future.value(PermissionStatus.denied),
      returnValueForMissingStub: Future.value(PermissionStatus.denied),
    );
  }
}

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {
  MockAndroidDeviceInfo androidInfoMock = MockAndroidDeviceInfo();

  @override
  Future<AndroidDeviceInfo> get androidInfo async => androidInfoMock;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionHelper Test', () {
    final permissionHandler = MockPermissionHandlerPlatform();
    late MockDeviceInfoPlugin mockPlugin;
    late MockAndroidDeviceInfo androidInfo;

    late PermissionHandlerPlatform originalPermissionHandlerPlatform;

    setUp(() {
      resetMockitoState();

      mockPlugin = MockDeviceInfoPlugin();
      androidInfo = mockPlugin.androidInfoMock;

      originalPermissionHandlerPlatform = PermissionHandlerPlatform.instance;

      PermissionHandlerPlatform.instance = permissionHandler;
      androidInfo.sdkInt = 30;
    });

    tearDown(() {
      PermissionHandlerPlatform.instance = originalPermissionHandlerPlatform;
    });

    test('returns true for Android 10+ (API 29+) using scoped storage', () async {
      androidInfo.sdkInt = 30;
      final result30 = await PermissionHelper.requestStoragePermission(deviceInfoPlugin: mockPlugin);
      expect(result30, true);

      androidInfo.sdkInt = 29;
      final result29 = await PermissionHelper.requestStoragePermission(deviceInfoPlugin: mockPlugin);
      expect(result29, true);
    });

    test('grants Permission.storage for Android 9 (API 28) and below', () async {
      androidInfo.sdkInt = 28;
      permissionHandler.statusToReturn = PermissionStatus.denied;
      permissionHandler.requestedStatus = PermissionStatus.granted;

      final result = await PermissionHelper.requestStoragePermission(deviceInfoPlugin: mockPlugin);
      expect(result, true);
    });

    test('denies Permission.storage for Android 9 (API 28) and below', () async {
      androidInfo.sdkInt = 28;
      permissionHandler.statusToReturn = PermissionStatus.denied;
      permissionHandler.requestedStatus = PermissionStatus.denied;

      final result = await PermissionHelper.requestStoragePermission(deviceInfoPlugin: mockPlugin);
      expect(result, false);
    });
  });
}