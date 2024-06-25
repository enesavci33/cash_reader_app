import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:cash_reader_app3/classes.dart';
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
      print("Error while creating interpreter: $e");
    }
  }

  Interpreter get interpreter => _interpreter;

  Future<DetectionClasses> predict(img.Image image) async {
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    Float32List inputBytes = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        int pixel = resizedImage.getPixel(x, y) as int;
        inputBytes[pixelIndex++] = img.getRed(pixel) / 255.0;
        inputBytes[pixelIndex++] = img.getGreen(pixel) / 255.0;
        inputBytes[pixelIndex++] = img.getBlue(pixel) / 255.0;
      }
    }

    final output = Float32List(1 * 6).reshape([1, 6]);

    final input = inputBytes.reshape([1, 224, 224, 3]);

    interpreter.run(input, output);

    final predictionResult = output[0] as List<double>;
    double maxElement = predictionResult.reduce(
      (double maxElement, double element) =>
          element > maxElement ? element : maxElement,
    );
    return DetectionClasses.values[predictionResult.indexOf(maxElement)];
  }
}
