import 'package:flutter/material.dart';

class RemoteActionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const RemoteActionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
