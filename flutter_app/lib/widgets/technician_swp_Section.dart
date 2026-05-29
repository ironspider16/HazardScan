import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/services/gemini_service.dart';
import 'package:kkhazardscan/widgets/swp_checklist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/WAH_Permit.dart';
import '../widgets/image_upload.dart';
import '../Design/style_constant.dart';
import '../widgets/App_Textfield.dart';
import '../widgets/safety_status_widget.dart';
import '../yolo/yolo_service.dart';

class TechnicianSwpSection extends StatefulWidget {
  final int templateId;
  final String categoryName;

  final String initialPtw;
  final bool initialAbove3m;
  final List<String> initialCheckedItems;
  final Uint8List? initialImage;
  final String initialDetails;
  final Function(String details) onDetailsChanged;

  final Function(bool isAbove3m, String ptw) onPtwChanged;
  final Function(List<String> checkedItems) onChecklistChanged;

  final Function(Uint8List bytes) onImageChanged;
  final Function(bool isCleared) onAllChecked;

  final Function(Map<String, dynamic> aiData)? onAiAnalyzed;

  const TechnicianSwpSection({
    super.key,
    required this.templateId,
    required this.categoryName,
    required this.onPtwChanged,
    required this.initialPtw,
    required this.initialCheckedItems,
    required this.initialImage,
    required this.onChecklistChanged,
    required this.onImageChanged,
    required this.initialAbove3m,
    required this.initialDetails,
    required this.onDetailsChanged,
    required this.onAllChecked,
    this.onAiAnalyzed,
  });

  @override
  State<TechnicianSwpSection> createState() => _TechnicianSwpSectionState();
}

class _TechnicianSwpSectionState extends State<TechnicianSwpSection> {
  final supabase = Supabase.instance.client;
  List<String> items = [];
  bool isSafetyCleared = false;
  bool isPtwCleared = true;
  bool isLoading = true;
  late final TextEditingController _detailsCtrl;

  String aiStatus = 'N/A';
  List<String> aiReasons = [];
  bool isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _detailsCtrl = TextEditingController(text: widget.initialDetails);

    if (widget.categoryName.toLowerCase().contains("work at height")) {
      isPtwCleared = !widget.initialAbove3m || widget.initialPtw.isNotEmpty;
    } else {
      isPtwCleared = true;
    }
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final response = await supabase
        .from('swp_items')
        .select('description')
        .eq('template_id', widget.templateId);

