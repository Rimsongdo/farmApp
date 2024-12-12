import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        children: [
          // Notifications toggle
          SwitchListTile(
            title: Text('Activer les alertes'),
            subtitle: Text('Recevoir des notifications pour les seuils critiques'),
            value: true, // Exemple, à connecter avec votre logique
            onChanged: (bool value) {
              // Ajouter logique pour activer/désactiver les alertes
            },
          ),
          Divider(),

          // Personnalisation des seuils
          ListTile(
            title: Text('Seuils d\'irrigation'),
            subtitle: Text('Personnaliser les seuils d\'alerte pour l\'humidité du sol'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Naviguer vers la page de réglage des seuils
            },
          ),
          Divider(),

          // Changer la langue
          ListTile(
            title: Text('Langue'),
            subtitle: Text('Changer la langue de l\'application'),
            trailing: DropdownButton<String>(
              value: 'Français',
              items: ['Français', 'Anglais'].map((String lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (String? newValue) {
                // Ajouter logique pour changer la langue
              },
            ),
          ),
          Divider(),

          // Thème
          ListTile(
            title: Text('Thème'),
            subtitle: Text('Changer le thème de l\'application'),
            trailing: DropdownButton<String>(
              value: 'Clair',
              items: ['Clair', 'Sombre'].map((String theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Text(theme),
                );
              }).toList(),
              onChanged: (String? newValue) {
                // Ajouter logique pour changer le thème
              },
            ),
          ),
          Divider(),

          // Détails du compte
          ListTile(
            title: Text('Détails du compte'),
            subtitle: Text('Voir ou modifier vos informations personnelles'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Naviguer vers la page de gestion du compte
            },
          ),
        ],
      ),
    );
  }
}
