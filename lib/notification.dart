import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Importez le package intl

class NotificationWidget extends StatefulWidget {
  @override
  _NotificationWidgetState createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  List<dynamic> notifications = [];
  String userId = "";

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Fonction pour récupérer les notifications depuis l'API
  Future<void> _fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    final url = Uri.parse('https://farm-1gno.onrender.com/getNotifications');
    final body = {
      'userId': userId,
    };
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      setState(() {
        notifications = json.decode(response.body)['notifications'];
      });
    } else {
      print('Erreur lors de la récupération des notifications');
    }
  }

  // Fonction pour formater la date
  String _formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    // Format pour l'heure
    String time = DateFormat.Hm().format(dateTime);
    // Format pour la date
    String date = DateFormat('dd/MM/yy').format(dateTime);
    return '$date à $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 5,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'Aucune notification.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications.reversed.toList()[index]; // Inversez la liste ici
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      notification['message'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(notification['date']), // Formatez la date ici
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: Icon(
                      Icons.notifications,
                      color: Colors.orange[700],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
