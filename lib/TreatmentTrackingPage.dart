// lib/treatment_tracking_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:graduation/fastapi.dart';

class TreatmentTrackingPage extends StatefulWidget {
  const TreatmentTrackingPage({super.key});

  @override
  State<TreatmentTrackingPage> createState() => _TreatmentTrackingPageState();
}

class _TreatmentTrackingPageState extends State<TreatmentTrackingPage> {
  final List<Map<String, String>> diseases = const [
    {'label': 'Apple black rot', 'value': 'apple black rot'},
    {'label': 'Apple cedar apple rust', 'value': 'apple cedar apple rust'},
    {'label': 'Apple scab', 'value': 'apple scab'},

    {'label': 'Cherry powdery mildew', 'value': 'cherry powdery mildew'},
    {
      'label': 'Corn cercospora leaf spot gray leaf spot',
      'value': 'corn cercospora leaf spot gray leaf spot',
    },
    {'label': 'Corn common rust', 'value': 'corn common rust'},
    {
      'label': 'Corn northern leaf blight',
      'value': 'corn northern leaf blight',
    },
    {'label': 'Grape black rot', 'value': 'grape black rot'},
    {'label': 'Grape esca black measles', 'value': 'grape esca black measles'},
    {
      'label': 'Grape leaf blight isariopsis leaf spot',
      'value': 'grape leaf blight isariopsis leaf spot',
    },
    {
      'label': 'Orange haunglongbing citrus greening',
      'value': 'orange haunglongbing citrus greening',
    },
    {'label': 'Peach bacterial spot', 'value': 'peach bacterial spot'},

    {
      'label': 'Pepper bell bacterial spot',
      'value': 'pepper bell bacterial spot',
    },

    {'label': 'Potato early blight', 'value': 'potato early blight'},
    {'label': 'Potato late blight', 'value': 'potato late blight'},

    {'label': 'Squash powdery mildew', 'value': 'squash powdery mildew'},
    {'label': 'Strawberry leaf scorch', 'value': 'strawberry leaf scorch'},
    {'label': 'Tomato bacterial spot', 'value': 'tomato bacterial spot'},
    {'label': 'Tomato early blight', 'value': 'tomato early blight'},

    {'label': 'Tomato late blight', 'value': 'tomato late blight'},
    {'label': 'Tomato leaf mold', 'value': 'tomato leaf mold'},
    {'label': 'Tomato mosaic virus', 'value': 'tomato mosaic virus'},
    {
      'label': 'Tomato septoria leaf spot',
      'value': 'tomato septoria leaf spot',
    },
    {
      'label': 'Tomato spider mites two spotted spider mite',
      'value': 'tomato spider mites two spotted spider mite',
    },
    {'label': 'Tomato target spot', 'value': 'tomato target spot'},
    {
      'label': 'Tomato yellow leaf curl virus',
      'value': 'tomato yellow leaf curl virus',
    },
  ];

  String? selectedLabel;
  String? selectedValue;

  int? severity, stage, temp, humidity, soil, incidence;

  String? actionLabel;
  String? startTimeLabel;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  InputDecoration _dec(String label, {String? question}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.green),
      helperText: question,
      helperMaxLines: 4,
      helperStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 1.6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _numberField(
    String label,
    void Function(int) onSaved, {
    String? question,
  }) {
    return TextFormField(
      decoration: _dec(label, question: question),
      keyboardType: TextInputType.number,
      cursorColor: Colors.green,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Required";
        final n = int.tryParse(v);
        if (n == null) return "Enter a number";
        if (label.contains("Growth") && (n < 0 || n > 3)) {
          return "Stage must be 0–3 (0=Seedling, 1=Vegetative, 2=Flower, 3=Fruit)";
        }
        if (label.contains("%") && (n < 0 || n > 100)) {
          return "Value 0–100";
        }
        if (label.contains("°C") && (n < 5 || n > 40)) {
          return "Value 5–40";
        }
        return null;
      },
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null) onSaved(n);
      },
    );
  }

  Widget _resultCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callBackend() async {
    if (!_formKey.currentState!.validate() || selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      actionLabel = null;
      startTimeLabel = null;
    });

    final uri = Uri.parse('$apiBaseUrl/treatment-fuzzy-advanced');
    final payload = {
      'disease_name': selectedValue!,
      'severity': severity!,
      'stage': stage!, // 0=seedling,1=vegetative,2=flower,3=fruit
      'temp': temp!,
      'humidity': humidity!,
      'soil': soil!,
      'incidence': incidence!,
    };

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final outputs = (data['outputs'] as Map<String, dynamic>);
        setState(() {
          actionLabel = outputs['action_label']?.toString();
          startTimeLabel = outputs['start_time_label']?.toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error (${res.statusCode}): ${res.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green[700]!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text(
          'Treatment Tracking',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: selectedLabel,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                hint: const Text('Select disease'),
                decoration: _dec(
                  'Disease Name',
                  question: "Which disease are you analyzing?",
                ),
                items:
                    diseases.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['label'],
                        child: Text(
                          m['label']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (v) {
                  setState(() {
                    selectedLabel = v;
                    selectedValue =
                        diseases.firstWhere((e) => e['label'] == v)['value'];
                  });
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                menuMaxHeight: 420,
              ),
              const SizedBox(height: 12),

              _numberField(
                "Severity (%)",

                (v) => severity = v,
                question: "How severe is the disease on the plant (0–100%)?",
              ),
              const SizedBox(height: 12),

              _numberField(
                "Growth Stage (0-3)",
                (v) => stage = v,
                question:
                    "Select the current growth stage:\n"
                    "0 = Seedling, 1 = Vegetative, 2 = Flower, 3 = Fruit",
              ),
              const SizedBox(height: 12),

              _numberField(
                "Temperature (°C)",
                (v) => temp = v,
                question:
                    "What is the current temperature of the environment (0-40%)?",
              ),
              const SizedBox(height: 12),

              _numberField(
                "Humidity (%)",
                (v) => humidity = v,
                question:
                    "What is the humidity level in the environment (0–100%)?",
              ),
              const SizedBox(height: 12),

              _numberField(
                "Soil Moisture (%)",
                (v) => soil = v,
                question: "What is the soil moisture level (0–100%)?",
              ),
              const SizedBox(height: 12),

              _numberField(
                "Incidence (%)",
                (v) => incidence = v,
                question: "What is the disease incidence (0–100%)?",
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: isLoading ? null : _callBackend,
                icon:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.analytics),
                label: Text(isLoading ? "Processing..." : "Analyze"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (actionLabel != null || startTimeLabel != null) ...[
                _resultCard(
                  title: 'Recommended Action',
                  value: actionLabel ?? '-',
                  icon: Icons.health_and_safety,
                  color: Colors.teal,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    "This field describes the recommended intervention to control or reduce the disease "
                    "(e.g., foliar spray, pruning, irrigation adjustment...).",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ),
                _resultCard(
                  title: 'Start Time',
                  value: startTimeLabel ?? '-',
                  icon: Icons.schedule,
                  color: const Color.fromARGB(255, 2, 2, 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    "This field explains how urgent the treatment should start:\n"
                    "Immediate = right away, Soon = in the near future, Later = can be delayed.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
