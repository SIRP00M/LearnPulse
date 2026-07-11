import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String code;
  final String teacherName;
  final int studentCount;
  final int assignmentCount;
  final double progress;
  final Color color;
  final IconData icon;

  const Course({
    required this.id,
    required this.title,
    required this.code,
    required this.teacherName,
    required this.studentCount,
    required this.assignmentCount,
    required this.progress,
    required this.color,
    required this.icon,
  });
}
