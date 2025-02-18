import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:tryapp/deviceInfos.dart';
import 'package:tryapp/doctor.dart';
import 'package:tryapp/irrigation.dart';
import 'package:tryapp/notification.dart';
import 'package:tryapp/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThingSpeak Data Fetcher',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Liste des pages
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(), // Page d'accueil
      SettingsPage(), // Page Paramètres
       NotificationWidget(), // Page Notifications
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Affiche la page selon l'index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Mise à jour de l'onglet sélectionné
          });
        },
        selectedItemColor: const Color(0xFF4CAF50), // Green color
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Device> devices = [];
  int _currentDeviceIndex = 0;
  bool isLoading = false;
  String userName = "";
  String userId = "";
  bool showAnimation = false;

  // Rain Animation
  late AnimationController _rainController;
  List<RainDrop> rainDrops = [];

  Timer? _fetchDataTimer; // Timer for periodic data fetching

  @override
  void initState() {
    super.initState();
    // Initialize rain animation
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Initialize raindrops
    for (int i = 0; i < 100; i++) {
      rainDrops.add(RainDrop());
    }

    // Load user data
    loadUserData().then((_) {
      fetchAllDevicesData(); // Fetch data immediately
      _startFetchDataTimer(); // Start the periodic timer
    });
  }

  void _startFetchDataTimer() {
    // Cancel any existing timer
    _fetchDataTimer?.cancel();

    // Start a new timer to fetch data every 30 seconds
    _fetchDataTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchAllDevicesData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _fetchDataTimer?.cancel();
    _rainController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';

    if (userId.isNotEmpty) {
      final cachedDevices = prefs.getString('userDevices');
      if (cachedDevices != null) {
        print("Cached Devices JSON: $cachedDevices");

        try {
          final decodedDevices = json.decode(cachedDevices) as List;
          print("Decoded Devices: $decodedDevices");

          setState(() {
            devices = decodedDevices.map((device) {
              print("Raw Device Data: $device");
              final deviceObj = Device(
                id: device['id'] ?? '',
                name: device['name'] ?? '',
                temperature: '...',
                humidityAir: '...',
                humiditySoil: '...',
                npk: '...',
                thingSpeakChannelId: device['thingSpeakChannelId'] ?? '',
                thingSpeakApiKey: device['thingSpeakApiKey'] ?? '',
                nextIrrigation: device['nextIrrigation'] ?? 'N/A',
                batteryLevel: device['batteryLevel'] ?? 'N/A',
                image: device['image'] ?? 'N/A',
              );
              print("Mapped Device: ${deviceObj.thingSpeakChannelId}, ID: ${deviceObj.thingSpeakApiKey}");
              return deviceObj;
            }).toList();
          });

          // Print the updated devices list after setState
          print("Devices after setState: ${devices.map((d) => d.thingSpeakApiKey).toList()}");

        } catch (e) {
          print("Error decoding or mapping devices: $e");
        }
      } else {
        print("No devices found in cache.");
      }
    } else {
      print("User ID is empty.");
    }
  }

  Future<Map<String, dynamic>> fetchThingSpeakData(String channelId, String apiKey) async {
    final url = Uri.parse('https://api.thingspeak.com/channels/$channelId/feeds.json?api_key=$apiKey&results=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data from ThingSpeak');
    }
  }

  Future<void> fetchAllDevicesData() async {
  setState(() {
    isLoading = true;
  });

  List<Device> updatedDevices = [];

  for (var device in devices) {
    try {
      print('Fetching data for device: ${device.name}');
      final thingSpeakData = await fetchThingSpeakData(device.thingSpeakChannelId, device.thingSpeakApiKey);
      final feed = thingSpeakData['feeds'][0];

      final updatedDevice = Device(
        id: device.id,
        name: device.name,
        temperature: feed['field1'] ?? '...',
        humidityAir: feed['field2'] ?? '...',
        humiditySoil: feed['field3'] ?? '...',
        npk: feed['field4'] ?? '...',
        thingSpeakChannelId: device.thingSpeakChannelId,
        thingSpeakApiKey: device.thingSpeakApiKey,
        nextIrrigation: feed['field5'] ?? '...', // Assuming field5 contains nextIrrigation
        batteryLevel: feed['field6'] ?? '...', // Assuming field6 contains batteryLevel
        image: device.image, // Pass the image field
      );

      updatedDevices.add(updatedDevice);
    } catch (e) {
      print("Error fetching data for device ${device.name}: $e");
      updatedDevices.add(device); // Keep the old data if fetching fails
    }
  }

  setState(() {
    devices = updatedDevices;
    isLoading = false;
  });
}
  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.account_circle, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/profil');
                    },
                  ),
                  const SizedBox(width: 10),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Rain Animation
          AnimatedBuilder(
            animation: _rainController,
            builder: (context, child) {
              for (var drop in rainDrops) {
                drop.fall();
              }
              return CustomPaint(
                size: Size.infinite,
                painter: RainPainter(rainDrops),
              );
            },
          ),

          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                const SizedBox(height: 30),
                Column(
                  children: [
                    CarouselSlider(
                      items: devices.map((device) {
                        return DeviceCard(
                          device: device,
                        );
                      }).toList(),
                      options: CarouselOptions(
                        height: 450,
                        enlargeCenterPage: true,
                        autoPlay: false,
                        aspectRatio: 16 / 9,
                        viewportFraction: 0.8,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentDeviceIndex = index;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const SizedBox(height: 30),
                    Center(
                child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 41, 156, 45),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
               
                label: const Text(
                  'Plant Doctor 🌱',
                  style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 255, 255, 255)),
                ),
                onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) =>  TFLiteIntegrationScreen()),
                        );
                    },
              ),             ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatefulWidget {
  final Device device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  _DeviceCardState createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool isLoading = false;
  String? nextIrrigationTime;
  Timer? _irrigationTimer; // Timer to handle the 5-second delay

  Future<void> fetchPrediction() async {
    final url = Uri.parse('https://farmpred-mt5y.onrender.com/predict');
    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({
      "soil_humidity_2": double.parse(widget.device.humiditySoil),
      "air_temperature": double.parse(widget.device.temperature),
      "air_humidity": double.parse(widget.device.humidityAir),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        int predictionValue = responseData['prediction'].toInt();
        int hours = predictionValue ~/ 60;
        int minutes = predictionValue % 60;
        setState(() {
          if (predictionValue == 0) {
            nextIrrigationTime = "Irrigation immédiate";
          } else {
            nextIrrigationTime = "Irrigation dans $hours heures et $minutes minutes.";
          }
        });

        // Start the 5-second timer
        _startIrrigationTimer();
      } else {
        throw Exception('Failed to load prediction');
      }
    } catch (error) {
      print("Error: $error");
      setState(() {
        nextIrrigationTime = 'Non disponible';
      });
    }
  }

  void _startIrrigationTimer() {
    // Cancel any existing timer
    _irrigationTimer?.cancel();

    // Start a new timer for 5 seconds
    _irrigationTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        nextIrrigationTime = null; // Clear the irrigation message
      });
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _irrigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8, // Limit card width to 80% of screen width
        minHeight: 400, // Minimum height to ensure content fits
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Image

              // Device Name and Info Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.device.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long device names
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: () {
                      
                      Navigator.push(
                        context,
                        
                        MaterialPageRoute(
                          builder: (context) => DeviceDetailsPage(device: widget.device),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Data Rows
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildDataRow(Icons.thermostat, 'Température', '${widget.device.temperature}°C'),
                    _buildDataRow(Icons.opacity, 'Humidité Air', '${widget.device.humidityAir}%'),
                    _buildDataRow(Icons.grass, 'Humidité Sol', '${widget.device.humiditySoil}%'),
                    _buildDataRow(Icons.water_drop, 'Pluie', widget.device.npk),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        )
                      : nextIrrigationTime == null
                          ? ElevatedButton(
                              onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) =>  IrrigationScreen()),
                        );
                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 10,
                                shadowColor: Colors.greenAccent.withOpacity(0.6),
                              ),
                              child: const Text(
                                'Prochaine irrigation',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              
                            )
                          : Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                nextIrrigationTime!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        // Gradient Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const Spacer(),
        // Value or Loading Spinner
        if (value == '...' || value.isEmpty||value == '...%'||value == '...°C')
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
      ],
    ),
  );
}
}
class Device {
  final String id;
  final String name;
  final String temperature;
  final String humidityAir;
  final String humiditySoil;
  final String npk;
  final String thingSpeakChannelId;
  final String thingSpeakApiKey;
  final String nextIrrigation;
  final String batteryLevel;
  final String? image; // Add this field for the device's photo

