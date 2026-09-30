import 'dart:math';
import '../models/user_profile.dart';
import '../models/study_session.dart';

class SubjectTimeAllocation {
  final Subject subject;
  final int totalMinutes;
  final int totalSlots;
  final double percentage;
  final double compositeWeight;
  final String rationale;

  const SubjectTimeAllocation({
    required this.subject,
    required this.totalMinutes,
    required this.totalSlots,
    required this.percentage,
    required this.compositeWeight,
    required this.rationale,
  });
}

class TimetableGenerator {
  /// Calculate composite scheduling weight for a subject based on:
  /// - Student manual priority (High: 3.0, Medium: 2.0, Low: 1.0)
  /// - Subject difficulty (Hard: 1.5, Medium: 1.2, Easy: 1.0)
  /// - Unfinished topics count
  /// - Upcoming exam proximity
  /// - Marks deficit vs target
  static double calculateSubjectWeight(Subject subject) {
    final priorityWeight = subject.priority.weightMultiplier;
    final difficultyWeight = subject.difficulty.weightMultiplier;

    // Unfinished topics factor (+8% per unfinished topic, up to +48%)
    final unfinishedCount = subject.unfinishedTopicsCount;
    final topicMultiplier = 1.0 + (min(unfinishedCount, 6) * 0.08);

    // Exam urgency multiplier
    double examMultiplier = 1.0;
    final daysToExam = subject.daysUntilExam;
    if (daysToExam != null && daysToExam >= 0) {
      if (daysToExam <= 3) {
        examMultiplier = 2.0;
      } else if (daysToExam <= 7) {
        examMultiplier = 1.5;
      } else if (daysToExam <= 14) {
        examMultiplier = 1.25;
      }
    }

    // Target marks gap factor
    double marksGapMultiplier = 1.0;
    if (subject.marks < subject.targetMarks) {
      final gap = (subject.targetMarks - subject.marks).clamp(0.0, 50.0);
      marksGapMultiplier = 1.0 + (gap / 100.0) * 0.3;
    }

    return priorityWeight *
        difficultyWeight *
        topicMultiplier *
        examMultiplier *
        marksGapMultiplier;
  }

  /// Generates a rationale explaining why this subject received its allocation
  static String buildRationale(Subject subject, double weight) {
    final factors = <String>[];
    factors.add('${subject.priority.label} Priority (${subject.priority.weightMultiplier.toStringAsFixed(1)}x)');
    factors.add('${subject.difficulty.label} Difficulty (${subject.difficulty.weightMultiplier.toStringAsFixed(1)}x)');

    final unfinished = subject.unfinishedTopicsCount;
    if (unfinished > 0) {
      factors.add('$unfinished unfinished topic${unfinished > 1 ? 's' : ''}');
    }

    final daysToExam = subject.daysUntilExam;
    if (daysToExam != null && daysToExam >= 0) {
      factors.add('Exam in $daysToExam day${daysToExam == 1 ? '' : 's'}');
    }

    return factors.join(' • ');
  }

  /// Calculates breakdown of recommended study time per subject
  static List<SubjectTimeAllocation> computeAllocations({
    required List<Subject> subjects,
    required int daysCount,
    required double dailyStudyHours,
    required int slotDurationMinutes,
  }) {
    if (subjects.isEmpty) return [];

    final slotsPerDay = max(1, (dailyStudyHours * 60 / slotDurationMinutes).round());
    final totalSlots = slotsPerDay * daysCount;
    final totalMinutes = (dailyStudyHours * 60 * daysCount).round();

    final weights = <Subject, double>{};
    double totalWeight = 0.0;

    for (final subject in subjects) {
      final w = calculateSubjectWeight(subject);
      weights[subject] = w;
      totalWeight += w;
    }

    if (totalWeight <= 0) totalWeight = 1.0;

    // Initial proportional slot assignment
    final slotCounts = <Subject, int>{};
    int assignedSlots = 0;

    for (final subject in subjects) {
      final proportion = weights[subject]! / totalWeight;
      int count = (totalSlots * proportion).round();
      if (count < 1 && totalSlots >= subjects.length) {
        count = 1;
      }
      slotCounts[subject] = count;
      assignedSlots += count;
    }

    // Balance rounding drift by adding/removing from highest priority subjects
    final sortedSubjects = List<Subject>.from(subjects)
      ..sort((a, b) => weights[b]!.compareTo(weights[a]!));

    while (assignedSlots < totalSlots) {
      for (final s in sortedSubjects) {
        if (assignedSlots >= totalSlots) break;
        slotCounts[s] = (slotCounts[s] ?? 0) + 1;
        assignedSlots++;
      }
    }

    while (assignedSlots > totalSlots) {
      // Deduct from lower priority subjects first
      for (final s in sortedSubjects.reversed) {
        if (assignedSlots <= totalSlots) break;
        if ((slotCounts[s] ?? 0) > 1) {
          slotCounts[s] = slotCounts[s]! - 1;
          assignedSlots--;
        }
      }
    }

    return subjects.map((subject) {
      final slots = slotCounts[subject] ?? 0;
      final mins = slots * slotDurationMinutes;
      final pct = totalMinutes > 0 ? (mins / totalMinutes) : (1.0 / subjects.length);
      final weight = weights[subject] ?? 1.0;

      return SubjectTimeAllocation(
        subject: subject,
        totalMinutes: mins,
        totalSlots: slots,
        percentage: pct,
        compositeWeight: weight,
        rationale: buildRationale(subject, weight),
      );
    }).toList();
  }

