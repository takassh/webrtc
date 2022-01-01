import 'package:flutter/material.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:socket_io_client/socket_io_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    _createClient();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
    );
  }

  void _createClient() {
    Socket socket = io(
      'http://localhost',
      OptionBuilder().disableAutoConnect().setTransports(['websocket']).build(),
    );

    Echo echo = Echo(
      broadcaster: EchoBroadcasterType.SocketIO,
      client: socket,
    );

    // Listening public channel
    echo.channel('check-channel').listen('CheckEvent', (e) {
      debugPrint(e.toString());
    });

    echo.connector.socket.on('connect', (_) => debugPrint('connected'));
    echo.connector.socket.on('disconnect', (_) => debugPrint('disconnected'));
  }
}
