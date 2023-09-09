import 'dart:convert';

import 'package:esp32cam/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ServicesPage extends StatefulWidget {
  final BluetoothDevice device;
  ServicesPage({required this.device});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<BluetoothService> services = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    discoverServices();
  }

  Future<void> discoverServices() async {
    try {
      if (widget.device! == null) {
        print('Error: Bluetooth device is null');
        return;
      }
      print('Here');
      List<BluetoothService> discoveredServices =
      await widget.device.discoverServices();
      setState(() {
        services = discoveredServices;
      });

      if (connectedDevice == null) {
        print('Error: Connected device is null');
        return;
      }

      final mtu = await connectedDevice!.mtu.first;
      await connectedDevice!.requestMtu(512);
      setupNotifications();
    } catch (error) {
      print('Error discovering services: $error');
    }
  }

  void setupNotifications() async {
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            // setState(() {
            //   characteristic.lastValue = value;
            // });
          });
        }
      }
    }
  }

  Future<String> readCharacteristicValue(
      BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      return utf8.decode(value).toString();
    } catch (error) {
      print('Error reading characteristic: $error');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Services'),
        actions: [
          // IconButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(services: services,))), icon: Icon(Icons.abc)),

        ],
      ),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          BluetoothService service = services[index];
          return ListTile(
            title: Text('Service: ${service.uuid}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: service.characteristics
                  .map(
                    (characteristic) => GestureDetector(
                  onTap: () async {
                    String value =
                    await readCharacteristicValue(characteristic);
                    print('Characteristic Value: $value');
                  },
                  child: StreamBuilder<List<int>>(
                    stream: characteristic.lastValueStream,
                    initialData: characteristic.lastValue,
                    builder: (context, snapshot) {
                      // if (snapshot.hasError) {
                      //   return Text('Error: ${snapshot.error}');
                      // }
                      List<int> value = snapshot.data!;
                      var val=utf8.decode(value).toString();
                      // String curr=
                      return Text(
                        'Characteristic: ${characteristic.uuid}\nValue: $val',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      );
                    },
                  ),
                ),
              )
                  .toList(),

            ),
          );
        },
      ),
    );
  }
}
