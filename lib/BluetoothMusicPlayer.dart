import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothMusicPlayer extends StatefulWidget {
  const BluetoothMusicPlayer({super.key});

  @override
  _BluetoothMusicPlayerState createState() => _BluetoothMusicPlayerState();
}

class _BluetoothMusicPlayerState extends State<BluetoothMusicPlayer> {
  final BluetoothClassic _bluetoothClassic = BluetoothClassic();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Device? _connectedDevice;
  List<Device> _devicesList = [];
  bool _isConnected = false;
  bool _isScanning = false;

  final List<AudioSource> _playlist = [
    AudioSource.uri(
      Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      tag: 'Nature Sound 1',
    ),
    AudioSource.uri(
      Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'),
      tag: 'Nature Sound 2',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: _playlist));
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      _showMessage("Permissions are required for Bluetooth functionality.");
    }
  }

  Future<void> _scanForDevices() async {
    setState(() => _isScanning = true);
    try {
      final devices = await _bluetoothClassic.getPairedDevices();
      setState(() {
        _devicesList = devices;
      });
    } catch (e) {
      _showMessage("Error scanning devices: $e");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(Device device) async {
    try {
      // Correcting the argument for connect
      await _bluetoothClassic.connect(device.address, "true");
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
      });
      _showMessage("Connected to ${device.name ?? 'Device'}");
    } catch (e) {
      _showMessage("Error connecting to device: $e");
    }
  }

  Future<void> _playMusic() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      _showMessage("Error playing music: $e");
    }
  }

  Future<void> _pauseMusic() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _showMessage("Error pausing music: $e");
    }
  }

  Future<void> _disconnect() async {
    try {
      await _audioPlayer.stop();
      await _bluetoothClassic.disconnect();
      setState(() {
        _connectedDevice = null;
        _isConnected = false;
      });
    } catch (e) {
      _showMessage("Error disconnecting: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Music Player'),
        backgroundColor: const Color.fromARGB(255, 4, 214, 233),
      ),
      backgroundColor: const Color.fromARGB(255, 216, 226, 216),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isConnected)
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanForDevices,
                icon: const Icon(Icons.search),
                label: Text(_isScanning ? "Scanning..." : "Scan Devices"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: _devicesList.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                            ? "Scanning for devices..."
                            : "No devices found. Please scan.",
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devicesList.length,
                      itemBuilder: (context, index) {
                        final device = _devicesList[index];
                        return ListTile(
                          title: Text(device.name ?? "Unknown Device"),
                          subtitle: Text(device.address),
                          onTap: () {
                            if (!_isConnected) _connectToDevice(device);
                          },
                        );
                      },
                    ),
            ),
            if (_isConnected)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _playMusic,
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    onPressed: _pauseMusic,
                    icon: const Icon(Icons.pause),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
