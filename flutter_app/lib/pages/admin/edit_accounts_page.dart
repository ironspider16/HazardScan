import 'package:flutter/material.dart';
import '../../services/accounts_file_service.dart';

class EditAccountsPage extends StatefulWidget {
  const EditAccountsPage({super.key});

  @override
  State<EditAccountsPage> createState() => _EditAccountsPageState();
}

class _EditAccountsPageState extends State<EditAccountsPage> {
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    final txt = await AccountsFileService.instance.loadRaw();
    setState(() {
      _controller.text = txt;
      _loading = false;
    });
  }

  Future<void> _saveFile() async {
    await AccountsFileService.instance.saveRaw(_controller.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Accounts updated")),
    );
  }

  Future<void> _resetFile() async {
    await AccountsFileService.instance.saveRaw(
      "admin@example.com,password123,admin\n"
      "worker@example.com,123456,user",
    );
    await _loadFile();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reset to default")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Accounts"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFile,
            tooltip: "Reset to default",
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Edit accounts.txt\n"
                    "Format: email,password,role\n"
                    "Example: admin@example.com,password123,admin",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),

                  // Text editor
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
