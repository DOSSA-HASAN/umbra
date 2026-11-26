import "package:flutter/material.dart";
import "package:umbra/app_colors.dart";

class PermissionBanner extends StatelessWidget {
  final bool permissionGranted;
  final VoidCallback onTap;

  const PermissionBanner({
    super.key,
    required this.permissionGranted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = permissionGranted
        ? "Overlay access enabled"
        : "Overlay permission required";

    final subtitle = permissionGranted
        ? 'Umbra can display overlays over other apps.'
        : 'Tap here to allow Umbra to display overlays.';

    final accent = permissionGranted ? AppColors.primary : AppColors.warning;

    final background = permissionGranted
        ? AppColors.successBackground
        : AppColors.warningBackground;

    final borderColor = permissionGranted
        ? const Color(0xFF3A5136)
        : const Color(0xFF59452B);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
