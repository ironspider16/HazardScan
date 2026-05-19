import 'package:flutter/material.dart';
import 'dart:typed_data';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final Uint8List imageBytes;
  final String aiRawResponse;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.imageBytes,
    required this.aiRawResponse,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  
  String _getOverallStatus() {
    try {
      final lines = widget.aiRawResponse.split('\n');
      final detectionLine = lines.firstWhere(
        (line) => line.toUpperCase().contains('DETECTION:'),
        orElse: () => 'DETECTION: N/A',
      );
      return detectionLine.split(':').last.replaceAll('[', '').replaceAll(']', '').trim().toUpperCase();
    } catch (e) {
      return "N/A";
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains("DANGEROUS")) return Colors.redAccent;
    if (status.contains("PARTIALLY COMPLIANT")) return Colors.orangeAccent;
    if (status.contains("COMPLIANT")) return Colors.blueAccent;
    if (status.contains("SAFE")) return Colors.greenAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final overallStatus = _getOverallStatus();
    final themeColor = _getStatusColor(overallStatus);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SWP Safety Audit Log'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Top Section: The Photo Frame
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 2. Middle Banner: Overall Status Breakdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              border: Border(
                top: BorderSide(color: themeColor.withValues(alpha: 0.4), width: 1),
                bottom: BorderSide(color: themeColor.withValues(alpha: 0.4), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "AUDIT ASSESSMENT:",
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: themeColor, width: 1),
                  ),
                  child: Text(
                    overallStatus,
                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Section: Detailed Category Markdown Layout
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETAILED COMPLIANCE ANALYSIS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          widget.aiRawResponse.replaceFirst(RegExp(r'DETECTION:.*?\n'), '').trim(),
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 14,
                            fontFamily: 'monospace',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}