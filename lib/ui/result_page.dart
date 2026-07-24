import 'dart:io';

import 'package:flutter/material.dart';
import 'package:deteksi_makanan/service/image_classifier_service.dart';
import 'package:deteksi_makanan/widget/classification_item.dart';

class ResultPage extends StatelessWidget {
  final File imageFile;

  const ResultPage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Result Page'),
      ),
      body: SafeArea(child: _ResultBody(imageFile: imageFile)),
    );
  }
}

class _ResultBody extends StatefulWidget {
  final File imageFile;

  const _ResultBody({required this.imageFile});

  @override
  State<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends State<_ResultBody> {
  final ImageClassifierService _classifier = ImageClassifierService();

  bool _isLoading = true;
  String? _errorMessage;
  ClassificationResult? _result;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runInference);
  }

  Future<void> _runInference() async {
    try {
      await _classifier.loadModel();
      final result = await _classifier.classifyImage(widget.imageFile.path);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal melakukan identifikasi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _classifier.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Expanded(
          child: Center(child: Image.file(widget.imageFile, fit: BoxFit.cover)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: _buildResultSection(),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    if (_isLoading) {
      return const ClassificationItemShimmer();
    }
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }
    final result = _result!;
    return ClassificationItem(
      item: result.label,
      value: '${(result.confidence * 100).toStringAsFixed(2)}%',
    );
  }
}
