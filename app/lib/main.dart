import 'package:app/webrtc_implment.dart';
import 'package:app/webrtc_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
  final _remoteRenderer = RTCVideoRenderer();
  final _localRenderer = RTCVideoRenderer();
  late final WebrtcInterface _webrtcInterface;

  @override
  void initState() {
    _remoteRenderer.initialize();
    _webrtcInterface = WebrtcImplement(onTrack, _localRenderer, () {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Text('You'),
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(_localRenderer),
                ),
              ),
              const Divider(height: 1.0),
              const Text('Other'),
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(_remoteRenderer),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: _webrtcInterface.makeOffer,
                      child: const Text('call'),
                    ),
                    ElevatedButton(
                      onPressed: _webrtcInterface.disconnect,
                      child: const Text('disconnect'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
        },
      ),
    );
  }

  void onTrack(RTCTrackEvent event) {
    setState(() {
      _remoteRenderer.srcObject = event.streams[0];
    });
  }
}