    setState(() {
      items = List<String>.from(response.map((x) => x['description']));
      isLoading = false;
    });
  }

  // Helper utility to convert camelCase keys (like ladderHeight) into clean labels (Ladder Height)
  String _formatCategoryKey(String key) {
    if (key == 'ppe') return 'PPE';
    final RegExp numUpperRegExp = RegExp(r'(?<=[a-z])(?=[A-Z])');
    final words = key.split(numUpperRegExp);
    return words
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppPadding.page),
        child: LinearProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 420;
          return Column(
            children: [
              if (widget.categoryName.toLowerCase().contains("work at height"))
                WAHPermitWidget(
                  isMobile: true,
                  initialPtw: widget.initialPtw,
                  initialAbove3m: widget.initialAbove3m,
                  onValidityChanged: (isAbove3m, ptwNum) {
                    setState(() {
                      isPtwCleared = !isAbove3m || ptwNum.trim().isNotEmpty;
                    });
                    widget.onPtwChanged(isAbove3m, ptwNum.trim());
                  },
                ),
              SWPChecklistWidget(
                isMobile: isMobile,
                items: items,
                initialCheckedItems: widget.initialCheckedItems,
                onChecklistChanged: (updatedCheckedList) {
                  widget.onChecklistChanged(updatedCheckedList);
                },
                onAllChecked: (status) {
                  setState(() => isSafetyCleared = status);
                  widget.onAllChecked(status);
                },
              ),
              if (widget.categoryName.toLowerCase().contains("work at height"))
                AppImageUpload(
                  label: "Site Photos",
                  onImageSelected: (bytes) async {
                    widget.onImageChanged(bytes as Uint8List);
                    print(
                      "Starting AI Analysis for: ${widget.categoryName}...",
                    );
                    setState(() {
                      isAnalyzing = true;
                    });
                    // YOLO Detection
                    final detections = await YoloService().yoloDetect(
                      context,
                      bytes,
                    );
                    print(detections);
                    try {
                      final String rawResponse =
                          await GeminiService.detectHazards(bytes as Uint8List, _detailsCtrl.text.trim());
                      print("--- GEMINI JSON OUTPUT ---");
                      print(rawResponse);

                      String cleanJson = rawResponse
                          .replaceAll('```json', '')
                          .replaceAll('```', '')
                          .trim();

                      final Map<String, dynamic> data = jsonDecode(cleanJson);

                      if (widget.onAiAnalyzed != null) {
                        widget.onAiAnalyzed!(data);
                      }

                      setState(() {
                        // 1. Correctly parse status using 'overallStatus'
                        aiStatus = data['overallStatus'] ?? "N/A";

                        // 2. Extract reasons dynamically from nested maps
                        List<String> extractedReasons = [];

                        data.forEach((key, value) {
                          if (value is Map<String, dynamic>) {
                            final compliance =
                                value['compliance']?.toString().toUpperCase() ??
                                '';

                            // Collect from non-compliant components
                            // if (compliance == 'PARTIALLY COMPLIANT' || compliance == 'DANGEROUS') {
                            final reasoning = value['reasoning'] ?? '';
                            final advice = value['advice'] ?? '';
                            final categoryTitle = _formatCategoryKey(key);

                            if (reasoning.isNotEmpty) {
                              extractedReasons.add(
                                "[$categoryTitle] $reasoning",
                              );
                            }
                            if (advice.isNotEmpty) {
                              extractedReasons.add("Recommendation: $advice");
                            }
                            // }
                          }
                        });

                        aiReasons = extractedReasons;
                        debugPrint("$aiReasons");
                        isAnalyzing = false;
                      });

                      // 3. Format text details beautifully into a human-readable summary
                      StringBuffer detailsBuffer = StringBuffer();
                      detailsBuffer.writeln(
                        "Overall Safety Status: $aiStatus\n",
                      );
                      data.forEach((key, value) {
                        if (value is Map<String, dynamic>) {
                          detailsBuffer.writeln(
                            "${_formatCategoryKey(key)}: ${value['compliance']}",
                          );
                          if (value['description'] != null) {
                            detailsBuffer.writeln(
                              " • Description: ${value['description']}",
                            );
                          }
                          if (value['reasoning'] != null) {
                            detailsBuffer.writeln(
                              " • Reasoning: ${value['reasoning']}",
                            );
                          }
                          if (value['advice'] != null) {
                            detailsBuffer.writeln(
                              " • Advice: ${value['advice']}",
                            );
                          }
                          detailsBuffer.writeln();
                        }
                      });
                    } catch (e) {
                      print("❌ AI Analysis failed: $e");
                      setState(() {
                        isAnalyzing = false;
                        aiStatus = "N/A";
                        aiReasons = [];
                      });
                    }
                  },
                ),
              if (widget.categoryName.toLowerCase().contains(
                "work at height",
              )) ...[
                if (isAnalyzing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppPadding.tight),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text("Analyzing site safety..."),
                      ],
                    ),
                  )
                else
                  SafetyStatusWidget(rawStatus: aiStatus, reasons: aiReasons),
              ],

              const SizedBox(height: AppPadding.medium),
              AppTextfield(
                label: "Details",
                hint: "Enter details here / Take photo to output AI details",
                controller: _detailsCtrl,
                Maxlines: 5, // Expanded display space for report layout logs
                onChanged: (value) {
                  widget.onDetailsChanged(value.trim());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
