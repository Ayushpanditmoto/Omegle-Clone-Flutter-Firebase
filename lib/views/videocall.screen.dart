// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCalling extends StatefulWidget {
  const VideoCalling({super.key});

  @override
  State<VideoCalling> createState() => _VideoCallingState();
}

class _VideoCallingState extends State<VideoCalling> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  @override
  Widget build(BuildContext context) {
    debugPrint('build');
    return Scaffold(
      appBar: AppBar(
        toolbarTextStyle: const TextStyle(color: Colors.black),
        title: const Text('Omegle Clone'),
        actions: [
          const Center(
            child: Text(
              // '$onlineUsers',
              "Online Users",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: () async {
              // await connectSocekt();
            },
            child: true
                ? const Icon(
                    Icons.circle,
                    color: Colors.green,
                  )
                : const Icon(
                    Icons.circle,
                    color: Colors.red,
                  ),
          ),
          const SizedBox(
            width: 10,
          )
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            videoRenderers(),
            buttonSection(),
            userJoinStatus(),
            messageSection(),
            messageArea(),
          ],
        ),
      ),
    );
  }

  messageSection() {
    return const Expanded(
        child: Column(
      children: [
        Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ));
  }

  messageArea() {
    return Container(
      height: 50,
      color: const Color.fromARGB(255, 211, 211, 211),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: TextField(
              // controller: _msgController,
              decoration: InputDecoration(
                hintText: 'Enter Messages',
              ),
            ),
          ),
          // IconButton(onPressed: connect, icon: const Icon(Icons.send)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }

  userJoinStatus() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.black38,
      ),
      child: const Align(
        alignment: Alignment.center,
        child: Text(
          "you are connected to a random person",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Row buttonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              // video = !video;
            });
            // _getUsersMedia(audio, video);
          },
          icon: const Icon(
            Icons.videocam,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: Colors.black,
        ),
        IconButton(
          onPressed: () {
            setState(() {
              // audio = !audio;
            });
            // _getUsersMedia(audio, video);
          },
          icon: const Icon(
            Icons.mic,
            color: Colors.blue,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: Colors.black,
        ),
        ElevatedButton(
          onPressed: () async {
            // await joinRoom();
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: const Text('Search for Partner',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  SizedBox videoRenderers() => SizedBox(
        height: 260,
        child: Row(
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Container(
                  height: 260,
                  key: const Key('local'),
                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                  ),
                  child: RTCVideoView(_localRenderer, mirror: true)),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Container(
                  height: 260,
                  key: const Key('remote'),
                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                  ),
                  child: RTCVideoView(_remoteRenderer)),
            ),
          ],
        ),
      );
}
