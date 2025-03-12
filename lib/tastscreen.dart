import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

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
  bool _isToggling = false;
  String _receivedData = ""; // Flag to track the toggling state
  int _waterHeightGlobal = 0; // Extracted water height
  int _humidifierState = 0;
  String? _connectedDeviceId;

  final Set<DiscoveredDevice> _foundDevices = {}; // Use Set to avoid duplicates
  late StreamSubscription<DiscoveredDevice> _scanSubscription;
  Timer? _scanTimer;

  final String _serviceUuid = "fd34f551-28ea-4db1-b83d-d4dc4719c508";
  final String _characteristicUuid = "fad2648e-5eba-4cf8-9275-68df18d432e0";
  final String _outputCharacteristicUuid =
      "142f29dd-b1f0-4fa8-8e55-5a2d5f3e2471";

  // Variable to hold received data (NEW)

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

    final Set<String> deviceIds = {};

    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
      if (deviceIds.add(device.id)) {
        setState(() {
          _foundDevices.add(device);
        });
      }
    }, onError: (error) {
      print("Scan error: $error");
      _scanSubscription.cancel();
    });

    _scanTimer = Timer(Duration(seconds: 5), () {
      _scanSubscription.cancel();
      print("Scanning stopped after timeout.");
      setState(() {});
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

        final services = await _ble.discoverServices(deviceId);
        print("Discovered services: ${services.map((s) => s.serviceId)}");

        for (var service in services) {
          if (service.serviceId == Uuid.parse(_serviceUuid)) {
            for (var characteristic in service.characteristics) {
              if (characteristic.characteristicId ==
                  Uuid.parse(_outputCharacteristicUuid)) {
                _outputCharacteristic = QualifiedCharacteristic(
                  deviceId: deviceId,
                  serviceId: Uuid.parse(_serviceUuid),
                  characteristicId: Uuid.parse(_outputCharacteristicUuid),
                );
                _subscribeToCharacteristic(); // Subscribe to notifications (NEW)
              }
              if (characteristic.characteristicId ==
                  Uuid.parse(_characteristicUuid)) {
                _txCharacteristic = QualifiedCharacteristic(
                  deviceId: deviceId,
                  serviceId: Uuid.parse(_serviceUuid),
                  characteristicId: Uuid.parse(_characteristicUuid),
                );
              }
            }
          }
        }

        setState(() {
          _isConnected = true;
        });
      }
    }, onError: (error) {
      print("Connection error: $error");
    });
  }
