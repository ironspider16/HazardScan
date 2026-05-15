import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),

          onPressed: () => Navigator.pop(context),
        ),

        title: const Text("Dashboard", style: AppTypography.Bluesubheading),

        centerTitle: true,
      ),

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),

        child: Column(
          children: [
            const SizedBox(height: AppPadding.medium),

            // ================= TOP STATS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: const [
                DashboardCircle(
                  icon: Icons.assignment_outlined,

                  value: "13",

                  label: "Total Reports",
                ),

                WorkActivityCircle(),
              ],
            ),

            const Divider(
              height: AppPadding.large,

              thickness: 1,

              color: Color(0xFFE0E0E0),
            ),

            // ================= FILTER =================
            Padding(
              padding: const EdgeInsets.only(bottom: AppPadding.medium),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,

                children: const [
                  Icon(Icons.filter_alt_outlined),

                  SizedBox(width: 6),

                  Text("All Filter", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            // ================= TASK LIST =================
            Expanded(
              child: ListView.separated(
                itemCount: 4,

                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppPadding.tight),

                itemBuilder: (context, index) {
                  return const TaskCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================

// DASHBOARD CIRCLE

// =====================================================

class DashboardCircle extends StatelessWidget {
  final IconData icon;

  final String value;

  final String label;

  const DashboardCircle({
    super.key,

    required this.icon,

    required this.value,

    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 180,

          height: 180,

          decoration: const BoxDecoration(
            color: AppColors.primaryTint,

            shape: BoxShape.circle,
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, size: 50),

              const SizedBox(height: 8),

              Text(
                value,

                style: const TextStyle(
                  fontSize: 22,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

// =====================================================

// WORK ACTIVITY CIRCLE

// =====================================================

class WorkActivityCircle extends StatelessWidget {
  const WorkActivityCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,

          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),

          padding: const EdgeInsets.all(12),

          child: PieChart(
            PieChartData(
              sectionsSpace: 1,
              centerSpaceRadius: 0,

              sections: [
                PieChartSectionData(
                  value: 25,
                  color: Colors.blue,
                  radius: 90,
                  title: 'WAH',
                  titleStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                PieChartSectionData(
                  value: 25,
                  color: Colors.orange,
                  radius: 90,
                  title: 'LN2',
                  titleStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                PieChartSectionData(
                  value: 25,
                  color: Colors.green,
                  radius: 90,
                  title: 'CS',
                  titleStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                PieChartSectionData(
                  value: 25,
                  color: const Color.fromARGB(255, 175, 79, 76),
                  radius: 90,
                  title: 'GS',
                  titleStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        const Text("Work Activity", style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

// =====================================================

// TASK CARD

// =====================================================

class TaskCard extends StatelessWidget {
  const TaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.primaryTint,

        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [
          // LEFT ICON
          Container(
            width: 90,

            height: 90,

            decoration: const BoxDecoration(
              color: AppColors.backgroundWhite,

              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.assignment_outlined, size: 45),
          ),

          const SizedBox(width: 24),

          // TASK DETAILS
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text("WO-2291-3290-005", style: TextStyle(fontSize: 14)),

                SizedBox(height: 10),

                Text("Electrical", style: TextStyle(fontSize: 14)),

                SizedBox(height: 10),

                Text(
                  "Ward 2B → Bed 12 / Corridor",

                  style: TextStyle(fontSize: 14),
                ),

                Spacer(),

                Text("worker1@example.com", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),

          // BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,

              foregroundColor: Colors.black,

              elevation: 0,

              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            onPressed: () {},

            child: const Text("Report Details"),
          ),
        ],
      ),
    );
  }
}
