import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:tryapp/home.dart';

class DeviceDetailsPage extends StatefulWidget {
  final Device device;

  const DeviceDetailsPage({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceDetailsPageState createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  List<FlSpot> temperatureData = [];
  List<FlSpot> airHumidityData = [];
  List<FlSpot> soilHumidityData = [];
  List<FlSpot> npkData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchThingSpeakData();
  }

  // Fetch data from ThingSpeak
  Future<void> _fetchThingSpeakData() async {
    final url = Uri.parse(
        'https://api.thingspeak.com/channels/${widget.device.thingSpeakChannelId}/feeds.json?api_key=${widget.device.thingSpeakApiKey}&results=10');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final feeds = data['feeds'] as List;

      // Prepare data for charts
      for (int i = 0; i < feeds.length; i++) {
        final feed = feeds[i];
        final timestamp = DateTime.parse(feed['created_at']).millisecondsSinceEpoch.toDouble();

        temperatureData.add(FlSpot(
          timestamp,
          double.tryParse(feed['field1'] ?? '0') ?? 0,
        ));

        airHumidityData.add(FlSpot(
          timestamp,
          double.tryParse(feed['field2'] ?? '0') ?? 0,
        ));

        soilHumidityData.add(FlSpot(
          timestamp,
          double.tryParse(feed['field3'] ?? '0') ?? 0,
        ));

        npkData.add(FlSpot(
          timestamp,
          double.tryParse(feed['field4'] ?? '0') ?? 0,
        ));
      }

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch data from ThingSpeak')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Here it is: ${widget.device.id}');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 120),
              painter: WavyAppBarPainter(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  const Spacer(),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: widget.device.image != null
                        ? NetworkImage(widget.device.image!) // Use NetworkImage for Cloudinary URL
                        : null, // No default image
                    child: widget.device.image == null
                        ? const Icon(
                            Icons.device_unknown, // Placeholder icon
                            size: 40,
                            color: Colors.white,
                          )
                        : null, // No child if there's an image
                  ),
                  const SizedBox(height: 20),

                  // Device Name
                  Text(
                    widget.device.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Battery Level
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.battery_std, color: Colors.green),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.device.batteryLevel}%',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Charts
                  _buildChart('Température (°C)', temperatureData),
                  _buildChart('Humidité Air (%)', airHumidityData),
                  _buildChart('Humidité Sol (%)', soilHumidityData),
                  _buildChart('NPK', npkData),
                ],
              ),
            ),
    );
  }

  Widget _buildChart(String title, List<FlSpot> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: data.isNotEmpty ? data.first.x : 0,
                  maxX: data.isNotEmpty ? data.last.x : 1,
                  minY: 0,
                  maxY: data.isNotEmpty ? data.map((e) => e.y).reduce((a, b) => a > b ? a : b) : 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}