// import 'dart:async';
// import 'package:flutter/material.dart';

// class AmbienceModePage extends StatefulWidget {
//   const AmbienceModePage({super.key});

//   @override
//   _AmbienceModePageState createState() => _AmbienceModePageState();
// }

// class _AmbienceModePageState extends State<AmbienceModePage> {
//   // Predefined mountain mode timestamps
//   final List<int> mountainTimestamps = [5, 9, 12, 17, 22, 27, 34, 41, 53, 77];




  
//   // For now, we use mountain mode timestamps as the active array.
//   late List<int> modeSecondsTimestampsArray;

//   Timer? _togglingTimer;
//   final int _totalInterval = 180; // Total duration in seconds (3 minutes)
//   int _elapsedSeconds = 0;

//   // Toggle flags (user editable) for each feature
//   bool flagLED = true;
//   bool flagFragrance = true;
//   bool flagSpeakerVolume = true;
//   bool flagHumidifier = true;
//   bool flagFanCooling = true;
//   bool flagHumidifierIntensity = true;

//   // Predefined values for each feature (can be sourced from a DB)
//   // LED state/color: represented as a two-digit int: MSB=state (0=off, 1=on) and LSB=color (1=R, 2=G, 3=B)
//   int ledState = 1; // 1 means ON
//   int ledColor = 2; // For example, 2 = Green

//   // Fragrance: values 1,2,3,4 (e.g., 3)
//   int fragranceLevel = 3;

//   // Speaker volume: 0 to 9 (mapped to 0-100% internally; here 7 means 70%)
//   int speakerVolumeLevel = 7;

//   // Humidifier state: 0=off, 1=on
//   int humidifierState = 1;

//   // Fan cooling: 0 to 9 (e.g., 6 means 60%)
//   int fanCoolingLevel = 6;

//   // Humidifier intensity: 0 or 1
//   int humidifierIntensity = 1;





//   @override

  
//   void initState() {
//     super.initState();
//     modeSecondsTimestampsArray = mountainTimestamps;
//   }

//   // Starts the periodic timer that ticks every second.
//   void _toggleLightPeriodically() {
//     // In a real-world scenario, you would first check connection status.
//     _elapsedSeconds = 0;
//     _togglingTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
//       _elapsedSeconds++;

//       // On the first second, send an initial command
//       if (_elapsedSeconds == 1) {
//         _sendAmbienceModeInitial(_elapsedSeconds);
//       }

//       // If the elapsed second is one of our predefined timestamps, send a command
//       if (modeSecondsTimestampsArray.contains(_elapsedSeconds)) {
//         _sendAmbienceMode(_elapsedSeconds);
//       }

//       // Stop after the total interval
//       if (_elapsedSeconds >= _totalInterval) {
//         _stopToggling();
//       }
//     });
//   }




//   void _stopToggling() {
//     _togglingTimer?.cancel();
//     _togglingTimer = null;
//   }

//   // Called at the first second to send an initial ambience command.
//   void _sendAmbienceModeInitial(int second) {
//     List<int> ambienceCmd = _composeAmbienceCommand();
//     print("Initial Command at second $second: $ambienceCmd");
//     _writeToBLE(ambienceCmd);
//   }

//   // Helper function to compose the ambience command based on current values and toggle flags.
//   List<int> _composeAmbienceCommand() {
//     // If a flag is false, we send 0 for that feature.
//     // LED command is a two-digit value: e.g., if ledState=1 and ledColor=2, then 12.
//     int ledComponent = flagLED ? (ledState * 10 + ledColor) : 0;
//     int fragranceComponent = flagFragrance ? fragranceLevel : 0;
//     int speakerComponent = flagSpeakerVolume ? speakerVolumeLevel : 0;
//     int humidifierComponent = flagHumidifier ? humidifierState : 0;
//     int fanCoolingComponent = flagFanCooling ? fanCoolingLevel : 0;
//     int humidifierIntensityComponent = flagHumidifierIntensity ? humidifierIntensity : 0;

//     // The command is combined into a single list in the following order.
//     return [
//       ledComponent,
//       fragranceComponent,
//       speakerComponent,
//       humidifierComponent,
//       fanCoolingComponent,
//       humidifierIntensityComponent,
//     ];
//   }



//   // Sends an ambience command based on the current elapsed second.
//   // Different cases can be used to change the command parameters.
//   void _sendAmbienceMode(int second) {
//     List<int> ambienceCmd = [];

