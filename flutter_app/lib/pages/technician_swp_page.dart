import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkhazardscan/config/app_users.dart';
import 'package:kkhazardscan/pages/main_menu.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kkhazardscan/pages/edit_report_data_screen.dart';
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

  List<String> _fetchedDesignations = [];
  List<String> _fetchedLocations = [];
  List<String> _fetchedDepartments = [];

  final Map<int, String> _savedPtwNumbers = {};
  final Map<int, bool> _savedAbove3m = {};
  final Map<int, List<String>> _savedChecklists = {};
  final Map<int, bool> _checklistCompletionStates = {};
  final List<Uint8List> _globalImageBytes =
      []; // Stores raw bytes of all captured images for analysis and reporting
  Uint8List? _globalPdfBytes;
  Map<String, dynamic>? _globalAiData;
  bool? _isSpreaderUnlocked = false;
  final TextEditingController _globalDetailsCtrl = TextEditingController();
  bool _isAnalyzing = false;

  Map<String, dynamic>? _lastAiCallMetrics;

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
    _fetchDropdownOptions();
  }

  @override
  void dispose() {
    _globalDetailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownOptions() async {
    try {
      // Assumes tables named 'designations', 'locations', and 'departments' exist
      // with a text column called 'name'
      final designationResponse = await supabase
          .from('designations')
          .select('designation')
          .order('designation');
      final locationResponse = await supabase
          .from('locations')
          .select('location')
          .order('location');
      final departmentResponse = await supabase
          .from('departments')
          .select('department')
          .order('department');

      setState(() {
        _fetchedDesignations = List<String>.from(
          (designationResponse as List).map(
            (item) => item['designation'].toString(),
          ),
        );
        _fetchedLocations = List<String>.from(
          (locationResponse as List).map((item) => item['location'].toString()),
        );
        _fetchedDepartments = List<String>.from(
          (departmentResponse as List).map(
            (item) => item['department'].toString(),
          ),
        );
      });
    } catch (e) {
      debugPrint("Error fetching dropdown options from Supabase: $e");
    }
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
    Future<void> _openEditReportScreen() async {
    if (_globalAiData == null) return;

    final updatedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReportDataScreen(initialAiData: _globalAiData!),
      ),
    );

    if (!mounted) return;

    if (updatedData != null) {
      setState(() {
        _globalAiData = updatedData;
        _globalPdfBytes = null; // Invalidate any cached PDF so it regenerates with new data
      });
    }
  }

  Future<Uint8List> _prepareEmailImage(Uint8List orginalBytes) async {
    if (kIsWeb) return orginalBytes;

    final compressed = await FlutterImageCompress.compressWithList(
      orginalBytes,
      quality: 60,
      minWidth: 500,
      minHeight: 500,
    );
    return compressed;
  }

  // --- CAMERA: CAPTURE AND APPEND MULTIPLE PHOTOS ---
  Future<void> _pickGlobalImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        // Appends the new photo bytes to the list array instead of overwriting it
        _globalImageBytes.add(bytes);

        // Reset old AI data states so user is forced to re-analyze the new batch
        _globalAiData = null;
      });
    }
  }

