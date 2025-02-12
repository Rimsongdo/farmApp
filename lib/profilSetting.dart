import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryapp/home.dart';

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

  // Clé pour le formulaire
  final _formKey = GlobalKey<FormState>();

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
    if (_formKey.currentState!.validate()) {
      // Si le formulaire est valide, enregistrer les données
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', nameController.text);
      await prefs.setString('userEmail', emailController.text);
      await prefs.setString('userPassword', passwordController.text);

      setState(() {
        userName = nameController.text;
        userEmail = emailController.text;
        userPassword = passwordController.text;
      });

      final url = Uri.parse('https://farm-1gno.onrender.com/api/userServices/updateUser');
      final headers = {'Content-Type': 'application/json'};

      final body = json.encode({
        "userId": userId,
        "name": userName,
        "email": userEmail,
        "password": userPassword,
      });

      try {
        final response = await http.put(url, headers: headers, body: body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées avec succès!')),
        );
      } catch (errors) {
        print(errors);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement des modifications.')),
        );
      }
    }
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
                  
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: logOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations de l\'utilisateur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                _buildProfileCard('Nom', userName, nameController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                }),
                _buildProfileCard('Email', userEmail, emailController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                }),
                _buildProfileCard('Mot de Passe', userPassword, passwordController, obscureText: true, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                }),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: saveUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour afficher et modifier les informations de l'utilisateur
  Widget _buildProfileCard(
    String label,
    String value,
    TextEditingController controller, {
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 5,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: value,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                prefixIcon: Icon(
                  label == 'Nom'
                      ? Icons.person
                      : label == 'Email'
                          ? Icons.email
                          : Icons.lock,
                  color: Colors.green,
                ),
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
}