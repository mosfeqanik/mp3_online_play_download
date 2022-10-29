import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
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
  final audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  final String url1 = "https://www.harlancoben.com/audio/PM_Ch2.mp3";
  // String fileurl = "https://fluttercampus.com/sample.pdf";
  final SnackBar _snackBar = const SnackBar(
    content: Text("MP3 is saved to download folder"),
    duration: Duration(seconds: 5),
  );

  @override
  void initState() {
    super.initState();
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.PLAYING;
      });
    });
    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });
    audioPlayer.onAudioPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });

  }
  Future setAudio()async{
    audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    audioPlayer.setUrl(url1);
  }
  // play() async {
  //   var url = "https://www.harlancoben.com/audio/PM_Ch2.mp3";
  //   int result = await audioPlayer.play(url);
  //   if (result == 1) {
  //     // success
  //   }
  // }
  @override
  void dispose() {
    // TODO: implement dispose
    audioPlayer.dispose();
    super.dispose();
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [if (duration.inHours > 0) hours, minutes, seconds].join(":");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  "https://cdn.pixabay.com/photo/2022/01/17/22/20/subtract-6945896_960_720.png",
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              const Text(
                "songname",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "Artist Name",
                style: TextStyle(fontSize: 20),
              ),
              // Slider(
              //     min: 0,
              //     max: duration.inSeconds.toDouble()+1,
              //     value: position.inSeconds.toDouble(),
              //     onChanged: (value) async {
              //       final position =  Duration(seconds: value.toInt());
              //       await audioPlayer.seek(position);
              //       await audioPlayer.resume();
              //     }),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatTime(position)),
                    Text(formatTime(position-duration))
                  ],
                ),
              ),
              CircleAvatar(
                radius: 35,
                child: IconButton(
                    onPressed: () async {
                      if (isPlaying) {
                        await audioPlayer.pause();
                      } else {
                        await audioPlayer.play(url1);
                        // audioPlayer.play(Source);
                      }
                    },
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Map<Permission, PermissionStatus> statuses = await [
                    Permission.storage,
                    //add more permission to request here.
                  ].request();

                  if(statuses[Permission.storage]!.isGranted){
                    var dir = await DownloadsPathProvider.downloadsDirectory;
                    if(dir != null){
                      String savename = "file.mp3";
                      String savePath = dir.path + "/$savename";
                      print(savePath);
                      //output:  /storage/emulated/0/Download/banner.png

                      try {
                        await Dio().download(
                            url1,
                            savePath,
                            onReceiveProgress: (received, total) {
                              if (total != -1) {
                                print((received / total * 100).toStringAsFixed(0) + "%");
                                //you can build progressbar feature too
                              }
                            });
                        ScaffoldMessenger.of(context).showSnackBar(_snackBar);
                      } on DioError catch (e) {
                        print(e.message);
                      }
                    }
                  }else{
                    print("No permission to read and write.");
                  }

                },
                child: Text("Download File."),
              )
            ],
          ),
        ),
      ),
    );
  }
}
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}