import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as image_lib;
import 'package:flutter_litert/flutter_litert.dart';

class ClassificationResult {
  final String label;
  final double confidence;

  ClassificationResult(this.label, this.confidence);
}

class ImageClassifierService {
  static const String _modelPath = 'assets/tflite/model.tflite';
  static const String _labelsPath = 'assets/tflite/probability-labels-en.txt';
  static const int _inputSize = 224; // sesuai spek: 224x224 RGB

  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(_modelPath);

    final labelsRaw = await rootBundle.loadString(_labelsPath);
    _labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<ClassificationResult> classifyImage(String imagePath) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Model belum dimuat. Panggil loadModel() dulu.');
    }

    final img = await image_lib.decodeImageFile(imagePath);
    if (img == null) {
      throw StateError('Gagal membaca gambar: $imagePath');
    }

    final resized = image_lib.copyResize(
      img,
      width: _inputSize,
      height: _inputSize,
    );

    // Cek tipe tensor input & output model (float32 vs uint8 terkuantisasi)
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final isInputQuantized = inputTensor.type == TensorType.uint8;
    final isOutputQuantized = outputTensor.type == TensorType.uint8;

    // Bentuk input tensor: [1, 224, 224, 3]
    final input = [
      List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          if (isInputQuantized) {
            // Model uint8: kirim nilai piksel mentah 0-255 sebagai int
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          } else {
            // Model float32: normalisasi 0-1
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }
        }),
      ),
    ];

    final outputLength = _labels.length; // seharusnya 2023
    final output = isOutputQuantized
        ? [List.filled(outputLength, 0)]
        : [List.filled(outputLength, 0.0)];

    interpreter.run(input, output);

    // Dequantize output kalau perlu, supaya confidence tetap 0.0 - 1.0
    late final List<double> scores;
    if (isOutputQuantized) {
      final params = outputTensor.params;
      scores = (output[0] as List<int>)
          .map((v) => (v - params.zeroPoint) * params.scale)
          .toList();
    } else {
      scores = (output[0] as List<double>);
    }

    int bestIndex = 0;
    double bestScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    final label = bestIndex < _labels.length ? _labels[bestIndex] : 'Unknown';
    return ClassificationResult(label, bestScore);
  }

  void close() {
    _interpreter?.close();
  }
}