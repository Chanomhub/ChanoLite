// test/permission_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
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
  @override
  Future<AndroidDeviceInfo> get androidInfo =>
      super.noSuchMethod(
        Invocation.getter(#androidInfo),
        returnValue: Future.value(MockAndroidDeviceInfo()),
        returnValueForMissingStub: Future.value(MockAndroidDeviceInfo()),
      ) as Future<AndroidDeviceInfo>;
}

class MockAndroidDeviceInfo extends Fake implements AndroidDeviceInfo {
  int _sdkInt = 30; // 默认值

  @override
  AndroidBuildVersion get version => MockAndroidBuildVersion(sdkInt: _sdkInt);

  // 使用 setter 来修改 SDK 版本
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
  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) {
    return super.noSuchMethod(
      Invocation.method(#requestPermissions, [permissions]),
      returnValue: Future.value(<Permission, PermissionStatus>{}),
      returnValueForMissingStub: Future.value(<Permission, PermissionStatus>{}),
    );
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) {
    return super.noSuchMethod(
      Invocation.method(#checkPermissionStatus, [permission]),
      returnValue: Future.value(PermissionStatus.denied),
      returnValueForMissingStub: Future.value(PermissionStatus.denied),
    );
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

  @override
  Future<bool> requestPermission(Permission permission) {
    return super.noSuchMethod(
      Invocation.method(#requestPermission, [permission]),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }

  @override
  Future<PermissionStatus> requestPermissionsExtend(List<Permission> permissions) {
    return super.noSuchMethod(
      Invocation.method(#requestPermissionsExtend, [permissions]),
      returnValue: Future.value(PermissionStatus.denied),
      returnValueForMissingStub: Future.value(PermissionStatus.denied),
    );
  }
}

void main() {
  group('PermissionHelper', () {
    late MockDeviceInfoPlatform deviceInfo;
    late MockAndroidDeviceInfo androidInfo;
    late MockPermissionHandlerPlatform permissionHandler;
    late DeviceInfoPlatform originalDeviceInfoPlatform;
    late PermissionHandlerPlatform originalPermissionHandlerPlatform;

    setUp(() {
      // 重置所有模拟对象
      resetMockitoState();

      deviceInfo = MockDeviceInfoPlatform();
      androidInfo = MockAndroidDeviceInfo();
      permissionHandler = MockPermissionHandlerPlatform();

      // 保存原始实例以便在 tearDown 中恢复
      originalDeviceInfoPlatform = DeviceInfoPlatform.instance;
      originalPermissionHandlerPlatform = PermissionHandlerPlatform.instance;

      DeviceInfoPlatform.instance = deviceInfo;
      PermissionHandlerPlatform.instance = permissionHandler;

      when(deviceInfo.androidInfo).thenAnswer((_) async => androidInfo);
    });

    tearDown(() {
      // 恢复原始实例，而不是设置为 null
      DeviceInfoPlatform.instance = originalDeviceInfoPlatform;
      PermissionHandlerPlatform.instance = originalPermissionHandlerPlatform;
    });

    test('grants MANAGE_EXTERNAL_STORAGE for Android 11+ (API 30+)', () async {
      androidInfo.sdkInt = 30;

      // 模拟所有可能的权限检查和请求
      when(permissionHandler.checkPermissionStatus(Permission.manageExternalStorage))
          .thenAnswer((_) async => PermissionStatus.denied);
      when(permissionHandler.shouldShowRequestPermissionRationale(Permission.manageExternalStorage))
          .thenAnswer((_) async => false);

      // 模拟权限请求成功
      when(permissionHandler.requestPermissions([Permission.manageExternalStorage]))
          .thenAnswer((_) async => {
        Permission.manageExternalStorage: PermissionStatus.granted,
      });

      final result = await PermissionHelper.requestStoragePermission();
      expect(result, true);

      // 验证权限请求被调用
      verify(permissionHandler.requestPermissions([Permission.manageExternalStorage])).called(1);
    });

    test('denies MANAGE_EXTERNAL_STORAGE for Android 11+ (API 30+)', () async {
      androidInfo.sdkInt = 30;

      // 模拟所有可能的权限检查和请求
      when(permissionHandler.checkPermissionStatus(Permission.manageExternalStorage))
          .thenAnswer((_) async => PermissionStatus.denied);
      when(permissionHandler.shouldShowRequestPermissionRationale(Permission.manageExternalStorage))
          .thenAnswer((_) async => false);

      // 模拟权限请求被拒绝
      when(permissionHandler.requestPermissions([Permission.manageExternalStorage]))
          .thenAnswer((_) async => {
        Permission.manageExternalStorage: PermissionStatus.denied,
      });

      final result = await PermissionHelper.requestStoragePermission();
      expect(result, false);
    });

    test('grants Permission.storage for Android 10 (API 29) and below', () async {
      androidInfo.sdkInt = 29;

      // 模拟所有可能的权限检查和请求
      when(permissionHandler.checkPermissionStatus(Permission.storage))
          .thenAnswer((_) async => PermissionStatus.denied);
      when(permissionHandler.shouldShowRequestPermissionRationale(Permission.storage))
          .thenAnswer((_) async => false);

      // 模拟权限请求成功
      when(permissionHandler.requestPermissions([Permission.storage]))
          .thenAnswer((_) async => {Permission.storage: PermissionStatus.granted});

      final result = await PermissionHelper.requestStoragePermission();
      expect(result, true);
    });

    test('denies Permission.storage for Android 10 (API 29) and below', () async {
      androidInfo.sdkInt = 29;

      // 模拟所有可能的权限检查和请求
      when(permissionHandler.checkPermissionStatus(Permission.storage))
          .thenAnswer((_) async => PermissionStatus.denied);
      when(permissionHandler.shouldShowRequestPermissionRationale(Permission.storage))
          .thenAnswer((_) async => false);

      // 模拟权限请求被拒绝
      when(permissionHandler.requestPermissions([Permission.storage]))
          .thenAnswer((_) async => {Permission.storage: PermissionStatus.denied});

      final result = await PermissionHelper.requestStoragePermission();
      expect(result, false);
    });
  });
}