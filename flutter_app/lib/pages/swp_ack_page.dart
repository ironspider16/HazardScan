import 'package:flutter/material.dart';
import '../models/swp.dart';
import '../services/swp_record_service.dart';

class SwpAckPage extends StatefulWidget {
  final SwpTemplate template;
  final List<bool> checks;
  final bool? workingAbove3m;
  final String? ptwNumber;
  final List<String> attachments;
  final String notes;

  const SwpAckPage({
    super.key,
    required this.template,
    required this.checks,
    required this.attachments,
    required this.notes,
    this.workingAbove3m,
    this.ptwNumber,
  });

  @override
  State<SwpAckPage> createState() => _SwpAckPageState();
}

class _SwpAckPageState extends State<SwpAckPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _desigCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  bool _submitting = false;

  static const String ackMessage =
      "The Safe Work Procedures have been communicated and are understood by all "
      "relevant personnel. Inspections have been conducted to verify that work is "
      "carried out in accordance with the established procedures, ensuring a safe "
      "and compliant working environment.";

  @override
  void dispose() {
    _nameCtrl.dispose();
    _desigCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    final record = SwpRecord(
      templateId: widget.template.id,
      templateTitle: widget.template.title,
      category: widget.template.category,
      createdAt: DateTime.now(),

      // ✅ acknowledgement fields
      name: _nameCtrl.text.trim(),
      designation: _desigCtrl.text.trim(),
      department: _deptCtrl.text.trim(),

      // ✅ from checklist
      workingAbove3m: widget.workingAbove3m,
      ptwNumber: widget.ptwNumber,
      checks: widget.checks,
      attachments: widget.attachments,
      notes: widget.notes,
    );

    await SwpRecordService.instance.appendRecord(record);

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SWP submitted ✅")),
    );

    // pop back to wherever you want; simplest: go back 2 pages
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Acknowledgement",
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _submitting
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      widget.template.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _field(
                      label: "Name",
                      controller: _nameCtrl,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    _field(
                      label: "Designation",
                      controller: _desigCtrl,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    _field(
                      label: "Department",
                      controller: _deptCtrl,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Acknowledgement",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      ackMessage,
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("SUBMIT",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1F2937),
            hintText: "Enter $label",
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }
}
