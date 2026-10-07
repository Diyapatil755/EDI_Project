import 'dart:io';
import 'dart:math';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceMetadata {
  final String deviceId;
  final String modelName;
  final String osName;
  final String osVersion;

  const DeviceMetadata({
    required this.deviceId,
    required this.modelName,
    required this.osName,
    required this.osVersion,
  });
}

abstract class DeviceService {
  Future<DeviceMetadata> getDeviceMetadata();
  Future<bool> isDeviceRegistered({required String registeredDeviceId});
  Future<void> bindDeviceAsRegistered({required String deviceId});
  Future<void> clearBoundDevice();

  /// Testing helper: simulate unmatching hardware to demonstrate security rejection
  void setSimulationMismatched(bool mismatched);
  bool get isSimulationMismatched;
}

class AppDeviceService implements DeviceService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _storageKeyDeviceId = 'app_unique_device_id';

  bool _simulateMismatch = false;

  @override
  bool get isSimulationMismatched => _simulateMismatch;

  @override
  void setSimulationMismatched(bool mismatched) {
    _simulateMismatch = mismatched;
  }

  /// Hardware-based id where the OS offers one (survives app reinstall).
  /// Falls back to a random id kept in secure storage (web / desktop).
  Future<String> _stableDeviceId() async {
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          final id = await const AndroidId().getId();
          if (id != null && id.isNotEmpty) return 'AND-$id';
        } else if (Platform.isIOS) {
          final info = await _deviceInfoPlugin.iosInfo;
          final id = info.identifierForVendor;
          if (id != null && id.isNotEmpty) return 'IOS-$id';
        }
      } catch (_) {}
    }

    String? stored;
    try {
      stored = await _secureStorage.read(key: _storageKeyDeviceId);
    } catch (_) {}
    if (stored == null || stored.isEmpty) {
      final rnd = Random.secure();
      final hex = List.generate(
        16,
        (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      stored = 'DEV-${hex.toUpperCase()}';
      try {
        await _secureStorage.write(key: _storageKeyDeviceId, value: stored);
      } catch (_) {}
    }
    return stored;
  }

  @override
  Future<DeviceMetadata> getDeviceMetadata() async {
    if (_simulateMismatch) {
      return const DeviceMetadata(
        deviceId: 'DEV-ROGUE-UNREGISTERED-88B1',
        modelName: 'Samsung Galaxy A12 (Unregistered)',
        osName: 'Android',
        osVersion: '11.0',
      );
    }

    final id = await _stableDeviceId();

    if (kIsWeb) {
      return DeviceMetadata(
        deviceId: id,
        modelName: 'Web Browser',
        osName: 'Web',
        osVersion: '-',
      );
    }

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        return DeviceMetadata(
          deviceId: id,
          modelName: '${info.brand} ${info.model}',
          osName: 'Android',
          osVersion: 'SDK ${info.version.sdkInt}',
        );
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        return DeviceMetadata(
          deviceId: id,
          modelName: info.utsname.machine,
          osName: 'iOS',
          osVersion: info.systemVersion,
        );
      }
    } catch (_) {}

    return DeviceMetadata(
      deviceId: id,
      modelName: Platform.operatingSystem,
      osName: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
    );
  }

  @override
  Future<bool> isDeviceRegistered({required String registeredDeviceId}) async {
    final current = await getDeviceMetadata();
    return current.deviceId == registeredDeviceId;
  }

  @override
  Future<void> bindDeviceAsRegistered({required String deviceId}) async {
    // Hardware ids (Android/iOS) are read from the OS each time. Only the
    // random fallback id (web / desktop) needs to be kept in storage.
    if (!deviceId.startsWith('DEV-') || deviceId.contains('ROGUE')) return;
    try {
      await _secureStorage.write(key: _storageKeyDeviceId, value: deviceId);
    } catch (_) {}
  }

  @override
  Future<void> clearBoundDevice() async {
    await _secureStorage.delete(key: _storageKeyDeviceId);
  }
}
