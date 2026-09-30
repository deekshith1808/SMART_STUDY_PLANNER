import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Study Insights 📊',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Subjects'), Tab(text: 'Sessions')],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(vm: vm),
              _SubjectsTab(vm: vm),
              _SessionsTab(vm: vm),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _OverviewTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final totalTasks = vm.tasks.length;
    final completedTasks = vm.tasks.where((t) => t.isCompleted).length;
    final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final totalMinutes = vm.sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final avgSession = vm.sessions.isEmpty ? 0 : totalMinutes ~/ vm.sessions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _AnalyticsCard(
                icon: '⏱️',
                label: 'Total Focus Hours',
                value: '${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
                color: AppColors.primary,
                bg: const Color(0xFFFEF3C7),
              ),
              _AnalyticsCard(
                icon: '✅',
                label: 'Tasks Completed',
                value: '$completedTasks of $totalTasks',
                color: AppColors.secondary,
                bg: const Color(0xFFD1FAE5),
              ),
              _AnalyticsCard(
                icon: '🔥',
                label: 'Pomodoro Cycles',
                value: '${vm.sessions.where((s) => s.sessionType == 'pomodoro').length}',
                color: AppColors.accent,
                bg: const Color(0xFFFFEDD5),
              ),
              _AnalyticsCard(
                icon: '⚡',
                label: 'Avg Session Length',
                value: '${avgSession}m',
                color: const Color(0xFF2563EB),
                bg: const Color(0xFFDBEAFE),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Task completion rate card
          Text(
            'Goal Completion Rate',
            style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(completionRate * 100).toStringAsFixed(0)}% Finished',
                      style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      '$completedTasks done / $totalTasks total',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: AppColors.secondary.withAlpha(25),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Weekly study bar chart
          if (vm.sessions.isNotEmpty) ...[
            Text(
              'Weekly Rhythm (Last 7 Days)',
              style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              height: 210,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _WeeklyBarChart(vm: vm),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _WeeklyBarChart({required this.vm});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final bars = days.map((day) {
      final minutes = vm.sessions
          .where((s) => s.startTime.year == day.year && s.startTime.month == day.month && s.startTime.day == day.day)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      return minutes / 60.0;
    }).toList();

    final maxY = bars.reduce((a, b) => a > b ? a : b);
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BarChart(
      BarChartData(
        maxY: maxY > 0 ? maxY + 1 : 5,
        barGroups: List.generate(7, (i) {
          final isToday = days[i].day == now.day;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: bars[i],
                color: isToday ? AppColors.primary : AppColors.primary.withAlpha(70),
                width: 18,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  dayLabels[value.toInt() % 7],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _SubjectsTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final subjects = vm.profile?.subjects ?? [];

    if (subjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects enrolled yet',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
        ),
      );
    }

    final sections = subjects.asMap().entries.map((e) {
      final color = _colorFromHex(e.value.color);
      return PieChartSectionData(
        color: color,
        value: e.value.marks > 0 ? e.value.marks : 1,
        title: '${e.value.marks.toStringAsFixed(0)}%',
        radius: 65,
        titleStyle: GoogleFonts.lora(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 230,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: PieChart(PieChartData(sections: sections, sectionsSpace: 3, centerSpaceRadius: 36)),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subjects.asMap().entries.map((e) {
                    final color = _colorFromHex(e.value.color);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            e.value.name,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Subject Ranking & Score Breakdown',
            style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          ...subjects.sorted((a, b) => b.marks.compareTo(a.marks)).asMap().entries.map((e) {
            final rank = e.key + 1;
            final subject = e.value;
            final color = _colorFromHex(subject.color);
            final rankEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '📖';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(70), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(rankEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Target: ${subject.targetMarks.toStringAsFixed(0)}% · ${subject.studyHours}h studied',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${subject.marks.toStringAsFixed(1)}%',
                    style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _SessionsTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final sessions = vm.sessions.reversed.toList();

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'No study logs yet',
              style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a Pomodoro session to see your timeline.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final session = sessions[i];
        final date = '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}';
        final time = '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: session.sessionType == 'pomodoro' ? AppColors.primary.withAlpha(25) : AppColors.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  session.sessionType == 'pomodoro' ? Icons.timer_outlined : Icons.book_rounded,
                  color: session.sessionType == 'pomodoro' ? AppColors.primary : AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subjectName,
                      style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      '$date at $time · ${session.sessionType}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.durationMinutes}m',
                    style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  Text(
                    '${(session.durationMinutes / 60).toStringAsFixed(1)}h focus',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _AnalyticsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _colorFromHex(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}

extension _SortedList<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final copy = [...this];
    copy.sort(compare);
    return copy;
  }
}
