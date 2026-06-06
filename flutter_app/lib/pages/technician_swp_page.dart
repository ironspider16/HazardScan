import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkhazardscan/config/app_users.dart';
import 'package:kkhazardscan/pages/main_menu.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design/style_constant.dart';
import '../widgets/technician_swp_Section.dart';
import '../widgets/Menu_button.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kkhazardscan/services/report_compiler.dart';
import 'package:kkhazardscan/services/gemini_service.dart';
import 'dart:ui';
import 'package:kkhazardscan/widgets/safety_status_widget.dart'; // adjust pat
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:kkhazardscan/yolo/yolo_service.dart';
import 'package:universal_html/html.dart' as html;

class TechnicianSWPPage extends StatefulWidget {
  final List<String> selectedCategories;
  final Map<String, dynamic>? task;

  const TechnicianSWPPage({
    super.key,
    required this.selectedCategories,
    this.task,
  });

  @override
  State<TechnicianSWPPage> createState() => _TechnicianSWPPageState();
}

class _TechnicianSWPPageState extends State<TechnicianSWPPage> {
  final supabase = Supabase.instance.client;
  final YoloService _yoloService = YoloService();

  List<Map<String, dynamic>> allTemplates = [];
  Map<String, int?> selectedSubCategories = {};
  bool isLoading = true;

  final Map<int, String> _savedPtwNumbers = {};
  final Map<int, bool> _savedAbove3m = {};
  final Map<int, List<String>> _savedChecklists = {};
  final Map<int, bool> _checklistCompletionStates = {};

  // --- NEW GLOBAL STATE VARIABLES ---
  Uint8List? _globalImageBytes;
  Uint8List? _globalPdfBytes;
  Map<String, dynamic>? _globalAiData;
  List<dynamic> _globalYoloDetections = [];
  bool? _isSpreaderUnlocked = false;
  final TextEditingController _globalDetailsCtrl = TextEditingController();
  bool _isAnalyzing = false;
  // ----------------------------------

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  @override
  void dispose() {
    _globalDetailsCtrl.dispose();
    super.dispose();
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

            _savedPtwNumbers[firstId] = "";
            _savedAbove3m[firstId] = false;
            _savedChecklists[firstId] = [];
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
    if (kIsWeb) return orginalBytes;

    final compressed = await FlutterImageCompress.compressWithList(
      orginalBytes,
      quality: 30,
      minWidth: 500,
      minHeight: 500,
    );
    return compressed;
  }

