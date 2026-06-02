// lib/models/game_state.dart
// The single source of truth for all game data.

import 'dart:math';

// ── Easy-to-tune game constants ───────────────────────────────────────────────
// Engine car: day length in seconds per tier (tier 0 shouldn't occur; matches tier 1)
const List<int> engineDaySeconds = [30, 30, 45, 60];

// Kitchen car: order tip timer seconds and max tip % per tier
const List<int>    kitchenOrderSeconds = [12, 12, 16, 20];
const List<double> kitchenTipPercent   = [0.12, 0.12, 0.16, 0.20];

// Prep car: starting stock per prepped ingredient per tier
const List<int> prepCarStartStock = [0, 2, 4, 6];

// Prep car: restock interval in seconds (how often sous chef preps one more)
const int prepRestockSeconds = 10;

// Crew car: player burgers per 1 sous chef bonus burger, per tier (0 = no sous chef)
const List<int> crewSousChefInterval = [0, 5, 4, 3];

// ── Train Car ─────────────────────────────────────────────────────────────────

class TrainCar {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final int tier;
  final int maxTier;
  final List<int> upgradeCosts;

  const TrainCar({
    required this.id, required this.emoji, required this.name,
    required this.description, required this.tier, required this.maxTier,
    required this.upgradeCosts,
  });

  bool get isLocked  => tier == 0;
  bool get isMaxed   => tier >= maxTier;
  int? get nextUpgradeCost => isMaxed ? null : upgradeCosts[tier];

  TrainCar copyWith({int? tier}) => TrainCar(
    id: id, emoji: emoji, name: name, description: description,
    tier: tier ?? this.tier, maxTier: maxTier, upgradeCosts: upgradeCosts,
  );
}

// ── Manager Profile ───────────────────────────────────────────────────────────

class ManagerProfile {
  final String emoji;
  final String name;

  const ManagerProfile(this.emoji, this.name);

  static const _profiles = [
    ManagerProfile('😄', 'Bud Grillmaster'),  ManagerProfile('👩‍🍳', 'Patty Melt'),
    ManagerProfile('🧔', 'Big Earl'),          ManagerProfile('👵', 'Grandma Jo'),
    ManagerProfile('🤠', 'Tex McGee'),         ManagerProfile('😎', 'Cool Rick'),
    ManagerProfile('🤓', 'Norbert Crumbs'),    ManagerProfile('👮', 'Officer Cheese'),
    ManagerProfile('🧑‍🌾', 'Farmer Dale'),     ManagerProfile('🧑‍🔬', 'Doc Saucy'),
    ManagerProfile('👸', 'Queen Brioche'),     ManagerProfile('🤵', 'Butler Benny'),
    ManagerProfile('🎅', 'Nick Pattyson'),     ManagerProfile('🧙', 'The Grill Wizard'),
    ManagerProfile('🦸', 'Captain Condiment'),
  ];

  static ManagerProfile random(Random rng) =>
      _profiles[rng.nextInt(_profiles.length)];
}

// ── Owned Diner ───────────────────────────────────────────────────────────────

class OwnedDiner {
  final int stopNumber;
  final String stopName;
  final String venueEmoji;
  final String venueType;
  final double baseIncomePerDay;
  final String managerEmoji;
  final String managerName;
  final double maintenanceLevel;
  final double popularityLevel;

  const OwnedDiner({
    required this.stopNumber, required this.stopName, required this.venueEmoji,
    required this.venueType, required this.baseIncomePerDay,
    required this.managerEmoji, required this.managerName,
    this.maintenanceLevel = 100.0, this.popularityLevel = 100.0,
  });

  double get effectiveIncomePerDay =>
      baseIncomePerDay * (maintenanceLevel / 100) * (popularityLevel / 100);

  double get maintenanceCost => stopNumber * 45.0;

  bool get needsAttention => maintenanceLevel < 60 || popularityLevel < 50;

  String get maintenanceStatusLabel {
    if (maintenanceLevel >= 80) return 'Good ✅';
    if (maintenanceLevel >= 50) return 'Fair 🟡';
    if (maintenanceLevel >= 25) return 'Poor 🟠';
    return 'Critical 🔴';
  }

  String get popularityStatusLabel {
    if (popularityLevel >= 80) return 'Buzzing 🌟';
    if (popularityLevel >= 50) return 'Steady 😊';
    if (popularityLevel >= 25) return 'Slipping 😕';
    return 'Forgotten 😢';
  }

