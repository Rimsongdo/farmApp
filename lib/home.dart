import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:tryapp/notification.dart';
import 'package:tryapp/settings.dart';

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
}

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
  String? nextIrrigationTime; // Stocke l'heure de la prochaine irrigation
  bool isButtonVisible = true; // Gère la visibilité du bouton
  String userName = "";
  String userId = "";
  bool isLoading = false; // Track if data is loading
  late Timer _timer;

  // Load user data from SharedPreferences
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('auth_token') ?? '';
    userId = prefs.getString('userId') ?? '';
    userName = prefs.getString('userName') ?? '';
    String thingSpeakChannelId = prefs.getString('userThingSpeakChannelId') ?? '';
    String thingSpeakApiKey = prefs.getString('userThingSpeakApiKey') ?? '';

    if (thingSpeakChannelId.isNotEmpty && thingSpeakApiKey.isNotEmpty) {
      fetchData(thingSpeakChannelId, thingSpeakApiKey, userId);

      // Start fetching data every 30 seconds
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
        fetchData(thingSpeakChannelId, thingSpeakApiKey, userId);
      });
    }
  }

Future<void> fetchPrediction(String thingSpeakChannelId, String thingSpeakApiKey, String userId) async {
  final url = Uri.parse('https://farm-1gno.onrender.com/fetchPrediction'); // Replace with your actual URL
  final headers = {'Content-Type': 'application/json'};

  final body = json.encode({
    'thingSpeakChannelId': thingSpeakChannelId,
    'thingSpeakApiKey': thingSpeakApiKey,
    'userId': userId,
  });

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Extract prediction value and format it to 2 decimal places
      double predictionValue = responseData['Prediction'][0].toDouble();
      String formattedPrediction = predictionValue.toStringAsFixed(2); // Format to 2 decimal places

      setState(() {
        if(double.parse(formattedPrediction)<=20){
            nextIrrigationTime = "Irrigation dans 10h";
        }
        else{
          nextIrrigationTime = "Non nécessaire dans 10 heures";
        }
         // Store the formatted prediction time
      });
    } else {
      throw Exception('Failed to load prediction');
    }
  } catch (error) {
    print("Error: $error");
    setState(() {
      nextIrrigationTime = 'Erreur'; // In case of error
    });
  }
}

Future<void> getNextIrrigation() async {
  setState(() {
    isLoading = true; // Start loading when the button is pressed
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? '';
  String thingSpeakChannelId = prefs.getString('userThingSpeakChannelId') ?? '';
  String thingSpeakApiKey = prefs.getString('userThingSpeakApiKey') ?? '';
  
  // Fetch the prediction data
  await fetchPrediction(thingSpeakChannelId, thingSpeakApiKey, userId);

  setState(() {
    isLoading = false; // Stop loading after data is fetched
    isButtonVisible = false; // Hide the button
  });

  // After displaying the time for 5 seconds, hide it and show the button again
  await Future.delayed(const Duration(seconds: 5));
  setState(() {
    // Clear the next irrigation time
    isButtonVisible = true; // Show the button again
  });
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
          tempList.add(feed['field1'] ?? '...');
          humidityAirList.add(feed['field2'] ?? '...');
          humiditySoilList.add(feed['field3'] ?? '...');
          npkList.add(feed['field4'] ?? '...');
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
      // Change the background color here
      backgroundColor: Colors.white, // Set your desired background color

      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.account_circle), // Profile icon
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/profil');// Navigate to the profile page
               
              },
            ),
            const SizedBox(width: 10),
            
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logOut,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // Hauteur de la bordure
          child: Container(
            color: Colors.black, // Couleur de la bordure
            height: 1.0, // Épaisseur de la bordure
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
           
            
            const SizedBox(height: 30),
            // Section Données en temps réel
           const Center(
                child:  Text(
                  'Données en temps réel',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),

            const SizedBox(height: 20),
            // Grille de données
            Builder(
              builder: (context) {
                double width = MediaQuery.of(context).size.width;
                int crossAxisCount = width > 600 ? 4 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildCard(
                      title: 'Température',
                      value: temperatures.isNotEmpty ? '${temperatures.last}°C' : 'chargement...',
                      iconPath: 'assets/img/temp.png',
                      color: Colors.orange[100]!,
                    ),
                    _buildCard(
                      title: 'Humidité Air',
                      value: humidityAir.isNotEmpty ? '${humidityAir.last}%' : 'chargement...',
                      iconPath: 'assets/img/humidite.png',
                      color: Colors.blue[100]!,
                    ),
                    _buildCard(
                      title: 'Humidité Sol',
                      value: humiditySoil.isNotEmpty ? '${humiditySoil.last}%' : 'chargement...',
                      iconPath: 'assets/img/moisture.png',
                      color: Colors.teal[100]!,
                    ),
                    _buildCard(
                      title: 'NPK',
                      value: npk.isNotEmpty ? '${npk.last}' : 'chargement...',
                      iconPath: 'assets/img/npk.png',
                      color: Colors.purple[100]!,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

const SizedBox(height: 20),
Center(
              child: AnimatedSwitcher(
  duration: const Duration(milliseconds: 800),
  switchInCurve: Curves.easeInOut,
  switchOutCurve: Curves.easeInOut,
  transitionBuilder: (child, animation) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  },
  child: isLoading
      ? Center( // Show loading spinner when data is being fetched
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        )
      : isButtonVisible
          ? ElevatedButton(
              onPressed: getNextIrrigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Afficher la prochaine irrigation',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$nextIrrigationTime',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
),

            ),
          ],
        ),
      ),
    );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 50),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }
}

