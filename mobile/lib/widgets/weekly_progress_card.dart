import 'package:flutter/material.dart';

class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF25347A);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly progress',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              _ProgressChangeBadge(),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '68%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF90F4BE)),
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ProgressStat(value: '12', label: 'Tasks done'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _ProgressStat(value: '8.5h', label: 'Study time'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _ProgressStat(value: '4', label: 'Day streak'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressChangeBadge extends StatelessWidget {
  const _ProgressChangeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF90F4BE)),
          SizedBox(width: 5),
          Text(
            '+12%',
            style: TextStyle(
              color: Color(0xFF90F4BE),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProgressStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
