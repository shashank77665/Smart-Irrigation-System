import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_irrigation/infor.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isPumpOn = false;
  bool _manualControl = false;
  int _soilMoisture = 0;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smart Irrigation System',
          style: TextStyle(
            fontSize: 23,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(245, 5, 51, 130),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InfoPage(),
                    ));
              },
              child: Icon(
                Icons.info,
                size: 30,
                color: const Color.fromARGB(124, 255, 255, 255),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _database.onValue, // Listen for any changes in the database
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text('Error fetching data'));
            }

            // Parse the data from the Realtime Database
            var data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            // Fetch the values from the data
            _manualControl = data['controls']['manualControlToggle'] ?? false;
            _isPumpOn = data['controls']['pumpState'] ?? false;
            _soilMoisture = data['sensors']['soilMoisture'] ?? 0;

            // Determine moisture-related info
            String moistureInfo;
            if (_manualControl) {
              moistureInfo = 'Manual control is active'; // Manual control is on
            } else if (_soilMoisture < 300) {
              moistureInfo =
                  'Moisture is low, watering needed'; // Moisture too low
            } else {
              moistureInfo = 'Soil moisture is adequate'; // Adequate moisture
            }

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(245, 5, 51, 130),
                    const Color.fromARGB(255, 121, 30, 137),
                  ],
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(245, 5, 51, 130),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: _manualControl
                        ? Center(
                            child: Text('Manual Mode',
                                style: TextStyle(
                                    fontSize: 24, color: Colors.white)))
                        : Column(
                            children: [
                              SizedBox(height: 10),
                              Container(
                                alignment: Alignment.centerLeft,
                                margin:
                                    const EdgeInsets.only(left: 20, bottom: 10),
                                child: const Text(
                                  'Current Status',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Show all information in one card
                              _buildStatisticsCard(
                                soilMoisture: _soilMoisture,
                                moistureInfo: moistureInfo,
                              ),
                            ],
                          ),
                  ),
                  SizedBox(height: 10),
                  // Manual control toggle
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        Text(
                          'Manual Control',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        SwitchListTile(
                          title: Text(
                            _manualControl
                                ? 'Manual Control is ON'
                                : 'Manual Control is OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          value: _manualControl,
                          onChanged: (bool value) {
                            setState(() {
                              _manualControl = value;
                            });
                            // Update Firebase Realtime Database
                            _database
                                .child('controls')
                                .update({'manualControlToggle': value});
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.red,
                        ),
                        SizedBox(height: 50),
                        // Circular button to toggle pump state
                        GestureDetector(
                            onTap: () {
                              // Check if manual control is enabled
                              if (_manualControl) {
                                setState(() {
                                  _isPumpOn = !_isPumpOn;
                                });
                                // Update Firebase Realtime Database
                                _database
                                    .child('controls')
                                    .update({'pumpState': _isPumpOn});
                              } else {
                                // Show Snackbar when manual control is not enabled
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Manual control is not enabled!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: _isPumpOn ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPumpOn
                                          ? Icons.local_florist
                                          : Icons.not_interested,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      _isPumpOn ? 'watering' : 'Stopped',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Pump Status',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Updated _buildStatisticsCard method to show all info in one card
  Widget _buildStatisticsCard({
    required int soilMoisture,
    required String moistureInfo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 30, right: 30),
      child: Container(
        height: 70,
        // width: 350,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Soil Moisture',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              '$soilMoisture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              moistureInfo,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