Future<void> _analyzeGlobalImage() async {
  if (_globalImageBytes.isEmpty) return; // Guard against no images before analysis

  setState(() => _isAnalyzing = true);
  final stopwatch = Stopwatch()..start(); // Start timing the analysis process
  dynamic decodedData;

  try {
    // 1. Execute Local Object Detection
    final detections = await _yoloService.runYoloDetect(
      imageBytes: _globalImageBytes.first, // Pass raw bytes to YOLO service
      isMounted: () => mounted,
      context: context,
    );

    if (!mounted) return;

    bool status = false;
    if (detections.isNotEmpty) {
      for (var detection in detections) {
        if (detection['label'] == 'spreader_unlocked') {
          status = true;
          break;
        }
      }
    }

    setState(() {
      _isSpreaderUnlocked = status;
    });

    // 2. Compress Images for Network Payload Optimization
    final List<Uint8List> compressedImages = await Future.wait(
      _globalImageBytes.map((bytes) => _prepareEmailImage(bytes)),
    );

    // 3. Dispatch Multi-Angle Payload to Edge Function Gateway
    final analysisResult = await GeminiService.detectHazards(
      compressedImages,
      _globalDetailsCtrl.text,
    );

    stopwatch.stop(); // Halt stopwatch upon response retrieval
    final double latencySeconds = stopwatch.elapsedMilliseconds / 1000.0;

    if (!mounted) return;

    // 4. Save Network Telemetry & Routing States
    setState(() {
      _lastAiCallMetrics = {
        'timestamp': DateTime.now().toString().split('.').first,
        'success': !analysisResult.isError,
        'keySlot': analysisResult.keySlot ?? -1,
        'modelUsed': analysisResult.modelUsed ?? 'none',
        'latency': '${latencySeconds.toStringAsFixed(2)}s',
        'errorType': analysisResult.errorType ?? 'NONE',
        'errorDetail': analysisResult.errorDetail ?? 'NONE',
        'systemNotice': analysisResult.systemNotice ?? 'NONE',
      };
    });

    if (_lastAiCallMetrics != null) {
  supabase.from('ai_telemetry_logs').insert({
    'timestamp':    _lastAiCallMetrics!['timestamp'],
    'success':      _lastAiCallMetrics!['success'],
    'key_slot':     _lastAiCallMetrics!['keySlot'],
    'model_used':   _lastAiCallMetrics!['modelUsed'],
    'latency':    _lastAiCallMetrics!['latency'],
    'error_type':   _lastAiCallMetrics!['errorType'],
    'error_detail': _lastAiCallMetrics!['errorDetail'],
    'image_size_kb': (_globalImageBytes.isNotEmpty ? _globalImageBytes.first.lengthInBytes / 1024 : 0).toStringAsFixed(2),
    'image_count':  _globalImageBytes.length,
  }).then((_) {
    debugPrint("[TELEMETRY] Log written successfully.");
  }).catchError((e) {
    debugPrint("[TELEMETRY] Failed to write log: $e");
  });
}


    // Routing telemetry log (visible in your debug console)
    debugPrint(
      "[ROUTING] Key Slot: ${analysisResult.keySlot} | "
      "Model: ${analysisResult.modelUsed} | "
      "Error: ${analysisResult.errorType ?? 'none'}",
    );

    // 5. Evaluate Edge Function Level System Faults
    if (analysisResult.isError) {
      setState(() {
        _isAnalyzing = false;
        _globalAiData = null;
      });

      final errorType = analysisResult.errorType ?? "";

      if (errorType == "EXHAUSTION_ERROR") {
        _showErrorDialog(
          "API Quota Warning",
          "All API keys and fallback models are currently exhausted. You are likely near quota limits. Please wait a moment and try again.",
        );
      } else if (errorType == "SDK_ERROR") {
        _showErrorDialog(
          "Analysis Error — Key Slot ${analysisResult.keySlot}, Model: ${analysisResult.modelUsed}",
          analysisResult.errorDetail ?? "The analysis engine returned an unexpected error.",
        );
      } else if (errorType == "SETUP_ERROR") {
        _showErrorDialog(
          "Configuration Error",
          "No API keys are configured on the server. Contact your administrator.",
        );
      } else if (errorType == "CONNECTION_ERROR") {
        _showErrorDialog(
          "Connection Failed",
          analysisResult.errorDetail ?? "Could not reach the analysis server. Check your connection.",
        );
      } else {
        _showErrorDialog(
          analysisResult.errorTitle ?? "Analysis Failed",
          analysisResult.errorDetail ?? "An unknown error occurred.",
        );
      }
      return;
    }
      
    // 6. Handle Soft Notices (E.g., Backup model was deployed instead of primary)
    if (analysisResult.systemNotice != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(analysisResult.systemNotice!),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    }

    // 7. Parse Structural Payload JSON Schema Data
    try {
      decodedData = jsonDecode(analysisResult.jsonPayload);
    } catch (e) {
      _showErrorDialog("Parse Error", "The server returned an unreadable response.");
      setState(() => _isAnalyzing = false);
      return;
    }

    setState(() {
      _globalAiData = decodedData;
      _isAnalyzing = false;
    });

  } catch (e) {
    if (stopwatch.isRunning) stopwatch.stop();
    if (!mounted) return;

    final double latencySeconds = stopwatch.elapsedMilliseconds / 1000.0;
    final String errorStr = e.toString();

    String determinedErrorType = "UNKNOWN_ERROR";
    String systemMessage = "Could not reach the analysis server. Check your connection.";
    
    // Explicitly intercept hard platform resource cuts (546 Worker limits)
    if (errorStr.contains("546") || errorStr.contains("WORKER_RESOURCE_LIMIT")) {
      determinedErrorType = "WORKER_RESOURCE_LIMIT (546)";
      systemMessage = "Edge function exceeded resource limits. Please try again later.";
    }

    setState(() {
      _isAnalyzing = false;
      _lastAiCallMetrics = {
        'timestamp': DateTime.now().toString().split('.').first,
        'success': false,
        'keySlot': -1,
        'modelUsed': 'none',
        'latency': '${latencySeconds.toStringAsFixed(2)}s',
        'errorType': determinedErrorType,
        'errorDetail': errorStr,
        'systemNotice': systemMessage,
      };
    });

if (_lastAiCallMetrics != null) {
  supabase.from('ai_telemetry_logs').insert({
    'timestamp':    _lastAiCallMetrics!['timestamp'],
    'success':      _lastAiCallMetrics!['success'],
    'key_slot':     _lastAiCallMetrics!['keySlot'],
    'model_used':   _lastAiCallMetrics!['modelUsed'],
    'latency':    _lastAiCallMetrics!['latency'],
    'error_type':   _lastAiCallMetrics!['errorType'],
    'error_detail': _lastAiCallMetrics!['errorDetail'],
    'image_count':  _globalImageBytes.length,
    'image_size_kb': (_globalImageBytes.isNotEmpty ? _globalImageBytes.first.lengthInBytes / 1024 : 0).toStringAsFixed(2),
  }).then((_) {
    debugPrint("[TELEMETRY] Log written successfully.");
  }).catchError((e) {
    debugPrint("[TELEMETRY] Failed to write log: $e");
  });
}

    _showErrorDialog("Network / Server Error", "$systemMessage\n\nDetails: $e");
  }
}


  void _showImagePreviewDialog(Uint8List imageBytes) {
    if (_globalImageBytes.isEmpty)
      return; // Guard against empty list before trying to access .last
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
                // .last to show most recently added image
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppPadding.tight,
                vertical: AppPadding.medium,
              ),
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
                      width: 500,
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
                                suffixIcon: _fetchedDesignations.isNotEmpty
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.black,
                                        ),
                                        onSelected: (String value) {
                                          desigCtrl.text = value;
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return _fetchedDesignations.map((
                                            String option,
                                          ) {
                                            return PopupMenuItem<String>(
                                              value: option,
                                              child: Text(
                                                option,
                                                style: AppTypography.body,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppPadding.tight),
                              AppTextfield(
                                label: "Location",
                                hint: "Ward-2B",
                                controller: locationCtrl,
                                suffixIcon: _fetchedLocations.isNotEmpty
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.black,
                                        ),
                                        onSelected: (String value) {
                                          locationCtrl.text = value;
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return _fetchedLocations.map((
                                            String option,
                                          ) {
                                            return PopupMenuItem<String>(
                                              value: option,
                                              child: Text(
                                                option,
                                                style: AppTypography.body,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppPadding.tight),
                              AppTextfield(
                                label: "Department",
                                controller: deptCtrl,
                                hint: "e.g. Facilities Management",
                                suffixIcon: _fetchedDepartments.isNotEmpty
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.black,
                                        ),
                                        onSelected: (String value) {
                                          deptCtrl.text = value;
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return _fetchedDepartments.map((
                                            String option,
                                          ) {
                                            return PopupMenuItem<String>(
                                              value: option,
                                              child: Text(
                                                option,
                                                style: AppTypography.body,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      )
                                    : null,
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
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
                                            //call report compiler with global state
                                            location: locationCtrl.text,
                                            supervisor: nameCtrl.text,
                                            employer: deptCtrl.text,
                                            manualNotes:
                                                _globalDetailsCtrl.text,
                                            initialAiData: _globalAiData ?? {},
                                            imagesBytes: _globalImageBytes,
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
                                        final url = html
                                            .Url.createObjectUrlFromBlob(blob);
                                        html.window.open(url, '_blank');
                                        html.Url.revokeObjectUrl(url);
                                      } else {
                                        // On native: use in-app PdfPreview screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => Scaffold(
                                              appBar: AppBar(
                                                title: const Text(
                                                  "Report Preview",
                                                ),
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
                              ],
                            ),
                            const SizedBox(height: AppPadding.tight),
                            Row(
                              children: [
                                Expanded(
                                  child: MenuButton(
                                    label: "Submit",
                                    isPrimary: true,
                                    isMini: true,
                                    icon: Icons.assignment_turned_in_rounded,
                                    onTap: () async {
                                      if (!(formKey.currentState?.validate() ??
                                          false))
                                        return;

                                      setDialogState(
                                        () => dialogSubmitting = true,
                                      );

                                      bool success = await _executeSubmitReport(
                                        name: nameCtrl.text.trim(),
                                        designation: desigCtrl.text.trim(),
                                        department: deptCtrl.text.trim(),
                                        location: locationCtrl.text.trim(),
                                      );

                                      if (success && mounted) {
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                            builder: (_) => MainMenu(
                                              user: anonymousTechnician,
                                            ),
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
        initialAiData:
            _globalAiData ??
            {}, // Pass current AI data even if PDF preview wasn't generated to ensure report has the latest analysis results
        imagesBytes:
            _globalImageBytes, // Pass current list of images to ensure report has all photos, even if PDF preview wasn't generated
      );

      final activeSubCategoryIds = selectedSubCategories.values
          .where((id) => id != null)
          .cast<int>()
          .toList();

      int? globalWahSafetyForeignKey;
      Uint8List? compressedImageBytes;

      if (_globalImageBytes.isNotEmpty) {
        // Ensure there's at least one image before trying to compress
        compressedImageBytes = await _prepareEmailImage(
          _globalImageBytes.first,
        );
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
              'spreaderUnlocked': _isSpreaderUnlocked ?? false,
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
          'WAH_safetyVariables_FK': category == "Work At Height"
              ? globalWahSafetyForeignKey
              : null,
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
          imageBytes:
              compressedImageBytes ??
              (_globalImageBytes.isNotEmpty
                  ? _globalImageBytes.first
                  : null), // Pass compressed image bytes if available, otherwise fallback to first raw image bytes if any exist
          pdfBytes: finalPdfBytes,
        );
      }

      await supabase.from('safety_reports').insert(recordsToInsert);
      return true;
    } catch (e) {
      debugPrint("Error executing report: $e");
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
        debugPrint('Failed to send email via function: ${response.data}');
      }
    } catch (e) {
      debugPrint('Error calling edge function: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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

            if (_globalImageBytes.isEmpty) {
              return "Please upload a site photo for Work at Height tasks.";
            }

            final status = _globalAiData?['overallStatus'];
            if (status == "N/A" || status == null) {
              return "Photo analysis required or shows N/A. Please analyze/retake.";
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
            bool hasImage = _globalImageBytes.isNotEmpty;
            final status = _globalAiData?['overallStatus'];
            // bool isCompliant =
            //     status != null && status != "DANGEROUS" && status != "N/A";
            bool hasValidStatus = status != null && status != "N/A";

            return isChecklistDone && isPtwValid && hasImage && hasValidStatus;
          } else {
            return isChecklistDone;
          }
        });

    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: UniversalAppBar(title: "Activity Checklists"),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppPadding.tight,
                        AppPadding.page,
                        AppPadding.tight,
                        AppPadding.tight,
                      ),
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
                            backgroundColor: AppColors.primaryTint.withAlpha(
                              10,
                            ),
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
                                      selectedSubCategories[category] =
                                          newValue;
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
                                        _savedPtwNumbers[currentSelectedId] ??
                                        "",
                                    initialAbove3m:
                                        _savedAbove3m[currentSelectedId] ??
                                        false,
                                    initialCheckedItems:
                                        _savedChecklists[currentSelectedId] ??
                                        [],
                                    onPtwChanged: (isAbove3m, ptw) {
                                      setState(() {
                                        _savedPtwNumbers[currentSelectedId] =
                                            ptw;
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
                        // horizontal: AppPadding.page,
                        horizontal: AppPadding.tight,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: AppColors.backgroundWhite,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                          side: BorderSide(
                            color: AppColors.borderGrey,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppPadding.medium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextfield(
                                label: "User Context / Details Box",
                                controller: _globalDetailsCtrl,
                                Maxlines: 4,
                                hint:
                                    "Enter Details to be submitted and to assist AI context...",
                              ),
                              const SizedBox(height: AppPadding.medium),
                              Row(
                                children: [
                                  Expanded(
                                    child: MenuButton(
                                      label: "Add Image",
                                      onTap: _pickGlobalImage,
                                      isPrimary: true,
                                      height: 32,
                                      icon: Icons.camera_alt,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: MenuButton(
                                      height: 32,
                                      label: _isAnalyzing
                                          ? "Analyzing..."
                                          : "Analyze",
                                      isPrimary: true,
                                      isDisabled:
                                          _globalImageBytes.isEmpty ||
                                          _isAnalyzing,
                                      onTap: _analyzeGlobalImage,
                                      leading: _isAnalyzing
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : null,
                                      icon: _isAnalyzing
                                          ? null
                                          : Icons.analytics,
                                    ),
                                  ),
                                ],
                              ),
                              // Horizontal thumbnail preview engine
                              if (_globalImageBytes.isNotEmpty) ...[
                                const SizedBox(height: AppPadding.medium),
                                Text(
                                  "Captured Workspace Images (${_globalImageBytes.length})",
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: AppPadding.tight),
                                SizedBox(
                                  height: 86,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _globalImageBytes.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10.0,
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showImagePreviewDialog(_globalImageBytes[index]),
                                              child: Container(
                                                width: 86,
                                                height: 86,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppDimensions
                                                            .radiusMedium,
                                                      ),
                                                  border: Border.all(
                                                    color: AppColors.borderGrey
                                                        .withAlpha(80),
                                                    width: 1,
                                                  ),
                                                  image: DecorationImage(
                                                    image: MemoryImage(
                                                      _globalImageBytes[index],
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Delete badge handler
                                            Positioned(
                                              top: -5,
                                              right: -5,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _globalImageBytes.removeAt(
                                                      index,
                                                    );
                                                    if (_globalImageBytes
                                                        .isEmpty) {
                                                      _globalAiData = null;
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    3,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.redAccent,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppPadding.medium),
                              SafetyStatusWidget(
                                aiData: _globalAiData,
                                isSpreaderUnlocked: _isSpreaderUnlocked,
                              ),

                              if (_globalAiData != null)
                                TextButton.icon(
                                  onPressed: _openEditReportScreen,
                                  icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                                  label: const Text("Manually Edit Report", style: TextStyle(color: Colors.blueAccent)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Final Continue Button Block
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.tight,
                        vertical: AppPadding.tight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            width: double.infinity,
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
            // color: Colors.black87
          ),
        ),
      ),
    );
  }
}
