import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Durée de l'animation
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward(); // Lance l'animation

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // Vérifie si un token existe

    await Future.delayed(const Duration(seconds: 3)); // Simule un délai de chargement

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home'); // Redirige vers HomePage
    } else {
      Navigator.pushReplacementNamed(context, '/login'); // Redirige vers LoginPage
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Nettoie l'animation
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation du texte "Bienvenue"
            FadeTransition(
              opacity: _opacityAnimation,
              child: const Text(
                'Bienvenue',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/img/monLogo.png',
              height: 250,
              
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chargement en cours...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
