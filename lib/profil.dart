import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "";
  String userId = "";
  String userEmail = ""; // Si tu stockes l'email ou d'autres informations
  String userThingSpeakChannelId = "";

  // Charge les données de l'utilisateur depuis SharedPreferences
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Nom non disponible';
      userId = prefs.getString('userId') ?? 'ID non disponible';
      userEmail = prefs.getString('userEmail') ?? 'Email non disponible';
      userThingSpeakChannelId = prefs.getString('userThingSpeakChannelId') ?? 'ID du canal non disponible';
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Effacer les données de l'utilisateur lors de la déconnexion
    Navigator.pushReplacementNamed(context, '/login'); // Rediriger vers la page de connexion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Utilisateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de l\'utilisateur',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildProfileInfo('Nom', userName),
            _buildProfileInfo('ID Utilisateur', userId),
            _buildProfileInfo('Email', userEmail),
            _buildProfileInfo('Canal ThingSpeak', userThingSpeakChannelId),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: logOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Couleur du bouton de déconnexion
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher les informations de l'utilisateur
  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label :',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
