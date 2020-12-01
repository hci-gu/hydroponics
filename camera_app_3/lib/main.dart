import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:lamp/lamp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();

    Timer.periodic(Duration(seconds: 10), (timer) async {
      // await Lamp.flash(new Duration(seconds: 2));

      try {
        final path = join(
          (await getTemporaryDirectory()).path,
          '${DateTime.now()}.png',
        );

        await _controller.takePicture(path);
        GallerySaver.saveImage(path);
        Uint8List bytes = File(path).readAsBytesSync();
        await uploadImage(bytes);
      } catch (e) {}
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0),

      // Kan vara användbar när vi installerar kameran.

      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          return CameraPreview(_controller);
        },
      ),
    );
  }

  Future uploadImage(Uint8List imageBytes) async {
    var url = 'http://192.168.0.4:3000/image';
    await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'data': base64Encode(imageBytes),
      }),
    );
  }
}
