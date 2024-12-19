import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryapp/profilSetting.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Couleur de fond douce
      appBar: AppBar(
        title: Text('Paramètres'),
        centerTitle: true,
         bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // Hauteur de la bordure
          child: Container(
            color: Colors.black, // Couleur de la bordure
            height: 1.0, // Épaisseur de la bordure
          ),
        ),
      ),
      body: Column(
        children: [
          // En-tête stylé
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
           
            child: Text(
              'Gérez vos préférences',
              style: TextStyle(
                color: const Color.fromARGB(255, 53, 54, 53),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Liste des paramètres
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.green),
                    title: Text('Profil'),
                    subtitle: Text('Modifier vos informations personnelles'),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
                    onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileSettingPage()),
                    );// Navigation vers la page de profil
                    },
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.devices, color: Colors.green),
                    title: Text('Dispositifs'),
                    subtitle: Text('Gérer vos dispositifs'),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
                    onTap: () {
                      // Navigation ou action pour changer le thème
                    },
                  ),
                ),
                
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.language, color: Colors.green),
                    title: Text('Langue'),
                    subtitle: Text('Changer la langue de l\'application'),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
                    onTap: () {
                      // Sélection de la langue
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 254, 201, 201),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.logout),
                  label: Text('Déconnexion', style: TextStyle(fontSize: 16)),
                  onPressed: () async{
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushReplacementNamed(context, '/login');// Action de déconnexion
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
