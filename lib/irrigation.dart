import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final String openWeatherApiKey = ""; // Remplace par ta clé OpenWeather
  final double latitude = 48.8566; // Ex: Paris
  final double longitude = 2.3522; // Ex: Paris

  double? windSpeed;
  double? radiation;
  List<dynamic>? forecastData;
  bool isLoading = false;
  double? airTemperature; // Température de l'air (en °C)
  double? soilHumidity; // Humidité du sol
  double? evapotranspiration; // Evapotranspiration
  bool? irrigationNeeded; // Indicateur si l'irrigation est nécessaire

  final double irrigationThreshold = 20.0; // Seuil d'humidité du sol pour irrigation
  final double evapotranspirationThreshold = 5.0; // Seuil de l'ETc pour déterminer si l'irrigation est nécessaire
  final double rainThreshold = 5.0; // Seuil de pluie pour reporter l'irrigation (en mm)

  int? plantDays; // Nombre de jours de culture
  double Kc = 0.7; // Valeur par défaut de Kc pour la tomate

  DateTime? nextRainDate; // Date de la pluie prévue

  // Remplacer avec les données de capteurs pour la température et l'humidité
  void fetchSensorData() {
    airTemperature = 25.0; // Exemple de température de l'air (en °C)
    soilHumidity = 30.0; // Exemple d'humidité du sol (%)
  }

  /// Récupère la vitesse du vent et une estimation de la radiation solaire avec OpenWeather
  Future<void> fetchWindAndRadiation() async {
    final String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$openWeatherApiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          windSpeed = data['wind']['speed']; // Vitesse du vent en m/s
          int cloudCoverage = data['clouds']['all']; // Pourcentage de nuages

          // Estimation de l'irradiation solaire basée sur la couverture nuageuse
          radiation = (100 - cloudCoverage) * 1.2; // Estimation de la radiation en W/m²
          print("cloudCoverage: $cloudCoverage, radiation: $radiation W/m²");
        });
      } else {
        throw Exception("Erreur de chargement des données de vent/radiation");
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  /// Met à jour le coefficient de culture Kc en fonction du nombre de jours de culture
  void updateKc() {
    if (plantDays != null) {
      if (plantDays! <= 30) {
        Kc = 0.7; // Première phase de la culture (croissance initiale)
      } else if (plantDays! <= 60) {
        Kc = 1.0; // Phase de développement végétatif
      } else if (plantDays! <= 90) {
        Kc = 1.15; // Phase de pleine croissance
      } else {
        Kc = 1.2; // Phase de maturation
      }
      print("Coefficient de culture (Kc) choisi : $Kc");
    }
  }

  /// Calcul de l'évapotranspiration (ETc) pour la culture de la tomate
  void calculateEvapotranspiration() {
    if (windSpeed != null && radiation != null && airTemperature != null && soilHumidity != null) {
      // Utilisation de la formule de Penman-Monteith simplifiée
      // ETc = Kc * (0.408 * radiation + windSpeedFactor * (airTemperature - 20) + soilHumidityFactor)
      double windSpeedFactor = 0.1; // Facteur d'impact du vent
      double soilHumidityFactor = 0.2; // Facteur d'impact de l'humidité du sol

      evapotranspiration = Kc * (0.408 * radiation! + windSpeedFactor * (airTemperature! - 20) + soilHumidityFactor);
      print("Evapotranspiration estimée (ETc): $evapotranspiration mm/jour");
    }
  }

  /// Récupère les prévisions de pluie sur 5 jours avec OpenWeather
  Future<void> fetchWeatherForecast() async {
    final String url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$openWeatherApiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          forecastData = data['list'];
        });
      } else {
        throw Exception("Erreur de chargement des prévisions météo");
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  /// Appel de l'API du modèle pour prédire l'humidité du sol après la pluie
  Future<void> predictSoilHumidity(DateTime rainDate) async {
    if (soilHumidity != null) {
      final String url = "https://api.exemple.com/predict"; // Remplacer par l'URL de l'API de ton modèle

      // Prépare les données à envoyer à l'API
      final Map<String, dynamic> requestData = {
        'current_soil_humidity': soilHumidity,
        'rain_date': rainDate.toIso8601String(),
        'plant_days': plantDays,
        // Ajouter d'autres paramètres nécessaires selon ton modèle
      };

      try {
        final response = await http.post(Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          double predictedHumidity = data['predicted_humidity']; // Valeur prédite de l'humidité du sol
          print("Humidité du sol prédite après pluie : $predictedHumidity");

          // Mettre à jour l'humidité du sol avec la valeur prédite
          soilHumidity = predictedHumidity;
          checkIrrigationNeed(); // Vérifier la nécessité d'irrigation avec la nouvelle valeur d'humidité
        } else {
          throw Exception("Erreur de prédiction de l'humidité du sol");
        }
      } catch (e) {
        print("Erreur lors de la prédiction de l'humidité du sol: $e");
      }
    }
  }

  /// Logique pour déterminer si l'irrigation est nécessaire
  void checkIrrigationNeedWithPrediction() {
  bool rainExpected = false;
  double totalRain = 0.0;

  // Vérification de la quantité de pluie prévue dans les prochains jours (par exemple 48h)
  for (var forecast in forecastData!) {
    var timeStamp = DateTime.parse(forecast['dt_txt']);
    var rainVolume = forecast['rain']?['3h'] ?? 0;

    // Si la pluie est prévue dans les prochains jours (au-delà de 24h par exemple)
    if (timeStamp.isAfter(DateTime.now())) {
      totalRain += rainVolume;
    }
  }

  // Si la pluie totale prévue dépasse un seuil, on reporte l'irrigation
  if (totalRain >= rainThreshold) {
    rainExpected = true;
  }

  // Si de la pluie est attendue dans les prochains jours, on ne va pas irriguer immédiatement
  if (rainExpected) {
    setState(() {
      irrigationNeeded = false;
    });
    print("Pluie attendue, pas d'irrigation immédiate.");

    // Vérifier la prédiction de l'humidité du sol
    double predictedSoilHumidity = predictFutureSoilHumidity();

    // Si la prédiction montre que l'humidité du sol va descendre sous le seuil
    if (predictedSoilHumidity <= irrigationThreshold) {
      setState(() {
        irrigationNeeded = true;
        irrigationAmount = calculateIrrigationAmount(predictedSoilHumidity);
      });
      print("Prédiction d'humidité faible malgré la pluie attendue, irrigation nécessaire.");
    } else {
      setState(() {
        irrigationNeeded = false;
      });
      print("Humidité du sol stable ou suffisante avec la pluie attendue.");
    }
  } else {
    // Si aucune pluie n'est prévue, on ajuste l'irrigation en fonction de la prédiction d'humidité
    double predictedSoilHumidity = predictFutureSoilHumidity();

    if (predictedSoilHumidity <= irrigationThreshold) {
      setState(() {
        irrigationNeeded = true;
        irrigationAmount = calculateIrrigationAmount(predictedSoilHumidity);
      });
      print("Prédiction d'humidité faible, irrigation nécessaire.");
    } else {
      setState(() {
        irrigationNeeded = false;
      });
      print("Humidité du sol stable.");
    }
  }
}

// Calcul de la quantité d'eau nécessaire
double calculateIrrigationAmount(double predictedHumidity) {
  double waterNeeded = irrigationThreshold - predictedHumidity;
  
  // Si la pluie prévue est suffisante pour compenser, ajuster la quantité d'irrigation
  double rainCompensation = totalRain > 0 ? totalRain : 0.0;
  waterNeeded -= rainCompensation;

  // Si l'irrigation nécessaire est inférieure à 0, on la fixe à 0
  return waterNeeded > 0 ? waterNeeded : 0;
}

// Méthode pour prédire l'humidité du sol
double predictFutureSoilHumidity() {
  // Logique pour la prédiction d'humidité du sol
  return soilHumidity! + (futureRainPrediction() - evapotranspiration!);
}

// Exemple de méthode pour la prévision de la pluie à venir
double futureRainPrediction() {
  return 0.0; // Remplace par la logique de collecte des prévisions
}

  /// Récupère toutes les données en parallèle
  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
    });

    // Fetch des données des capteurs et des données météo en parallèle
    fetchSensorData();
    await Future.wait([fetchWindAndRadiation(), fetchWeatherForecast()]);
    calculateEvapotranspiration(); // Calcul de l'ETc après avoir récupéré toutes les données
    checkIrrigationNeed(); // Vérification de la nécessité d'irrigation

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Météo & Prévisions de Pluie")),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                children: [
                  SizedBox(height: 20),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nombre de jours de culture",
                      hintText: "Entrez le nombre de jours",
                    ),
                    onChanged: (value) {
                      setState(() {
                        plantDays = int.tryParse(value);
                        updateKc(); // Mettre à jour Kc dès que le nombre de jours change
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Text("Coefficient de culture (Kc) : $Kc"),
                  SizedBox(height: 20),
                  Text("🌬 Vitesse du vent : ${windSpeed ?? 'N/A'} m/s"),
                  Text("☀️ Radiation solaire estimée : ${radiation?.toStringAsFixed(2) ?? 'N/A'} W/m²"),
                  SizedBox(height: 20),
                  Text("🌡 Température de l'air : ${airTemperature ?? 'N/A'} °C"),
                  Text("💧 Humidité du sol : ${soilHumidity ?? 'N/A'}%"),
                  SizedBox(height: 20),
                  Text("💧 Evapotranspiration estimée (ETc) : ${evapotranspiration?.toStringAsFixed(2) ?? 'N/A'} mm/jour"),
                  SizedBox(height: 20),
                  Text(
                    irrigationNeeded == null
                        ? "Statut d'irrigation : Non déterminé"
                        : irrigationNeeded!
                            ? "Irrigation nécessaire"
                            : "Pas d'irrigation nécessaire",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
