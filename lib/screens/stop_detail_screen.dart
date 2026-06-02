// lib/screens/stop_detail_screen.dart
// Detailed view of a single owned burger joint.
// Shows manager, lore, maintenance, popularity, income, and action buttons.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/game_provider.dart';
import '../models/game_state.dart';
import '../models/order_models.dart';
import 'order_screen.dart';

class StopDetailScreen extends StatelessWidget {
  final int stopNumber;

  const StopDetailScreen({super.key, required this.stopNumber});

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameProvider>();
    final diner = game.ownedDiners.firstWhere((d) => d.stopNumber == stopNumber);
    final stop  = StopRegistry.forStop(stopNumber);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Ad banner ────────────────────────────────────────────────
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

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: const Text('⬅️',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(diner.venueEmoji,
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(diner.stopName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900,
                                color: Color(0xFF3D2000))),
                        Text(
                            'Stop ${diner.stopNumber} · ${diner.venueType}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    // About card
                    _InfoCard(
                      title: 'About',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${stop.tagline}"',
                            style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3D2000)),
                          ),
                          const SizedBox(height: 8),
                          Text(stop.lore,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.5)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Manager card
                    _InfoCard(
                      title: 'Manager',
                      child: Row(
                        children: [
                          Text(diner.managerEmoji,
                              style: const TextStyle(fontSize: 36)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(diner.managerName,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF3D2000))),
                                const SizedBox(height: 2),
                                Text(
                                  'Running things since you bought the place. Loyal, reliable, and deeply invested in the secret sauce.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Maintenance card
                    _MaintenanceCard(diner: diner, game: game),

                    const SizedBox(height: 12),

                    // Popularity card
                    _PopularityCard(
                        diner: diner, stop: stop, game: game),

                    const SizedBox(height: 12),

                    // Income breakdown card
                    _IncomeCard(diner: diner),

                    const SizedBox(height: 24),
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

// ── Maintenance Card ──────────────────────────────────────────────────────────

class _MaintenanceCard extends StatelessWidget {
  final OwnedDiner diner;
  final GameProvider game;

  const _MaintenanceCard({required this.diner, required this.game});

  Color get _color {
    if (diner.maintenanceLevel >= 80) return const Color(0xFF4CAF50);
    if (diner.maintenanceLevel >= 50) return const Color(0xFFFF9500);
    if (diner.maintenanceLevel >= 25) return const Color(0xFFE65100);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final atFull    = diner.maintenanceLevel >= 100;
    final canAfford = game.cashOnHand >= diner.maintenanceCost;
    final cost      = diner.maintenanceCost;

    return _InfoCard(
      title: '🔧 Maintenance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${diner.maintenanceLevel.round()}%',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900,
                    color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(diner.maintenanceStatusLabel,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _color)),
                    Text(
                      atFull
                          ? 'Everything is running smoothly.'
                          : 'Affects your daily passive income.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: diner.maintenanceLevel / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          const SizedBox(height: 12),
          if (atFull)
            const _StatusChip(label: '✅ At full capacity', color: Color(0xFF4CAF50))
          else
            _ActionButton(
              label: 'Run Maintenance  ·  \$${cost.toStringAsFixed(0)}',
              emoji: '🔧',
              enabled: canAfford,
              disabledReason: canAfford ? null : 'Need \$${cost.toStringAsFixed(0)} — keep working!',
              onTap: () {
                final ok = game.runMaintenance(diner.stopNumber);
                if (!ok) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '🔧 ${diner.stopName} is back to 100% maintenance!'),
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Popularity Card ───────────────────────────────────────────────────────────

class _PopularityCard extends StatelessWidget {
  final OwnedDiner diner;
  final StopDefinition stop;
  final GameProvider game;

  const _PopularityCard(
      {required this.diner, required this.stop, required this.game});

  Color get _color {
    if (diner.popularityLevel >= 80) return const Color(0xFF9C27B0);
    if (diner.popularityLevel >= 50) return const Color(0xFFFF9500);
    if (diner.popularityLevel >= 25) return const Color(0xFFE65100);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '⭐ Popularity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${diner.popularityLevel.round()}%',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900,
                    color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(diner.popularityStatusLabel,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _color)),
                    Text(
                      diner.popularityLevel >= 80
                          ? 'The locals are talking about you!'
                          : 'Your fans miss you. Come back and work a day.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: diner.popularityLevel / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Spend the Day Here',
            emoji: '🍔',
            sublabel: 'Restores popularity to 100%',
            enabled: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderScreen(
                    isVisit: true,
                    visitStopNumber: diner.stopNumber,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Income Card ───────────────────────────────────────────────────────────────

class _IncomeCard extends StatelessWidget {
  final OwnedDiner diner;

  const _IncomeCard({required this.diner});

  String _fmt(double v) =>
      v >= 1000 ? '\$${(v / 1000).toStringAsFixed(2)}k' : '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final maintFactor = diner.maintenanceLevel / 100;
    final popFactor   = diner.popularityLevel / 100;
    final effective   = diner.effectiveIncomePerDay;

    return _InfoCard(
      title: '💰 Income Breakdown',
      child: Column(
        children: [
          _BreakdownRow('Base income',
              '${_fmt(diner.baseIncomePerDay)}/day'),
          _BreakdownRow('Maintenance factor',
              '${(maintFactor * 100).round()}%'),
          _BreakdownRow('Popularity factor',
              '${(popFactor * 100).round()}%'),
          const Divider(height: 16),
          _BreakdownRow(
            'Effective daily income',
            '${_fmt(effective)}/day',
            bold: true,
            color: const Color(0xFF2E7D32),
          ),
          if (effective < diner.baseIncomePerDay) ...[
            const SizedBox(height: 6),
            Text(
              'You\'re leaving \$${(diner.baseIncomePerDay - effective).toStringAsFixed(2)}/day on the table.',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _BreakdownRow(this.label, this.value,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 14 : 12,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color ?? (bold ? const Color(0xFF3D2000) : Colors.grey.shade700),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: Color(0xFF3D2000), letterSpacing: 0.3)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String emoji;
  final String? sublabel;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.emoji,
    this.sublabel, required this.enabled,
    this.disabledReason, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFFF9500) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : Colors.grey.shade400)),
              ],
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(sublabel!,
                    style: TextStyle(
                        fontSize: 10,
                        color: enabled
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.grey.shade400)),
              ),
            ],
            if (!enabled && disabledReason != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(disabledReason!,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}