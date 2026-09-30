import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();
        final notes = vm.notes.where((n) =>
          n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.content.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            elevation: 0,
            title: Text(
              'Quick Sticky Notes 📌',
              style: GoogleFonts.lora(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSecondary : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.darkSecondary : AppColors.primary).withAlpha(70),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  onPressed: () => _showAddNoteDialog(context, vm),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(62),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search notes, formulas or key insights...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    fillColor: isDark ? AppColors.darkTranslucentCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0x338B5CF6) : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0x338B5CF6) : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkAccent : AppColors.accent).withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sticky_note_2_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkAccent : AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No sticky notes yet',
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Capture study reminders, shortcuts, and key ideas.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showAddNoteDialog(context, vm),
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: const Text('Add First Sticky Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.darkSecondary : AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(18),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, i) => _NoteCard(
                      note: notes[i],
                      onDelete: () => vm.deleteNote(notes[i].id),
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, StudyPlannerViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final subjects = vm.profile?.subjects ?? [];
    String? selectedSubjectId = subjects.isNotEmpty ? subjects.first.id : null;
    String? selectedSubjectName = subjects.isNotEmpty ? subjects.first.name : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFD6CBC0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Sticky Note 📝',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : null,
                    ),
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Content / Formula',
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : null,
                    ),
                    prefixIcon: Icon(
                      Icons.notes_rounded,
                      color: isDark ? AppColors.darkAccent : AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubjectId,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Related Subject',
                      labelStyle: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : null,
                      ),
                      prefixIcon: Icon(
                        Icons.book_rounded,
                        color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                      ),
                    ),
                    items: subjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        s.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    )).toList(),
                    onChanged: (id) {
                      setModalState(() {
                        selectedSubjectId = id;
                        selectedSubjectName = subjects.firstWhere((s) => s.id == id).name;
                      });
                    },
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isNotEmpty) {
                        final note = QuickNote(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          subjectId: selectedSubjectId ?? '',
                          subjectName: selectedSubjectName ?? 'General Note',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        vm.addNote(note);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSecondary : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Pin to Notes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final QuickNote note;
  final VoidCallback onDelete;

  const _NoteCard({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warm handcrafted craft paper pastels for light mode
    final lightColors = [
      const Color(0xFFFEF3C7), // Manila Paper
      const Color(0xFFD1FAE5), // Soft Sage Mint
      const Color(0xFFFFEDD5), // Peach Clay
      const Color(0xFFEDE9FE), // Lavender Haze
      const Color(0xFFF3ECE0), // Linen Oatmeal
      const Color(0xFFDBEAFE), // Dusty Slate Blue
    ];

    // Translucent glass tints for dark mode (Blue, Violet, Purple, Black palette)
    final darkBorderColors = [
      const Color(0x6038BDF8), // Electric Blue
      const Color(0x608B5CF6), // Royal Violet
      const Color(0x60A855F7), // Neon Purple
      const Color(0x60818CF8), // Indigo
      const Color(0x6006B6D4), // Cyan
    ];

    final lightColor = lightColors[note.id.hashCode.abs() % lightColors.length];
    final darkBorder = darkBorderColors[note.id.hashCode.abs() % darkBorderColors.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: isDark
          ? AppColors.glassCardDecoration(
              isDark: true,
              borderColor: darkBorder,
              glowColor: darkBorder.withAlpha(25),
              borderRadius: 18,
            )
          : BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withAlpha(15), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(25) : Colors.white.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              note.content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary.withAlpha(200),
                height: 1.45,
              ),
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note.subjectName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkPrimary : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
