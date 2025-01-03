import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_yoga_mat/tastscreen.dart';
//import 'package:smart_yoga_mat/tastscreen.dart';
import 'BluetoothController.dart';

class BluetoothHumidifierApp extends StatelessWidget {
  final BluetoothController controller = Get.put(BluetoothController());

  BluetoothHumidifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Bluetooth Humidifier"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to the TestScreen or Settings Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TestScreen()),
                );
              },
            ),
            SizedBox(width: 10,),
             IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to the TestScreen or Settings Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TestScreen()),
                );
              },
            ),

          ],
        ),
        body: Obx(() {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scan Button
                ElevatedButton(
                  onPressed: controller.isScanning.value
                      ? null
                      : controller.scanDevices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isScanning.value
                        ? Colors.grey
                        : const Color.fromARGB(255, 243, 82, 33),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text(controller.isScanning.value
                      ? "Scanning..."
                      : "Scan for Devices"),
                ),
                const SizedBox(height: 20),

                // Device List
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.devices.length,
                    itemBuilder: (context, index) {
                      final device = controller.devices[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          title: Text(
                            device.name.isEmpty
                                ? "Unknown Device"
                                : device.name,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              Text(device.id, style: TextStyle(fontSize: 14)),
                          trailing: ElevatedButton(
                            onPressed: () =>
                                controller.connectToDevice(device.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  controller.connectedDeviceId.value == device.id
                                      ? Colors.green
                                      : Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                            ),
                            child: Text(
                              controller.connectedDeviceId.value == device.id
                                  ? "Connected"
                                  : "Connect",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Interaction Buttons if Connected
                if (controller.isConnected.value) ...[
                  const Divider(),
                  // Humidifier Toggle Button
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Toggle humidifier state
                        final dataToSend = controller.statusMessage.value.contains("'1'")
                            ? 0
                            : 1;
                        await controller.sendDataToDevice(
                          dataToSend.toString(),
                          withResponse: dataToSend == 1,
                        );
                      } catch (e) {
                        controller.statusMessage.value = "Error: $e";
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text("Toggle Humidifier"),
                  ),
                  const SizedBox(height: 10),

                  // Disconnect Button
                  ElevatedButton(
                    onPressed: controller.disconnectDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text("Disconnect"),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Connect to a device to interact",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

void main() => runApp(BluetoothHumidifierApp());
