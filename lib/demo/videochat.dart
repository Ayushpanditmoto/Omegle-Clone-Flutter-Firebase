import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoChat extends StatefulWidget {
  final String createdBy;
  final String incoming;
  final bool isAvailable;
  final bool firstTime;

  const VideoChat(
      {super.key,
      required this.createdBy,
      required this.incoming,
      required this.isAvailable,
      required this.firstTime});

  @override
  State<VideoChat> createState() => _VideoChatState();
}

class _VideoChatState extends State<VideoChat> with WidgetsBindingObserver {
  double left = 100;
  double top = 100;
  final Peer peer = Peer(
    id: FirebaseAuth.instance.currentUser!.uid,
  );
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  late String? peerId;
  bool isPermissionGranted = false;
  bool inCall = false;
  StreamSubscription? _streamSubscription;

  void requestMultiplePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] == PermissionStatus.granted &&
        statuses[Permission.microphone] == PermissionStatus.granted) {
      setState(() {
        isPermissionGranted = true;
      });

      _getUsersMedia(true, true);

      debugPrint('Permission granted');
    } else {
      debugPrint('Permission denied');
      setState(() {
        isPermissionGranted = false;
      });

      // requestMultiplePermissions();
    }
  }

  //generate peer id function
  String? generatePeerId() {
    peer.on('open').listen((id) {
      setState(() {
        // peerId = id;
        peerId = FirebaseAuth.instance.currentUser!.uid;
      });
    });
    return peer.id;
  }

  @override
  void initState() {
    super.initState();
    requestMultiplePermissions();
    initRenderers();
    peerId = generatePeerId();

    peer.on<MediaConnection>("call").listen((call) async {
      final mediaStream = await navigator.mediaDevices
          .getUserMedia({"video": true, "audio": true});

      call.answer(mediaStream);

      call.on("close").listen((event) {
        setState(() {
          inCall = false;
          remoteRenderer.srcObject = null;
          Navigator.of(context).pop(context);
        });
      });

      call.on<MediaStream>("stream").listen((event) {
        localRenderer.srcObject = mediaStream;
        remoteRenderer.srcObject = event;

        setState(() {
          inCall = true;
        });
      });
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (widget.firstTime == true) {
        connect(widget.incoming);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AppLifecycleState.resumed == state) {
      _getUsersMedia(true, true);
    } else if (AppLifecycleState.inactive == state) {
      _getUsersMedia(true, true);
    } else if (AppLifecycleState.paused == state) {
      _getUsersMedia(true, true);
    } else if (AppLifecycleState.detached == state) {
      closeCameraStream();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    if (mounted) {
      closeCameraStream();
      peer.dispose();
      localRenderer.dispose();
      remoteRenderer.dispose();
    }
    super.dispose();
  }

  void connect(String incoming) async {
    final mediaStream = await navigator.mediaDevices
        .getUserMedia({"video": true, "audio": true});

    debugPrint("Status: $incoming");

    // final conn = peer.call(_controller.text, mediaStream);
    final conn = peer.call(incoming, mediaStream);

    conn.on("close").listen((event) {
      setState(() {
        inCall = false;

        Navigator.pop(context);
      });
    });

    conn.on<MediaStream>("stream").listen((event) {
      remoteRenderer.srcObject = event;
      localRenderer.srcObject = mediaStream;

      setState(() {
        inCall = true;
      });
    });
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  _getUsersMedia(bool x, bool y) async {
    final Map<String, dynamic> mediaConstraints = {'audio': x, 'video': y};
    try {
      final MediaStream stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      localRenderer.srcObject = stream;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  closeCameraStream() async {
    try {
      final MediaStream? stream = localRenderer.srcObject;
      stream!.getTracks().forEach((track) => track.stop());
      localRenderer.srcObject = null;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void deactivate() {
    _streamSubscription?.cancel();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Video Chat'),
      ),
      body: isPermissionGranted
          ? peerId != null
              ? SizedBox(
                  // height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      videoRenderers(),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Text("${FirebaseAuth.instance.currentUser!.uid} Me"),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Text("${widget.createdBy} created this room"),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Text("${widget.incoming} is calling you"),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Text("FirstTime: ${widget.firstTime}"),
                    ],
                  ),
                )
              : SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Connecting to server...'),
                      SizedBox(
                        height: 10,
                      ),
                      CircularProgressIndicator(),
                    ],
                  ),
                )
          : requestPermission(),
    );
  }

  SizedBox videoRenderers() => SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.85,
              key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: RTCVideoView(
                  remoteRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
            Positioned(
              top: top,
              left: left,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    top = max(
                      0,
                      min(top + details.delta.dy,
                          MediaQuery.of(context).size.height * 0.65 - 2),
                    );
                    left = max(
                        0,
                        min(left + details.delta.dx,
                            MediaQuery.of(context).size.width * 0.7 - 10));
                  });
                },
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: MediaQuery.of(context).size.height * 0.19,
                    key: const Key('remote'),
                    margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: RTCVideoView(localRenderer,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                    )),
              ),
            )
          ],
        ),
      );

  Widget requestPermission() => Center(
        child: ElevatedButton(
          onPressed: () {
            requestMultiplePermissions();
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          child: const Text('Request Permission'),
        ),
      );
}
