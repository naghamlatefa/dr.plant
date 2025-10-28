// lib/SearchAboutYourRegion.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Data model to hold disease + preventions (list)
class DiseaseInfo {
  final String name;
  final List<String> preventions;

  const DiseaseInfo({required this.name, required this.preventions});

  static Map<String, dynamic> _normalize(Map m) {
    final n = <String, dynamic>{};
    m.forEach((k, v) {
      if (k is String) n[k.trim().toLowerCase()] = v;
    });
    return n;
  }

  /// يحوّل أي نص وقاية إلى عناصر قائمة بحسب الفواصل/الأسطر
  static List<String> _splitPreventions(String s) {
    final raw = s.trim();
    if (raw.isEmpty) return const [];
    final parts = raw.split(RegExp(r'[,\n;•]+'));
    return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  }

  factory DiseaseInfo.fromDynamic(dynamic e) {
    if (e is Map) {
      final m = _normalize(e);
      final name =
          (m['disease_name'] ?? m['name'] ?? m['disease'] ?? '')
              .toString()
              .trim();

      final pv = m['preventions'];
      List<String> preventions;

      if (pv is List) {
        // لو الـ API رجّع List فعلاً
        preventions =
            pv
                .map((x) => (x ?? '').toString().trim())
                .expand(
                  (s) => _splitPreventions(s),
                ) // دعم العناصر المحتوية على فواصل
                .where((s) => s.isNotEmpty)
                .toList();
      } else if (pv is String) {
        // لو رجّع String كامل
        preventions = _splitPreventions(pv);
      } else {
        // key بديل: prevention
        final one = (m['prevention'] ?? '').toString();
        preventions = _splitPreventions(one);
      }

      return DiseaseInfo(name: name, preventions: preventions);
    }
    return DiseaseInfo(name: e.toString(), preventions: const []);
  }

  /// Join list nicely (fallback)
  String get joinedPreventions =>
      preventions.isEmpty ? '—' : preventions.join(', ');

  /// Consider names like "healthy", "Apple___healthy", "apple_healthy"… as healthy (to exclude)
  bool get isHealthy {
    final n = name.trim().toLowerCase();
    if (n == 'healthy') return true;
    return n.endsWith('___healthy') ||
        n.endsWith('_healthy') ||
        n.endsWith(' healthy') ||
        n.contains('___healthy') ||
        (n.split(RegExp(r'[_\s/\\-]+')).isNotEmpty &&
            n.split(RegExp(r'[_\s/\\-]+')).last == 'healthy');
  }
}

class SearchAboutYourRegion extends StatefulWidget {
  final String apiBaseUrl;

  const SearchAboutYourRegion({Key? key, required this.apiBaseUrl})
    : super(key: key);

  @override
  State<SearchAboutYourRegion> createState() => _SearchAboutYourRegionState();
}

class _SearchAboutYourRegionState extends State<SearchAboutYourRegion> {
  bool _loading = false;
  String? _error;
  List<DiseaseInfo> _diseases = [];

  String? _lastPlant;
  String? _lastRegion;

  static const List<String> _plantNames = [
    "Apple",
    "Blueberry",
    "Cherry",
    "Corn",
    "Grape",
    "Orange",
    "peach",
    "Pepper",
    "Potato",
    "Raspberry",
    "Soybean",
    "Squash",
    "Strawberry",
    "Tomato",
  ];

