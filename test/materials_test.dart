import 'package:flutter_test/flutter_test.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';

void main() {
  group('StudyMaterial & Materials Management Tests', () {
    test('StudyMaterial serialization and deserialization works correctly', () {
      final material = StudyMaterial(
        id: 'mat_1',
        title: 'Calculus Chapter 1 Formulas',
        type: StudyMaterialType.pdf,
        fileName: 'calc_ch1.pdf',
        filePath: 'C:/Users/student/Documents/calc_ch1.pdf',
        fileSizeBytes: 2048576,
        uploadedAt: DateTime(2026, 9, 30, 10, 0),
        content: 'Important derivative rules',
      );

      final json = material.toJson();
      expect(json['id'], 'mat_1');
      expect(json['title'], 'Calculus Chapter 1 Formulas');
      expect(json['fileName'], 'calc_ch1.pdf');
      expect(json['type'], 'pdf');
      expect(json['filePath'], 'C:/Users/student/Documents/calc_ch1.pdf');
      expect(json['fileSizeBytes'], 2048576);
      expect(json['content'], 'Important derivative rules');

      final reconstructed = StudyMaterial.fromJson(json);
      expect(reconstructed.id, material.id);
      expect(reconstructed.title, material.title);
      expect(reconstructed.type, StudyMaterialType.pdf);
      expect(reconstructed.filePath, material.filePath);
      expect(reconstructed.fileSizeBytes, material.fileSizeBytes);
      expect(reconstructed.formattedSize, '2.0 MB');
      expect(reconstructed.content, material.content);
    });

    test('StudyMaterial formattedSize formats B, KB, MB correctly', () {
      final bMat = StudyMaterial(
        id: '1',
        title: 'Tiny note',
        type: StudyMaterialType.note,
        fileSizeBytes: 500,
        uploadedAt: DateTime.now(),
      );
      expect(bMat.formattedSize, '500 B');

      final kbMat = StudyMaterial(
        id: '2',
        title: 'Summary',
        type: StudyMaterialType.document,
        fileSizeBytes: 45000,
        uploadedAt: DateTime.now(),
      );
      expect(kbMat.formattedSize, '43.9 KB');

      final mbMat = StudyMaterial(
        id: '3',
        title: 'Full Textbook',
        type: StudyMaterialType.pdf,
        fileSizeBytes: 15728640,
        uploadedAt: DateTime.now(),
      );
      expect(mbMat.formattedSize, '15.0 MB');

      final zeroMat = StudyMaterial(
        id: '4',
        title: 'Empty link',
        type: StudyMaterialType.link,
        uploadedAt: DateTime.now(),
      );
      expect(zeroMat.formattedSize, '');
    });

    test('Subject serializes and deserializes list of materials correctly', () {
      final subject = Subject(
        id: 'sub_math',
        name: 'Mathematics',
        marks: 85,
        targetMarks: 95,
        studyHours: 10,
        color: '#2196F3',
        topics: const ['Calculus', 'Linear Algebra'],
        priority: SubjectPriority.high,
        difficulty: SubjectDifficulty.hard,
        materials: [
          StudyMaterial(
            id: 'mat_doc',
            title: 'Linear Algebra Slides',
            fileName: 'algebra.pptx',
            type: StudyMaterialType.document,
            filePath: 'C:/docs/algebra.pptx',
            uploadedAt: DateTime(2026, 9, 30),
          ),
          StudyMaterial(
            id: 'mat_link',
            title: '3Blue1Brown Essence of Linear Algebra',
            type: StudyMaterialType.link,
            fileUrl: 'https://youtube.com/playlist?list=some_id',
            uploadedAt: DateTime(2026, 9, 30),
          ),
        ],
      );

      final json = subject.toJson();
      expect(json['materials'], isNotNull);
      expect((json['materials'] as List).length, 2);

      final parsed = Subject.fromJson(json);
      expect(parsed.materials.length, 2);
      expect(parsed.materials[0].title, 'Linear Algebra Slides');
      expect(parsed.materials[0].fileName, 'algebra.pptx');
      expect(parsed.materials[0].type, StudyMaterialType.document);
      expect(parsed.materials[1].title, '3Blue1Brown Essence of Linear Algebra');
      expect(parsed.materials[1].fileUrl, 'https://youtube.com/playlist?list=some_id');
      expect(parsed.materials[1].type, StudyMaterialType.link);
    });
  });
}
