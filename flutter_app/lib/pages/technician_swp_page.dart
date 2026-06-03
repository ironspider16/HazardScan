import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design/style_constant.dart';
import '../widgets/technician_swp_Section.dart';
import '../widgets/Menu_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kkhazardscan/services/report_compiler.dart';

class TechnicianSWPPage extends StatefulWidget {
  final List<String> selectedCategories;
  final Map<String, dynamic>?
  task; // Fixed: Restored task property to prevent widget.task errors


  const TechnicianSWPPage({
    super.key,
    required this.selectedCategories,
    this.task, // Optional for flexibility
  });


  @override
  State<TechnicianSWPPage> createState() => _TechnicianSWPPageState();
}


class _TechnicianSWPPageState extends State<TechnicianSWPPage> {
  final supabase = Supabase.instance.client;


  List<Map<String, dynamic>> allTemplates = [];
  Map<String, int?> selectedSubCategories = {};
  bool isLoading = true;


  final Map<int, String> _savedPtwNumbers = {};
  final Map<int, bool> _savedAbove3m = {};
  final Map<int, List<String>> _savedChecklists = {};
  final Map<int, Uint8List> _savedImages = {};
  final Map<int, String> _savedDetails = {};
  final Map<int, bool> _checklistCompletionStates = {};


