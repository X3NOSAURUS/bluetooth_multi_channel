import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart'; // or use flutter_blue_plus if you switch libraries
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothDevicesScreen(),
    );
  }
}

class BluetoothDevicesScreen extends StatefulWidget {
  @override
  _BluetoothDevicesScreenState createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance; // or FlutterBluePlus if using flutter_blue_plus
  List<BluetoothDevice> devices = [];
  String error = '';

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  void requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    bool allGranted = statuses[Permission.bluetooth]?.isGranted == true &&
                      statuses[Permission.bluetoothConnect]?.isGranted == true &&
                      statuses[Permission.bluetoothScan]?.isGranted == true &&
                      statuses[Permission.location]?.isGranted == true;

    if (allGranted) {
      startScan();
    } else {
      setState(() {
        error = 'Permissions not granted';
      });
      print('Permissions not granted');
    }
  }

  void startScan() {
    try {
      flutterBlue.startScan(timeout: Duration(seconds: 4)).catchError((e) {
        setState(() {
          error = 'Error starting scan: $e';
        });
        print('Error starting scan: $e');
      });

      flutterBlue.scanResults.listen((results) {
        for (ScanResult r in results) {
          try {
            if (_isValidUUID(r.device.id.toString())) {
              if (!devices.contains(r.device)) {
                setState(() {
                  devices.add(r.device);
                });
              }
            } else {
              print('Invalid UUID: ${r.device.id.toString()}');
            }
          } catch (e) {
            setState(() {
              error = 'Error processing scan result: $e';
            });
            print('Error processing scan result: $e');
          }
        }
      });

      flutterBlue.stopScan();
    } catch (e) {
      setState(() {
        error = 'Error during scan: $e';
      });
      print('Error during scan: $e');
    }
  }

  bool _isValidUUID(String uuid) {
    return uuid.length <= 36; // A simple check to avoid excessively large UUID strings
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
      ),
      body: error.isEmpty
          ? ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devices[index].name),
                  subtitle: Text(devices[index].id.toString()),
                );
              },
            )
          : Center(
              child: Text(error),
            ),
    );
  }
}
