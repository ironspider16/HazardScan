import 'package:flutter/material.dart';
import 'dart:convert';
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
  Map<String, dynamic>? _parsedJson;
  String _overallStatus = "N/A";
  bool _hasParsingError = false;
  String _parsingExceptionMessage = "";

  @override
  void initState() {
    super.initState();
    _parseResponse();
  }

  void _parseResponse() {
    try {
      String cleanResponse = widget.aiRawResponse.trim();

      if (cleanResponse.isEmpty) {
        setState(() {
          _hasParsingError = true;
          _parsingExceptionMessage = "aiRawResponse is completely empty. Nothing was received from the edge function.";
          _overallStatus = "ERROR";
        });
        return;
      }

      // Strip markdown code wraps if present
      if (cleanResponse.startsWith('```')) {
        if (cleanResponse.startsWith('```json')) {
          cleanResponse = cleanResponse.substring(7);
        } else {
          cleanResponse = cleanResponse.substring(3);
        }
        if (cleanResponse.endsWith('```')) {
          cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
        }
        cleanResponse = cleanResponse.trim();
      }

      // Fix potential nested string escape artifacts
      if (cleanResponse.startsWith('"') &&
          cleanResponse.endsWith('"') &&
          cleanResponse.contains('\\"')) {
        cleanResponse = cleanResponse
            .substring(1, cleanResponse.length - 1)
            .replaceAll('\\"', '"')
            .replaceAll('\\\\', '\\');
      }

      final Map<String, dynamic> decoded = jsonDecode(cleanResponse);
      setState(() {
        _parsedJson = decoded;
        _overallStatus = (decoded['overallStatus'] ?? 'N/A')
            .toString()
            .toUpperCase();
        _hasParsingError = false;
      });
    } catch (e) {
      setState(() {
        _hasParsingError = true;
        _parsingExceptionMessage = e.toString();
        _overallStatus = "ERROR";
      });
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains("DANGEROUS") || s.contains("NON-COMPLIANT"))
      return Colors.redAccent;
    if (s.contains("PARTIALLY")) return Colors.orangeAccent;
    if (s.contains("COMPLIANT") || s.contains("SAFE"))
      return Colors.greenAccent;
    return Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getStatusColor(_overallStatus);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'SWP Safety Audit Log',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _hasParsingError
          ? SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.code_off_rounded,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          "JSON Parsing Failed",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // --- PARSE EXCEPTION ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "EXCEPTION:",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              _parsingExceptionMessage,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- RESPONSE LENGTH INDICATOR ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "RAW RESPONSE LENGTH:",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "${widget.aiRawResponse.length} chars",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- FIRST 500 CHARS ---
                      const Text(
                        "RAW PAYLOAD — FIRST 500 CHARS:",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: SelectableText(
                          widget.aiRawResponse.isEmpty
                              ? "[Empty string — nothing received]"
                              : widget.aiRawResponse.length > 500
                                  ? widget.aiRawResponse.substring(0, 500) + "\n\n... [truncated]"
                                  : widget.aiRawResponse,
                          style: const TextStyle(
                            color: Color(0xFF00FF66),
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- LAST 200 CHARS (catches truncation artifacts) ---
                      const Text(
                        "RAW PAYLOAD — LAST 200 CHARS:",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: SelectableText(
                          widget.aiRawResponse.length > 200
                              ? "..." + widget.aiRawResponse.substring(widget.aiRawResponse.length - 200)
                              : widget.aiRawResponse.isEmpty
                                  ? "[Empty]"
                                  : widget.aiRawResponse,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text("Go Back and Re-scan"),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(color: themeColor.withOpacity(0.3), width: 1),
                      bottom: BorderSide(color: themeColor.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "AUDIT ASSESSMENT:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: themeColor, width: 1.5),
                        ),
                        child: Text(
                          _overallStatus,
                          style: TextStyle(
                            color: themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                          'PARSED COMPLIANCE DICTIONARY VALUES',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _parsedJson == null
                              ? const Center(
                                  child: CircularProgressIndicator(color: Colors.blueAccent),
                                )
                              : SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Column(
                                      children: [
                                        _buildJsonCategoryCard("Ladders & Height", Icons.stairs_rounded, _parsedJson!['ladderHeight']),
                                        _buildJsonCategoryCard("PPE Setup", Icons.health_and_safety_rounded, _parsedJson!['ppe']),
                                        _buildJsonCategoryCard("Buddy System", Icons.people_alt_rounded, _parsedJson!['buddySystem']),
                                        _buildJsonCategoryCard("Area/Surface", Icons.warning_rounded, _parsedJson!['areaHazards']),
                                      ],
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

  Widget _buildJsonCategoryCard(
    String title,
    IconData iconData,
    Map<String, dynamic>? sectionData,
  ) {
    if (sectionData == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        ),
        child: Text(
          "Missing key '$title' in response payload.",
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      );
    }

    final String compliance = (sectionData['compliance'] ?? 'N/A').toString();
    final String description = (sectionData['description'] ?? 'N/A').toString();
    final String reasoning = (sectionData['reasoning'] ?? 'N/A').toString();
    final String advice = (sectionData['advice'] ?? 'N/A').toString();
    final Color statusColor = _getStatusColor(compliance);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(iconData, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  compliance.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildFieldRow("Observation", description),
          const SizedBox(height: 10),
          _buildFieldRow("Reasoning", reasoning),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: Colors.blueAccent, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Corrective Advice:",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}