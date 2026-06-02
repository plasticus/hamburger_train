// lib/state/game_provider.dart
// Manages game state and exposes actions the UI can call.

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/order_models.dart';

// Which car + tier unlocks each non-base ingredient
const Map<IngredientType, ({String carId, int tier})> _ingredientRequirements = {
  IngredientType.ketchup:      (carId: 'stock',  tier: 1),
  IngredientType.mayo:         (carId: 'stock',  tier: 2),
  IngredientType.mustard:      (carId: 'stock',  tier: 3),
  IngredientType.pickle:       (carId: 'stock',  tier: 4),
  IngredientType.friedEgg:     (carId: 'stock',  tier: 5),
  IngredientType.bacon:        (carId: 'cooler', tier: 1),
  IngredientType.lettuce:      (carId: 'cooler', tier: 2),
  IngredientType.tomato:       (carId: 'cooler', tier: 3),
  IngredientType.onion:        (carId: 'cooler', tier: 4),
  IngredientType.fancyCheese:  (carId: 'cooler', tier: 5),
};

class GameProvider extends ChangeNotifier {
  GameState _state = GameState.initial();
  final Random _rng = Random();

  // ── Session state ──────────────────────────────────────────────────────────
  BurgerOrder? _currentOrder;
  List<Ingredient> _builtStack = [];
  double _sessionEarnings = 0;
  double _sessionTips = 0;
  int _ordersCompleted = 0;
  bool _sessionActive = false;
  double _lastPenalty = 0;
  String _currentCustomerEmoji = '😊';
  int? _visitingStopNumber;

  // Prep inventory: stock count for each prepped ingredient
  final Map<IngredientType, int> _prepInventory = {
    for (final type in preppedIngredients) type: 0,
  };
  Timer? _restockTimer;

  // Sous chef
  int _burgersMadeByPlayer = 0;
  String? _sousChefMessage; // brief notification for the UI

  // ── Session getters ────────────────────────────────────────────────────────
  BurgerOrder? get currentOrder => _currentOrder;
  List<Ingredient> get builtStack => List.unmodifiable(_builtStack);
  double get sessionEarnings => _sessionEarnings;
  double get sessionTips => _sessionTips;
  int get ordersCompleted => _ordersCompleted;
  bool get sessionActive => _sessionActive;
  double get lastPenalty => _lastPenalty;
  String get currentCustomerEmoji => _currentCustomerEmoji;
  String? get sousChefMessage => _sousChefMessage;

  // ── Dynamic game values (read from car tiers) ──────────────────────────────
  int get dayLengthSeconds {
    final t = _carTier('engine').clamp(0, 3);
    return engineDaySeconds[t];
  }

  int get orderTimerSeconds {
    final t = _carTier('kitchen').clamp(0, 3);
    return kitchenOrderSeconds[t];
  }

  double get tipMaxPercent {
    final t = _carTier('kitchen').clamp(0, 3);
    return kitchenTipPercent[t];
  }

  int get _prepMaxStock {
    final t = _carTier('prep').clamp(0, 3);
    return prepCarStartStock[t];
  }

  int get _sousChefInterval {
    final t = _carTier('crew').clamp(0, 3);
    return crewSousChefInterval[t];
  }

  // ── Ingredient helpers ─────────────────────────────────────────────────────

  bool isIngredientUnlocked(IngredientType type) {
    final req = _ingredientRequirements[type];
    if (req == null) return true; // base ingredient
    return _carTier(req.carId) >= req.tier;
  }

  bool isIngredientAvailable(IngredientType type) {
    if (!isIngredientUnlocked(type)) return false;
    if (preppedIngredients.contains(type)) {
      return (_prepInventory[type] ?? 0) > 0;
    }
    return true;
  }

  int prepStockFor(IngredientType type) => _prepInventory[type] ?? 0;

  /// All ingredients unlocked AND present in this stop's menu — for the tray.
  List<Ingredient> unlockedIngredientsForStop(StopDefinition stop) {
    final Set<IngredientType> usedInMenu = {};
    for (final order in stop.menu) {
      for (final ing in order.stack) {
        usedInMenu.add(ing.type);
      }
    }
    return allIngredients
        .where((ing) => usedInMenu.contains(ing.type) && isIngredientUnlocked(ing.type))
        .toList();
  }

  // ── Game state getters ─────────────────────────────────────────────────────
  GameState get state => _state;
  double get cashOnHand => _state.cashOnHand;
  double get passiveIncomePerDay => _state.passiveIncomePerDay;
  int get dinersOwned => _state.dinersOwned;
  int get currentStopNumber => _state.currentStopNumber;
  String get currentStopName => _state.currentStopName;
  List<TrainCar> get trainCars => _state.trainCars;
  List<OwnedDiner> get ownedDiners => _state.ownedDiners;

  int get dinersNeedingAttention =>
      _state.ownedDiners.where((d) => d.needsAttention).length;

  StopDefinition get currentStop =>
      StopRegistry.forStop(_state.currentStopNumber);

