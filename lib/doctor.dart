import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:image/image.dart' as img; // Add prefix here



class TFLiteIntegrationScreen extends StatefulWidget {
  @override
  _TFLiteIntegrationScreenState createState() => _TFLiteIntegrationScreenState();
}

class _TFLiteIntegrationScreenState extends State<TFLiteIntegrationScreen> {
  File? _image;
  List<dynamic> _predictions = [];
  late tflite.Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // Load the TFLite model from assets
      final options = tflite.InterpreterOptions();

      // Enable GPU Delegate for better performance (optional)
      // options.addDelegate(tflite.GpuDelegate());

      _interpreter = await tflite.Interpreter.fromAsset('model.tflite', options: options);
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Run inference on the selected image
      _runInference(_image!);
    }
  }

  Future<void> _runInference(File image) async {
    // Preprocess the image
    var input = _preprocessImage(image);

    // Prepare output tensor
    var output = List.filled(1 * 10, 0).reshape([1, 10]); // Adjust output shape based on your model

    // Run inference
    _interpreter.run(input, output);

    // Postprocess the output
    setState(() {
      _predictions = output[0]; // Adjust based on your model's output format
    });
  }

  Uint8List _preprocessImage(File imageFile) {
    // Load and resize the image
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
    image = img.copyResize(image, width: 256, height: 256); // Adjust size based on your model's input

    // Convert image to byte array and normalize pixel values
    var convertedBytes = Float32List(256 * 256 * 3); // Adjust based on your model's input shape
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 256; x++) {
        var pixel = image.getPixel(x, y);

        // Extract RGB values using the Pixel methods
        num red = pixel.r;
        num green = pixel.g;
        num blue = pixel.b;

        // Normalize pixel values to [-1, 1]
        buffer[pixelIndex++] = (red - 127.5) / 127.5;
        buffer[pixelIndex++] = (green - 127.5) / 127.5;
        buffer[pixelIndex++] = (blue - 127.5) / 127.5;
      }
    }

    return convertedBytes.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TFLite with Flutter'),
      ),
      body: Column(
        children: [
          // Display selected image
          _image == null
              ? Center(child: Text('No image selected'))
              : Image.file(_image!, height: 300, width: double.infinity, fit: BoxFit.cover),

          // Button to pick an image
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Select Image'),
          ),

          // Display predictions
          Expanded(
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Class: ${_predictions[index]}'),
                  subtitle: Text('Confidence: ${_predictions[index].toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}