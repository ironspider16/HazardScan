import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

/// Self-contained telemetry widget for the admin dashboard.
/// Fetches its own data from ai_telemetry_logs and renders:
///   - 4 summary stat cards (success rate, avg latency, fallback rate, volume)
///   - Model usage breakdown (which models are actually being called)
///   - Key slot distribution (which keys are being hit)
///   - Last 5 failed calls table
class AiTelemetryWidget extends StatefulWidget {
  const AiTelemetryWidget({super.key});

  @override
  State<AiTelemetryWidget> createState() => _AiTelemetryWidgetState();
}

class _AiTelemetryWidgetState extends State<AiTelemetryWidget> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  // Summary metrics
  double _successRate = 0;
  double _avgLatency = 0;
  double _fallbackRate = 0;
  int _totalCalls = 0;

  // Breakdown maps — populated from GROUP BY queries
  Map<String, int> _modelUsage = {};
  Map<String, int> _keySlotUsage = {};

  // Recent failures
  List<Map<String, dynamic>> _recentFailures = [];

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch last 200 rows — enough for meaningful stats without over-fetching
      final rows = await _supabase
          .from('ai_telemetry_logs')
          .select(
            'success, latency, model_used, key_slot, error_type, error_detail, timestamp, system_notice',
          )
          .order('timestamp', ascending: false)
          .limit(200);

      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(rows);

      if (data.isEmpty) {
        setState(() {
          _isLoading = false;
          _totalCalls = 0;
        });
        return;
      }

      // ── Summary metrics ──────────────────────────────────────────────────
      final total = data.length;
      final successes = data.where((r) => r['success'] == true).length;
      final fallbacks = data
          .where((r) => r['success'] == true && r['system_notice'] != null)
          .length;

      final latencies = data
          .where((r) => r['latency'] != null)
          .map((r) => double.tryParse(r['latency'].toString()) ?? 0.0)
          .toList();
      final avgLatency = latencies.isEmpty
          ? 0.0
          : latencies.reduce((a, b) => a + b) / latencies.length;

      // ── Model usage breakdown ─────────────────────────────────────────────
      final Map<String, int> modelMap = {};
      for (final row in data) {
        final model = (row['model_used'] as String?) ?? 'unknown';
        modelMap[model] = (modelMap[model] ?? 0) + 1;
      }

      // ── Key slot usage breakdown ──────────────────────────────────────────
      final Map<String, int> keyMap = {};
      for (final row in data) {
        final slot = row['key_slot'];
        if (slot != null && slot >= 0) {
          final label = 'Key ${slot.toString()}';
          keyMap[label] = (keyMap[label] ?? 0) + 1;
        }
      }

      // ── Recent failures (last 5) ──────────────────────────────────────────
      final failures = data
          .where((r) => r['success'] == false)
          .take(5)
          .toList();

      setState(() {
        _totalCalls = total;
        _successRate = total > 0 ? (successes / total) * 100 : 0;
        _avgLatency = avgLatency;
        _fallbackRate = successes > 0 ? (fallbacks / successes) * 100 : 0;
        _modelUsage = modelMap;
        _keySlotUsage = keyMap;
        _recentFailures = failures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildSection(
        title: 'AI Engine Monitor',
        child: Text(
          'Failed to load telemetry: $_error',
          style: AppTypography.body.copyWith(color: Colors.red),
        ),
      );
    }

    if (_totalCalls == 0) {
      return _buildSection(
        title: 'AI Engine Monitor',
        child: Text(
          'No analysis calls logged yet. Run an analysis to begin monitoring.',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AI Engine Monitor', style: AppTypography.Bluesubheading),
            TextButton.icon(
              onPressed: _loadTelemetry,
              icon: const Icon(Icons.refresh, fontWeight: FontWeight.bold, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Text(
          'Last $_totalCalls analysis calls',
          style: AppTypography.body.copyWith(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppPadding.medium),

        // ── 4 Summary Cards ─────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final cards = [
              _buildStatCard(
                label: 'Success Rate',
                value: '${_successRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                color: _successRate >= 90
                    ? Colors.green.shade600
                    : _successRate >= 70
                        ? Colors.orange
                        : Colors.red,
              ),
              _buildStatCard(
                label: 'Avg Latency',
                value: '${_avgLatency.toStringAsFixed(1)}s',
                icon: Icons.timer_outlined,
                color: _avgLatency <= 20
                    ? Colors.green.shade600
                    : _avgLatency <= 45
                        ? Colors.orange
                        : Colors.red,
              ),
              _buildStatCard(
                label: 'Fallback Rate',
                value: '${_fallbackRate.toStringAsFixed(1)}%',
                icon: Icons.swap_horiz_rounded,
                color: _fallbackRate == 0
                    ? Colors.green.shade600
                    : _fallbackRate < 20
                        ? Colors.orange
                        : Colors.red,
                subtitle: 'backup model used',
              ),
              _buildStatCard(
                label: 'Total Calls',
                value: _totalCalls.toString(),
                icon: Icons.analytics_outlined,
                color: AppColors.primaryBlue,
                subtitle: 'in last 200 logs',
              ),
            ];

            if (isWide) {
              return Row(
                children: cards
                    .map(
                      (c) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: c,
                        ),
                      ),
                    )
                    .toList(),
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 8),
                      Expanded(child: cards[1]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: cards[2]),
                      const SizedBox(width: 8),
                      Expanded(child: cards[3]),
                    ],
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: AppPadding.medium),

        // ── Model Usage ──────────────────────────────────────────────────────
        _buildSection(
          title: 'Model Usage',
          subtitle: 'Which Gemini models served your requests',
          child: Column(
            children: _modelUsage.entries.map((entry) {
              final pct = (_totalCalls > 0)
                  ? (entry.value / _totalCalls * 100)
                  : 0.0;
              final isPrimary = entry.key == _modelUsage.keys.first &&
                  entry.value ==
                      _modelUsage.values.reduce((a, b) => a > b ? a : b);
              return _buildUsageBar(
                label: entry.key,
                count: entry.value,
                total: _totalCalls,
                percentage: pct.toDouble(),
                color: isPrimary ? AppColors.primaryBlue : Colors.orange,
                tag: isPrimary ? 'PRIMARY' : 'FALLBACK',
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppPadding.medium),

        // ── Key Slot Distribution ────────────────────────────────────────────
        if (_keySlotUsage.isNotEmpty)
          _buildSection(
            title: 'Key Slot Usage',
            subtitle: 'Calls distributed across API keys',
            child: Column(
              children: _keySlotUsage.entries.map((entry) {
                final pct = (_totalCalls > 0)
                    ? (entry.value / _totalCalls * 100)
                    : 0.0;
                return _buildUsageBar(
                  label: entry.key,
                  count: entry.value,
                  total: _totalCalls,
                  percentage: pct.toDouble(),
                  color: Colors.indigo.shade400,
                );
              }).toList(),
            ),
          ),
        if (_keySlotUsage.isNotEmpty) const SizedBox(height: AppPadding.medium),

        // ── Recent Failures ──────────────────────────────────────────────────
        _buildSection(
          title: 'Recent Failures',
          subtitle: _recentFailures.isEmpty
              ? null
              : 'Last ${_recentFailures.length} failed calls',
          child: _recentFailures.isEmpty
              ? Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'No failures in the last $_totalCalls calls.',
                      style: AppTypography.body.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: _recentFailures
                      .map((row) => _buildFailureRow(row))
                      .toList(),
                ),
        ),
      ],
    );
  }

  // ── Sub-builders ───────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildUsageBar({
    required String label,
    required int count,
    required int total,
    required double percentage,
    required Color color,
    String? tag,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: AppTypography.body.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$count calls (${percentage.toStringAsFixed(0)}%)',
                style: AppTypography.body.copyWith(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureRow(Map<String, dynamic> row) {
    final timestamp = row['timestamp'] as String? ?? '';
    final errorType = row['error_type'] as String? ?? 'UNKNOWN';
    final model = row['model_used'] as String? ?? '—';
    final keySlot = row['key_slot'];
    final detail = row['error_detail'] as String? ?? '';

    // Trim timestamp to readable format
    final shortTime = timestamp.length >= 16 ? timestamp.substring(0, 16) : timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  errorType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              Text(
                shortTime,
                style: AppTypography.body.copyWith(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Model: $model  •  Key Slot: ${keySlot ?? "—"}',
            style: AppTypography.body.copyWith(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          if (detail.isNotEmpty && detail != 'NONE') ...[
            const SizedBox(height: 2),
            Text(
              detail.length > 120 ? '${detail.substring(0, 120)}...' : detail,
              style: AppTypography.body.copyWith(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}