// search_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'fastapi.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  File? imageFile;
  DateTime? imageDate;

  final TextEditingController locationController = TextEditingController();

  final List<String> plantNames = const [
    'Apple',
    'Blueberry',
    'Cherry',
    'Corn',
    'Grape',
    'Orange',
    'Peach',
    'Pepper',
    'Potato',
    'Raspberry',
    'Soybean',
    'Squash',
    'Strawberry',
    'Tomato',
  ];

  String? selectedPlantName;
  String? predictedDisease;

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        imageDate = File(picked.path).lastModifiedSync();
      });
    }
  }

  // التقاط صورة بالكاميرا
  Future<void> _pickFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        imageDate = DateTime.now();
      });
    }
  }

  void _chooseSource() {
    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Choose Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromCamera();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<bool> _isPlantLeaf(File file) async {
    final uri = Uri.parse('$apiBaseUrl/predict/both');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 200) {
        final data = jsonDecode(body);
        final hasLeaf =
            (data['has_leaf'] ?? data['has_leave'] ?? false) == true;
        return hasLeaf;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _onSend() async {
    if (imageFile == null ||
        selectedPlantName == null ||
        locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      final ok = await _isPlantLeaf(imageFile!);
      if (!ok) {
        setState(() => predictedDisease = null);

        showDialog<void>(
          context: context,
          builder:
              (_) => const AlertDialog(
                title: Text(
                  'Invalid Image',
                  style: TextStyle(color: Colors.green),
                ),
                content: Text('This image is not a plant leaf'),
              ),
        );

        return;
      }

      final uri = Uri.parse('$apiBaseUrl/predict/intake');
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['plant_name'] = selectedPlantName!
            ..fields['region'] = locationController.text.trim()
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile!.path),
            );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);

        // حماية إضافية لو عاد الباك إند بلا ورقة بشكل غير متوقع
        if ((data['has_leaf'] ?? data['has_leave'] ?? true) != true ||
            data['disease'] == null ||
            data['error'] != null) {
          setState(() => predictedDisease = null);
          return;
        }

        final diseaseName = data['disease']['label'];
        setState(() => predictedDisease = diseaseName);

        showDialog<void>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text(
                  'Prediction Result',
                  style: TextStyle(color: Colors.green),
                ),
                content: Text('The disease: $diseaseName'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
        );
      } else {
        final err = jsonDecode(body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${err["detail"] ?? body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  Widget _portraitImagePreview(BuildContext context) {
    if (imageFile == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No image selected')),
      );
    }

    final screenH = MediaQuery.of(context).size.height;
    final previewH = screenH * 0.55;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black12,
        height: previewH,
        width: double.infinity,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Image.file(imageFile!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan For Disease'),
        centerTitle: true,
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _chooseSource,
        child: Icon(Icons.add_a_photo_outlined, color: green),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _portraitImagePreview(context),
            const SizedBox(height: 16),

            if (imageFile != null) ...[
              // اختيار النبات
              DropdownButtonFormField<String>(
                value: selectedPlantName,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Plant name',
                  labelStyle: const TextStyle(color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 1.6),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.2),
                  ),
                ),
                items:
                    plantNames
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => selectedPlantName = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                menuMaxHeight: 420,
              ),
              const SizedBox(height: 16),

              // إدخال المنطقة
              TextFormField(
                controller: locationController,
                cursorColor: const Color.fromRGBO(136, 144, 99, 1),
                decoration: InputDecoration(
                  labelText: 'Region',
                  labelStyle: const TextStyle(color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 1.6),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSend,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // إظهار المرض المكتشف
              if (predictedDisease != null)
                Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_florist,
                      color: Colors.green,
                    ),
                    title: const Text(
                      "Your Plant's Disease :",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      predictedDisease!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
