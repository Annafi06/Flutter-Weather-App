import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.blueAccent),
        fontFamily: 'Roboto',
      ),
      home: WeatherHomePage(),
    );
  }
}

class Location {
  final String cityName;
  final String latitude;
  final String longitude;

  Location({
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String _cityName = '';
  double _temperature = 0.0;
  String _conditionDescription = '';
  String _latitude = '';
  String _longitude = '';
  int _humidity = 0;
  double _windSpeed = 0.0;
  List<WeatherForecast> _weatherForecast = [];
  List<Location> _savedLocations = [];

  final String _apiKey = 'b07e3978d2842a792c27780a907ec9d4';

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _cityName = 'London'; // Default city
    fetchWeather();
    // Fetch weather periodically every 15 minutes
    const weatherFetchInterval = Duration(minutes: 15);
    Timer.periodic(weatherFetchInterval, (timer) {
      fetchWeather();
    });

    // Initialize FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showWeatherAlertNotification() async {
    var android = AndroidNotificationDetails(
      'channelId',
      'channelName',
      'channelDescription',
      importance: Importance.high,
      priority: Priority.high,
    );
    var iOS = IOSNotificationDetails();
    var platform = NotificationDetails(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Severe Weather Alert!',
      'Take necessary precautions. Severe weather is expected in $_cityName.',
      platform,
    );
  }

  Future<void> fetchWeather() async {
    final currentWeatherResponse = await http.get(Uri.parse(
        'http://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$_apiKey&units=metric'));

    if (currentWeatherResponse.statusCode == 200) {
      final jsonData = json.decode(currentWeatherResponse.body);
      setState(() {
        _cityName = jsonData['name'];
        _temperature = jsonData['main']['temp'];
        _conditionDescription = jsonData['weather'][0]['description'];
        _latitude = jsonData['coord']['lat'].toString();
        _longitude = jsonData['coord']['lon'].toString();
        _humidity = jsonData['main']['humidity'];
        _windSpeed = jsonData['wind']['speed'];
      });
    } else {
      throw Exception('Failed to load current weather data');
    }

    // Example: Check if temperature drops below freezing point
    if (_temperature < 0) {
      await showWeatherAlertNotification();
    }

    final forecastResponse = await http.get(Uri.parse(
        'http://api.openweathermap.org/data/2.5/forecast?q=$_cityName&appid=$_apiKey&units=metric'));

    if (forecastResponse.statusCode == 200) {
      final jsonData = json.decode(forecastResponse.body);
      final List<WeatherForecast> forecasts = [];
      for (var forecast in jsonData['list']) {
        forecasts.add(WeatherForecast(
          date: DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000),
          temperature: forecast['main']['temp'],
          condition: forecast['weather'][0]['description'],
        ));
      }
      setState(() {
        _weatherForecast = forecasts;
      });
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  void addLocation(String cityName, String latitude, String longitude) {
    setState(() {
      _savedLocations.add(Location(cityName: cityName, latitude: latitude, longitude: longitude));
    });
  }

  void selectLocation(Location location) {
    setState(() {
      _cityName = location.cityName;
    });
    fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current Location:',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            Text(
              _cityName,
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.location_on),
                SizedBox(width: 5.0),
                Text(
                  'Latitude: $_latitude | Longitude: $_longitude',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Text(
              'Weather Condition:',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            Text(
              _conditionDescription,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              'Temperature:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              '${_temperature.toStringAsFixed(1)}°C',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16.0),
            Text(
              'Humidity:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              '$_humidity%',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16.0),
            Text(
              'Wind Speed:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              '$_windSpeed m/s',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add Location'),
                      content: TextField(
                        decoration: InputDecoration(
                          labelText: 'City Name',
                        ),
                        onSubmitted: (value) {
                          addLocation(value, _latitude, _longitude);
                          Navigator.pop(context);
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            addLocation('London', '51.5074', '-0.1278');
                            Navigator.pop(context);
                          },
                          child: Text('Use Default Location'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Add Location'),
            ),
            SizedBox(height: 20.0),
            Text(
              'Saved Locations:',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _savedLocations.length,
              itemBuilder: (context, index) {
                final location = _savedLocations[index];
                return ListTile(
                  title: Text(location.cityName),
                  onTap: () {
                    selectLocation(location);
                  },
                );
              },
            ),
            SizedBox(height: 20.0),
            Text(
              'Weather Forecast for the Next 7 Days:',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            Container(
              height: 200.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weatherForecast.length,
                itemBuilder: (context, index) {
                  final forecast = _weatherForecast[index];
                  return ForecastCard(
                    date: forecast.date,
                    temperature: forecast.temperature,
                    condition: forecast.condition,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherForecast {
  final DateTime date;
  final double temperature;
  final String condition;

  WeatherForecast({
    required this.date,
    required this.temperature,
    required this.condition,
  });
}

class ForecastCard extends StatelessWidget {
  final DateTime date;
  final double temperature;
  final String condition;

  ForecastCard({
    required this.date,
    required this.temperature,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        padding: EdgeInsets.all(10.0),
        width: 150.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_getWeekday(date.weekday)}, ${date.day}/${date.month}',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              '${temperature.toStringAsFixed(1)}°C',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 5.0),
            Text(
              condition,
              style: TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}

