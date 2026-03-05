import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

import 'package:smart_yoga_mat/command_config.dart';


//import 'package:smart_yoga_mat/command_config.dart';

class Bledatascreen extends StatefulWidget {
  const Bledatascreen({super.key});

  @override
  _BledatascreenState createState() => _BledatascreenState();
}

class _BledatascreenState extends State<Bledatascreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late QualifiedCharacteristic _txCharacteristic;
  late QualifiedCharacteristic _outputCharacteristic;
  bool _isConnected = false;
  bool _lightState = false; // Light is initially OFF
  bool _outputEnabled = false; // Output button state
  bool _isToggling = false; 
  String _receivedData = "";
  int _waterHeightGlobal = 0; // Extracted water height
  int _humidifierState = 0;
  String? _connectedDeviceId;

  // JSON related variables
  int _currentCommandIndex = 0;  // Track current command progress
  bool _isPaused = false;  // For pause/resume functionality
  List<String> _executionLog = [];  // Track command execution history
  int _retryCount = 0;
  static const int MAX_RETRIES = 3;

  final Set<DiscoveredDevice> _foundDevices = {}; // Use Set to avoid duplicates
  late StreamSubscription<DiscoveredDevice> _scanSubscription;
  Timer? _scanTimer;

  final String _serviceUuid = "fd34f551-28ea-4db1-b83d-d4dc4719c508";
  final String _characteristicUuid = "fad2648e-5eba-4cf8-9275-68df18d432e0";
  final String _outputCharacteristicUuid =
      "142f29dd-b1f0-4fa8-8e55-5a2d5f3e2471";

  // JSON command configurations
  Map<String, dynamic> _commandData = {}; // Store JSON data
  bool _isLoadingCommands = false; // Flag for loading commands
  Timer? _commandTimer;
  bool _isExecuting = false;

  // Global variables for data packet
  List<String> _globalDataPacket = List.filled(10, '0'); // Global packet (size 10)
  int _globalWaterLevel = 0; // Global water level
  int _globalHumidifierState = 0; // Global humidifier state

  // BLE output subscription
  void _subscribeToCharacteristic() {
    _ble.subscribeToCharacteristic(_outputCharacteristic).listen((data) {
      try {
        final receivedString = utf8.decode(data);
        print("Data received: $receivedString");

        final List<String> stringArray = receivedString
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((e) => e.trim())
            .toList();

        if (stringArray.length == 10) {
          setState(() {
            _globalDataPacket = List.from(stringArray);
            _globalWaterLevel = int.parse(_globalDataPacket[0]);
            _globalHumidifierState = int.parse(_globalDataPacket[1]);
            _lightState = _globalHumidifierState == 1;
          });
        }

        int waterHeightGlobal = int.parse(stringArray[0]);
        int humidifierState = int.parse(stringArray[1]);

        setState(() {
          _receivedData = receivedString;
          _waterHeightGlobal = waterHeightGlobal;
          _humidifierState = humidifierState;
        });

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
                _subscribeToCharacteristic();
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

        Future.delayed(Duration(seconds: 3), () {
          print("BLE CONNECTED READY TO SEND COMMANDS");
        });
      }
    }, onError: (error) {
      print("Connection error: $error");
    });
  }


//flage toggle started here



  // Toggle flags (user editable) for each feature
  bool flagLED = true;
  bool flagFragrance = true;
  bool flagSpeakerVolume = true;
  bool flagHumidifier = true;
  bool flagFanCooling = true;
  bool flagHumidifierIntensity = true;
  bool flagIoniser = true;
  bool _isPausedFlag = false;
bool _sectionStarted = false;

  // Predefined values for each feature (can be sourced from a DB)
  int ledState = 1;
  int ledColor = 2;
  int fragranceLevel = 3;
  int speakerVolumeLevel = 7;
  int humidifierState = 1;
  int fanCoolingLevel = 6;
  int humidifierIntensity = 1;

  // Timing for toggling
  late List<int> modeSecondsTimestampsArray = [];
  Timer? _togglingTimer;
  final int _totalInterval = 180; // Total duration in seconds (3 minutes)
  int _elapsedSeconds = 0;



// Modify your _toggleLightPeriodically function
void _toggleLightPeriodically() {
  setState(() {
    _elapsedSeconds = 0;
    _sectionStarted = true;
    _isPaused = false;
    _isToggling = true;
    _executionLog = []; // Clear previous execution log
  });
  
  _togglingTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
    if (!_isPaused) {
      setState(() {
        _elapsedSeconds++;
      });

      if (modeSecondsTimestampsArray.contains(_elapsedSeconds)) {
        _sendAmbienceMode(_elapsedSeconds);
      }

      if (_elapsedSeconds >= _totalInterval) {
        _endSection();
      }
    }
  });
}


