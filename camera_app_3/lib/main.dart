import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:adv_camera/adv_camera.dart';

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
  AdvCameraController cameraController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kamera'),
      ),
      body: AdvCamera(
        onCameraCreated: _onCameraCreated,
        flashType: FlashType.on,
        bestPictureSize: true,
        onImageCaptured: (String path) async {
          print("onImageCaptured => " + path);
          await GallerySaver.saveImage(path);
          Uint8List bytes = File(path).readAsBytesSync();
          try {
            await uploadImage(bytes);
          } catch (e) {}
          takeImage();
        },
        cameraPreviewRatio: CameraPreviewRatio.r16_9,
      ),
    );
  }

  _onCameraCreated(AdvCameraController controller) async {
    this.cameraController = controller;
    takeImage();
  }

  void takeImage() async {
    await Future.delayed(Duration(minutes: 15));
    cameraController.captureImage();
  }

  Future uploadImage(Uint8List imageBytes) async {
    var url = 'https://hydroponics-api-bhtyw.ondigitalocean.app/image';
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
