import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/swp.dart';
import 'swp_ack_page.dart';

class SwpChecklistPage extends StatefulWidget {
  final SwpTemplate template;

  const SwpChecklistPage({super.key, required this.template});

  @override
  State<SwpChecklistPage> createState() => _SwpChecklistPageState();
}

class _SwpChecklistPageState extends State<SwpChecklistPage> {
  late List<bool> _checks;

  // WAH PTW rule: >3m requires PTW
  bool? _above3m; // only for WAH
  final _ptwCtrl = TextEditingController();

  final _notesCtrl = TextEditingController();
  final List<String> _attachments = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checks = List<bool>.filled(widget.template.checklist.length, false);
    _above3m = false;
  }

  @override
  void dispose() {
    _ptwCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isWah => widget.template.category == SwpCategory.wah;
  bool get _ptwRequired => _isWah && (_above3m == true);

  bool get _canProceed {
    final allChecked = _checks.every((c) => c);
    final ptwOk = !_ptwRequired || _ptwCtrl.text.trim().isNotEmpty;
    return allChecked && ptwOk;
  }

  Future<void> _addImage() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x == null) return;
    setState(() => _attachments.add(x.path));
  }

  Future<void> _addVideo() async {
    final x = await _picker.pickVideo(source: ImageSource.camera);
    if (x == null) return;
    setState(() => _attachments.add(x.path));
  }

  Future<void> _goNext() async {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required items.')),
      );
      return;
    }

    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SwpAckPage(
          template: widget.template,
          checks: _checks,
          workingAbove3m: _isWah ? (_above3m ?? false) : null,
          ptwNumber: _isWah ? _ptwCtrl.text.trim() : null,
          attachments: List<String>.from(_attachments),
          notes: _notesCtrl.text.trim(),
        ),
      ),
    );

    // If acknowledgement page submitted, close this checklist page too
    if (submitted == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'SWP Checklist',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.title,
            style: const TextStyle(
              color: Color.fromARGB(255, 64, 64, 64),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // ---------------- WAH PTW SECTION ----------------
          if (_isWah) ...[
            const Text(
              'Work at height above 3 metres?',
              style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _pill(
                    label: 'No',
                    selected: _above3m == false,
                    onTap: () => setState(() => _above3m = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pill(
                    label: 'Yes',
                    selected: _above3m == true,
                    onTap: () => setState(() => _above3m = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_ptwRequired) ...[
              const Text(
                'Permit To Work (PTW) Number (required):',
                style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ptwCtrl,
                style: const TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
                decoration: InputDecoration(
                  hintText: 'Enter PTW number',
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
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
              const SizedBox(height: 12),
            ],
          ],

          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          const Text(
            'Checklist (tick all to continue):',
            style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
          ),
          const SizedBox(height: 8),

          ...List.generate(t.checklist.length, (i) {
            return CheckboxListTile(
              value: _checks[i],
              onChanged: (v) => setState(() => _checks[i] = v ?? false),
              activeColor: const Color(0xFF2563EB),
              checkColor: const Color.fromARGB(255, 255, 255, 255),
              title: Text(
                t.checklist[i],
                style: const TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),

          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),

          // ---------------- ATTACHMENTS ----------------
          const Text(
            'Attachments (image/video):',
            style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Add Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Add Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Attached: ${_attachments.length} file(s)',
            style: const TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
          ),

          const SizedBox(height: 12),

          // ---------------- NOTES ----------------
          const Text(
            'Notes (optional):',
            style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add notes about hazards / observations...',
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 130, 130, 130),
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

          const SizedBox(height: 16),

          // ---------------- NEXT BUTTON ----------------
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canProceed ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color.fromARGB(90, 37, 100, 235), // when not all checklist is ticked
                disabledForegroundColor: const Color.fromARGB(90, 255, 255, 255)
              ),
              child: Text(
                _canProceed
                    ? 'Next'
                    // next button text to show how many more to tick
                    : 'Next (tick ${_checks.where((c) => !c).length} more to continue)', 
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : const Color.fromARGB(255, 157, 157, 157),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