//     switch (second) {
//       case 5:
//         // Example: LED on with Green (12), fragrance level 3, speaker volume 7, humidifier on, fan cooling 6, humidifier intensity 1.
//         ledState = 1;
//         ledColor = 2;
//         fragranceLevel = 3;
//         speakerVolumeLevel = 7;
//         humidifierState = 1;
//         fanCoolingLevel = 6;
//         humidifierIntensity = 1;
//         ambienceCmd = _composeAmbienceCommand();
//         break;

//       case 12:
//         // Sample case: change LED to Blue (13), fragrance level 4, speaker volume 5, humidifier off, fan cooling 4, humidifier intensity 0.
//         ledState = 1;
//         ledColor = 3; // Blue
//         fragranceLevel = 4;
//         speakerVolumeLevel = 5;
//         humidifierState = 0;
//         fanCoolingLevel = 4;
//         humidifierIntensity = 0;
//         ambienceCmd = _composeAmbienceCommand();
//         break;

//       case 17:
//         // Sample case: turn LED off (will result in 0 regardless of color), fragrance level 2, speaker volume 9, humidifier on, fan cooling 9, humidifier intensity 1.
//         ledState = 0;
//         ledColor = 0; // Not used when LED is off
//         fragranceLevel = 2;
//         speakerVolumeLevel = 9;
//         humidifierState = 1;
//         fanCoolingLevel = 9;
//         humidifierIntensity = 1;
//         ambienceCmd = _composeAmbienceCommand();
//         break;

//       case 22:
//         // Sample case: LED on with Red (11), fragrance level 1, speaker volume 3, humidifier on, fan cooling 7, humidifier intensity 1.
//         ledState = 1;
//         ledColor = 1; // Red
//         fragranceLevel = 1;
//         speakerVolumeLevel = 3;
//         humidifierState = 1;
//         fanCoolingLevel = 7;
//         humidifierIntensity = 1;
//         ambienceCmd = _composeAmbienceCommand();
//         break;

//       default:
//         // For any other timestamp, send the default command.
//         ambienceCmd = _composeAmbienceCommand();
//         break;
//     }

//     print("Sending data: $ambienceCmd at second $second");
//     _writeToBLE(ambienceCmd);

//     // Optionally, update UI or toggle internal state here.
//     setState(() {
//       // e.g., update a light state or log output
//     });
//   }








//   // Simulated BLE write function (replace with your actual BLE logic)
//   void _writeToBLE(List<int> command) {
//     print("BLE Write: $command");
//     // _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//   }

//   @override
//   void dispose() {
//     _togglingTimer?.cancel();
//     super.dispose();
//   }



//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Ambience Mode"),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[



//               Text("Elapsed Seconds: $_elapsedSeconds"),


//               ElevatedButton(
//                 onPressed: _toggleLightPeriodically,
//                 child: const Text("Start Ambience Mode"),
//               ),



//               const SizedBox(height: 20),
//               // Toggle switches for each feature so the user can enable/disable them.


//               SwitchListTile(
//                 title: const Text("LED"),
//                 value: flagLED,
//                 onChanged: (bool value) {
//                   setState(() {
//                     flagLED = value;
//                   });
//                 },
//               ),


//               SwitchListTile(
//                 title: const Text("Fragrance"),
//                 value: flagFragrance,
//                 onChanged: (bool value) {
//                   setState(() {
//                     flagFragrance = value;
//                   });
//                 },
//               ),


              
//               SwitchListTile(
//                 title: const Text("Speaker Volume"),
//                 value: flagSpeakerVolume,
//                 onChanged: (bool value) {
//                   setState(() {
//                     flagSpeakerVolume = value;
//                   });
//                 },
//               ),
//               SwitchListTile(
//                 title: const Text("Humidifier"),
//                 value: flagHumidifier,
//                 onChanged: (bool value) {
//                   setState(() {
//                     flagHumidifier = value;
//                   });
//                 },
//               ),
//               SwitchListTile(
//                 title: const Text("Fan Cooling"),
//                 value: flagFanCooling,
//                 onChanged: (bool value) {
//                   setState(() {
//                     flagFanCooling = value;
//                   });
//                 },
//               ),
//               SwitchListTile(
//                 title: const Text("Humidifier Intensity"),
//                 value: flagHumidifierIntensity,
//                 onChanged: (bool value) {
//                   setState(() {
//                     flagHumidifierIntensity = value;
//                   });
//                 },
//               ),


              
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