  final Map<int, Map<String, dynamic>> _savedAiData = {};


  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }


  Future<void> _fetchSubCategories() async {
    try {
      setState(() => isLoading = true);


      final response = await supabase
          .from('swp_templates')
          .select('id, category, title')
          .order('title');


      final templateList = List<Map<String, dynamic>>.from(response);


      setState(() {
        allTemplates = templateList
            .where((t) => widget.selectedCategories.contains(t['category']))
            .toList();


        for (String category in widget.selectedCategories) {
          final matchedList = allTemplates
              .where((t) => t['category'] == category)
              .toList();
          if (matchedList.isNotEmpty) {
            final firstId = matchedList.first['id'] as int;
            selectedSubCategories[category] = firstId;


            // PRE-POPULATE THE CORES HERE SO CONTROLLERS DO NOT GET WIPED
            _savedPtwNumbers[firstId] = "";
            _savedAbove3m[firstId] = false;
            _savedChecklists[firstId] = [];
            _savedDetails[firstId] = "";
            _checklistCompletionStates[firstId] = false;
          } else {
            selectedSubCategories[category] = null;
          }
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching sub-categories : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<Uint8List> _prepareEmailImage(Uint8List orginalBytes) async {
    final compressed = await FlutterImageCompress.compressWithList(
      orginalBytes,
      quality: 30,
      minWidth: 500,
      minHeight: 500,
    );
    return compressed;
  }


  void _showAcknowledgementDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    bool dialogSubmitting = false;


    const String ackMessage =
        "The Safe Work Procedures have been communicated and are understood by all "
        "relevant personnel. Inspections have been conducted to verify that work is "
        "carried out in accordance with the established procedures, ensuring a safe "
        "and compliant working environment.";


    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents closing accidentally by clicking outside
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              title: Text(
                "Safety Acknowledgement",
                style: AppTypography.Bluesubheading,
              ),
              content: dialogSubmitting
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 400, // Fixed layout sizing bounds
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextfield(
                                label: "Name",
                                controller: nameCtrl,
                                hint: "Enter your full name",
                              ),
                              const SizedBox(height: AppPadding.tight),
                              AppTextfield(
                                label: "Designation",
                                controller: desigCtrl,
                                hint: "e.g. Senior Technician",
                              ),
                              const SizedBox(height: AppPadding.tight),
                              AppTextfield(
                                label: "Location",
                                hint: "Ward-2B",
                                controller: locationCtrl,
                              ),
                              const SizedBox(height: AppPadding.tight),
                              AppTextfield(
                                label: "Department",
                                controller: deptCtrl,
                                hint: "e.g. Facilities Management",
                              ),
                              const SizedBox(height: AppPadding.tight),
                              Text(
                                "Declaration Statement",
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppPadding.tight),
                              Container(
                                padding: const EdgeInsets.all(AppPadding.tight),
                                decoration: BoxDecoration(
                                  color: AppColors.borderGrey.withAlpha(10),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall,
                                  ),
                                  border: Border.all(
                                    color: AppColors.borderGrey.withAlpha(75),
                                  ),
                                ),
                                child: Text(
                                  ackMessage,
                                  style: AppTypography.faintbody.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              actions: dialogSubmitting
                  ? []
                  : [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            // 1. Cancel Button
                            Expanded(
                              flex: 2,
                              child: MenuButton(
                                label: "Cancel",
                                isMini: true,
                                onTap: () => Navigator.pop(dialogContext),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. NEW: Preview Button
                            Expanded(
                              flex: 3,
                              child: MenuButton(
                                label: "Preview",
                                isPrimary:
                                    false, // Make it look different from the submit button
                                isMini: true,
                                icon: Icons.remove_red_eye,
                                onTap: () {
                                  // Find the first active template ID to pull the AI data and notes
                                  final firstActiveId = selectedSubCategories
                                      .values
                                      .firstWhere(
                                        (id) => id != null,
                                        orElse: () => null,
                                      );

                                  if (firstActiveId != null) {
                                    final aiData =
                                        _savedAiData[firstActiveId] ?? {};
                                    final textDetail =
                                        _savedDetails[firstActiveId] ?? "";

                                    // Generate the raw text report instantly
                                    final markdownReport =
                                        LocalReportCompiler.generateWshReport(
                                          locationCtrl: locationCtrl,
                                          supervisorCtrl: nameCtrl,
                                          employerCtrl: deptCtrl,
                                          // We create dummy empty controllers for fields not currently in your dialog
                                          feedbackCtrl: TextEditingController(),
                                          changesCtrl: TextEditingController(),
                                          manualNotesCtrl:
                                              TextEditingController(
                                                text: textDetail,
                                              ),
                                          initialAiData: aiData,
                                        );

                                    // Navigate to the dummy debug screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReportPreviewScreen(
                                              reportContent: markdownReport,
                                            ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 3. Submit Button
                            Expanded(
                              flex: 3,
                              child: MenuButton(
                                label: "Submit",
                                isPrimary: true,
                                isMini: true,
                                icon: Icons.assignment_turned_in_rounded,
                                onTap: () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false))
                                    return;


                                  setDialogState(() => dialogSubmitting = true);


                                  bool success = await _executeSubmitReport(
                                    name: nameCtrl.text.trim(),
                                    designation: desigCtrl.text.trim(),
                                    department: deptCtrl.text.trim(),
                                    location: locationCtrl.text.trim(),
                                  );


                                  if (success && mounted) {
                                    Navigator.pop(dialogContext);
                                    // ... the rest of your existing success routing code ...
                                  } else {
                                    setDialogState(
                                      () => dialogSubmitting = false,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }


  Future<bool> _executeSubmitReport({
    required String name,
    required String designation,
    required String department,
    required String location,
  }) async {
    try {
      if (name.trim() == "" ||
          designation.trim() == "" ||
          department.trim() == "" ||
          location.trim() == "") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fill in all fields"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }


      final activeSubCategoryIds = selectedSubCategories.values
          .where((id) => id != null)
          .cast<int>()
          .toList();


      List<Map<String, dynamic>> recordsToInsert = [];
      for (int templateId in activeSubCategoryIds) {
        final template = allTemplates.firstWhere((t) => t['id'] == templateId);
        final String title = template['title'] ?? 'Unknown';
        final String category = template['category'] ?? 'Unknown';


        String ptwNumber = _savedPtwNumbers[templateId] ?? "";
        String detailsText = _savedDetails[templateId] ?? "";


        int? wahSafetyForeignKey;
        Uint8List? imageBytes = _savedImages[templateId];


        // Process AI data
        if (_savedAiData.containsKey(templateId) &&
            _savedAiData[templateId] != null) {
          final aiData = _savedAiData[templateId]!;


          final insertedWahData = await supabase
              .from('WAH_safetyVariables')
              .insert({
            'Overall Status': aiData['overallStatus'] ?? 'N/A',
            'ladderheight': aiData['ladderHeight'] ?? {},
            'ppe': aiData['ppe'] ?? {},
            'buddySystem': aiData['buddySystem'] ?? {},
            'areaHazards': aiData['areaHazards'] ?? {},
          })
              .select('id')
              .single();


          wahSafetyForeignKey = insertedWahData['id'];
        }


        recordsToInsert.add({
          'swp_template_id': templateId,
          'wah_permit_numbers': ptwNumber.isNotEmpty ? ptwNumber : null,
          'Details': detailsText.isNotEmpty ? detailsText : null,
          'technician_name': name,
          'designation': designation,
          'department': department,
          'location': location,
          'WAH_safetyVariables_FK': wahSafetyForeignKey,
          'image_url': null, // Storing null since we are no longer using Supabase storage
        });


        // Send email via Brevo
        await sendBrevoEmail(
          technicianName: name,
          details: detailsText,
          title: title,
          category: category,
          ptwNumber: ptwNumber,
          designation: designation,
          department: department,
          location: location,
          imageBytes: imageBytes,
        );
      }


      await supabase.from('safety_reports').insert(recordsToInsert);
      return true;
    } catch (e) {
      print("Error executing report: $e");
      return false;
    }
  }


    Future<void> sendBrevoEmail({
    required String technicianName,
    required String details,
    required String ptwNumber,
    required String designation,
    required String department,
    required String title,
    required String category,
    required String location,
    Uint8List? imageBytes,
  }) async {
    final Uri url = Uri.parse('https://api.brevo.com/v3/smtp/email');


    // Prepare body
    final Map<String, dynamic> body = {
      "sender": {"name": "Safety System", "email": "liewjunlei16@gmail.com"},
      "to": [{"email": "liewjunlei16@gmail.com", "name": "Manager"}],
      "templateId": 1, // Replace with your actual Brevo template ID
      "params": {
        "category": category,
        "technician_name": technicianName,
        "name": technicianName,
        "template_title": title,
        "ptw": ptwNumber,
        "designation": designation,
        "department": department,
        "location": location,
        "message": details,
      },
    };


    // Attach image if it exists
    if (imageBytes != null) {
      final String base64Image = base64Encode(imageBytes);
      body['attachment'] = [
        {
          "name": "safety_evidence.jpg",
          "content": base64Image,
        }
      ];
    }


    try {
      final response = await http.post(
        url,
        headers: {
          'api-key': apiKey,
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode(body),
      );


      if (response.statusCode != 201) {
        print('Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final double fieldWidth = (MediaQuery.of(context).size.width * 0.85).clamp(
      300.0,
      450.0,
    );


    final activeSubCategoryIds = selectedSubCategories.values
        .where((id) => id != null)
        .cast<int>()
        .toList();


    final String? errorMessage = activeSubCategoryIds
        .map((id) {
          // Check common condition first
          if (_checklistCompletionStates[id] != true) {
            return "Please complete all checklist items.";
          }


          // Only check photo/PTW requirements if it is Work at Height
          bool isAbove3m = _savedAbove3m[id] ?? false;
          if (isAbove3m) {
            String ptw = _savedPtwNumbers[id] ?? "";
            if (ptw.trim().isEmpty) {
              return "Permit To Work (PTW) number is required.";
            }
            if (_savedImages[id] == null) {
              return "Please upload a photo for Work at Height tasks.";
            }


            final status = _savedAiData[id]?['overallStatus'];
            if (status == "DANGEROUS" || status == "N/A") {
              return "Photo analysis shows non-compliance. Please retake.";
            }
          }


          return null;
        })
        .firstWhere((msg) => msg != null, orElse: () => null);


    // Evaluates to true only if active components are selected and every single one is 100% completed
    final bool canSubmitReport =
        activeSubCategoryIds.isNotEmpty &&
        activeSubCategoryIds.every((id) {
          // 1. Checklist must always be completed
          bool isChecklistDone = _checklistCompletionStates[id] == true;


          // 2. Check WAH status
          bool isAbove3m = _savedAbove3m[id] ?? false;
          String ptw = _savedPtwNumbers[id] ?? "";


          if (isAbove3m) {
            // If it IS Work at Height:
            bool isPtwValid = ptw.trim().isNotEmpty;
            bool hasImage = _savedImages[id] != null;


            final status = _savedAiData[id]?['overallStatus'];
            bool isCompliant = status != "DANGEROUS" && status != "N/A";


            return isChecklistDone && isPtwValid && hasImage && isCompliant;
          } else {
            // If it is NOT Work at Height:
            return isChecklistDone;
          }
        });


    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          widget.task != null
              ? "Task SWPs: ${widget.task!['workorder_id']}"
              : "Activity Checklists",
          style: AppTypography.Bluesubheading,
        ),
        foregroundColor: AppColors.textMain,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppPadding.page),
                    itemCount: widget.selectedCategories.length,
                    itemBuilder: (context, index) {
                      final category = widget.selectedCategories[index];


                      final categoryTemplates = allTemplates
                          .where((t) => t['category'] == category)
                          .toList();


                      final currentSelectedId = selectedSubCategories[category];


                      return Card(
                        color: AppColors.primaryTint,
                        margin: const EdgeInsets.only(
                          bottom: AppPadding.medium,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          maintainState: true,
                          initiallyExpanded: true,
                          backgroundColor: AppColors.primaryTint.withAlpha(10),
                          title: Text(category, style: AppTypography.body),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.medium,
                                vertical: AppPadding.tight,
                              ),
                              child: DropdownButtonFormField<int>(
                                initialValue: currentSelectedId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Select Specific Activity Type",
                                  filled: true,
                                ),
                                items: categoryTemplates.map((t) {
                                  return DropdownMenuItem<int>(
                                    value: t['id'] as int,
                                    child: Text(
                                      t['title']?.toString().trim() ??
                                          'Untitled',
                                      style: AppTypography.body,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedSubCategories[category] = newValue;


                                    if (newValue != null) {
                                      _savedPtwNumbers.putIfAbsent(
                                        newValue,
                                        () => "",
                                      );
                                      _savedAbove3m.putIfAbsent(
                                        newValue,
                                        () => false,
                                      );
                                      _savedChecklists.putIfAbsent(
                                        newValue,
                                        () => [],
                                      );
                                      _savedDetails.putIfAbsent(
                                        newValue,
                                        () => "",
                                      );
                                      _checklistCompletionStates.putIfAbsent(
                                        newValue,
                                        () => false,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),


                            if (currentSelectedId != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppPadding.tight,
                                ),
                                child: TechnicianSwpSection(
                                  key: ValueKey(currentSelectedId),
                                  templateId: currentSelectedId,
                                  categoryName: category,
                                  initialPtw:
                                      _savedPtwNumbers[currentSelectedId] ?? "",
                                  initialAbove3m:
                                      _savedAbove3m[currentSelectedId] ?? false,
                                  initialCheckedItems:
                                      _savedChecklists[currentSelectedId] ?? [],
                                  initialImage: _savedImages[currentSelectedId],
                                  initialDetails:
                                      _savedDetails[currentSelectedId] ?? "",
                                  onPtwChanged: (isAbove3m, ptw) {
                                    setState(() {
                                      _savedPtwNumbers[currentSelectedId] = ptw;
                                      _savedAbove3m[currentSelectedId] =
                                          isAbove3m;
                                    });
                                  },
                                  onChecklistChanged: (checkedList) {
                                    setState(() {
                                      _savedChecklists[currentSelectedId] =
                                          checkedList;
                                    });
                                  },
                                  onImageChanged: (bytes) {
                                    setState(() {
                                      _savedImages[currentSelectedId] = bytes;
                                    });
                                  },
                                  onDetailsChanged: (textValue) {
                                    setState(() {
                                      _savedDetails[currentSelectedId] =
                                          textValue;
                                    });
                                  },
                                  onAllChecked: (isCleared) {
                                    setState(() {
                                      _checklistCompletionStates[currentSelectedId] =
                                          isCleared;
                                    });
                                  },
                                  onAiAnalyzed: (aiData) {
                                    _savedAiData[currentSelectedId] = aiData;
                                  },
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(AppPadding.medium),
                                child: Text(
                                  "No specific activities configured for this field.",
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.all(AppPadding.page),
                  child: Column(
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: const Divider(
                          height: AppPadding.large,
                          thickness: 1,
                          color: AppColors.borderGrey,
                        ),
                      ),
                      const SizedBox(height: AppPadding.tight),
                      if (errorMessage != null && !canSubmitReport)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            errorMessage,
                            style: AppTypography.faintbody.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: fieldWidth,
                        child: MenuButton(
                          label: "Continue",
                          onTap: canSubmitReport
                              ? _showAcknowledgementDialog
                              : () => {},
                          isPrimary: true,
                          icon: Icons.arrow_forward_rounded,
                          isDisabled: !canSubmitReport,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}


class ReportPreviewScreen extends StatelessWidget {
  final String reportContent;


  const ReportPreviewScreen({super.key, required this.reportContent});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Debug Report Preview"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          reportContent,
          style: const TextStyle(
            fontSize: 14,
            fontFamily:
                'Courier', // Monospace font helps spot formatting issues
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}