//i added this part

  List<String> _globalDataPacket =
      List.filled(10, '0'); // Global packet (size 10)
  int _globalWaterLevel = 0; // Global water level
  int _globalHumidifierState = 0; // Global humidifier state

  // Full received array as a string
  // Extracted humidifier state

  // Replace with your BLE subscription logic
  void _subscribeToCharacteristic() {
    _ble.subscribeToCharacteristic(_outputCharacteristic).listen((data) {
      try {
        // Decode received data
        final receivedString = utf8.decode(data);
        print("Data received From SmartMat: $receivedString");

        // Convert the received string into an array
        final List<String> stringArray = receivedString
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((e) => e.trim())
            .toList();

        if (stringArray.length == 10) {
          // Update global packet
          setState(() {
            _globalDataPacket = List.from(stringArray);
            _globalWaterLevel = int.parse(_globalDataPacket[0]);
            _globalHumidifierState = int.parse(_globalDataPacket[1]);

            // Sync toggle button state with global humidifier state
            _lightState = _globalHumidifierState == 1;
          });
        }

        // Update received packet values for the local UI
        int waterHeightGlobal = int.parse(stringArray[0]);
        int humidifierState = int.parse(stringArray[1]);

        setState(() {
          _receivedData = receivedString; // Display full received packet
          _waterHeightGlobal = waterHeightGlobal; // Local water height
          _humidifierState = humidifierState; // Local humidifier state
        });

        // Debug information
        print("Global Packet: $_globalDataPacket");
        print("Global Water Level: $_globalWaterLevel");
        print("Global Humidifier State: $_globalHumidifierState");
      } catch (error) {
        print("Error parsing received data: $error");
      }
    }, onError: (error) {
      print("Error receiving data: $error");
    });
  }

  // addetationaladded

  void _toggleLight() {
    if (_isConnected && _connectedDeviceId != null) {
      final command = [_lightState ? 0 : 1]; // ON: 1, OFF: 0
      _ble.writeCharacteristicWithoutResponse(_txCharacteristic,
          value: command);

      // Update the global humidifier state
      setState(() {
        _lightState = !_lightState; // Toggle light state
        _globalHumidifierState =
            _lightState ? 1 : 0; // Update global humidifier state
        _globalDataPacket[1] =
            _globalHumidifierState.toString(); // Reflect in global packet
      });

      print("Light toggled: ${_lightState ? 'ON' : 'OFF'}");
      print("Updated Global Humidifier State: $_globalHumidifierState");
      print("Updated Global Packet: $_globalDataPacket");
    }
  }

  void _sendOutputData() {
    if (_isConnected && _connectedDeviceId != null) {
      final outputData = utf8.encode("smart");
      _ble.writeCharacteristicWithoutResponse(_txCharacteristic,
          value: outputData);
      print("Data sent via OUTPUT characteristic.");
    }
  }

  void _toggleLightPeriodically() {
    if (_isConnected && _connectedDeviceId != null) {
      int count = 0;
      const int maxCount = 6; // 1 minute = 6 intervals of 10 seconds

      Timer.periodic(Duration(seconds: 10), (Timer timer) {
        if (count >= maxCount) {
          timer.cancel(); // Stop after 1 minute
          setState(() {
            _isToggling = false; // Stop the toggling
          });
          print("Toggling finished.");
          return;
        }

        // Toggle the light between on (1) and off (0)
        final command = [_lightState ? 5 : 9]; // ON: 1, OFF: 0
        _ble.writeCharacteristicWithoutResponse(_txCharacteristic,
            value: command);
        setState(() => _lightState = !_lightState);
        print("Light toggled: ${_lightState ? 'ON' : 'OFF'}");

        count++;
      });
    } else {
      print("Device not connected or _connectedDeviceId is null.");
    }
  }

//extra added////////////////////////////////////

  // Dummy BLE Service Class for demonstration

////recived part will ended

  @override
  void dispose() {
    _scanSubscription.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }

  void _stopToggling() {
    setState(() {
      _isToggling = false; // Stop the toggling
    });
    print("Toggling stopped.");
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
                  title: Text(
                      device.name.isNotEmpty ? device.name : "Unnamed Device"),
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

                SizedBox(height: 10),

                ElevatedButton(
                  onPressed: _isConnected ? _sendOutputData : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.blue : Colors.grey,
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

                SizedBox(height: 5),

                ElevatedButton(
                  onPressed: _isConnected && _connectedDeviceId != null
                      ? () {
                          if (_isToggling) {
                            _stopToggling(); // Stop toggling
                          } else {
                            _toggleLightPeriodically(); // Start toggling
                            setState(() {
                              _isToggling = true; // Mark toggling as started
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isToggling
                        ? Colors.red
                        : Colors.blue, // Change color based on toggling state
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isToggling
                        ? 'Stop Toggling Light'
                        : 'Start Toggling Light', // Change text based on toggling state
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                SizedBox(height: 5),
                Text(
                  "Received Data:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _receivedData,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),

                SizedBox(height: 5),
                Text(
                  "Water Height:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text(
                  '$_waterHeightGlobal',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  "Humidifier State:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text(
                  '$_humidifierState',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),

                // Global Data Section
                SizedBox(height: 5),
                Text(
                  "Global Data:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _globalDataPacket.join(', '),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Global Water Level:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text(
                  '$_globalWaterLevel',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  "Global Humidifier State:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text(
                  '$_globalHumidifierState',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],

              ///annded thing screen
            ),
        ],
      ),
    );
  }
}
