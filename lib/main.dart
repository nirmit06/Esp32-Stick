import 'package:esp32cam/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Esp32cam'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

BluetoothDevice? connectedDevice;

class _MyHomePageState extends State<MyHomePage> {
  List<ScanResult> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
  }

  void startScan() {
    setState(() {
      isScanning = true;
    });
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devices.contains(result)) {
          setState(() {
            devices.add(result);
          });
        }
      }
    }).onDone(() {
      setState(() {
        isScanning = false;
      });
      FlutterBluePlus.stopScan();
    });
  }

  void navigateToServicesPage() {
    if (connectedDevice != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServicesPage(device: connectedDevice!),
        ),
      );
    } else {
      // Handle the case when no device is connected
      // You can show an error message or take appropriate action
      print('No device connected');
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: true);
    setState(() {
      connectedDevice = device;
      print(connectedDevice?.localName);
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ServicesPage(device: connectedDevice!),
      ),
    );

  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isScanning ? null : startScan,
              child: Text('Scan for Devices'),
              style: ButtonStyle(
                elevation: MaterialStateProperty.all<double>(0.0),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.deepPurple),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (BuildContext context, int index) {
                  ScanResult result = devices[index];
                  BluetoothDevice device = result.device;
                  return ListTile(
                    title: Text(devices[index].device.localName),
                    subtitle: Text(devices[index].device.remoteId.toString()),
                    trailing: ElevatedButton(
                      onPressed: () => connectToDevice(device),
                      child: Text('Connect'),
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all<double>(0.0),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.deepPurple),
                        foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.white), // Set the desired text color
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
