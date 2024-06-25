import 'dart:typed_data';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cash_reader_app3/classes.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CashClassifier {
  late Interpreter _interpreter;

  static const String modelFile = "assets/model_son.tflite";

  Future<void> loadModel({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            modelFile,
            options: InterpreterOptions()..threads = 4,
          );

      _interpreter.allocateTensors();
    } catch (e) {
      print("Interpreter oluşturulurken hata: $e");
    }
  }

  Interpreter get interpreter => _interpreter;

  Future<DetectionClasses> predict(img.Image image) async {
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    Float32List inputBytes = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        int pixel = resizedImage.getPixel(x, y);
        inputBytes[pixelIndex++] = img.getRed(pixel) / 255.0;
        inputBytes[pixelIndex++] = img.getGreen(pixel) / 255.0;
        inputBytes[pixelIndex++] = img.getBlue(pixel) / 255.0;
      }
    }

    final output = Float32List(1 * 6).reshape([1, 6]);

    final input = inputBytes.reshape([1, 224, 224, 3]);

    try {
      _interpreter.run(input, output);
    } catch (e) {
      print("Model çıkarımı sırasında hata: $e");
    }

    final predictionResult = output[0];
    double maxElement = predictionResult.reduce(
      (double maxElement, double element) =>
          element > maxElement ? element : maxElement,
    );

    print("Tahmin sonucu: $predictionResult");
    return DetectionClasses.values[predictionResult.indexOf(maxElement)];
  }
}

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late CameraController cameraController;
  final classifier = CashClassifier();

  bool initialized = false;
  DetectionClasses detected = DetectionClasses.bos;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await classifier.loadModel();

    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );

    await cameraController.initialize();

    setState(() {
      initialized = true;
    });
  }

  Future<void> captureAndProcessImage() async {
    if (!cameraController.value.isInitialized) {
      return;
    }

    try {
      XFile file = await cameraController.takePicture();

      if (file != null) {
        // Çekilen görüntüyü işleme
        final result = await processCapturedImage(File(file.path));

        if (result != null) {
          setState(() {
            detected = result;
          });
        }
      }
    } catch (e) {
      print("Görüntü yakalama hatası: $e");
    }
  }

  Future<DetectionClasses?> processCapturedImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(bytes));

    if (image == null) return null;

    final result = await classifier.predict(image);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Para Tanıma Tarayıcısı'),
      ),
      body: initialized
          ? Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  child: CameraPreview(cameraController),
                ),
                ElevatedButton(
                  onPressed: captureAndProcessImage,
                  child: Text('Görüntü Yakala'),
                ),
                Text(
                  "Tespit Edilen: ${detected.label}",
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.blue,
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
