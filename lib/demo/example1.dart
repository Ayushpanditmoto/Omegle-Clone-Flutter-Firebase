import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';

import 'videochat.dart';

class ConnectingActivity extends StatefulWidget {
  const ConnectingActivity({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ConnectingActivityState createState() => _ConnectingActivityState();
}

class _ConnectingActivityState extends State<ConnectingActivity>
    with WidgetsBindingObserver {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseDatabase database = FirebaseDatabase.instance;
  bool isRoomAvailable = false;
  String? username;
  Map<String, dynamic>? rooms;
  String? roomCreated;
  DatabaseReference roomRef = FirebaseDatabase.instance.ref().child("rooms");
  @override
  void initState() {
    super.initState();
    requestMultiplePermissions();
    WidgetsBinding.instance.addObserver(this);
    username = auth.currentUser!.uid;
    roomFunction(username!);
  }

  void requestMultiplePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] == PermissionStatus.granted &&
        statuses[Permission.microphone] == PermissionStatus.granted) {
      debugPrint('Permission granted');
    } else {
      requestMultiplePermissions();
    }
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      //app resumed
      deleteRoom(
        roomCreated != null ? roomCreated! : username!,
      );
      Navigator.pop(context);
    }
    super.didChangeAppLifecycleState(state);
  }

  void roomFunction(String username) async {
    database
        .ref()
        .child("rooms")
        .orderByChild("status")
        .equalTo(0)
        .limitToFirst(1)
        .once()
        .then((event) {
      rooms = event.snapshot.value != null
          ? Map.from(event.snapshot.value as dynamic)
          : null;
      if (rooms != null) {
        rooms!.forEach((key, value) {
          if (isRoomAvailable) return;

          setState(() {
            isRoomAvailable = true;
          });

          database
              .ref()
              .child("rooms")
              .child(key)
              .child("incoming")
              .set(username);
          database.ref().child("rooms").child(key).child("status").set(1);
          roomCreated = key;

          String incoming = username;
          String createdBy = value["createdBy"];
          bool isAvailable = value["isAvailable"];
          inspect(incoming);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoChat(
                incoming: incoming,
                createdBy: createdBy,
                isAvailable: isAvailable,
                firstTime: false,
              ),
            ),
          );

          //room joined
          debugPrint("Room Joined Already Created");
        });
      } else {
        debugPrint("New Room Created");
        Map<String, dynamic> room = {
          "incoming": username,
          "createdBy": username,
          "isAvailable": true,
          "status": 0,
        };

        database.ref().child("rooms").child(username).set(room).then((value) {
          database.ref().child("rooms").child(username).onValue.listen((event) {
            if (event.snapshot.value != null) {
              int status = (event.snapshot.value as dynamic)["status"];

              debugPrint("Status: ${event.snapshot.value}");

              if (status == 1) {
                if (isRoomAvailable) return;
                setState(() {
                  isRoomAvailable = true;
                });
                roomCreated = username;

                String incoming = (event.snapshot.value as dynamic)["incoming"];
                String createdBy =
                    (event.snapshot.value as dynamic)["createdBy"];
                bool isAvailable =
                    (event.snapshot.value as dynamic)["isAvailable"];

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoChat(
                      incoming: incoming,
                      createdBy: createdBy,
                      isAvailable: isAvailable,
                      firstTime: true,
                    ),
                  ),
                );

                //room joined
                debugPrint("Room Joined");
              }
            }
          });
        });
      }
    });
  }

  void joinRoom(String roomId) {
    //update room status
    roomRef.child(roomId).update({
      "status": 1,
      "incoming": username,
    });
  }

  void createRoom(String username) {
    debugPrint("Room Created");
    roomRef.child(username).set({
      "status": 0,
      "created": username,
      "incoming": username,
      "isAvailable": true
    });
  }

  void deleteRoom(String username) {
    debugPrint("Room Deleted");
    database.ref().child("rooms").child(username).remove();
  }

  @override
  void dispose() {
    //delete room
    WidgetsBinding.instance.removeObserver(this);
    deleteRoom(
      roomCreated != null ? roomCreated! : username!,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Random Video Chat"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            //total online users task left

            Text("Searching for a random person..."),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