  bool get canBuyDiner => _state.cashOnHand >= currentStop.buyPrice;

  StopDefinition get _activeStop => _visitingStopNumber != null
      ? StopRegistry.forStop(_visitingStopNumber!)
      : currentStop;

  // ── Session management ─────────────────────────────────────────────────────

  void startSession({int? visitingStopNumber}) {
    _visitingStopNumber = visitingStopNumber;
    _sessionEarnings = 0;
    _sessionTips = 0;
    _ordersCompleted = 0;
    _lastPenalty = 0;
    _burgersMadeByPlayer = 0;
    _sousChefMessage = null;
    _sessionActive = true;
    _builtStack = [];

    // Fill prep inventory based on Prep Car tier
    final maxStock = _prepMaxStock;
    for (final type in preppedIngredients) {
      _prepInventory[type] = isIngredientUnlocked(type) ? maxStock : 0;
    }

    // Start restock timer
    _restockTimer?.cancel();
    if (maxStock > 0) {
      _restockTimer = Timer.periodic(
        const Duration(seconds: prepRestockSeconds),
            (_) => _restockPrepIngredients(),
      );
    }

    _dealNextOrder();
    notifyListeners();
  }

  void endSession() {
    _restockTimer?.cancel();
    _restockTimer = null;
    _sessionActive = false;
    _currentOrder = null;
    _builtStack = [];
    _visitingStopNumber = null;
    _sousChefMessage = null;
    notifyListeners();
  }

  void clearSousChefMessage() {
    _sousChefMessage = null;
    // No notifyListeners needed — UI clears it silently
  }

