import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/reports_file_service.dart';
import 'report_detail_page.dart';

class ReportsListPage extends StatefulWidget {
  final bool isAdmin;

  const ReportsListPage({super.key, required this.isAdmin});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  bool _loading = true;
  List<Report> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final items = await ReportsFileService.instance.loadReports();
    setState(() {
      _reports = items;
      _loading = false;
    });
  }

  String _formatDate(DateTime dt) {
    // Simple format: 12 Dec 2025, 10:30
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_monthName(dt.month)} '
        '${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(
        color: Colors.white,), // <-- back arrow colour
        title: const Text('Reports', style: TextStyle(
      color: Color.fromARGB(255, 255, 255, 255), // <-- change to any colour you want
      fontWeight: FontWeight.w600,
      ),
        ),  
        backgroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _reports.isEmpty
              ? const Center(
                  child: Text(
                    'No reports yet.\nThey will appear here after analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = _reports[index];
                    return InkWell(
                      onTap: () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(
                              report: r,
                              index: index,
                              isAdmin: widget.isAdmin,
                            ),
                          ),
                        );

                        if (changed == true) {
                          // user (admin) edited report, reload list
                          _loadReports();
                        }
                      },

                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(r.createdAt),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r.body.length > 120
                                  ? '${r.body.substring(0, 120)}...'
                                  : r.body,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