  String _titleCase(String? s) {
    if (s == null) return '';
    final t = s.trim();
    if (t.isEmpty) return '';
    return t
        .split(RegExp(r'\s+'))
        .map(
          (w) =>
              w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<void> _fetchRegionDiseasesWithPreventions({
    required String region,
    String? plantName,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
      _diseases = [];
      _lastRegion = region;
      _lastPlant =
          plantName?.trim().isNotEmpty == true ? plantName!.trim() : null;
    });

    try {
      final qp = <String, String>{'region': region.trim()};
      if (_lastPlant != null) qp['plant_name'] = _lastPlant!;

      final uri = Uri.parse(
        '${widget.apiBaseUrl}/region-diseases-with-preventions',
      ).replace(queryParameters: qp);

      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final body = json.decode(utf8.decode(resp.bodyBytes));
        if (body is List) {
          // نحول + نفلتر العناصر الـ healthy
          final results =
              body
                  .map((e) => DiseaseInfo.fromDynamic(e))
                  .where((d) => !d.isHealthy)
                  .toList();

          setState(() {
            if (results.isEmpty) {
              _error = 'No results found.';
            } else {
              _diseases = results;
            }
          });
        } else {
          setState(() => _error = 'Unexpected response format.');
        }
      } else {
        setState(() => _error = 'Server error: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPlantAndRegionDialog() {
    String? selectedPlant; // منسدلة
    final regionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setS) => AlertDialog(
                  title: const Text('Enter Plant and Region Name'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedPlant,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Plant Name',
                          labelStyle: const TextStyle(color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.greenAccent,
                              width: 2.2,
                            ),
                          ),
                        ),
                        items:
                            _plantNames
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setS(() => selectedPlant = v),
                        menuMaxHeight: 420,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: regionController,
                        cursorColor: Colors.green,
                        decoration: InputDecoration(
                          labelText: 'Region Name',
                          labelStyle: const TextStyle(color: Colors.green),
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.greenAccent,
                              width: 2.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        final region = regionController.text.trim();
                        if (selectedPlant == null || region.isEmpty) return;
                        Navigator.of(context).pop();
                        _fetchRegionDiseasesWithPreventions(
                          region: region,
                          plantName: selectedPlant!,
                        );
                      },
                      child: const Text(
                        'Send',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showRegionOnlyDialog() {
    final regionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Region Name'),
            content: TextField(
              controller: regionController,
              cursorColor: Colors.green,
              decoration: InputDecoration(
                labelText: 'Region Name',
                labelStyle: const TextStyle(color: Colors.green),
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.greenAccent, width: 2.2),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  final region = regionController.text.trim();
                  if (region.isEmpty) return;
                  Navigator.of(context).pop();
                  _fetchRegionDiseasesWithPreventions(region: region);
                },
                child: const Text(
                  'Send',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _lastRegion == null
            ? 'Search About Your Region'
            : (_lastPlant == null
                ? 'Diseases in "${_lastRegion!}"'
                : 'Diseases for "${_lastPlant!}" in "${_lastRegion!}"');

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text(
                      'Search diseases by Plant & Region',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showPlantAndRegionDialog,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.public, color: Colors.white),
                    label: const Text(
                      'Search diseases by Region',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showRegionOnlyDialog,
                  ),
                ),
                const SizedBox(height: 28),

                if (_loading) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ] else if (_error != null) ...[
                  const SizedBox(height: 24),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ] else if (_diseases.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ResultHeader(
                    plant: _lastPlant,
                    region: _lastRegion,
                    titleCase: _titleCase,
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _diseases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final disease = _diseases[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),

                          title: Text(
                            disease.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            // مسافة مناسبة بين العنوان وكلمة Prevention
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prevention:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // ✅ كل جملة وقاية في سطر مع إشارة
                                if (disease.preventions.isEmpty)
                                  const Text(
                                    '—',
                                    style: TextStyle(color: Colors.black54),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        disease.preventions.map((p) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    p,
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 150,
                    height: 40,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _diseases.clear();
                          _lastPlant = null;
                          _lastRegion = null;
                          _error = null;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String? plant;
  final String? region;
  final String Function(String?) titleCase;

  const _ResultHeader({
    required this.plant,
    required this.region,
    required this.titleCase,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlant = (plant != null && plant!.trim().isNotEmpty);
    final hasRegion = (region != null && region!.trim().isNotEmpty);

    final line =
        hasPlant && hasRegion
            ? '${titleCase(plant)} • ${titleCase(region)}'
            : hasRegion
            ? titleCase(region)
            : '';

    if (line.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.label_important, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
