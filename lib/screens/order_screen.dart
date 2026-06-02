// lib/screens/order_screen.dart
// 60-second day session. Build burger orders, earn tips for speed.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../state/game_provider.dart';
import '../models/order_models.dart';

class OrderScreen extends StatefulWidget {
  final bool isVisit;
  final int? visitStopNumber;

  const OrderScreen({super.key, this.isVisit = false, this.visitStopNumber});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin {
  // Captured at session start from car tiers — don't change mid-session
  late int _daySecondsTotal;
  late int _orderSecondsTotal;
  late double _tipMaxPercent;

  int  _daySecondsRemaining   = 60;
  int  _orderSecondsRemaining = 20;
  Timer? _timer;
  bool _dayComplete = false;
  bool _buying      = false;
  String? _penaltyText;

  late AnimationController _shakeController;
  late Animation<double>   _shakeAnimation;
  late AnimationController _hopController;
  late Animation<double>   _hopAnimation;
  late ConfettiController  _confettiController;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _shakeAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut));

    _hopController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -20.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: -20.0, end: 4.0),  weight: 25),
      TweenSequenceItem(tween: Tween(begin: 4.0,   end: 0.0),  weight: 40),
    ]).animate(CurvedAnimation(parent: _hopController, curve: Curves.easeOut));

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameProvider>();
      // Capture car-based values at session start
      _daySecondsTotal   = game.dayLengthSeconds;
      _orderSecondsTotal = game.orderTimerSeconds;
      _tipMaxPercent     = game.tipMaxPercent;
      _daySecondsRemaining   = _daySecondsTotal;
      _orderSecondsRemaining = _orderSecondsTotal;

      game.startSession(visitingStopNumber: widget.visitStopNumber);
      _startTimer();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _hopController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_daySecondsRemaining > 0) {
          _daySecondsRemaining--;
          if (_orderSecondsRemaining > 0) _orderSecondsRemaining--;
        } else {
          t.cancel();
          _dayComplete = true;
        }
      });
    });
  }

  void _onIngredientTap(Ingredient ingredient) {
    if (_dayComplete || _buying) return;
    final game  = context.read<GameProvider>();
    final order = game.currentOrder;
    if (order == null) return;
    if (!game.isIngredientAvailable(ingredient.type)) return;

    final orderValue = order.baseValue;
    final result = game.tapIngredient(ingredient);
    HapticFeedback.lightImpact();

    switch (result) {
      case StackResult.correct:
        break;
      case StackResult.wrong:
        _shakeController.forward(from: 0);
        HapticFeedback.heavyImpact();
        final penalty = game.lastPenalty;
        if (penalty > 0) {
          setState(() => _penaltyText =
          '-\$${penalty.toStringAsFixed(2)} in wasted supplies 😬');
          Future.delayed(const Duration(milliseconds: 2000),
                  () { if (mounted) setState(() => _penaltyText = null); });
        }
        break;
      case StackResult.orderComplete:
        final tipRatio  = _orderSecondsRemaining / _orderSecondsTotal;
        final tipAmount = orderValue * _tipMaxPercent * tipRatio;
        if (tipAmount > 0.01) game.addTip(tipAmount);
        setState(() => _orderSecondsRemaining = _orderSecondsTotal);
        _hopController.forward(from: 0);
        // Show sous chef message if one fired
        final msg = game.sousChefMessage;
        if (msg != null) {
          game.clearSousChefMessage();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg),
                backgroundColor: const Color(0xFF7B5EA7),
                duration: const Duration(seconds: 2)),
          );
        }
        break;
    }
  }

  void _onBuyDiner() {
    final game = context.read<GameProvider>();
    if (!game.purchaseCurrentDiner()) return;
    setState(() => _buying = true);
    _confettiController.play();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        game.advanceDay(isVisit: false);
        Navigator.of(context).pop();
      }
    });
  }

  void _onAdvanceDay() {
    context.read<GameProvider>().advanceDay(
      isVisit: widget.isVisit,
      visitedStopNumber: widget.visitStopNumber,
    );
    Navigator.of(context).pop();
  }

  Color get _dayTimerColor {
    final ratio = _daySecondsRemaining / (_daySecondsTotal > 0 ? _daySecondsTotal : 1);
    if (ratio > 0.5) return const Color(0xFF4CAF50);
    if (ratio > 0.2) return const Color(0xFFFF9500);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameProvider>();
    final stop  = widget.isVisit && widget.visitStopNumber != null
        ? StopRegistry.forStop(widget.visitStopNumber!)
        : game.currentStop;
    final order = game.currentOrder;
    final built = game.builtStack;
    final unlockedIngredients = game.unlockedIngredientsForStop(stop);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_buying) {
          _timer?.cancel();
          game.endSession();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ── Ad banner ────────────────────────────────────────
                  Container(
                    width: double.infinity, height: 50,
                    color: const Color(0xFFE0E0E0),
                    child: const Center(
                      child: Text('📢 Ad Banner',
                          style: TextStyle(color: Colors.grey, fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ),
                  ),

                  // ── Top bar ──────────────────────────────────────────
                  _TopBar(
                    stop: stop,
                    sessionEarnings: game.sessionEarnings,
                    sessionTips: game.sessionTips,
                    onBack: () {
                      _timer?.cancel();
                      game.endSession();
                      Navigator.of(context).pop();
                    },
                  ),

                  // ── Day timer ────────────────────────────────────────
                  _DayTimerBar(
                    secondsRemaining: _daySecondsRemaining,
                    totalSeconds: _daySecondsTotal > 0 ? _daySecondsTotal : 1,
                    color: _dayTimerColor,
                  ),

                  // ── Buy progress (current stop only) ─────────────────
                  if (!widget.isVisit)
                    _BuyProgressBar(
                        cashOnHand: game.cashOnHand,
                        buyPrice: stop.buyPrice),

                  // ── Penalty banner ───────────────────────────────────
                  if (_penaltyText != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      color: const Color(0xFFFFEBEE),
                      child: Text(_penaltyText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFFE53935), fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),

                  // ── Customer + order area ────────────────────────────
                  Expanded(
                    child: order == null
                        ? const Center(child: Text('🍔',
                        style: TextStyle(fontSize: 48)))
                        : _CustomerOrderArea(
                      order: order,
                      builtStack: built,
                      customerEmoji: game.currentCustomerEmoji,
                      hopAnimation: _hopAnimation,
                      shakeAnimation: _shakeAnimation,
                    ),
                  ),

                  // ── Tip timer ────────────────────────────────────────
                  _TipTimerBar(
                    secondsRemaining: _orderSecondsRemaining,
                    totalSeconds: _orderSecondsTotal > 0 ? _orderSecondsTotal : 1,
                    tipMaxPercent: _tipMaxPercent,
                  ),

                  // ── Ingredient tray ──────────────────────────────────
                  _IngredientTray(
                    ingredients: unlockedIngredients,
                    builtStack: built,
                    currentOrder: order,
                    onTap: _onIngredientTap,
                    prepStockFor: game.prepStockFor,
                    isAvailable: game.isIngredientAvailable,
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),

            // ── Day summary overlay ──────────────────────────────────
            if (_dayComplete && !_buying)
              _DaySummaryOverlay(
                stop: stop,
                ordersCompleted: game.ordersCompleted,
                sessionEarnings: game.sessionEarnings - game.sessionTips,
                tips: game.sessionTips,
                passiveIncome: game.passiveIncomePerDay,
                cashOnHand: game.cashOnHand,
                canBuy: game.canBuyDiner && !widget.isVisit,
                isVisit: widget.isVisit,
                onAdvanceDay: _onAdvanceDay,
                onBuy: _onBuyDiner,
              ),

            // ── Confetti ─────────────────────────────────────────────
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 45,
                colors: const [
                  Color(0xFFFF9500), Color(0xFF4CAF50),
                  Color(0xFF2196F3), Color(0xFFE91E63), Color(0xFFFFEB3B),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final StopDefinition stop;
  final double sessionEarnings;
  final double sessionTips;
  final VoidCallback onBack;

  const _TopBar({required this.stop, required this.sessionEarnings,
    required this.sessionTips, required this.onBack});

  String _fmt(double v) =>
      v >= 1000 ? '\$${(v / 1000).toStringAsFixed(1)}k' : '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300)),
              child: const Text('⬅️', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${stop.venueEmoji} ${stop.stopName}',
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w800, color: Color(0xFF3D2000))),
                Text(stop.venueType,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(sessionEarnings),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32))),
              Text('incl. \$${sessionTips.toStringAsFixed(2)} tips',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Day Timer Bar ─────────────────────────────────────────────────────────────

class _DayTimerBar extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final Color color;

  const _DayTimerBar({required this.secondsRemaining,
    required this.totalSeconds, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text('🌅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            child: Text('${secondsRemaining}s',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: secondsRemaining / totalSeconds,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('DAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: Colors.grey.shade500, letterSpacing: 1)),
        ],
      ),
    );
  }
}