  OwnedDiner copyWith({double? maintenanceLevel, double? popularityLevel}) =>
      OwnedDiner(
        stopNumber: stopNumber, stopName: stopName, venueEmoji: venueEmoji,
        venueType: venueType, baseIncomePerDay: baseIncomePerDay,
        managerEmoji: managerEmoji, managerName: managerName,
        maintenanceLevel: maintenanceLevel ?? this.maintenanceLevel,
        popularityLevel: popularityLevel ?? this.popularityLevel,
      );
}

// ── Game State ────────────────────────────────────────────────────────────────

class GameState {
  final double cashOnHand;
  final int dinersOwned;
  final int currentStopNumber;
  final String currentStopName;
  final List<TrainCar> trainCars;
  final List<OwnedDiner> ownedDiners;

  GameState({
    required this.cashOnHand, required this.dinersOwned,
    required this.currentStopNumber, required this.currentStopName,
    required this.trainCars, required this.ownedDiners,
  });

  double get passiveIncomePerDay =>
      ownedDiners.fold(0.0, (sum, d) => sum + d.effectiveIncomePerDay);

  GameState copyWith({
    double? cashOnHand, int? dinersOwned, int? currentStopNumber,
    String? currentStopName, List<TrainCar>? trainCars, List<OwnedDiner>? ownedDiners,
  }) => GameState(
    cashOnHand: cashOnHand ?? this.cashOnHand,
    dinersOwned: dinersOwned ?? this.dinersOwned,
    currentStopNumber: currentStopNumber ?? this.currentStopNumber,
    currentStopName: currentStopName ?? this.currentStopName,
    trainCars: trainCars ?? this.trainCars,
    ownedDiners: ownedDiners ?? this.ownedDiners,
  );

  static GameState initial() => GameState(
    cashOnHand: 42.50, dinersOwned: 0,
    currentStopNumber: 1, currentStopName: 'Bun Hollow',
    trainCars: _initialTrainCars(), ownedDiners: [],
  );

  static List<TrainCar> _initialTrainCars() => [
    const TrainCar(
      id: 'engine', emoji: '🚂', name: 'The Engine',
      description: 'More speed = more time. Extends your work day.',
      tier: 1, maxTier: 3, upgradeCosts: [0, 500, 2000],
    ),
    const TrainCar(
      id: 'kitchen', emoji: '🍳', name: 'Kitchen Car',
      description: 'More time per order + better tip potential.',
      tier: 1, maxTier: 3, upgradeCosts: [0, 300, 1200],
    ),
    // Stock Car: unlocks ketchup→mayo→mustard→pickle→fried egg (tiers 1-5)
    const TrainCar(
      id: 'stock', emoji: '📦', name: 'Stock Car',
      description: 'Dry goods. Each tier unlocks a new ingredient.',
      tier: 0, maxTier: 5, upgradeCosts: [150, 350, 700, 1500, 3500],
    ),
    // Cooler Car: unlocks bacon→lettuce→tomato→onion→fancy cheese (tiers 1-5)
    const TrainCar(
      id: 'cooler', emoji: '🧊', name: 'Cooler Car',
      description: 'Always fresh, never frozen. Each tier unlocks a new ingredient.',
      tier: 0, maxTier: 5, upgradeCosts: [250, 550, 1000, 2000, 5000],
    ),
    const TrainCar(
      id: 'prep', emoji: '🥗', name: 'Prep Car',
      description: 'Sous chef preps more per ingredient. Higher = more starting stock.',
      tier: 0, maxTier: 3, upgradeCosts: [400, 1500, 5000],
    ),
    const TrainCar(
      id: 'orders', emoji: '📋', name: 'Order Car',
      description: 'Peek at the upcoming order queue.',
      tier: 0, maxTier: 2, upgradeCosts: [500, 2000],
    ),
    const TrainCar(
      id: 'crew', emoji: '🏠', name: 'Crew Car',
      description: 'Your sous chef makes bonus burgers. Higher = more often.',
      tier: 0, maxTier: 3, upgradeCosts: [800, 3000, 10000],
    ),
    const TrainCar(
      id: 'maintenance_car', emoji: '🔧', name: 'Maintenance Car',
      description: 'Repair crew on board. Joints stay in shape longer.',
      tier: 0, maxTier: 3, upgradeCosts: [350, 1200, 3500],
    ),
    const TrainCar(
      id: 'promo_car', emoji: '📣', name: 'Promo Car',
      description: 'Keeps the buzz alive. Popularity drops slower.',
      tier: 0, maxTier: 3, upgradeCosts: [450, 1500, 4500],
    ),
  ];
}