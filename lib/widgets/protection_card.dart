import "package:flutter/material.dart";
import "package:umbra/app_colors.dart";

class ProtectionCard extends StatelessWidget {
  final int activeOverlayCount;
  final bool serviceRunning;

  const ProtectionCard({
    super.key,
    required this.activeOverlayCount,
    required this.serviceRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PROTECTION',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            activeOverlayCount.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Active overlays',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 20),

          Divider(color: AppColors.border),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: serviceRunning ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Overlay service',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Text(
                serviceRunning ? 'Running' : 'Stopped',
                style: TextStyle(
                  color: serviceRunning ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
