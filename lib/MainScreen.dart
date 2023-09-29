import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key, required this.peerid}) : super(key: key);

  final String peerid;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  late final Peer peer;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool inCall = false;
  String? peerId;

  bool cameraOn = true;
  bool audioOn = true;

  @override
  void initState() {
    super.initState();
    peerId = widget.peerid;

    peer = Peer(id: peerId, options: PeerOptions(debug: LogLevel.All));

    _localRenderer.initialize();
    _remoteRenderer.initialize();

    peer.on("open").listen((id) {
      setState(() {
        peerId = peer.id;
      });
    });

    peer.on<MediaConnection>("call").listen((call) async {

      await Permission.camera.request();
      await Permission.microphone.request();

      final mediaStream = await navigator.mediaDevices
          .getUserMedia({"video": true, "audio": false});

      call.answer(mediaStream);

      call.on("close").listen((event) {
        setState(() {
          inCall = false;
        });
      });

      call.on<MediaStream>("stream").listen((event) {
        _localRenderer.srcObject = mediaStream;
        _remoteRenderer.srcObject = event;

        setState(() {
          inCall = true;
        });
      });
    });


  }

  @override
  void dispose() {
    peer.dispose();
    _controller.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void connect() async {

    await Permission.camera.request();
    await Permission.microphone.request();


    final mediaStream = await navigator.mediaDevices
        .getUserMedia({"video": true, "audio": true});

    final conn = peer.call(_controller.text, mediaStream);

    conn.on("close").listen((event) {
      setState(() {
        inCall = false;
      });
    });

    conn.on<MediaStream>("stream").listen((event) {
      _remoteRenderer.srcObject = event;
      _localRenderer.srcObject = mediaStream;

      setState(() {
        inCall = true;
      });
    });

    // });
  }

  void send() {
    // conn.send('Hello!');
  }

  //TODO: colocar uns avisos se eu estiver sem camera e ver se dá: se o outro estiver sem camera/mic mostrar icons

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Video Call - ${_renderState()}'),
        ),
        body: Stack(
          children: [

            if (inCall)
              RTCVideoView(
                _remoteRenderer,
              ),
            if (inCall)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container( decoration: BoxDecoration(color: Colors.black26, border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ),),
                    child: SizedBox(
                      width: 100,
                      height: 150,
                      child: Center(
                        child: RTCVideoView(
                          _localRenderer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(.6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: toggleVideo,
                      icon: Icon(
                          cameraOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          size: 50,
                          color: cameraOn ? Colors.white30 : Colors.red),
                    ),
                    SizedBox(height: 4,),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: toggleAudio,
                      icon: Icon(
                          audioOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                          size: 50,
                          color: audioOn ? Colors.white30 : Colors.red),
                    ),
                    SizedBox(height: 8,),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                title: Text('End call?'),
                                content: Text(
                                    'Are you sure you want to end the call?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('End Call'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      endCall();
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                      child: Icon(Icons.call_end_rounded,
                          size: 40, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(8),
                        backgroundColor: Colors.red, // <-- Button color
                        foregroundColor: Colors.red
                            .withOpacity(.8), // <-- Splash color
                      ),
                    )
                  ],
                ),
              ),
            ),
            if(!inCall)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                TextField(
                  controller: _controller,
                ),
                ElevatedButton(
                    onPressed: connect, child: const Text("connect")),
                ElevatedButton(
                    onPressed: send, child: const Text("send message")),


              ],
            ),
          ],
        ));
  }



  void endCall() {
    toggleVideo();
    toggleAudio();

    Navigator.of(context).pop();

   // toast("Call Ended");
  }

  void toggleVideo() {
    if (cameraOn) {
      _localRenderer.srcObject?.getVideoTracks().forEach((element) { element.enabled = false; });
    } else {
      _localRenderer.srcObject?.getVideoTracks().forEach((element) { element.enabled = true; });
    }

    cameraOn = !cameraOn;
    setState(() {});
  }

  void toggleAudio() {
    if (audioOn) {
      _localRenderer.srcObject?.getAudioTracks().forEach((element) { element.enabled = false; });
    } else {
      _localRenderer.srcObject?.getAudioTracks().forEach((element) { element.enabled = true; });
    }

    audioOn = !audioOn;
    setState(() {});
  }



  String _renderState() {
   /* Color bgColor = inCall ? Colors.green : Colors.grey;
    Color txtColor = Colors.white;*/
    String txt = inCall ? "Connected" : "Standby";
   /* return Container(
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        txt,
        style:
            Theme.of(context).textTheme.titleLarge?.copyWith(color: txtColor),
      ),
    );*/
    return txt;
  }
}