/// Add this new function to handle pausing and resuming
void _togglePausePlay() {
  if (_sectionStarted) {
    setState(() {
      _isPaused = !_isPaused;
    });
    print(_isPaused ? "Section paused at $_elapsedSeconds seconds" : "Section resumed");
  }
}

// Update this function to send a "stop" command
void _endSection() {
  // Send "stop" command via BLE
  if (_isConnected && _connectedDeviceId != null) {
    final stopCommand = utf8.encode("STOP");
    _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: stopCommand);
    print("Sent STOP command");
  }
  
  // Then proceed with the existing functionality
  _togglingTimer?.cancel(); 
  _togglingTimer = null;
  setState(() {
    _isToggling = false;
    _sectionStarted = false;
    _isPaused = false;
  });
  print("Section ended at $_elapsedSeconds seconds");
}

  // This function sends the command based on the configuration flag.
  // For testing, we update only the LED command ("B3") using its flag.






 void _sendAmbienceMode(int second) {
  // Find the command for the current second
  final config = _commandConfigs.firstWhere(
    (element) => element.time == second,
    orElse: () => CommandConfig(time: second, flag: false, command: ''),
  );
  
  // Skip if no command is found
  if (config.command.isEmpty) return;
  
  // Determine command type and whether it should be sent
  bool isLedCommand = config.command == 'B3' || 
                     config.command.startsWith('Red_Led_') ||
                     config.command.startsWith('Green_Led_') ||
                     config.command.startsWith('Blue_Led_');
                     
  bool isHumidCommand = config.command.startsWith('humid_');
  bool isFragranceCommand = config.command.startsWith('Frag_1') ||  config.command.startsWith('Frag_2') ||config.command.startsWith('Frag_3') ||config.command.startsWith('Frag_4');
  bool isFanCommand = config.command.startsWith('fan_');
  bool isSpeakerCommand = config.command.startsWith('vol_');
  bool isIoniser = config.command.startsWith('ion_');
  // Determine if the command should be sent based on feature flags
  bool shouldSend = false;
  String fallbackValue = "disabled";
  
  if (isLedCommand) {
    shouldSend = flagLED;
    fallbackValue = "LED_OFF";
  } else if (isHumidCommand) {
    shouldSend = flagHumidifier;
    fallbackValue = "HUMID_OFF";
  } else if (isFragranceCommand) {
    shouldSend = flagFragrance;
    fallbackValue = "FRAG_OFF";
  } else if (isFanCommand) {
    shouldSend = flagFanCooling;
    fallbackValue = "FAN_OFF";
  } else if (isSpeakerCommand) {
    shouldSend = flagSpeakerVolume;
    fallbackValue = "VOL_OFF";
  } else if (isIoniser) {
    shouldSend = flagIoniser;
    fallbackValue = "ION_OFF";
  } else {  
    // For any other command type, use the original flag
    shouldSend = config.flag;
    fallbackValue = "DISABLED";
  }

  // Send the appropriate command
  if (shouldSend) {
    List<int> commandBytes = utf8.encode(config.command);
    _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: commandBytes);
    print("Sent ${config.command} at second $second (feature enabled)");
  } else {
    // Send a more descriptive fallback message instead of just "false"
    List<int> commandBytes = utf8.encode(fallbackValue);
    _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: commandBytes);
    print("Sent $fallbackValue at second $second (feature disabled)");
  }
  
  // Log command execution
  _executionLog.add("$second: ${shouldSend ? config.command : fallbackValue}");
}


  Future<List<CommandConfig>> loadCommandConfigs() async {

    try {
      final jsonString = await rootBundle.loadString('lib/assets/commands.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);
      return jsonResponse.map((data) => CommandConfig.fromJson(data)).toList();
    } catch (e) {
      print("Error loading command configurations: $e");
      return [];
    }
  }

  List<CommandConfig> _commandConfigs = [];

  @override
void initState() {
  super.initState();
  _requestPermissions();

  // Load command configurations from JSON
  loadCommandConfigs().then((configs) {
    _commandConfigs = configs;
    // Update all LED commands with the global flagLED value
    for (var config in _commandConfigs) {
      if (config.command == 'B3' || 
          config.command.startsWith('Red_Led_') ||
          config.command.startsWith('Green_Led_') ||
          config.command.startsWith('Blue_Led_') ||
          config.command.startsWith('ion_'))
          
           {
        config.flag = flagLED;
      }
    }
    // Extract timestamps from loaded command configs
    setState(() {
      modeSecondsTimestampsArray =
          _commandConfigs.map((config) => config.time).toList();
    });
  });


  
}
  


///flage will enede here 



  void _writeToBLE(List<int> command) {
    print("BLE Write: $command");
    _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
  }

  void _stopToggling() {
    _togglingTimer?.cancel();
    _togglingTimer = null;
    setState(() {
      _isToggling = false;
    });
    print("Toggling stopped.");
  }

  void _sendData(int second) {
    final command = [_lightState ? 0 : 1];
    print("Sending data: ${command.first} at second $second");
    _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
    setState(() {
      _lightState = !_lightState;
    });
  }

  void _sendDataInitial(int second) {
    final command = [0];
    print("Sending initial data: ${command.first} at second $second");
    _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
    setState(() {
      _lightState = false;
    });
  }

  // BLE output sending
  void _sendOutputData() {
    if (_isConnected && _connectedDeviceId != null) {
      final outputData = utf8.encode("smart");
      _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: outputData);
      print("Data sent via OUTPUT characteristic.");
    }
  }

  // A simple toggle function for the LED button.
  void _toggleLight() {
    if (_isConnected && _connectedDeviceId != null) {
      final command = [_lightState ? 0 : 1]; // ON: 1, OFF: 0
      _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
      setState(() {
        _lightState = !_lightState;
        // Update global humidifier state as an example.
        _globalHumidifierState = _lightState ? 1 : 0;
        _globalDataPacket[1] = _globalHumidifierState.toString();
      });
      print("Light toggled: ${_lightState ? 'ON' : 'OFF'}");
      print("Updated Global Humidifier State: $_globalHumidifierState");
      print("Updated Global Packet: $_globalDataPacket");
    }
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    _scanTimer?.cancel();
    _togglingTimer?.cancel();
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
                  title: Text(device.name.isNotEmpty ? device.name : "Unnamed Device"),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isConnected ? _toggleLight : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lightState ? Colors.red : Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _lightState ? 'Turn OFF' : 'Turn ON',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isConnected ? _sendOutputData : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected ? Colors.blue : Colors.grey,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Send Data',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      ///the play and pause button feature will be added here
                      ///
                      ///
                  
                    ElevatedButton(
        onPressed: _isConnected && _connectedDeviceId != null
            ? () {
                if (!_sectionStarted) {
                  // Start the section
                  _toggleLightPeriodically();
                } else if (!_isPaused) {
                  // Pause the section
                  _togglePausePlay();
                } else {
                  // Resume the section
                  _togglePausePlay();
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: !_sectionStarted
              ? Color.fromARGB(255, 247, 104, 9)
              : (_isPaused ? Colors.green : Color.fromARGB(255, 35, 4, 234)),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          !_sectionStarted 
              ? 'Start Section' 
              : (_isPaused ? 'Resume Section' : 'Pause Section'),
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),


      SizedBox(width: 10),
      // End Section Button

      
     ElevatedButton(
        onPressed: _sectionStarted ? _endSection : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'End Section',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),


// Add section status indicators
if (_sectionStarted) 
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      _isPaused 
        ? "Section PAUSED at $_elapsedSeconds seconds" 
        : "Section RUNNING: $_elapsedSeconds seconds",
      style: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.bold,
        color: _isPaused ? Colors.orange : Colors.blue
      ),
    ),
  ),       
  
  
  
  
          ],
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
                SizedBox(height: 2),
                Text("Elapsed Seconds: $_elapsedSeconds"),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: SwitchListTile(
                          title: const Text("LED"),
                          value: flagLED,
                          onChanged: (bool value) {
                            setState(() {
                              flagLED = value;
                              // Update any command with "B3" to reflect the new LED flag
                              for (var config in _commandConfigs) {
                                if (config.command == 'B3') {
                                  config.flag = flagLED;
                                }
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: SwitchListTile(
                          title: const Text("Fragrance"),
                          value: flagFragrance,
                          onChanged: (bool value) {
                            setState(() {
                              flagFragrance = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: SwitchListTile(
                          title: const Text("Speaker Volume"),
                          value: flagSpeakerVolume,
                          onChanged: (bool value) {
                            setState(() {
                              flagSpeakerVolume = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: SwitchListTile(
                          title: const Text("Humidifier"),
                          value: flagHumidifier,
                          onChanged: (bool value) {
                            setState(() {
                              flagHumidifier = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: SwitchListTile(
                          title: const Text("Fan Cooling"),
                          value: flagFanCooling,
                          onChanged: (bool value) {
                            setState(() {
                              flagFanCooling = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: SwitchListTile(
                          title: const Text("Humidifier Intensity"),
                          value: flagHumidifierIntensity,
                          onChanged: (bool value) {
                            setState(() {
                              flagHumidifierIntensity = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}