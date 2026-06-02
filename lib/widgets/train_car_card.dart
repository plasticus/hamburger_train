// lib/widgets/train_car_card.dart
// Displays one train car as a status card on the dashboard.

import 'package:flutter/material.dart';
import '../models/game_state.dart';

class TrainCarCard extends StatelessWidget {
  final TrainCar car;
  final double cashOnHand;
  final VoidCallback onUpgrade;

  const TrainCarCard({
    super.key,
    required this.car,
    required this.cashOnHand,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAfford =
        !car.isMaxed && (car.nextUpgradeCost ?? double.infinity) <= cashOnHand;
    final bool isLocked = car.isLocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 128,
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFEEEEEE) : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? Colors.grey.shade300
              : canAfford
              ? const Color(0xFFFF9500)
              : const Color(0xFFFFD580),
          width: canAfford && !isLocked ? 2.5 : 1.5,
        ),
        boxShadow: isLocked
            ? []
            : [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.12),
              blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Emoji + lock overlay ──────────────────────────────────
            Stack(
              children: [
                const Text('', style: TextStyle(fontSize: 0)), // baseline
                Text(car.emoji, style: const TextStyle(fontSize: 26)),
                if (isLocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle),
                      child: const Text('🔒',
                          style: TextStyle(fontSize: 9)),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Car name ──────────────────────────────────────────────
            Text(
              car.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isLocked
                    ? Colors.grey.shade400
                    : const Color(0xFF3D2000),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 3),

            // ── Description ───────────────────────────────────────────
            Text(
              car.description,
              style: TextStyle(
                fontSize: 9,
                color: isLocked
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // ── Tier pips ─────────────────────────────────────────────
            if (!isLocked) _TierPips(car: car),

            const SizedBox(height: 6),

            // ── Upgrade button or status ──────────────────────────────
            if (car.isMaxed)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFD4F5C4),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('✅ Maxed',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: Color(0xFF2D7A00))),
              )
            else
              GestureDetector(
                onTap: canAfford ? onUpgrade : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? const Color(0xFFFF9500)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isLocked ? '🔓' : '⬆️',
                          style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Text(
                        '\$${_formatCost(car.nextUpgradeCost!)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: canAfford
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCost(int cost) {
    if (cost >= 1000) return '${(cost / 1000).toStringAsFixed(1)}k';
    return cost.toString();
  }
}

class _TierPips extends StatelessWidget {
  final TrainCar car;
  const _TierPips({required this.car});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(car.maxTier, (i) {
        final filled = i < car.tier;
        return Container(
          margin: const EdgeInsets.only(right: 3),
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? const Color(0xFFFF9500)
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}