  Future<void> _pickGlobalImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _globalImageBytes = bytes;
        _globalAiData = null;
        _globalYoloDetections = [];
      });
    }
  }

  Future<void> _analyzeGlobalImage() async {
    dynamic decodedData;
    if (_globalImageBytes == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final detections = await _yoloService.runYoloDetect(
        imageBytes: _globalImageBytes!,
        isMounted: () => mounted,
        context: context,
      );

      if (!mounted) return;

      bool status = false;
      if (detections.isNotEmpty) {
        double confidence = detections[0]["confidence"];
        status = confidence > 0.55;
      }

      setState(() {
        _globalYoloDetections = detections;
        _isSpreaderUnlocked = status;
      });

      final String rawResponse = await GeminiService.detectHazards(
        _globalImageBytes!,
        _globalDetailsCtrl.text,
      );

      if (!mounted) return;

      final String sanitizedResponse = rawResponse
          .replaceAll(RegExp(r'^```json\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^```\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'```$'), '')
          .trim();

      try {
        decodedData = jsonDecode(sanitizedResponse);
      } catch (e) {
        // Handle the case where JSON is malformed
        _showErrorDialog(
          "Analysis Error",
          "The server returned an invalid response.",
        );
        setState(() => _isAnalyzing = false);
        return;
      }

      if (decodedData['overallStatus'] == 'N/A') {
        final diagnosticTitle =
            decodedData['ladderHeight']?['description'] ?? "Error";
        final diagnosticReason =
            decodedData['ladderHeight']?['reasoning'] ?? "";

        setState(() {
          _isAnalyzing = false;
          _globalAiData = null; 
        });

        if (diagnosticTitle.contains("Exhaustion") ||
            diagnosticReason.contains("quota")) {
          _showErrorDialog(
            "API Quota Warning",
            "API limit reached. If you are experiencing this, you are nearing your quota limit (approx. 75%+ utilization across rotating keys). Please wait a moment and try again.",
          );
        } else if (diagnosticReason.contains("503") ||
            diagnosticReason.contains("overloaded")) {
          _showErrorDialog(
            "Service Unavailable",
            "Gemini servers are temporarily overloaded or unavailable. Please try your analysis again in 30 seconds.",
          );
        } else {
          _showErrorDialog("Analysis Failed", diagnosticReason);
        }
        return;
      }
      // ------------------------------

      setState(() {
        _globalAiData = decodedData;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      _showErrorDialog(
        "Network Error",
        "Could not reach the analysis server. Check your connection.\n\nDetails: $e",
      );
    }
  }
  // --------------------------------

  void _showImagePreviewDialog() {
    if (_globalImageBytes == null) return;
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur background
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                // Allows pinching to zoom
                child: Image.memory(_globalImageBytes!, fit: BoxFit.contain),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiDetailsDialog() {
    if (_globalAiData == null) return;

    // Helper to format the sections
    Widget buildSection(String title, Map<String, dynamic>? data) {
      if (data == null || data.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              "Status: ${data['compliance'] ?? 'N/A'}",
              style: AppTypography.faintbody.copyWith(color: Colors.black87),
            ),
            Text(
              "Reason: ${data['reasoning'] ?? 'N/A'}",
              style: AppTypography.faintbody,
            ),
            Text(
              "Advice: ${data['advice'] ?? 'N/A'}",
              style: AppTypography.faintbody.copyWith(color: Colors.red[800]),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Safety Analysis Breakdown",
          style: AppTypography.Bluesubheading,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSection("Ladder & Heights", _globalAiData!['ladderHeight']),
              buildSection("PPE", _globalAiData!['ppe']),
              buildSection("Buddy System", _globalAiData!['buddySystem']),
              buildSection("Area Hazards", _globalAiData!['areaHazards']),
              buildSection(
                "Site Supervision",
                _globalAiData!['siteSupervision'],
              ),
              buildSection("Major Hazard Installations", _globalAiData!['mhi']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Understood"),
          ),
        ],
      ),
    );
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
      barrierDismissible: false,
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
                      width: 400,
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
                            Expanded(
                              flex: 2,
                              child: MenuButton(
                                label: "Cancel",
                                isMini: true,
                                onTap: () => Navigator.pop(dialogContext),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: MenuButton(
                                label: "Preview",
                                isPrimary: false,
                                isMini: true,
                                icon: Icons.remove_red_eye,
                                onTap: () async {
                                  final Uint8List pdfBytes =
                                      await LocalReportCompiler.generateWshReport(
                                        location: locationCtrl.text,
                                        supervisor: nameCtrl.text,
                                        employer: deptCtrl.text,
                                        manualNotes: _globalDetailsCtrl.text,
                                        initialAiData: _globalAiData ?? {},
                                        imageBytes: _globalImageBytes,
                                      );

                                  setState(() {
                                    _globalPdfBytes = pdfBytes;
                                  });

                                  if (!context.mounted) return;

                                  if (kIsWeb) {
                                    // On web: open PDF as blob URL in a new browser tab
                                    final blob = html.Blob([
                                      pdfBytes,
                                    ], 'application/pdf');
                                    final url =
                                        html.Url.createObjectUrlFromBlob(blob);
                                    html.window.open(url, '_blank');
                                    html.Url.revokeObjectUrl(url);
                                  } else {
                                    // On native: use in-app PdfPreview screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Scaffold(
                                          appBar: AppBar(
                                            title: const Text("Report Preview"),
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            elevation: 1,
                                          ),
                                          body: PdfPreview(
                                            build: (_) => pdfBytes,
                                            allowPrinting: false,
                                            allowSharing: true,
                                            canChangePageFormat: false,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "All safety checks successfully submitted!",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    final anonymousTechnician = AppUser(
                                      id: 0,
                                      email: "technician@example.com",
                                      password: '',
                                      role: UserRole.user,
                                    );

                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MainMenu(user: anonymousTechnician),
                                      ),
                                      (route) => false,
                                    );
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

      Uint8List? finalPdfBytes = _globalPdfBytes;
      finalPdfBytes ??= await LocalReportCompiler.generateWshReport(
        location: location,
        supervisor: name,
        employer: department,
        manualNotes: _globalDetailsCtrl.text,
        initialAiData: _globalAiData ?? {},
        imageBytes: _globalImageBytes,
      );

      final activeSubCategoryIds = selectedSubCategories.values
          .where((id) => id != null)
          .cast<int>()
          .toList();

      int? globalWahSafetyForeignKey;
      Uint8List? compressedImageBytes;

      if (_globalImageBytes != null) {
        compressedImageBytes = await _prepareEmailImage(_globalImageBytes!);
      }

      if (_globalAiData != null) {
        final insertedWahData = await supabase
            .from('WAH_safetyVariables')
            .insert({
              'Overall Status': _globalAiData!['overallStatus'] ?? 'N/A',
              'ladderheight': _globalAiData!['ladderHeight'] ?? {},
              'ppe': _globalAiData!['ppe'] ?? {},
              'buddySystem': _globalAiData!['buddySystem'] ?? {},
              'areaHazards': _globalAiData!['areaHazards'] ?? {},
              'mhi': _globalAiData!['mhi'] ?? {},
            })
            .select('id')
            .single();

        globalWahSafetyForeignKey = insertedWahData['id'];
      }

      List<Map<String, dynamic>> recordsToInsert = [];
      for (int templateId in activeSubCategoryIds) {
        final template = allTemplates.firstWhere((t) => t['id'] == templateId);
        final String title = template['title'] ?? 'Unknown';
        final String category = template['category'] ?? 'Unknown';

        String ptwNumber = _savedPtwNumbers[templateId] ?? "";

        recordsToInsert.add({
          'swp_template_id': templateId,
          'wah_permit_numbers': ptwNumber.isNotEmpty ? ptwNumber : null,
          'Details': _globalDetailsCtrl.text.isNotEmpty
              ? _globalDetailsCtrl.text
              : null,
          'technician_name': name,
          'designation': designation,
          'department': department,
          'location': location,
          'WAH_safetyVariables_FK': globalWahSafetyForeignKey,
        });

        // Trigger edge function email process
        await sendBrevoEmail(
          technicianName: name,
          details: _globalDetailsCtrl.text,
          title: title,
          category: category,
          ptwNumber: ptwNumber,
          designation: designation,
          department: department,
          location: location,
          imageBytes: compressedImageBytes ?? _globalImageBytes,
          pdfBytes: finalPdfBytes,
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
    Uint8List? pdfBytes,
  }) async {
    try {
      String? base64Image;
      if (imageBytes != null) {
        base64Image = base64Encode(imageBytes);
      }

      String? base64Pdf;
      if (pdfBytes != null) {
        base64Pdf = base64Encode(pdfBytes);
      }

      // Route to Supabase Edge Function to protect API credentials
      final response = await supabase.functions.invoke(
        'email-sending',
        body: {
          "technician_name": technicianName,
          "details": details,
          "title": title,
          "category": category,
          "ptw_number": ptwNumber,
          "designation": designation,
          "department": department,
          "location": location,
          "image": base64Image,
          "pdf": base64Pdf,
        },
      );

      if (response.status != 200 && response.status != 201) {
        print('Failed to send email via function: ${response.data}');
      }
    } catch (e) {
      print('Error calling edge function: $e');
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

    // Re-mapped validation to check the global state instead of local loops
    final String? errorMessage = activeSubCategoryIds
        .map((id) {
          if (_checklistCompletionStates[id] != true) {
            return "Please complete all checklist items.";
          }

          bool isAbove3m = _savedAbove3m[id] ?? false;
          if (isAbove3m) {
            String ptw = _savedPtwNumbers[id] ?? "";
            if (ptw.trim().isEmpty)
              return "Permit To Work (PTW) number is required.";

            if (_globalImageBytes == null) {
              return "Please upload a site photo for Work at Height tasks.";
            }

            final status = _globalAiData?['overallStatus'];
            if (status == "DANGEROUS" || status == "N/A" || status == null) {
              return "Photo analysis required or shows non-compliance. Please analyze/retake.";
            }
          }
          return null;
        })
        .firstWhere((msg) => msg != null, orElse: () => null);

    final bool canSubmitReport =
        activeSubCategoryIds.isNotEmpty &&
        activeSubCategoryIds.every((id) {
          bool isChecklistDone = _checklistCompletionStates[id] == true;
          bool isAbove3m = _savedAbove3m[id] ?? false;
          String ptw = _savedPtwNumbers[id] ?? "";

          if (isAbove3m) {
            bool isPtwValid = ptw.trim().isNotEmpty;
            bool hasImage = _globalImageBytes != null;
            final status = _globalAiData?['overallStatus'];
            bool isCompliant =
                status != null && status != "DANGEROUS" && status != "N/A";

            return isChecklistDone && isPtwValid && hasImage && isCompliant;
          } else {
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
          : SingleChildScrollView(
              // Makes the whole page scroll together
              child: Column(
                children: [
                  // 1. Checklist Iteration Area
                  ListView.builder(
                    shrinkWrap: true, // Lets the list size itself
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevents inner scrolling conflicts
                    padding: const EdgeInsets.all(AppPadding.page),
                    itemCount: widget.selectedCategories.length,
                    itemBuilder: (context, index) {
                      final category = widget.selectedCategories[index];

                      // FIX: Derive local variables from category so they are defined in this scope
                      final int? currentSelectedId =
                          selectedSubCategories[category];
                      final List<Map<String, dynamic>> categoryTemplates =
                          allTemplates
                              .where((t) => t['category'] == category)
                              .toList();

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
                                value: currentSelectedId,
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
                                  onAllChecked: (isCleared) {
                                    setState(() {
                                      _checklistCompletionStates[currentSelectedId] =
                                          isCleared;
                                    });
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

                  // Global Image Analysis Block
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.page,
                    ),
                    child: Card(
                      color: AppColors.backgroundWhite,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                        side: BorderSide(
                          color: AppColors.borderGrey.withAlpha(50),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Site Condition Validation",
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppPadding.tight),
                            AppTextfield(
                              label: "Site Context / Notes",
                              controller: _globalDetailsCtrl,
                              hint:
                                  "Enter site conditions to assist AI context...",
                            ),
                            const SizedBox(height: AppPadding.medium),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text(
                                      "Select Image",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    onPressed: _pickGlobalImage,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: _isAnalyzing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.analytics),
                                    label: Text(
                                      _isAnalyzing
                                          ? "Analyzing..."
                                          : "Analyze Image",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed:
                                        (_globalImageBytes != null &&
                                            !_isAnalyzing)
                                        ? _analyzeGlobalImage
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            if (_globalImageBytes != null) ...[
                              const SizedBox(height: AppPadding.medium),
                              InkWell(
                                onTap:
                                    _showImagePreviewDialog, // Opens blurred popup
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppPadding.tight,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.borderGrey.withAlpha(
                                        100,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSmall,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "View Captured Image",
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppPadding.medium),
                            SafetyStatusWidget(aiData: _globalAiData, isSpreaderUnlocked : _isSpreaderUnlocked),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Final Continue Button Block
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
                              textAlign: TextAlign.center,
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
            fontFamily: 'Courier',
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