  void _restockPrepIngredients() {
    final maxStock = _prepMaxStock;
    if (maxStock == 0) return;
    bool changed = false;
    for (final type in preppedIngredients) {
      if (isIngredientUnlocked(type) && (_prepInventory[type] ?? 0) < maxStock) {
        _prepInventory[type] = (_prepInventory[type] ?? 0) + 1;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _dealNextOrder() {
    final menu = _activeStop.menu;
    // Only deal orders where all ingredients are unlocked
    final fulfillable = menu.where(_isOrderFulfillable).toList();
    final source = fulfillable.isNotEmpty ? fulfillable : [StopRegistry.fallbackOrder];
    _currentOrder = source[_rng.nextInt(source.length)];
    _currentCustomerEmoji = customerEmojis[_rng.nextInt(customerEmojis.length)];
    _builtStack = [];
  }

  bool _isOrderFulfillable(BurgerOrder order) {
    return order.stack.every((ing) => isIngredientUnlocked(ing.type));
  }

  // ── Ingredient tapping ─────────────────────────────────────────────────────

  StackResult tapIngredient(Ingredient ingredient) {
    if (_currentOrder == null) return StackResult.wrong;

    final expectedIndex = _builtStack.length;
    final expectedStack = _currentOrder!.stack;

    // Wrong ingredient — penalty + full stack reset, return prep ingredients
    if (expectedIndex >= expectedStack.length ||
        ingredient.type != expectedStack[expectedIndex].type) {
      _lastPenalty = _builtStack.length * 0.50;
      if (_lastPenalty > 0) {
        _state = _state.copyWith(
          cashOnHand: (_state.cashOnHand - _lastPenalty).clamp(0, double.infinity),
        );
        // Return any prepped ingredients already on the stack
        for (final ing in _builtStack) {
          if (preppedIngredients.contains(ing.type)) {
            final maxStock = _prepMaxStock;
            final current = _prepInventory[ing.type] ?? 0;
            if (current < maxStock) _prepInventory[ing.type] = current + 1;
          }
        }
      }
      _builtStack = [];
      notifyListeners();
      return StackResult.wrong;
    }

    // Correct ingredient — decrement prep stock if needed
    if (preppedIngredients.contains(ingredient.type)) {
      final current = _prepInventory[ingredient.type] ?? 0;
      if (current > 0) _prepInventory[ingredient.type] = current - 1;
    }

    _builtStack.add(ingredient);

    // Order complete
    if (_builtStack.length == expectedStack.length) {
      _sessionEarnings += _currentOrder!.baseValue;
      _ordersCompleted++;
      _lastPenalty = 0;
      _state = _state.copyWith(
          cashOnHand: _state.cashOnHand + _currentOrder!.baseValue);
      _burgersMadeByPlayer++;
      _checkSousChef();
      _dealNextOrder();
      notifyListeners();
      return StackResult.orderComplete;
    }

    notifyListeners();
    return StackResult.correct;
  }

  void _checkSousChef() {
    final interval = _sousChefInterval;
    if (interval == 0) return; // no crew car
    if (_burgersMadeByPlayer % interval == 0) {
      _triggerSousChef();
    }
  }

  void _triggerSousChef() {
    final menu = _activeStop.menu;
    final fulfillable = menu.where(_isOrderFulfillable).toList();
    if (fulfillable.isEmpty) return;
    final order = fulfillable[_rng.nextInt(fulfillable.length)];
    _sessionEarnings += order.baseValue;
    _state = _state.copyWith(cashOnHand: _state.cashOnHand + order.baseValue);
    _sousChefMessage =
    '🧑‍🍳 Sous Chef made a ${order.name}! +\$${order.baseValue.toStringAsFixed(2)}';
    // Message is cleared by the UI after displaying
  }

  void addTip(double amount) {
    if (amount <= 0) return;
    _sessionTips += amount;
    _sessionEarnings += amount;
    _state = _state.copyWith(cashOnHand: _state.cashOnHand + amount);
    notifyListeners();
  }

  // ── Day advancement ────────────────────────────────────────────────────────

  void advanceDay({required bool isVisit, int? visitedStopNumber}) {
    _restockTimer?.cancel();
    _restockTimer = null;

    final passiveEarned = _state.passiveIncomePerDay;
    final maintDegr = [10.0, 7.0, 4.0, 2.0][_carTier('maintenance_car').clamp(0, 3)];
    final popDegr   = [12.0, 8.0, 5.0, 3.0][_carTier('promo_car').clamp(0, 3)];

    final updatedDiners = _state.ownedDiners.map((diner) {
      final newMaint = (diner.maintenanceLevel - maintDegr).clamp(0.0, 100.0);
      final newPop = isVisit && visitedStopNumber == diner.stopNumber
          ? 100.0
          : (diner.popularityLevel - popDegr).clamp(0.0, 100.0);
      return diner.copyWith(maintenanceLevel: newMaint, popularityLevel: newPop);
    }).toList();

    _state = _state.copyWith(
      cashOnHand: _state.cashOnHand + passiveEarned,
      ownedDiners: updatedDiners,
    );

    _visitingStopNumber = null;
    _sessionActive = false;
    _sessionEarnings = 0;
    _sessionTips = 0;
    _ordersCompleted = 0;
    _lastPenalty = 0;
    _burgersMadeByPlayer = 0;
    _sousChefMessage = null;
    notifyListeners();
  }

  // ── Maintenance ────────────────────────────────────────────────────────────

  bool runMaintenance(int stopNumber) {
    final idx = _state.ownedDiners.indexWhere((d) => d.stopNumber == stopNumber);
    if (idx == -1) return false;
    final diner = _state.ownedDiners[idx];
    if (_state.cashOnHand < diner.maintenanceCost) return false;
    final updated = List<OwnedDiner>.from(_state.ownedDiners);
    updated[idx] = diner.copyWith(maintenanceLevel: 100.0);
    _state = _state.copyWith(
      cashOnHand: _state.cashOnHand - diner.maintenanceCost,
      ownedDiners: updated,
    );
    notifyListeners();
    return true;
  }

  // ── Diner purchase ─────────────────────────────────────────────────────────

  bool purchaseCurrentDiner() {
    final stop = currentStop;
    if (_state.cashOnHand < stop.buyPrice) return false;
    final manager = ManagerProfile.random(_rng);
    final newDiner = OwnedDiner(
      stopNumber: stop.stopNumber, stopName: stop.stopName,
      venueEmoji: stop.venueEmoji, venueType: stop.venueType,
      baseIncomePerDay: stop.incomePerDay,
      managerEmoji: manager.emoji, managerName: manager.name,
    );
    final updatedDiners = [..._state.ownedDiners, newDiner];
    final nextStop = StopRegistry.forStop(stop.stopNumber + 1);
    _state = _state.copyWith(
      cashOnHand: _state.cashOnHand - stop.buyPrice,
      dinersOwned: _state.dinersOwned + 1,
      ownedDiners: updatedDiners,
      currentStopNumber: nextStop.stopNumber,
      currentStopName: nextStop.stopName,
    );
    notifyListeners();
    return true;
  }

  // ── Train upgrades ─────────────────────────────────────────────────────────

  bool upgradeTrainCar(String carId) {
    final cars = List<TrainCar>.from(_state.trainCars);
    final index = cars.indexWhere((c) => c.id == carId);
    if (index == -1) return false;
    final car = cars[index];
    if (car.isMaxed || _state.cashOnHand < (car.nextUpgradeCost ?? 0)) return false;
    cars[index] = car.copyWith(tier: car.tier + 1);
    _state = _state.copyWith(
      cashOnHand: _state.cashOnHand - car.nextUpgradeCost!,
      trainCars: cars,
    );
    notifyListeners();
    return true;
  }

  // ── Dev helpers ────────────────────────────────────────────────────────────

  void devAddCash(double amount) {
    _state = _state.copyWith(cashOnHand: _state.cashOnHand + amount);
    notifyListeners();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _restockTimer?.cancel();
    super.dispose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  int _carTier(String carId) {
    try { return _state.trainCars.firstWhere((c) => c.id == carId).tier; }
    catch (_) { return 0; }
  }
}

enum StackResult { correct, wrong, orderComplete }