import 'package:flutter/material.dart';
import 'package:messaging_app_mobile/pages/login.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class ConnectionCheck extends StatefulWidget {
  @override
  _ConnectionCheckState createState() => _ConnectionCheckState();
}

class _ConnectionCheckState extends State<ConnectionCheck> {
  late bool _isConnected = false;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _checkConnection();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      // If result is a List, check if any of the items indicate connectivity
      setState(() {
        if (result is List<ConnectivityResult>) {
          _isConnected = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);
        } else {
          _isConnected = result != ConnectivityResult.none;
        }
      });
    });
  }

  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Internet Connection Status')),
      body: Center(
        child: Text(
          _isConnected ? 'true' : 'false',  // Display true or false based on connection status
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging App',
      theme: ThemeData(
        fontFamily: 'VollkornRegular',
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 54, 168, 255)),
        // useMaterial3: true,
      ),
      home: ConnectionCheck(
        // title: 'Messaging App'
        ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: LoginPage()
      ),
    );
  }
}
