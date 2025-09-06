import 'package:flutter/material.dart';
import '../../models/user_rewards.dart';

class RewardBadges extends StatelessWidget {
  final UserRewards userRewards;

  const RewardBadges({
    super.key,
    required this.userRewards,
  });

  @override
  Widget build(BuildContext context) {
    if (userRewards.totalBzpPoints == 0 && userRewards.totalMindDust == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadge(
              icon: Icons.stars,
              iconColor: Colors.blue,
              value: userRewards.totalBzpPoints,
              label: 'BZP',
            ),
            const SizedBox(width: 12),
            _buildBadge(
              icon: Icons.auto_awesome,
              iconColor: Colors.orange,
              value: userRewards.totalMindDust,
              label: 'Mind Dust',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color iconColor,
    required int value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 14,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
