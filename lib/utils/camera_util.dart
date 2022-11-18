import 'package:camera/camera.dart';

class CameraUtil {
  // on changing back and front camera
  static void onCamChange(
      CameraDescription camDes,
      CameraController? controller,
      bool mounted,
      bool isCameraReady,
      Function setState) async {
    final prevCamController = controller;

    //create new camera controller
    final CameraController newCamController = CameraController(
        camDes, ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg);

    // free memory of pervious
    await prevCamController?.dispose();

    if (mounted) {
      setState(() {
        controller = newCamController;
      });
    }

    newCamController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    try {
      await newCamController.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {
        isCameraReady = controller!.value.isInitialized;
      });
    }
  }
}
