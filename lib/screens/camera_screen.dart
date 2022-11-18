import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import "../main.dart";
import "dart:developer";

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late CameraController controller;

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    controller = CameraController(cameraDescription, ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
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
    onNewCameraSelected(cameras[0]);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: Text(
          'LOADING',
          style: TextStyle(color: Colors.white),
        ),
      );
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
