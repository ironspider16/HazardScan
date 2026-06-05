import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import 'package:kkhazardscan/llm/llm_service.dart';
import 'package:kkhazardscan/llm/report_statistics_service.dart';
import 'package:kkhazardscan/yolo/yolo_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // Image File
  XFile? image;

  // Image Picker
  final picker = ImagePicker();

  // Pick Image Method
  Future<void> pickImage(ImageSource source) async {
    //Pick from camera or gallery
    final pickedFile = await picker.pickImage(source: source);

    // Update selected image
    if (pickedFile != null) {
      setState(() {
        image = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Taking"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 0, 0, 0),
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1000;

          final imageSize = isMobile
              ? constraints.maxWidth * 0.9
              : constraints.maxWidth * 0.6;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: imageSize,
                      width: imageSize,
                      child: image != null
                          ? Image.network(image!.path, fit: BoxFit.cover)
                          : const Center(child: Text("No image selected")),
                    ),

                    const SizedBox(height: 20),

                    isMobile
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      pickImage(ImageSource.camera),
                                  child: const Text("Take a Photo"),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: image == null
                                      ? null
                                      : () async {
                                          final imageBytes = await image!
                                              .readAsBytes();

                                          await YoloService().yoloDetect(
                                            context,
                                            imageBytes,
                                            image!.path,
                                          );
                                        },
                                  child: const Text("Analysis Hazard"),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final stats =
                                        await ReportStatisticsService.getRiskScores();
                                    final totalReports =
                                        stats['totalReports'] as int;
                                    final scores = Map<String, int>.from(
                                      stats['scores'],
                                    );

                                    final report =
                                        await LlmService.generateWeeklyReport(
                                          totalInspections: totalReports,
                                          missingPPE: scores['PPE'] ?? 0,
                                          buddySystem:
                                              scores['Buddy System'] ?? 0,
                                          ladderIssues:
                                              scores['Ladder Height'] ?? 0,
                                          areaHazards:
                                              scores['Area Hazards'] ?? 0,
                                          startDate: '2026-06-01',
                                          endDate: '2026-06-07',
                                        );

                                    print(report);
                                  },
                                  child: const Text("Generate Report"),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => pickImage(ImageSource.camera),
                                child: const Text("Take a Photo"),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: image == null
                                    ? null
                                    : () async {
                                        final imageBytes = await image!
                                            .readAsBytes();

                                        await YoloService().yoloDetect(
                                          context,
                                          imageBytes,
                                          image!.path,
                                        );
                                      },
                                child: const Text("Analysis Hazard"),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  final scores =
                                      await ReportStatisticsService.getRiskScores();

                                  final report =
                                      await LlmService.generateWeeklyReport(
                                        totalInspections: scores.values.reduce(
                                          (a, b) => a + b,
                                        ),
                                        missingPPE: scores['PPE'] ?? 0,
                                        buddySystem:
                                            scores['Buddy System'] ?? 0,
                                        ladderIssues:
                                            scores['Ladder Height'] ?? 0,
                                        areaHazards:
                                            scores['Area Hazards'] ?? 0,
                                        startDate: '2026-06-01',
                                        endDate: '2026-06-07',
                                      );

                                  print(report);
                                },
                                child: const Text("Generate Report"),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
