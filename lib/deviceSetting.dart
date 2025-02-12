import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tryapp/home.dart';

class UploadPage extends StatefulWidget {
  final Map<String, dynamic> device;

  const UploadPage({Key? key, required this.device}) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();
  XFile? _imageFile;
  bool _isUploading = false;
  String? _uploadedUrl;
  String? _errorMessage;

  // Hardcoded Cloudinary configuration values
  String apiKey = '341452574329686'; // Example API key
  String apiSecret = 'g-bYDRCc77zCGZduqSPPodyB_nc'; // Example API secret
  String cloudName = 'dwwucmvkb'; // Example cloud name
  String uploadPreset = 'RogerFlutter'; // Example upload preset

  // Initialize Cloudinary with correct values
  late final Cloudinary cloudinary;

  @override
  void initState() {
    super.initState();
    cloudinary = Cloudinary.unsignedConfig(
      cloudName: cloudName,
    );
    _nameController.text = widget.device['name'] ?? ''; // Initialize the name field
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _imageFile = image;
        _uploadedUrl = null; // Reset uploaded URL
        _errorMessage = null; // Reset error message
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: ${e.toString()}";
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      setState(() {
        _errorMessage = "No image selected";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Upload the image to Cloudinary
      final response = await cloudinary.unsignedUpload(
        file: _imageFile!.path,
        resourceType: CloudinaryResourceType.image,
        uploadPreset: uploadPreset,
      );

      if (response.isSuccessful && response.secureUrl != null) {
        setState(() {
          _uploadedUrl = response.secureUrl;
        });

        // Send the updated name and image URL to the backend
        await _updateDeviceInBackend(_uploadedUrl!);
      } else {
        setState(() {
          _errorMessage = response.error ?? "Upload failed";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Upload failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _updateDeviceInBackend(String imageUrl) async {
    final uri = Uri.parse('https://farm-1gno.onrender.com/api/userServices/updateDevice');
    final body = {
      'deviceId': widget.device['id'], // Use the device ID from the widget
      'name': _nameController.text.trim(), // Use the updated name from the text field
      'imageUrl': imageUrl, // Use the uploaded image URL
    };

    // Debugging: Print the device information
    print('Device ID: ${widget.device['id']}');
    print('Updated Name: ${_nameController.text.trim()}');
    print('Image URL: $imageUrl');
    print('Request Body: $body');

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      // Debugging: Print the response status and body
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Handle success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device updated successfully!')),
        );
      } else {
        // Handle server errors
        final responseJson = json.decode(response.body);
        final errorMessage = responseJson['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage')),
        );
      }
    } catch (error) {
      // Debugging: Print the error
      print('Network Error: $error');

      // Handle network errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 120),
              painter: WavyAppBarPainter(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  const Spacer(),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Modifiers vos dispositifs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Display the current or selected image
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundImage: _imageFile != null
                    ? FileImage(File(_imageFile!.path)) // Display the newly picked image
                    : widget.device['image'] != null
                        ? NetworkImage(widget.device['image']) // Display the current image
                        : null, // No image
                child: _imageFile == null && widget.device['image'] == null
                    ? const Icon(
                        Icons.camera_alt, // Placeholder icon
                        size: 40,
                        color: Colors.white,
                      )
                    : null, // No child if there's an image
              ),
            ),
            const SizedBox(height: 20),
            // Text form for updating the device name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Button to pick an image
            Center(
              child: ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Choisir une image',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Button to upload the image and update the device
            Center(
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enregistrer',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Display error messages
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}