//**************other cases from the ble data screen*********/


// void _sendAmbienceMode(int second) {
//   switch (second) {
//     case 5:
//       // LED Control
//       if (flagLED) {
//         List<int> command = utf8.encode("A15"); // Example LED command
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent A15 because flagLED is true");
//       } else {
//         List<int> command = utf8.encode("false");
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent false because flagLED is false");
//       }
//       break;

//     case 9:
//       // Fragrance Control
//       if (flagFragrance) {
//         List<int> command = utf8.encode("B${fragranceLevel}"); // Fragrance level command
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent fragrance command: B$fragranceLevel");
//       } else {
//         List<int> command = utf8.encode("false");
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent false because flagFragrance is false");
//       }
//       break;

//     case 12:
//       // Speaker Volume Control
//       if (flagSpeakerVolume) {
//         List<int> command = utf8.encode("C${speakerVolumeLevel}"); // Volume level command
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent speaker volume command: C$speakerVolumeLevel");
//       } else {
//         List<int> command = utf8.encode("false");
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent false because flagSpeakerVolume is false");
//       }
//       break;

//     case 17:
//       // Humidifier Control
//       if (flagHumidifier) {
//         List<int> command = utf8.encode("D${humidifierState}"); // Humidifier state command
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent humidifier command: D$humidifierState");
//       } else {
//         List<int> command = utf8.encode("false");
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent false because flagHumidifier is false");
//       }
//       break;

//     case 22:
//       // Fan Cooling Control
//       if (flagFanCooling) {
//         List<int> command = utf8.encode("E${fanCoolingLevel}"); // Fan cooling level command
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent fan cooling command: E$fanCoolingLevel");
//       } else {
//         List<int> command = utf8.encode("false");
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent false because flagFanCooling is false");
//       }
//       break;

//     case 27:
//       // Humidifier Intensity Control
//       if (flagHumidifierIntensity) {
//         List<int> command = utf8.encode("F${humidifierIntensity}"); // Humidifier intensity command
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent humidifier intensity command: F$humidifierIntensity");
//       } else {
//         List<int> command = utf8.encode("false");
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent false because flagHumidifierIntensity is false");
//       }
//       break;

//     case 34:
//       // Optional: Additional feature or repeat of previous commands
//       // Example: Combining LED and Fragrance
//       if (flagLED && flagFragrance) {
//         List<int> ledCommand = utf8.encode("A${ledState}${ledColor}");
//         List<int> fragranceCommand = utf8.encode("B${fragranceLevel}");
        
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: ledCommand);
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: fragranceCommand);
        
//         print("Sent combined LED and Fragrance commands");
//       } else {
//         List<int> command = utf8.encode("false");
//         _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//         print("Sent false due to LED or Fragrance flag being false");
//       }
//       break;

//     case 41:
//       // Optional: System-wide reset or synchronization
//       List<int> command = utf8.encode("SYNC");
//       _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//       print("Sent system sync command");
//       break;

//     case 53:
//       // Optional: Status check or diagnostic
//       List<int> command = utf8.encode("STATUS");
//       _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//       print("Sent status check command");
//       break;

//     case 77:
//       // Final stage: Potential shutdown or reset
//       List<int> command = utf8.encode("RESET");
//       _ble.writeCharacteristicWithoutResponse(_txCharacteristic, value: command);
//       print("Sent final reset command");
//       break;
//   }
// }






// SingleChildScrollView(
//   scrollDirection: Axis.horizontal,
//   child: Row(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       ElevatedButton(
//         onPressed: _isConnected ? _toggleLight : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _lightState ? Colors.red : Colors.green,
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           _lightState ? 'Turn OFF' : 'Turn ON',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//       SizedBox(width: 10),
//       ElevatedButton(
//         onPressed: _isConnected ? _sendOutputData : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _isConnected ? Colors.blue : Colors.grey,
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           'Send Data',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//       SizedBox(width: 10),


//       ElevatedButton(
//         onPressed: _isConnected && _connectedDeviceId != null
//             ? () {
//                 if (_sectionStarted) {
//                   _endSection();
//                 } else {
//                   _toggleLightPeriodically();
//                 }
//               }
//             : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _sectionStarted
//               ? Colors.red
//               : Color.fromARGB(255, 247, 104, 9),
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           _sectionStarted ? 'End Section' : 'Start Section',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),


//       SizedBox(width: 10),


