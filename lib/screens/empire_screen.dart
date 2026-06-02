// lib/screens/empire_screen.dart
// Overview of all owned burger joints — income, maintenance, and popularity.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_provider.dart';
import '../models/game_state.dart';
import 'stop_detail_screen.dart';

class EmpireScreen extends StatelessWidget {
  const EmpireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game   = context.watch<GameProvider>();
    final diners = game.ownedDiners;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Ad banner ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 50,
              color: const Color(0xFFE0E0E0),
              child: const Center(
                child: Text('📢 Ad Banner',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text('⬅️', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My Burger Joints 🏘️',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900,
                                color: Color(0xFF3D2000))),
                        Text('${diners.length} locations · '
                            '\$${game.passiveIncomePerDay.toStringAsFixed(2)}/day passive',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Attention banner ───────────────────────────────────────────
            if (game.dinersNeedingAttention > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '${game.dinersNeedingAttention} burger joint${game.dinersNeedingAttention > 1 ? 's need' : ' needs'} attention',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF7A5C00)),
                    ),
                  ],
                ),
              ),

            if (game.dinersNeedingAttention > 0) const SizedBox(height: 8),

            // ── Diner list ─────────────────────────────────────────────────
            Expanded(
              child: diners.isEmpty
                  ? const Center(
                  child: Text('No burger joints yet!\nGet out there and buy one. 🍔',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: diners.length,
                itemBuilder: (ctx, i) =>
                    _DinerCard(diner: diners[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diner Card ────────────────────────────────────────────────────────────────

class _DinerCard extends StatelessWidget {
  final OwnedDiner diner;

  const _DinerCard({required this.diner});

  Color _levelColor(double level) {
    if (level >= 80) return const Color(0xFF4CAF50);
    if (level >= 50) return const Color(0xFFFF9500);
    if (level >= 25) return const Color(0xFFE65100);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final effective = diner.effectiveIncomePerDay;
    final needsAttention = diner.needsAttention;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsAttention
              ? const Color(0xFFFFD700)
              : Colors.grey.shade200,
          width: needsAttention ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: venue info + manager
            Row(
              children: [
                Text(diner.venueEmoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Stop ${diner.stopNumber} · ',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                          Text(diner.stopName,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800,
                                  color: Color(0xFF3D2000))),
                        ],
                      ),
                      Text(diner.venueType,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                      const SizedBox(height: 2),
                      Text('${diner.managerEmoji} ${diner.managerName}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                if (needsAttention)
                  const Text('⚠️', style: TextStyle(fontSize: 18)),
              ],
            ),

            const SizedBox(height: 10),

            // Maintenance bar
            _LevelBar(
              label: '🔧 Maintenance',
              level: diner.maintenanceLevel,
              statusLabel: diner.maintenanceStatusLabel,
              color: _levelColor(diner.maintenanceLevel),
            ),
            const SizedBox(height: 6),

            // Popularity bar
            _LevelBar(
              label: '⭐ Popularity',
              level: diner.popularityLevel,
              statusLabel: diner.popularityStatusLabel,
              color: _levelColor(diner.popularityLevel),
            ),

            const SizedBox(height: 10),

            // Income + details button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${effective.toStringAsFixed(2)}/day',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32)),
                    ),
                    Text(
                      'of \$${diner.baseIncomePerDay.toStringAsFixed(2)} base',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          StopDetailScreen(stopNumber: diner.stopNumber),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Details →',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Level Bar ─────────────────────────────────────────────────────────────────

class _LevelBar extends StatelessWidget {
  final String label;
  final double level;
  final String statusLabel;
  final Color color;

  const _LevelBar({
    required this.label, required this.level,
    required this.statusLabel, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: level / 100,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('${level.round()}%',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text(statusLabel,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }
}