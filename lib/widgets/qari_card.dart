import 'package:flutter/material.dart';
import '../models/qari_model.dart';
import '../theme/app_theme.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryEmerald
              : AppTheme.divider.withValues(alpha: 0.6),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppTheme.emeraldGradient
                            : const LinearGradient(
                                colors: [Color(0xFF2E3248), Color(0xFF1E202E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryEmeraldLight
                              : AppTheme.divider,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          size: 24,
                          color: isSelected ? Colors.black : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryEmeraldLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  qari.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryEmeraldLight
                        : AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryEmerald.withValues(alpha: 0.2)
                        : AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSelected ? 'Aktif Dipilih' : 'Hafs A\'n Assem',
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryEmeraldLight
                          : AppTheme.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
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
