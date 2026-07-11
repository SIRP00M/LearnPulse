import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../models/student.dart';

class MockData {
  static const courses = [
    Course(
      id: 'c1',
      title: 'Mobile Application Development',
      code: 'MAD-401',
      teacherName: 'Dr. Amelia Hart',
      studentCount: 32,
      assignmentCount: 4,
      progress: 0.68,
      color: Color(0xFF246BFD),
      icon: Icons.phone_android_rounded,
    ),
    Course(
      id: 'c2',
      title: 'Introduction to Data Science',
      code: 'DS-210',
      teacherName: 'Dr. Amelia Hart',
      studentCount: 28,
      assignmentCount: 3,
      progress: 0.74,
      color: Color(0xFF7C4DFF),
      icon: Icons.analytics_rounded,
    ),
    Course(
      id: 'c3',
      title: 'Human Computer Interaction',
      code: 'HCI-315',
      teacherName: 'Dr. Amelia Hart',
      studentCount: 24,
      assignmentCount: 5,
      progress: 0.56,
      color: Color(0xFF00A884),
      icon: Icons.groups_rounded,
    ),
  ];

  static const students = [
    Student(
      id: 's1',
      name: 'Anna Lee',
      email: 'anna.lee@example.com',
      progress: 0.91,
      submittedAssignments: 10,
      totalAssignments: 10,
      averageScore: 89,
      atRisk: false,
    ),
    Student(
      id: 's2',
      name: 'John Smith',
      email: 'john.smith@example.com',
      progress: 0.82,
      submittedAssignments: 8,
      totalAssignments: 10,
      averageScore: 76,
      atRisk: false,
    ),
    Student(
      id: 's3',
      name: 'Michael Tan',
      email: 'michael.tan@example.com',
      progress: 0.45,
      submittedAssignments: 4,
      totalAssignments: 10,
      averageScore: 58,
      atRisk: true,
    ),
    Student(
      id: 's4',
      name: 'Nora Wilson',
      email: 'nora.wilson@example.com',
      progress: 0.67,
      submittedAssignments: 7,
      totalAssignments: 10,
      averageScore: 72,
      atRisk: false,
    ),
  ];

  static const assignments = [
    Assignment(
      id: 'a1',
      title: 'Flutter UI Prototype',
      courseName: 'Mobile Application Development',
      dueDate: 'Today, 11:59 PM',
      submittedCount: 23,
      totalStudents: 32,
      status: AssignmentStatus.active,
    ),
    Assignment(
      id: 'a2',
      title: 'Data Cleaning Worksheet',
      courseName: 'Introduction to Data Science',
      dueDate: '14 July',
      submittedCount: 18,
      totalStudents: 28,
      status: AssignmentStatus.active,
    ),
    Assignment(
      id: 'a3',
      title: 'Usability Evaluation Report',
      courseName: 'Human Computer Interaction',
      dueDate: '18 July',
      submittedCount: 0,
      totalStudents: 24,
      status: AssignmentStatus.draft,
    ),
  ];
}
