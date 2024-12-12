import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryapp/home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> saveToken(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('userId', user['id']);
    await prefs.setString('userName', user['name']);
    await prefs.setString('userEmail', user['email']);
    await prefs.setString('userThingSpeakChannelId', user['thingSpeakChannelId']);
    await prefs.setString('userThingSpeakApiKey', user['thingSpeakApiKey']);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final url = Uri.parse('https://farm-1gno.onrender.com/api/userServices/login');
      final body = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      };

      try {
        // Récupérer le Token FCM
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          body['fcmToken'] = fcmToken;
        } else {
          print('Impossible de récupérer le token FCM.');
        }

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final token = data['token'];
          final user = data['user'];

          // Sauvegarder le token JWT et les informations utilisateur
          await saveToken(token, user);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bienvenue ${user['name']}!')),
          );

          // Aller à la page d'accueil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>const MainPage()),
          );
        } else {
          final error = json.decode(response.body)['message'] ?? 'Erreur inconnue';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $error')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue : $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/maPlante.png',
                    height: 250,
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Veuillez vous connecter pour continuer',
                    style: TextStyle(fontSize: 18, color: Colors.blue[600]),
                  ),
                  SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // Ajouter une action si nécessaire
                    },
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