//       ElevatedButton(
//         onPressed: _sectionStarted ? _togglePausePlay : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _isPaused ? Colors.green : Colors.blue,
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           _isPaused ? 'Resume' : 'Pause',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),


//     ],
//   ),
// ),
// // Add section status indicators
// if (_sectionStarted) 
//   Padding(
//     padding: const EdgeInsets.symmetric(vertical: 10),
//     child: Text(
//       _isPaused 
//         ? "Section PAUSED at $_elapsedSeconds seconds" 
//         : "Section RUNNING: $_elapsedSeconds seconds",
//       style: TextStyle(
//         fontSize: 16, 
//         fontWeight: FontWeight.bold,
//         color: _isPaused ? Colors.orange : Colors.blue
//       ),
//     ),
//   ),


// The "Start Section" button now includes the pause/resume functionality:

// Initially shows "Start Section"
// Changes to "Pause Section" when section is running
// Changes to "Resume Section" when section is paused
// Add these variables to your _BledatascreenState class


// bool _isPaused = false;
// bool _sectionStarted = false;

// // Modify your _toggleLightPeriodically function
// void _toggleLightPeriodically() {
//   setState(() {
//     _elapsedSeconds = 0;
//     _sectionStarted = true;
//     _isPaused = false;
//     _isToggling = true;
//     _executionLog = []; // Clear previous execution log
//   });
  
//   _togglingTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
//     if (!_isPaused) {
//       setState(() {
//         _elapsedSeconds++;
//       });

//       if (modeSecondsTimestampsArray.contains(_elapsedSeconds)) {
//         _sendAmbienceMode(_elapsedSeconds);
//       }

//       if (_elapsedSeconds >= _totalInterval) {
//         _endSection();
//       }
//     }
//   });
// }




// // Add this new function to handle pausing and resuming
// void _togglePausePlay() {
//   if (_sectionStarted) {
//     setState(() {
//       _isPaused = !_isPaused;
//     });
//     print(_isPaused ? "Section paused at $_elapsedSeconds seconds" : "Section resumed");
//   }
// }

// // Add this function to end the section completely
// void _endSection() {
//   _togglingTimer?.cancel();
//   _togglingTimer = null;
//   setState(() {
//     _isToggling = false;
//     _sectionStarted = false;
//     _isPaused = false;
//   });
//   print("Section ended at $_elapsedSeconds seconds");
// }

// //ui


// SingleChildScrollView(
//   scrollDirection: Axis.horizontal,
//   child: Row(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       ElevatedButton(
//         onPressed: _isConnected ? _toggleLight : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _lightState ? Colors.red : Colors.green,
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           _lightState ? 'Turn OFF' : 'Turn ON',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//       SizedBox(width: 10),
//       ElevatedButton(
//         onPressed: _isConnected ? _sendOutputData : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _isConnected ? Colors.blue : Colors.grey,
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           'Send Data',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//       SizedBox(width: 10),


//       // Start/Pause/Resume Section Button
//       ElevatedButton(
//         onPressed: _isConnected && _connectedDeviceId != null
//             ? () {
//                 if (!_sectionStarted) {
//                   // Start the section
//                   _toggleLightPeriodically();
//                 } else if (!_isPaused) {
//                   // Pause the section
//                   _togglePausePlay();
//                 } else {
//                   // Resume the section
//                   _togglePausePlay();
//                 }
//               }
//             : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: !_sectionStarted
//               ? Color.fromARGB(255, 247, 104, 9)
//               : (_isPaused ? Colors.green : Color.fromARGB(255, 35, 4, 234)),
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           !_sectionStarted 
//               ? 'Start Section' 
//               : (_isPaused ? 'Resume Section' : 'Pause Section'),
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//       SizedBox(width: 10),
//       // End Section Button



//       ElevatedButton(
//         onPressed: _sectionStarted ? _endSection : null,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red,
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: Text(
//           'End Section',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),


//     ],
//   ),
// ),
// // Add section status indicators
// if (_sectionStarted) 
//   Padding(
//     padding: const EdgeInsets.symmetric(vertical: 10),
//     child: Text(
//       _isPaused 
//         ? "Section PAUSED at $_elapsedSeconds seconds" 
//         : "Section RUNNING: $_elapsedSeconds seconds",
//       style: TextStyle(
//         fontSize: 16, 
//         fontWeight: FontWeight.bold,
//         color: _isPaused ? Colors.orange : Colors.blue
//       ),
//     ),
//   ),