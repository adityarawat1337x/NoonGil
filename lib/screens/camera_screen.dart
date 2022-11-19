import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import "../main.dart";
import "dart:developer";
import 'package:tflite/tflite.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late CameraController controller;
  late CameraImage cameraImage;
  String output = 'detecting...';

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    controller = CameraController(cameraDescription, ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg);

    controller.initialize().then((_) {
      if (!mounted) return;

      setState(() {
        controller.startImageStream((image) => {
              cameraImage = image,
              runModel(),
            });
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            log('User denied camera access.');
            break;
          default:
            log('Handle other errors.');
            break;
        }
      }
    });
  }

  runModel() async {
    var recognitions = await Tflite.detectObjectOnFrame(
        bytesList: cameraImage.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        imageMean: 0, // defaults to 127.5
        imageStd: 255.0, // defaults to 127.5
        threshold: 0.4, // defaults to 0.1
        numResultsPerClass: 1, // defaults to 5
        blockSize: 32, // defaults to 32
        numBoxesPerBlock: 5, // defaults to 5
        asynch: true // defaults to true
        );

    for (var element in recognitions!) {
      print("ffffffffffffffffffffff");
      print(element);
      setState(() {
        output = element['label'];
      });
    }
  }

  Future loadModel() async {
    Tflite.close();

    await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    late CameraController cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void initState() {
    super.initState();
    onNewCameraSelected(cameras[1]);
    loadModel();
  }

  @override
  void dispose() {
    controller.stopImageStream();
    Tflite.close();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              'Loading',
              style: TextStyle(
                  fontSize: 30,
                  decoration: TextDecoration.none,
                  color: Colors.white),
            ),
          ));
    }

    return MaterialApp(
        home: CameraPreview(
      controller,
      child: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/camera_aim.png',
              color: Colors.white,
              width: 100,
              height: 100,
            ),
          ),
          // ignore: prefer_const_constructors
          Positioned(
            bottom: 40,
            left: 100,
            width: 350,
            height: 100,
            // ignore: prefer_const_constructors
            child: Text(
              output,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            width: 350,
            height: 100,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(30)),
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 3),
                  left: BorderSide(color: Colors.white, width: 3),
                  right: BorderSide(color: Colors.white, width: 3),
                  top: BorderSide(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
              bottom: 30,
              left: 30,
              width: 330,
              height: 80,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        'assets/loader.gif',
                        fit: BoxFit.cover,
                        height: 50,
                        width: 50,
                      )),
                ),
              )),
        ],
      ),
    ));
  }
}
