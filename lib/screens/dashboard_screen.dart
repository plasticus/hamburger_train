// lib/screens/dashboard_screen.dart
// The home screen. Shows train overview, key stats, and navigation buttons.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_provider.dart';
import '../widgets/train_car_card.dart';
import '../widgets/stat_card.dart';
import 'order_screen.dart';
import 'empire_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatCash(double amount) {
    if (amount >= 1000000) return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return '\$${(amount / 1000).toStringAsFixed(1)}k';
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Ad Banner ────────────────────────────────────────────────
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

            // ── Scrollable Body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Row(
                      children: [
                        const Text('🍔🚂', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hamburger Train',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w900,
                                    color: Color(0xFF3D2000),
                                    letterSpacing: -0.5)),
                            Text(
                              'Stop ${game.currentStopNumber} · ${game.currentStopName}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Stat Cards ──────────────────────────────────────
                    Row(
                      children: [
                        StatCard(
                          emoji: '💰',
                          label: 'Cash',
                          value: _formatCash(game.cashOnHand),
                          accentColor: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          emoji: '📈',
                          label: '/day',
                          value: _formatCash(game.passiveIncomePerDay),
                          accentColor: const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          emoji: '🏠',
                          label: 'Joints',
                          value: game.dinersOwned.toString(),
                          accentColor: const Color(0xFFFF9500),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Work the Stop button ────────────────────────────
                    _BigActionButton(
                      emoji: '🍔',
                      label: 'Work the Stop',
                      sublabel:
                      'Stop ${game.currentStopNumber} · ${game.currentStopName}',
                      color: const Color(0xFFFF9500),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OrderScreen()),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Empire button (only if you own burger joints) ───
                    if (game.dinersOwned > 0) ...[
                      _BigActionButton(
                        emoji: '🏘️',
                        label: 'My Burger Joints',
                        sublabel: '${game.dinersOwned} locations'
                            '${game.dinersNeedingAttention > 0 ? ' · ⚠️ ${game.dinersNeedingAttention} need attention' : ' · All good ✅'}',
                        color: const Color(0xFF7B5EA7),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EmpireScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Train section ───────────────────────────────────
                    Row(
                      children: [
                        const Text('🚂 Your Train',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800,
                                color: Color(0xFF3D2000))),
                        const Spacer(),
                        Text('Tap to upgrade',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Train Cars horizontal scroll ────────────────────
                    SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: game.trainCars.length,
                        separatorBuilder: (_, __) => const Center(
                          child: Text('➖', style: TextStyle(fontSize: 10)),
                        ),
                        itemBuilder: (context, index) {
                          final car = game.trainCars[index];
                          return TrainCarCard(
                            car: car,
                            cashOnHand: game.cashOnHand,
                            onUpgrade: () {
                              final ok = game.upgradeTrainCar(car.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? '${car.emoji} ${car.name} upgraded!'
                                      : '💸 Not enough cash!'),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Dev Tools ───────────────────────────────────────
                    _DevTools(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Big Action Button ─────────────────────────────────────────────────────────

class _BigActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.emoji, required this.label, required this.sublabel,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text(sublabel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}

// ── Dev Tools ─────────────────────────────────────────────────────────────────

class _DevTools extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🛠️ Dev Tools',
              style:
              TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _devBtn('+ \$100',  () => game.devAddCash(100),  context),
              _devBtn('+ \$1000', () => game.devAddCash(1000), context),
              _devBtn('+ \$5000', () => game.devAddCash(5000), context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _devBtn(String label, VoidCallback onTap, BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}