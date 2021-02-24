import 'package:flutter/material.dart';
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
  runApp(MaterialApp(
    home: TakePictureScreen(),
  ));
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

  var cameraBody = false;
  @override
  Widget build(BuildContext context) {
    if (cameraBody == false) {
      return Scaffold(
          body: AdvCamera(
        onCameraCreated: _onCameraCreated,
        flashType: FlashType.on,
        cameraSessionPreset: CameraSessionPreset.high,
        bestPictureSize: true,
        onImageCaptured: (String path) async {
          print("onImageCaptured => " + path);
          await GallerySaver.saveImage(path);
          Uint8List bytes = File(path).readAsBytesSync();
          try {
            print("Trying to upload image");
            await uploadImage(bytes);
            print("Done uploading image");
          } catch (e) {
            print(e);
          }
          takeImage();
          timer();
          setState(() {
            cameraBody = true;
          });
        },
        cameraPreviewRatio: CameraPreviewRatio.r16_9,
      ));
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
      );
    }
  }

  _onCameraCreated(AdvCameraController controller) async {
    this.cameraController = controller;
    takeImage();
  }

  void takeImage() async {
    await Future.delayed(Duration(seconds: 20));
    cameraController.captureImage();
  }

  void timer() async {
    await Future.delayed(Duration(minutes: 20));
    setState(() {
      cameraBody = false;
    });
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
