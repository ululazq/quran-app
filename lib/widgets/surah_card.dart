import 'package:flutter/material.dart';
import '../models/surah_model.dart';
import '../theme/app_theme.dart';

class SurahCard extends StatelessWidget {
  final Surah surah;
  final bool isSelected;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
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
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Islamic Octagonal Number Badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryEmerald
                        : AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryEmeraldLight
                          : AppTheme.accentGold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${surah.number}',
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppTheme.accentGoldLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Surah Name (Latin) & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              surah.name,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryEmeraldLight
                                    : AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.volume_up_rounded,
                              size: 16,
                              color: AppTheme.primaryEmerald,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              surah.revelationType.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${surah.verses} Ayat',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arabic Calligraphy Text
                Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryEmeraldLight
                        : AppTheme.textPrimary.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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
