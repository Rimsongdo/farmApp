import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingPage extends StatefulWidget {
  const ProfileSettingPage({Key? key}) : super(key: key);

  @override
  _ProfileSettingPageState createState() => _ProfileSettingPageState();
}

class _ProfileSettingPageState extends State<ProfileSettingPage> {
  // Variables pour stocker les informations de l'utilisateur
  String userName = "";
  String userId = "";
  String userEmail = "";
  String userPassword = "";
  String userThingSpeakChannelId = "";

  // Variables pour les champs de modification
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Charge les données de l'utilisateur depuis SharedPreferences
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Nom non disponible';
      userId = prefs.getString('userId') ?? 'ID non disponible';
      userEmail = prefs.getString('userEmail') ?? 'Email non disponible';
      userPassword = prefs.getString('userPassword') ?? 'Mot de passe non disponible';
      userThingSpeakChannelId = prefs.getString('userThingSpeakChannelId') ?? 'ID du canal non disponible';

      // Initialiser les contrôleurs avec les valeurs existantes
      nameController.text = userName;
      emailController.text = userEmail;
      passwordController.text = userPassword;
    });
  }

  // Sauvegarder les modifications dans SharedPreferences
  Future<void> saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', nameController.text);
    await prefs.setString('userEmail', emailController.text);
    await prefs.setString('userPassword', passwordController.text);

    setState(() {
      userName = nameController.text;
      userEmail = emailController.text;
      userPassword = passwordController.text;
    });

    // Affichage d'un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifications enregistrées avec succès!')),
    );
  }

  // Déconnexion de l'utilisateur
  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Effacer les données de l'utilisateur lors de la déconnexion
    Navigator.pushReplacementNamed(context, '/login'); // Rediriger vers la page de connexion
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations de l\'utilisateur',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 20),
              _buildProfileCard('Nom', userName, nameController),
              _buildProfileCard('Email', userEmail, emailController),
              _buildProfileCard('Mot de Passe', userPassword, passwordController, obscureText: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Couleur du bouton
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enregistrer les modifications',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour afficher et modifier les informations de l'utilisateur
  Widget _buildProfileCard(String label, String value, TextEditingController controller, {bool obscureText = false}) {
    return Card(
      elevation: 5,
      color: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: value,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
