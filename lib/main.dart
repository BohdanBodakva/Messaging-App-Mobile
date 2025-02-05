import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:messaging_app_mobile/pages/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging App',
      theme: ThemeData(
        fontFamily: 'VollkornRegular',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 54, 168, 255)),
      ),
      home: const ConnectionStatusPage(),
    );
  }
}

class ConnectionStatusPage extends StatefulWidget {
  const ConnectionStatusPage({super.key});

  @override
  ConnectionStatusPageState createState() => ConnectionStatusPageState();
}

class ConnectionStatusPageState extends State<ConnectionStatusPage> {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _listenToConnectionChanges();
  }

  Future<void> _checkInitialConnection() async {
    var result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result.first);
  }

  void _listenToConnectionChanges() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isConnected = (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile);
    });

    if (!_isConnected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NoConnectionPage()),
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isConnected ? const LoginPage() : const NoConnectionPage();
  }
}

class NoConnectionPage extends StatelessWidget {
  const NoConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off, size: 100, color: Colors.grey[500]),
            const SizedBox(height: 20),
            Text("No Internet Connection", style: TextStyle(fontSize: 20, color: Colors.grey[700])),
            const SizedBox(height: 10),
            Text("Please check your network settings", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ConnectionStatusPage()),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
