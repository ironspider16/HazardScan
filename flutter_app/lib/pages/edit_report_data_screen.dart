import 'package:flutter/material.dart';

class EditReportDataScreen extends StatefulWidget {
  final Map<String, dynamic> initialAiData;

  const EditReportDataScreen({super.key, required this.initialAiData});

  @override
  State<EditReportDataScreen> createState() => _EditReportDataScreenState();
}

class _EditReportDataScreenState extends State<EditReportDataScreen> {
  // Map containing deep copies of controllers organized by category
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  late String _overallStatus;

  // Define categories matching exactly what your LocalReportCompiler reads
  final List<Map<String, String>> _categories = [
    {'key': 'ladderHeight', 'label': 'Working at Heights'},
    {'key': 'ppe', 'label': 'Personal Protective Equipment (PPE)'},
    {'key': 'buddySystem', 'label': 'Buddy System'},
    {'key': 'electricalMachinery', 'label': 'Electrical & Machinery Hazards'},
    {'key': 'areaHazards', 'label': 'Housekeeping and Area Hazards'},
  ];

  @override
  void initState() {
    super.initState();
    _overallStatus = widget.initialAiData['overallStatus'] ?? 'PENDING';

    // Populate editing controllers dynamically from current AI Map data
    for (var category in _categories) {
      final String key = category['key']!;
      final Map<String, dynamic> block = widget.initialAiData[key] ?? {};

      _controllers[key] = {
        'compliance': TextEditingController(text: block['compliance']?.toString() ?? 'COMPLIANT'),
        'description': TextEditingController(text: block['description']?.toString() ?? ''),
        'reasoning': TextEditingController(text: block['reasoning']?.toString() ?? ''),
        'advice': TextEditingController(text: block['advice']?.toString() ?? ''),
      };
    }
  }

  @override
  void dispose() {
    // Prevent memory leaks by cleanly disposing all dynamic text controllers
    for (var innerMap in _controllers.values) {
      for (var controller in innerMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // Pack the typed values back into a map structured perfectly for the compiler
  void _saveChanges() {
    final Map<String, dynamic> updatedData = {
      'overallStatus': _overallStatus,
    };

    _controllers.forEach((categoryKey, fields) {
      updatedData[categoryKey] = {
        'compliance': fields['compliance']!.text,
        'description': fields['description']!.text,
        'reasoning': fields['reasoning']!.text,
        'advice': fields['advice']!.text,
      };
    });

    Navigator.pop(context, updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Refine AI Observations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.blueAccent),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Overall status dropdown editor
            Card(
              child: ListTile(
                title: const Text("Overall Report Status", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: DropdownButton<String>(
                  value: ['DANGEROUS', 'PARTIALLY COMPLIANT', 'COMPLIANT', 'SAFE'].contains(_overallStatus.toUpperCase()) 
                      ? _overallStatus.toUpperCase() 
                      : 'COMPLIANT',
                  items: ['DANGEROUS', 'PARTIALLY COMPLIANT', 'COMPLIANT', 'SAFE'].map((String status) {
                    return DropdownMenuItem<String>(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _overallStatus = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Loop and build cards for the 4 core categories
            ..._categories.map((cat) {
              final String key = cat['key']!;
              final String label = cat['label']!;
              final fields = _controllers[key]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ),
                          DropdownButton<String>(
                            value: ['DANGEROUS', 'PARTIALLY COMPLIANT', 'COMPLIANT', 'SAFE'].contains(fields['compliance']!.text.toUpperCase())
                                ? fields['compliance']!.text.toUpperCase()
                                : 'COMPLIANT',
                            items: ['DANGEROUS', 'PARTIALLY COMPLIANT', 'COMPLIANT', 'SAFE'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            onChanged: (val) => setState(() => fields['compliance']!.text = val ?? 'COMPLIANT'),
                          )
                        ],
                      ),
                      const Divider(),
                      TextField(
                        controller: fields['description'],
                        decoration: const InputDecoration(labelText: "Observation Text"),
                        maxLines: null,
                      ),
                      TextField(
                        controller: fields['reasoning'],
                        decoration: const InputDecoration(labelText: "Reasoning Matrix"),
                        maxLines: null,
                      ),
                      TextField(
                        controller: fields['advice'],
                        decoration: const InputDecoration(labelText: "Corrective Actions / Recommendations"),
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}