import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

late List<CameraDescription> cameras;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController cameraController;
  late CameraImage cameraImage;
  List recognitionsList = [];
  bool predicting = false;

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) return;

      setState(() {
        cameraController.startImageStream((image) => {
              cameraImage = image,
              runModel(),
            });
      });
    });
  }

  runModel() async {
    if (predicting || !mounted) return;
    predicting = true;
    recognitionsList = (await Tflite.detectObjectOnFrame(
      bytesList: cameraImage.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResultsPerClass: 1,
      threshold: 0.4,
    ))!;
    predicting = false;
    setState(() {
      cameraImage;
    });
  }

  Future loadModel() async {
    Tflite.close();
    await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    late CameraController controller = cameraController;

    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      initCamera();
    }
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (recognitionsList == null) return [];

    double factorX = screen.width;
    double factorY = screen.height;

    Color colorPick = Colors.pink;

    return recognitionsList!.map((result) {
      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.black,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> list = [
      CameraPreview(cameraController),
      //?[AIM]
      Center(
        child: Image.asset(
          'assets/camera_aim.png',
          color: Colors.white,
          width: 100,
          height: 100,
        ),
      ),
      //?[OUTPUT]
      // Positioned(
      //   bottom: 40,
      //   left: 100,
      //   width: 350,
      //   height: 100,
      //   child: Text(
      //     "output",
      //     style:
      //         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      //   ),
      // ),
      //![NAVBAR BORDER]
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
      // ![NAVBAR]
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
    ];
//    list.add();

    if (cameraImage != null) {
      list.addAll(displayBoxesAroundRecognizedObjects(size));
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: EdgeInsets.only(top: 50),
          color: Colors.black,
          child: Stack(
            children: list,
          ),
        ),
      ),
    );
  }
}