  Device({
    required this.id,
    required this.name,
    required this.temperature,
    required this.humidityAir,
    required this.humiditySoil,
    required this.npk,
    required this.thingSpeakChannelId,
    required this.thingSpeakApiKey,
    this.nextIrrigation = 'N/A',
    this.batteryLevel = 'N/A',
    this.image, // Initialize the image field
  });
}
class RainDrop {
  double x = Random().nextDouble() * 1000; // Random X position
  double y = Random().nextDouble() * -1000; // Random Y position (start above the screen)
  double speed = Random().nextDouble() * 10 + 5; // Random fall speed
  double length = Random().nextDouble() * 20 + 10; // Random length of the raindrop

  void fall() {
    y += speed; // Move the raindrop down
    if (y > 1000) {
      // Reset raindrop to the top when it goes off the screen
      y = Random().nextDouble() * -1000;
      x = Random().nextDouble() * 1000;
    }
  }
}

class RainPainter extends CustomPainter {
  final List<RainDrop> rainDrops;

  RainPainter(this.rainDrops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 2;

    for (var drop in rainDrops) {
      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x, drop.y + drop.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WavyAppBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200 // Light blue color for the app bar
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height) // Start at the bottom-left corner
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.7,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, 0) // Draw a straight line to the top-right corner
      ..lineTo(0, 0) // Draw a straight line to the top-left corner
      ..close(); // Close the path to complete the shape

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

