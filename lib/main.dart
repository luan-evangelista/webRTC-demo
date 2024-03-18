import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:uuid/uuid.dart';
import 'dart:developer';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Application - Video Conference'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Participant {
  Participant(this.title, this.renderer, this.stream);
  MediaStream? stream;
  String title;
  RTCVideoRenderer renderer;
}

class _MyHomePageState extends State<MyHomePage> {
  List<Participant> plist = <Participant>[];
  bool isPub = false;

  RTCVideoRenderer _localRender = RTCVideoRenderer();
  RTCVideoRenderer _remoteRender = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRender();
    initSfu();
  }

  initRender() async {
    await _localRender.initialize();
    await _remoteRender.initialize();
  }

  getUrl() {
    if (kIsWeb) {
      return ion.GRPCWebSignal('http://localhost:9090');
    } else {
      setState(() {
        isPub = true;
      });
      return ion.GRPCWebSignal('http://187.55.40.38:9090');
    }
  }

  ion.Signal? _signal;
  ion.Client? _client;
  ion.LocalStream? _localStream;
  final String _uuid = Uuid().v4();

  initSfu() async {
    final _signal = await getUrl();
    _client =
        await ion.Client.create(sid: "test room", uid: _uuid, signal: _signal);
    if (isPub == false) {
      _client?.ontrack = (track, ion.RemoteStream remoteStream) async {
        if (track.kind == 'video') {
          print('ontrack: remote stream => ${remoteStream.id}');
          setState(() {
            _remoteRender.srcObject = remoteStream.stream;
          });
        }
      };
    }
  }

  // pushlist funtion
  void publish() async {
    _localStream = await ion.LocalStream.getUserMedia(
        constraints: ion.Constraints.defaults..simulcast = false);

    await _client?.publish(_localStream!);

    setState(() {
      _localRender.srcObject = _localStream?.stream;
    });
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
          children: <Widget>[getVideoView()],
        ),
      ),
      floatingActionButton: getFab(),
    );
  }

  // video view
  Widget getVideoView() {
    if (isPub == true) {
      return Expanded(
        child: RTCVideoView(_localRender),
      );
    } else {
      return Expanded(
        child: RTCVideoView(_remoteRender),
      );
    }
  }

// publish button
  Widget getFab() {
    if (isPub == false) {
      return Container();
    } else {
      return FloatingActionButton(
        onPressed: publish,
        child: Icon(Icons.video_call),
      );
    }
  }
}
