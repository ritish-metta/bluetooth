import 'dart:async';
import 'dart:convert'; // For encoding and decoding strings
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController with WidgetsBindingObserver {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Observables
  final devices = <DiscoveredDevice>[].obs;
  final isScanning = false.obs;
  final isConnecting = false.obs;
  final isConnected = false.obs;
  final connectedDeviceId = ''.obs;
  final connectedDeviceName = ''.obs;
  final receivedTextData = ''.obs;
  final statusMessage = ''.obs;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  final discoveredServices = <Uuid, List<Uuid>>{}.obs;

  // UUIDs for reading and writing
  final predefinedUUIDs = {
    'serviceId': Uuid.parse("fd34f551-28ea-4db1-b83d-d4dc4719c508"),
    'CHARACTERISTIC_OUTPUT_UUID':
        Uuid.parse("fad2648e-5eba-4cf8-9275-68df18d432e0"),
    'CHARACTERISTIC_INPUT_UUID':
        Uuid.parse("02639a8e-b355-476d-9028-274125328b58"),
  };

  get currentCharacteristic => null;

  // Method to scan for devices
  Future<void> scanDevices({Duration duration = const Duration(seconds: 5)}) async {
    if (isScanning.value) return;

    isScanning.value = true;
    devices.clear();

    try {
      _scanSubscription = _ble.scanForDevices(
          withServices: [], // You can specify services to scan for if needed
          scanMode: ScanMode.lowLatency)
        .listen((device) {
          // Check if the device is not already in the list before adding it
          if (!devices.any((d) => d.id == device.id)) {
            devices.add(device);
          }
        }, onError: (error) {
          statusMessage.value = "Scan error: $error";
        });

      // Wait for the scan duration, then stop scanning
      await Future.delayed(duration);
    } catch (e) {
      statusMessage.value = "Error during scan: $e";
    } finally {
      // Ensure the scan subscription is canceled after scan ends
      await _scanSubscription?.cancel();
      isScanning.value = false;
    }
  }

  // Optimized method to connect to a device
  Future<void> connectToDevice(String deviceId) async {
    if (isConnected.value || isConnecting.value) return;
    isConnecting.value = true;

    try {
      _connectionSubscription = _ble
          .connectToDevice(
              id: deviceId, connectionTimeout: const Duration(seconds: 10))
          .listen((state) async {
        switch (state.connectionState) {
          case DeviceConnectionState.connected:
            await _onDeviceConnected(deviceId);
            break;
          case DeviceConnectionState.disconnected:
            await _onDeviceDisconnected();
            break;
          default:
            break;
        }
      }, onError: (error) {
        statusMessage.value = "Connection error: $error";
      });
    } finally {
      isConnecting.value = false;
    }
  }

  // Connection successful callback
  Future<void> _onDeviceConnected(String deviceId) async {
    isConnected.value = true;
    connectedDeviceId.value = deviceId;

    final device = devices.firstWhereOrNull((d) => d.id == deviceId);
    connectedDeviceName.value = device?.name ?? "Unknown Device";

    await discoverServices(deviceId);
    await _subscribeToNotifications(deviceId);
  }

  // Discover services of the connected device
  Future<void> discoverServices(String deviceId) async {
    try {
      final services = await _ble.discoverServices(deviceId);
      discoveredServices.clear();

      for (var service in services) {
        discoveredServices[service.serviceId] =
            service.characteristics.map((c) => c.characteristicId).toList();
      }
    } catch (e) {
      statusMessage.value = "Error discovering services: $e";
    }
  }

  // Subscribe to notifications from the device
  Future<void> _subscribeToNotifications(String deviceId) async {
    await _notificationSubscription?.cancel();

    final outputUuid = predefinedUUIDs['CHARACTERISTIC_OUTPUT_UUID'];
    if (outputUuid == null || discoveredServices.isEmpty) return;

    final characteristic = QualifiedCharacteristic(
      serviceId: discoveredServices.keys.first,
      characteristicId: outputUuid,
      deviceId: deviceId,
    );

    _notificationSubscription =
        _ble.subscribeToCharacteristic(characteristic).listen((data) {
      receivedTextData.value = utf8.decode(data);
    });
  }



  // Optimized method for sending data to the device
  Future<void> sendDataToDevice(String data, {bool withResponse = false}) async {
  if (!isConnected.value) return;

  try {
    final inputUuid = predefinedUUIDs['CHARACTERISTIC_INPUT_UUID'];
    if (inputUuid == null || discoveredServices.isEmpty) return;

    final characteristic = QualifiedCharacteristic(
      serviceId: discoveredServices.keys.first,
      characteristicId: inputUuid,
      deviceId: connectedDeviceId.value,
    );

    final encodedData = utf8.encode(data);

    if (withResponse) {
      // Write with response
      await _ble.writeCharacteristicWithResponse(characteristic, value: encodedData);
      statusMessage.value = "Sent with response: '$data'";
    } else {
      // Write without response
      await _ble.writeCharacteristicWithoutResponse(characteristic, value: encodedData);
      statusMessage.value = "Sent without response: '$data'";
    }
  } catch (e) {
    statusMessage.value = "Error sending data: $e";
  }
}





  // Disconnect the device and reset states
  Future<void> disconnectDevice() async {
    if (!isConnected.value) return;

    try {
      await _connectionSubscription?.cancel();
      await _onDeviceDisconnected();
    } catch (e) {
      statusMessage.value = "Error disconnecting device: $e";
    }
  }

  // Device disconnected callback
  Future<void> _onDeviceDisconnected() async {
    isConnected.value = false;
    connectedDeviceId.value = '';
    connectedDeviceName.value = '';
    discoveredServices.clear();
    await _notificationSubscription?.cancel();
  }
}
