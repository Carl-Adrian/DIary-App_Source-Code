import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherPage extends StatefulWidget {
  final Function(String icon, int temp)? onWeatherUpdate;

  const WeatherPage({Key? key, this.onWeatherUpdate}) : super(key: key);

  @override
  WeatherPageState createState() => WeatherPageState();
}

class WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  String weather = "Loading...";
  int temperature = 0;
  String icon = "☁️";
  String locationName = "Fetching...";
  int humidity = 0;
  double windSpeed = 0.0;
  int feelsLike = 0;
  bool _isLoading = false;

  final String apiKey = "53b4723fdb84ff4c71e8615408e09b21";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    fetchWeather();
  }

  Future<void> fetchWeather() async {
    setState(() => _isLoading = true);
    _fadeController.reset();

    double? lat;
    double? lon;

    try {
      // STEP 1: Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationName = "Location access denied";
          icon = "📍";
          weather = "Enable GPS";
          _isLoading = false;
        });
        return;
      }

      // STEP 2: Get real location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      lat = position.latitude;
      lon = position.longitude;

      // STEP 3: Reverse geocode → REAL AREA NAME (e.g., Santo Niño)
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Combine barangay + city if possible
        String locality = place.subLocality?.isNotEmpty == true
            ? place.subLocality!
            : place.locality ?? "Unknown";

        locationName = "$locality, ${place.country}";
      }

    } catch (e) {
      print("⚠️ Location error: $e");
      locationName = "Manila (fallback)";
      lat ??= 14.5995;
      lon ??= 120.9842;
    }

    // STEP 4: Fetch weather
    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        temperature = (data["main"]["temp"] as num).toInt();
        feelsLike = (data["main"]["feels_like"] as num).toInt();
        humidity = (data["main"]["humidity"] as num).toInt();
        windSpeed = (data["wind"]["speed"] as num).toDouble();

        weather = data["weather"][0]["main"];
        icon = _mapWeatherToEmoji(weather);

        widget.onWeatherUpdate?.call(icon, temperature);
        _isLoading = false;
      });

      _fadeController.forward();
    } else {
      setState(() {
        weather = "Error loading";
        _isLoading = false;
      });
    }
  }

  String _mapWeatherToEmoji(String main) {
    switch (main.toLowerCase()) {
      case "clear":
        return "☀️";
      case "clouds":
        return "☁️";
      case "rain":
      case "drizzle":
        return "🌧️";
      case "thunderstorm":
        return "🌩️";
      case "snow":
        return "❄️";
      case "mist":
      case "fog":
      case "haze":
        return "🌫️";
      default:
        return "🌡️";
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111428),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111428),
        elevation: 0,
        title: const Text("Weather", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : fetchWeather,
          ),
        ],
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) =>
              Opacity(opacity: _fadeAnimation.value, child: child),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  locationName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white, // FIXED (was too dark before)
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),
                Text(icon, style: const TextStyle(fontSize: 100)),
                const SizedBox(height: 10),
                Text(
                  "$temperature°",
                  style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(weather,
                    style: const TextStyle(
                        fontSize: 24, color: Colors.white70)),
                const SizedBox(height: 30),
                Container(
                  width: 100,
                  height: 1,
                  color: Colors.white24,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoTile("Feels Like", "$feelsLike°"),
                    _infoTile("Humidity", "$humidity%"),
                    _infoTile(
                        "Wind", "${windSpeed.toStringAsFixed(1)} m/s"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white, // FIXED
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white, // FIXED (was white70)
          ),
        ),
      ],
    );
  }
}
