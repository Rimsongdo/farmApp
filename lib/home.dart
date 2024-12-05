import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> temperatures = [];
  List<String> humidityAir = [];
  List<String> humiditySoil = [];
  List<String> npk = [];
  String userName = "";
  String userId = "";
  late Timer _timer;

  // Load user data from SharedPreferences
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String token = prefs.getString('auth_token') ?? '';
    userId = prefs.getString('userId') ?? '';
    userName = prefs.getString('userName') ?? '';
    String userEmail = prefs.getString('userEmail') ?? '';
    String thingSpeakChannelId = prefs.getString('userThingSpeakChannelId') ?? '';
    String thingSpeakApiKey = prefs.getString('userThingSpeakApiKey') ?? '';

    if (thingSpeakChannelId.isNotEmpty && thingSpeakApiKey.isNotEmpty) {
      fetchData(thingSpeakChannelId, thingSpeakApiKey, userId);

      // Start fetching data every 30 seconds
      _timer = Timer.periodic(Duration(seconds: 30), (timer) {
        fetchData(thingSpeakChannelId, thingSpeakApiKey, userId);
      });
    }
  }

  // Fetch data from API
  Future<void> fetchData(String thingSpeakChannelId, String thingSpeakApiKey, String userId) async {
    final url = Uri.parse('https://farm-1gno.onrender.com/fetchData');
    final body = {
      'thingSpeakChannelId': thingSpeakChannelId,
      'thingSpeakApiKey': thingSpeakApiKey,
      'userId': userId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        List<String> tempList = [];
        List<String> humidityAirList = [];
        List<String> humiditySoilList = [];
        List<String> npkList = [];

        for (var feed in data['feeds']) {
          tempList.add(feed['field1'] ?? '0');
          humidityAirList.add(feed['field2'] ?? '0');
          humiditySoilList.add(feed['field3'] ?? '0');
          npkList.add(feed['field4'] ?? '0');
        }

        setState(() {
          temperatures = tempList;
          humidityAir = humidityAirList;
          humiditySoil = humiditySoilList;
          npk = npkList;
        });
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        temperatures = ['Erreur'];
        humidityAir = ['Erreur'];
        humiditySoil = ['Erreur'];
        npk = ['Erreur'];
      });
    }
  }

  // Log out function
  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName.isNotEmpty ? userName : 'User', style: TextStyle(fontSize: 20)),
        backgroundColor: const Color.fromARGB(255, 218, 242, 223),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Données en temps réel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C6E47),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCard(
                    title: 'Température',
                    value: temperatures.isNotEmpty ? '${temperatures.last}°C' : '0°C',
                    iconPath: 'assets/img/temp.png',
                    color: getAdjustedColor(
                      const Color.fromARGB(255, 250, 215, 169),
                      temperatures.isNotEmpty ? double.tryParse(temperatures.last) ?? 0 : 0,
                      0,
                      50,
                    ),
                  ),
                  _buildCard(
                    title: 'Humidité Air',
                    value: humidityAir.isNotEmpty ? '${humidityAir.last}%' : '0%',
                    iconPath: 'assets/img/humidite.png',
                    color: getAdjustedColor(
                      const Color.fromARGB(255, 165, 194, 245),
                      humidityAir.isNotEmpty ? double.tryParse(humidityAir.last) ?? 0 : 0,
                      0,
                      100,
                    ),
                  ),
                  _buildCard(
                    title: 'Humidité Sol',
                    value: humiditySoil.isNotEmpty ? '${humiditySoil.last}%' : '0%',
                    iconPath: 'assets/img/moisture.png',
                    color: getAdjustedColor(
                      const Color.fromARGB(255, 167, 247, 208),
                      humiditySoil.isNotEmpty ? double.tryParse(humiditySoil.last) ?? 0 : 0,
                      0,
                      100,
                    ),
                  ),
                  _buildCard(
                    title: 'NPK',
                    value: npk.isNotEmpty ? '${npk.last}' : '0',
                    iconPath: 'assets/img/npk.png',
                    color: getAdjustedColor(
                      const Color.fromARGB(255, 233, 165, 245),
                      npk.isNotEmpty ? double.tryParse(npk.last) ?? 0 : 0,
                      0,
                      150,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF3C6E47),
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

  // Function to adjust color brightness
  Color getAdjustedColor(Color baseColor, double value, double minValue, double maxValue) {
    double normalizedValue = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    int alpha = (50 + (205 * normalizedValue)).toInt();
    return baseColor.withAlpha(alpha);
  }

  // Card widget to display data in grid
  Widget _buildCard({
    required String title,
    required String value,
    required String iconPath,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 60),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
