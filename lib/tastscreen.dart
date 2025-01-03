import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late QualifiedCharacteristic _txCharacteristic;
  late QualifiedCharacteristic _outputCharacteristic;
  bool _isConnected = false;
  bool _lightState = false; // Light is initially OFF
  bool _outputEnabled = false; // Output button state
  String? _connectedDeviceId;
  final Set<DiscoveredDevice> _foundDevices = {}; // Use Set to avoid duplicates
  late StreamSubscription<DiscoveredDevice> _scanSubscription;
  Timer? _scanTimer;

  final String _serviceUuid = "fd34f551-28ea-4db1-b83d-d4dc4719c508";
  final String _characteristicUuid = "fad2648e-5eba-4cf8-9275-68df18d432e0";
  final String _outputCharacteristicUuid =
      "fad2648e-5eba-4cf8-9275-68df18d432e0";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.locationWhenInUse.isDenied) {
      await Permission.locationWhenInUse.request();
    }
  }

  void _startDeviceScan() {
    print("Starting device scan...");
    setState(() {
      _foundDevices.clear();
      _isConnected = false;
      _connectedDeviceId = null;
      _outputEnabled = false;
    });

    // Use a Set to store unique device IDs
    final Set<String> deviceIds = {};

    // Start scanning
    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
      if (deviceIds.add(device.id)) { // Add device ID to the set if it's not already added
        setState(() {
          _foundDevices.add(device); // Add device to the list
        });
      }
    }, onError: (error) {
      print("Scan error: $error");
      _scanSubscription.cancel();
    });

    // Set a timeout for scanning
    _scanTimer = Timer(Duration(seconds: 5), () {
      _scanSubscription.cancel();
      print("Scanning stopped after timeout.");
      setState(() {}); // Update UI after scan stops
    });
  }

  void _connectToDevice(String deviceId) {
    print("Attempting to connect to device: $deviceId");
    setState(() {
      _connectedDeviceId = deviceId;
      _isConnected = false;
      _outputEnabled = false;
    });

    _ble.connectToDevice(id: deviceId).listen((connectionState) async {
      print("Connection state: ${connectionState.connectionState}");
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        print("Connected to $deviceId");

        // Discover services
        final services = await _ble.discoverServices(deviceId);
        print("Discovered services: ${services.map((s) => s.serviceId)}");

        // Check if the expected service and characteristic are discovered
        bool foundService = false;
        bool foundCharacteristic = false;

        for (var service in services) {
          if (service.serviceId == Uuid.parse(_serviceUuid)) {
            foundService = true;
            for (var characteristic in service.characteristics) {
              print("Discovered characteristic: ${characteristic.characteristicId}");
              if (characteristic.characteristicId == Uuid.parse(_characteristicUuid)) {
                foundCharacteristic = true;
                _txCharacteristic = QualifiedCharacteristic(
                  deviceId: deviceId,
                  serviceId: Uuid.parse(_serviceUuid),
                  characteristicId: Uuid.parse(_characteristicUuid),
                );
                _outputCharacteristic = QualifiedCharacteristic(
                  deviceId: deviceId,
                  serviceId: Uuid.parse(_serviceUuid),
                  characteristicId: Uuid.parse(_outputCharacteristicUuid),
                );
              }
            }
          }
        }

        if (!foundService) {
          print("Service not found on the device.");
        }

        if (!foundCharacteristic) {
          print("Characteristic not found on the device.");
        }

        setState(() {
          _isConnected = true;
          _outputEnabled = foundCharacteristic; // Enable output if characteristic found
        });
      }
    }, onError: (error) {
      print("Connection error: $error");
    });
  }

  void _toggleLight() {
    if (_isConnected && _connectedDeviceId != null) {
      final command = _lightState ? [10] : [9]; // OFF: 0x00, ON: 0x01
      _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
      setState(() => _lightState = !_lightState);
      print("Light toggled: ${_lightState ? 'ON' : 'OFF'}");
    }
  }

  void _sendOutputData() {
    if (_isConnected && _outputEnabled && _connectedDeviceId != null) {
      final outputData = [2025]; // Example data to send
      _ble.writeCharacteristicWithoutResponse(
          _outputCharacteristic, value: outputData);
      print("Data sent via OUTPUT characteristic.");
    }
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Light & Output Control'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startDeviceScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: Text(
              'Start Scanning',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _foundDevices.length,
              itemBuilder: (context, index) {
                final device = _foundDevices.elementAt(index);
                return ListTile(
                  title: Text(device.name.isNotEmpty
                      ? device.name
                      : "Unnamed Device"),
                  subtitle: Text(device.id),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device.id),
                    child: Text('Connect'),
                  ),
                );
              },
            ),
          ),
          if (_connectedDeviceId != null)
            Column(
              children: [
                Text(
                  _isConnected
                      ? 'Connected to $_connectedDeviceId'
                      : 'Connecting to $_connectedDeviceId...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _isConnected ? _toggleLight : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lightState ? Colors.red : Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _lightState ? 'Turn OFF Light' : 'Turn ON Light',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _outputEnabled ? _sendOutputData : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _outputEnabled ? Colors.blue : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Send Output Data',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
