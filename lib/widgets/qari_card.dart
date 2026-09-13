import 'package:flutter/material.dart';
import 'models/qari_model.dart';

class QariCard extends StatelessWidget {
  final Qari qari;
  final bool isSelected;
  final VoidCallback onTap;

  const QariCard({
    super.key,
    required this.qari,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? const Color(0xFF1DB954) : const Color(0xFF282828),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.person : Icons.person_outline,
                size: 36,
                color: isSelected ? Colors.black : Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                qari.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