// ── Buy Progress Bar ──────────────────────────────────────────────────────────

class _BuyProgressBar extends StatelessWidget {
  final double cashOnHand;
  final double buyPrice;

  const _BuyProgressBar({required this.cashOnHand, required this.buyPrice});

  String _fmt(double v) =>
      v >= 1000 ? '\$${(v / 1000).toStringAsFixed(1)}k' : '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final progress = (cashOnHand / buyPrice).clamp(0.0, 1.0);
    final canBuy   = cashOnHand >= buyPrice;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Text('🏠 ${_fmt(cashOnHand)} / ${_fmt(buyPrice)}',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: canBuy ? const Color(0xFF2E7D32) : Colors.grey.shade600)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress, minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                    canBuy ? const Color(0xFF4CAF50) : const Color(0xFFFF9500)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer Order Area ───────────────────────────────────────────────────────

class _CustomerOrderArea extends StatelessWidget {
  final BurgerOrder order;
  final List<Ingredient> builtStack;
  final String customerEmoji;
  final Animation<double> hopAnimation;
  final Animation<double> shakeAnimation;

  const _CustomerOrderArea({required this.order, required this.builtStack,
    required this.customerEmoji, required this.hopAnimation,
    required this.shakeAnimation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: hopAnimation,
              builder: (_, child) => Transform.translate(
                  offset: Offset(0, hopAnimation.value), child: child),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(customerEmoji, style: const TextStyle(fontSize: 38)),
                  const SizedBox(height: 2),
                  Text(order.name,
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: Color(0xFF3D2000)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  ...order.stack.reversed.map((ing) =>
                      _IngredientLayer(emoji: ing.emoji, isBuilt: false, isTarget: true)),
                  const SizedBox(height: 4),
                  Text('\$${order.baseValue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32))),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 200, color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: AnimatedBuilder(
              animation: shakeAnimation,
              builder: (_, child) {
                final dx = math.sin(shakeAnimation.value * math.pi * 5) * 6;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('BUILDING', style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: Colors.grey.shade500,
                      letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(
                    builtStack.isEmpty ? 'Start tapping!'
                        : '${builtStack.length}/${order.stack.length}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: builtStack.isEmpty
                            ? Colors.grey.shade400 : const Color(0xFF3D2000)),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(order.stack.length, (i) {
                    final rev     = order.stack.length - 1 - i;
                    final isBuilt = rev < builtStack.length;
                    final ing     = isBuilt ? builtStack[rev] : order.stack[rev];
                    return _IngredientLayer(
                        emoji: ing.emoji, isBuilt: isBuilt, isTarget: false);
                  }),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ingredient Layer ──────────────────────────────────────────────────────────

class _IngredientLayer extends StatelessWidget {
  final String emoji;
  final bool isBuilt;
  final bool isTarget;

  const _IngredientLayer({required this.emoji, required this.isBuilt, required this.isTarget});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isTarget ? Colors.orange.withValues(alpha: 0.06)
            : isBuilt ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTarget ? Colors.orange.withValues(alpha: 0.2)
              : isBuilt ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Text(isBuilt || isTarget ? emoji : '⬜',
          style: TextStyle(fontSize: 22,
              color: isBuilt || isTarget ? null : Colors.transparent),
          textAlign: TextAlign.center),
    );
  }
}

// ── Tip Timer Bar ─────────────────────────────────────────────────────────────

class _TipTimerBar extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final double tipMaxPercent;

  const _TipTimerBar({required this.secondsRemaining,
    required this.totalSeconds, required this.tipMaxPercent});

  @override
  Widget build(BuildContext context) {
    final ratio    = secondsRemaining / totalSeconds;
    final tipPct   = (ratio * tipMaxPercent * 100).round();
    final tipColor = ratio > 0.5 ? const Color(0xFF4CAF50)
        : ratio > 0.25 ? const Color(0xFFFF9500)
        : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text('⚡ Tip +$tipPct%', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w700, color: tipColor)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio, minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(tipColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ingredient Tray ───────────────────────────────────────────────────────────

class _IngredientTray extends StatelessWidget {
  final List<Ingredient> ingredients;
  final List<Ingredient> builtStack;
  final BurgerOrder? currentOrder;
  final void Function(Ingredient) onTap;
  final int Function(IngredientType) prepStockFor;
  final bool Function(IngredientType) isAvailable;

  const _IngredientTray({
    required this.ingredients, required this.builtStack,
    required this.currentOrder, required this.onTap,
    required this.prepStockFor, required this.isAvailable,
  });

  bool _isNextCorrect(Ingredient ingredient) {
    if (currentOrder == null) return false;
    final nextIndex = builtStack.length;
    if (nextIndex >= currentOrder!.stack.length) return false;
    return currentOrder!.stack[nextIndex].type == ingredient.type;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD580), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8, runSpacing: 8,
        children: ingredients.map((ing) {
          final available = isAvailable(ing.type);
          final isNext    = available && _isNextCorrect(ing);
          final needsPrep = preppedIngredients.contains(ing.type);
          final stock     = needsPrep ? prepStockFor(ing.type) : -1;

          return GestureDetector(
            onTap: available ? () => onTap(ing) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 58, height: 64,
              decoration: BoxDecoration(
                color: !available ? Colors.grey.shade100
                    : isNext ? const Color(0xFFE8F5E9)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: !available ? Colors.grey.shade300
                        : isNext ? const Color(0xFF4CAF50)
                        : Colors.grey.shade200,
                    width: isNext ? 2 : 1),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: available ? 0.06 : 0.02),
                    blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ing.emoji,
                      style: TextStyle(fontSize: 22,
                          color: available ? null : Colors.grey.shade400)),
                  // Stock badge for prepped ingredients
                  if (needsPrep)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: stock > 0
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stock > 0 ? '×$stock' : '⏳',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: stock > 0
                              ? const Color(0xFF2E7D32)
                              : Colors.red.shade400,
                        ),
                      ),
                    )
                  else
                    Text(ing.name,
                        style: TextStyle(fontSize: 7,
                            color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Day Summary Overlay ───────────────────────────────────────────────────────

class _DaySummaryOverlay extends StatelessWidget {
  final StopDefinition stop;
  final int ordersCompleted;
  final double sessionEarnings;
  final double tips;
  final double passiveIncome;
  final double cashOnHand;
  final bool canBuy;
  final bool isVisit;
  final VoidCallback onAdvanceDay;
  final VoidCallback onBuy;

  const _DaySummaryOverlay({
    required this.stop, required this.ordersCompleted,
    required this.sessionEarnings, required this.tips,
    required this.passiveIncome, required this.cashOnHand,
    required this.canBuy, required this.isVisit,
    required this.onAdvanceDay, required this.onBuy,
  });

  String _fmt(double v) =>
      v >= 1000 ? '\$${(v / 1000).toStringAsFixed(1)}k' : '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isVisit ? '⭐' : '🌅', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              Text(isVisit ? 'Day Well Spent!' : 'Day Complete!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: Color(0xFF3D2000))),
              if (isVisit) ...[
                const SizedBox(height: 6),
                Text('Popularity at ${stop.stopName} restored to 100%! 🎉',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              _Row('Orders filled', '$ordersCompleted'),
              _Row('Earned', _fmt(sessionEarnings)),
              _Row('Tips', _fmt(tips)),
              if (passiveIncome > 0)
                _Row('Passive income', '+${_fmt(passiveIncome)}',
                    color: Colors.blue.shade700),
              const Divider(height: 20),
              _Row('Cash on hand', _fmt(cashOnHand), bold: true,
                  color: const Color(0xFF2E7D32)),
              const SizedBox(height: 16),
              if (canBuy) ...[
                _ActionButton(
                  label: '🎉 Buy ${stop.stopName}! (${_fmt(stop.buyPrice)})',
                  color: const Color(0xFF4CAF50), onTap: onBuy,
                ),
                const SizedBox(height: 8),
              ],
              _ActionButton(
                label: isVisit ? '🚂 Head Back' : '🚂 Next Day',
                color: const Color(0xFFFF9500), onTap: onAdvanceDay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;

  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 14 : 12,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color ?? (bold ? const Color(0xFF3D2000) : Colors.grey.shade700),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}