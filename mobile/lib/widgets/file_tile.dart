import 'package:flutter/material.dart';

class FileTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String extension;
  final VoidCallback? onTap;

  const FileTile({
    required this.name,
    required this.subtitle,
    required this.extension,
    this.onTap,
    super.key,
  });

  Color get color {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFFF5C66);
      case 'docx':
        return const Color(0xFF246BFD);
      case 'pptx':
        return const Color(0xFFFF9F1C);
      case 'zip':
        return const Color(0xFF7C4DFF);
      default:
        return const Color(0xFF00A884);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withAlpha(22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            extension.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12)),
        ),
        trailing: const Icon(Icons.download_rounded),
      ),
    );
  }
}