  /// Generates the schedule of [ScheduledTask]s distributed over [daysCount] days
  static List<ScheduledTask> generateSchedule({
    required List<Subject> subjects,
    DateTime? startDate,
    int daysCount = 7,
    double dailyStudyHours = 3.0,
    int slotDurationMinutes = 60,
    String dailyStartTime = '09:00',
    List<ScheduledTask> existingTasks = const [],
    bool preserveCompleted = true,
  }) {
    if (subjects.isEmpty) return existingTasks;

    final start = startDate ?? DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);

    // Filter existing tasks if preserving
    final preservedTasks = <ScheduledTask>[];
    if (preserveCompleted) {
      for (final task in existingTasks) {
        final taskDate = DateTime(
          task.scheduledDate.year,
          task.scheduledDate.month,
          task.scheduledDate.day,
        );
        // Keep completed tasks or tasks from past days
        if (task.isCompleted || taskDate.isBefore(startDay)) {
          preservedTasks.add(task);
        }
      }
    }

    final allocations = computeAllocations(
      subjects: subjects,
      daysCount: daysCount,
      dailyStudyHours: dailyStudyHours,
      slotDurationMinutes: slotDurationMinutes,
    );

    // Build pool of slot assignments
    final slotPool = <Subject>[];
    for (final alloc in allocations) {
      for (int i = 0; i < alloc.totalSlots; i++) {
        slotPool.add(alloc.subject);
      }
    }

    // Interleave subjects so no single subject takes all slots on the same day consecutively
    final interleavedPool = _interleaveSubjects(slotPool);

    // Parse daily start time
    final timeParts = dailyStartTime.split(':');
    final startHour = int.tryParse(timeParts[0]) ?? 9;
    final startMinute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

    final slotsPerDay = max(1, (dailyStudyHours * 60 / slotDurationMinutes).round());
    final newTasks = <ScheduledTask>[];
    int poolIndex = 0;

    final topicIndices = <String, int>{};

    for (int dayOffset = 0; dayOffset < daysCount; dayOffset++) {
      final currentDate = startDay.add(Duration(days: dayOffset));
      var currentSlotStartMinutes = startHour * 60 + startMinute;

      for (int slot = 0; slot < slotsPerDay; slot++) {
        if (poolIndex >= interleavedPool.length) break;

        final subject = interleavedPool[poolIndex++];
        final slotEndMinutes = currentSlotStartMinutes + slotDurationMinutes;

        final startFormatted = _formatMinutesToTime(currentSlotStartMinutes);
        final endFormatted = _formatMinutesToTime(slotEndMinutes);

        // Pick specific topic
        final unfinished = subject.unfinishedTopics;
        final allTopics = subject.topics;
        String taskTitle;
        String? description;

        if (unfinished.isNotEmpty) {
          final tIndex = (topicIndices[subject.id] ?? 0) % unfinished.length;
          final topic = unfinished[tIndex];
          topicIndices[subject.id] = tIndex + 1;
          taskTitle = '${subject.name}: $topic';
          description = 'Focus study on unfinished topic ($topic). Priority: ${subject.priority.label.toUpperCase()}.';
        } else if (allTopics.isNotEmpty) {
          final tIndex = (topicIndices[subject.id] ?? 0) % allTopics.length;
          final topic = allTopics[tIndex];
          topicIndices[subject.id] = tIndex + 1;
          taskTitle = '${subject.name}: Review $topic';
          description = 'Revision and practice questions on $topic.';
        } else {
          taskTitle = '${subject.name} Focus Session';
          description = 'Deep focus study block. Target: ${subject.targetMarks.toStringAsFixed(0)}% marks.';
        }

        final taskId = 'task_${currentDate.millisecondsSinceEpoch}_${slot}_${subject.id}';

        newTasks.add(ScheduledTask(
          id: taskId,
          title: taskTitle,
          subjectId: subject.id,
          subjectName: subject.name,
          scheduledDate: currentDate,
          startTime: startFormatted,
          endTime: endFormatted,
          isCompleted: false,
          priority: subject.priority.name,
          description: description,
        ));

        // Advance slot with 10 min break
        currentSlotStartMinutes = slotEndMinutes + 10;
      }
    }

    return [...preservedTasks, ...newTasks];
  }

  /// Interleaves subjects across days so the student gets healthy variety
  static List<Subject> _interleaveSubjects(List<Subject> pool) {
    if (pool.isEmpty) return [];

    final counts = <Subject, int>{};
    for (final s in pool) {
      counts[s] = (counts[s] ?? 0) + 1;
    }

    final uniqueSubjects = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final result = <Subject>[];
    final remaining = Map<Subject, int>.from(counts);

    while (result.length < pool.length) {
      bool addedAny = false;
      for (final subject in uniqueSubjects) {
        if ((remaining[subject] ?? 0) > 0) {
          result.add(subject);
          remaining[subject] = remaining[subject]! - 1;
          addedAny = true;
        }
      }
      if (!addedAny) break;
    }

    return result;
  }

  static String _formatMinutesToTime(int totalMinutes) {
    final normalized = totalMinutes % (24 * 60);
    final hours = normalized ~/ 60;
    final mins = normalized % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
}
