import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../widgets/file_tile.dart';

class StudentAssignmentDetailPage extends StatefulWidget {
  final Course course;
  final String title;
  const StudentAssignmentDetailPage({
    required this.course,
    required this.title,
    super.key,
  });

  @override
  State<StudentAssignmentDetailPage> createState() =>
      _StudentAssignmentDetailPageState();
}

class _StudentAssignmentDetailPageState
    extends State<StudentAssignmentDetailPage> {
  String? selectedFileName;

  void _pickMockFile() {
    setState(() => selectedFileName = 'learn_pulse_submission.zip');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mock file selected. Backend upload is not connected yet.',
        ),
      ),
    );
  }

  void _submitMock() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedFileName == null
              ? 'Attach a file first.'
              : 'Mock submission completed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            widget.course.title,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Due',
                    value: 'Today, 11:59 PM',
                  ),
                  Divider(height: 26),
                  _InfoRow(
                    icon: Icons.grade_outlined,
                    label: 'Points',
                    value: '100',
                  ),
                  Divider(height: 26),
                  _InfoRow(
                    icon: Icons.file_upload_outlined,
                    label: 'Submission',
                    value: 'File upload',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Instructions',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Create a Flutter UI prototype with at least three screens, navigation, responsive layout, and reusable widgets. Submit the source code as a ZIP file and include a short PDF report.',
                style: TextStyle(height: 1.55),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Attached files',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const FileTile(
            name: 'Assignment rubric.pdf',
            subtitle: '184 KB • Provided by teacher',
            extension: 'pdf',
          ),
          const SizedBox(height: 22),
          const Text(
            'Your work',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickMockFile,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(70),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    selectedFileName == null
                        ? Icons.cloud_upload_outlined
                        : Icons.insert_drive_file_rounded,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectedFileName ?? 'Tap to attach a file',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    selectedFileName == null
                        ? 'PDF, DOCX, ZIP or image • Maximum 25 MB'
                        : 'File ready to submit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Submission comment',
              hintText: 'Add a note for your teacher...',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitMock,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Submit assignment'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
