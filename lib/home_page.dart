import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'local_notifications.dart';

import 'consts.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Timer? _timer;
  int _countdown = 45;

  @override
  void initState() {
    listenToNotifications();
    super.initState();
    getLocationUpdates();
    _startCountdown();
    _timer = Timer.periodic(Duration(seconds: 45), (timer) {
      fetchLocationFromFirebase();
      _startCountdown();
    });
  }

  void _startCountdown() {
    setState(() {
      _countdown = 45;
    });
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  //  to listen to any notification clicked or not
  listenToNotifications() {
    print("Listening to notification");
    LocalNotifications.onClickNotification.stream.listen((event) {
      print(event);
      Navigator.pushNamed(context, '/another', arguments: event);
    });
  }

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Location _locationController = new Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  // static const LatLng _pApplePark = LatLng(37.3346, -122.0090);

  bool flag = true;
  LatLng? _currentP = null;
  LatLng? _currentVehicleP = null;
  String _eta = '';
  BitmapDescriptor? _homeIcon;
  BitmapDescriptor? _busIcon;
  bool locFlag = true;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null ? const Center(child: Text("Loading..."))
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              setCustomMapPins();
            },
            initialCameraPosition: CameraPosition(
              target: _currentP!,
              zoom: 10,
            ),
            markers: {
              if (_currentP != null)
                Marker(
                  markerId: MarkerId('_currentLocation'),
                  icon: _homeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  position: _currentP!,
                  infoWindow: InfoWindow(title: 'Current Location'),
                ),
              if (_currentVehicleP != null)
                Marker(
                  markerId: MarkerId('_fetchedLocation'),
                  icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  position: _currentVehicleP!,
                  infoWindow: InfoWindow(title: 'Fetched Location'),
                ),
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 0, 0, 0),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'ETA: $_eta',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 80,
            child: Container(
              padding: EdgeInsets.all(10),
              // padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 0, 0, 0),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Next GPS update in: $_countdown seconds',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition =  CameraPosition(target: pos, zoom: 13);
    await controller.animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          if (flag) {
            _cameraToPosition(_currentP!);
            flag = !flag;
          }
          if (_currentP != null) {
            if (locFlag) {
              fetchLocationFromFirebase();
              locFlag = false;
            }
          }
        });
      }
    });
  }

  Future<void> fetchLocationFromFirebase() async {
    _dbRef.child('/').once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        double lat = data['lat'] ?? 0.0;
        double lng = data['lng'] ?? 0.0;
        setState(() {
          _currentVehicleP = LatLng(lat, lng);
          if (_currentP != null) {
            calculateETA(_currentP!, _currentVehicleP!);
          }
        });
      }
    }).catchError((error) {
      print("Error fetching data: $error");
    });
  }

  Future<void> calculateETA(LatLng start, LatLng end) async {
    // Using OpenRouteService API instead of Google Maps
    final String apiKey = ORS_API_KEY; // Get a free API key from openrouteservice.org
    final String url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // OpenRouteService returns duration in seconds
        if (data['features'] != null && data['features'].isNotEmpty) {
          final durationSeconds = data['features'][0]['properties']['segments'][0]['duration'];
          final durationMinutes = (durationSeconds / 60).round();

          String formattedDuration;
          if (durationMinutes < 60) {
            formattedDuration = '$durationMinutes mins';
          } else {
            final hours = durationMinutes ~/ 60;
            final minutes = durationMinutes % 60;
            formattedDuration = '$hours hour${hours > 1 ? 's' : ''} $minutes min${minutes > 1 ? 's' : ''}';
          }

          setState(() {
            _eta = formattedDuration;
            if(durationMinutes > 10) {
              showSimpleNotification(
                title: "Delay Alert", // Title
                body: "Your vehicle is delayed by $formattedDuration", // Body
                payload: "payload", // Payload
              );
            }
          });
        }
      } else {
        print('Failed to fetch ETA: ${response.statusCode} - ${response.body}');
        // Fallback to a simple distance-based estimation if API fails
        calculateSimpleETA(start, end);
      }
    } catch (e) {
      print('Error calculating ETA: $e');
      // Fallback to a simple distance-based estimation if API fails
      calculateSimpleETA(start, end);
    }
  }

  static Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('123456', 'gps_tracking_system',
        channelDescription: 'gps_tracking_system',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await _flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: payload);
  }

  // Simple distance-based ETA calculation as a fallback
  void calculateSimpleETA(LatLng start, LatLng end) {
    // Calculate distance using Haversine formula
    final double lat1 = start.latitude * (pi / 180);
    final double lon1 = start.longitude * (pi / 180);
    final double lat2 = end.latitude * (pi / 180);
    final double lon2 = end.longitude * (pi / 180);

    final double dlon = lon2 - lon1;
    final double dlat = lat2 - lat1;

    final double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Earth's radius in kilometers
    const double radius = 6371;
    final double distance = radius * c;

    // Assuming average speed of 50 km/h
    final double timeHours = distance / 50;
    final int timeMinutes = (timeHours * 60).round();

    String formattedDuration;
    if (timeMinutes < 60) {
      formattedDuration = '$timeMinutes mins';
    } else {
      final hours = timeMinutes ~/ 60;
      final minutes = timeMinutes % 60;
      formattedDuration = '$hours hour${hours > 1 ? 's' : ''} $minutes min${minutes > 1 ? 's' : ''}';
    }

    setState(() {
      _eta = formattedDuration + ' (est)';
    });
  }


  void setCustomMapPins() async {
    _homeIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 1), 'assets/home_icon.png');
    _busIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 1), 'assets/bus_icon.png');
  }
}

// Add these imports at the top of your file
// import 'dart:math';
// import 'package:vector_math/vector_math.dart';