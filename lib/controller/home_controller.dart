import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:deteksi_makanan/ui/result_page.dart';

class HomeController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  File? pickedImage;

  Future<void> pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (xFile != null) {
        pickedImage = File(xFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal mengambil gambar: $e');
    }
  }

  void goToResultPage(BuildContext context) {
    final image = pickedImage;
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil atau pilih gambar dulu ya')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultPage(imageFile: image)),
    );
  }
}