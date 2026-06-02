// lib/models/order_models.dart
// Data models for ingredients, burger orders, and stop definitions.

// ── Customer emojis ───────────────────────────────────────────────────────────

const List<String> customerEmojis = [
  '😊', '😄', '😋', '🤤', '😍', '🧐', '🤠', '😎',
  '🥸', '🤓', '👮', '👷', '🧑‍🌾', '🎅', '🤵', '🧙',
  '🤴', '👸', '🦸', '🧑‍🚀', '🧑‍💼', '🕵️', '🤶', '🧑‍🍳',
];

// ── Ingredient types ──────────────────────────────────────────────────────────
// Base (always available): bottomBun, topBun, patty, cheese
// Stock Car tier 1-5:      ketchup, mayo, mustard, pickle, friedEgg
// Cooler Car tier 1-5:     bacon, lettuce, tomato, onion, fancyCheese

enum IngredientType {
  // Base — always available, no prep
  bottomBun, topBun, patty, cheese,
  // Stock Car unlocks — dry goods
  ketchup, mayo, mustard, pickle, friedEgg,
  // Cooler Car unlocks — refrigerated
  bacon, lettuce, tomato, onion, fancyCheese,
}

// Which ingredients require prep (managed by Prep Car)
const Set<IngredientType> preppedIngredients = {
  IngredientType.pickle,
  IngredientType.friedEgg,
  IngredientType.lettuce,
  IngredientType.tomato,
  IngredientType.onion,
  IngredientType.fancyCheese,
};

// ── Ingredient ────────────────────────────────────────────────────────────────

class Ingredient {
  final IngredientType type;
  final String emoji;
  final String name;

  const Ingredient({required this.type, required this.emoji, required this.name});

  // Base
  static const bottomBun  = Ingredient(type: IngredientType.bottomBun,  emoji: '🍞', name: 'Bottom Bun');
  static const topBun     = Ingredient(type: IngredientType.topBun,     emoji: '🍔', name: 'Top Bun');
  static const patty      = Ingredient(type: IngredientType.patty,      emoji: '🥩', name: 'Patty');
  static const cheese     = Ingredient(type: IngredientType.cheese,     emoji: '🧀', name: 'Cheese');
  // Stock Car
  static const ketchup    = Ingredient(type: IngredientType.ketchup,    emoji: '🔴', name: 'Ketchup');
  static const mayo       = Ingredient(type: IngredientType.mayo,       emoji: '🤍', name: 'Mayo');
  static const mustard    = Ingredient(type: IngredientType.mustard,    emoji: '🟡', name: 'Mustard');
  static const pickle     = Ingredient(type: IngredientType.pickle,     emoji: '🥒', name: 'Pickle');
  static const friedEgg   = Ingredient(type: IngredientType.friedEgg,   emoji: '🍳', name: 'Fried Egg');
  // Cooler Car
  static const bacon      = Ingredient(type: IngredientType.bacon,      emoji: '🥓', name: 'Bacon');
  static const lettuce    = Ingredient(type: IngredientType.lettuce,    emoji: '🥬', name: 'Lettuce');
  static const tomato     = Ingredient(type: IngredientType.tomato,     emoji: '🍅', name: 'Tomato');
  static const onion      = Ingredient(type: IngredientType.onion,      emoji: '🧅', name: 'Onion');
  static const fancyCheese = Ingredient(type: IngredientType.fancyCheese, emoji: '💛', name: 'Fancy Cheese');
}

// Full ordered list used for tray display
const List<Ingredient> allIngredients = [
  Ingredient.bottomBun, Ingredient.patty,   Ingredient.cheese,  Ingredient.topBun,
  Ingredient.ketchup,   Ingredient.mayo,    Ingredient.mustard, Ingredient.pickle,  Ingredient.friedEgg,
  Ingredient.bacon,     Ingredient.lettuce, Ingredient.tomato,  Ingredient.onion,   Ingredient.fancyCheese,
];

// ── Burger Order ──────────────────────────────────────────────────────────────

class BurgerOrder {
  final String name;
  final List<Ingredient> stack;
  final double baseValue;

  const BurgerOrder({required this.name, required this.stack, required this.baseValue});
}

// A guaranteed fallback order — only base ingredients, always fulfillable
const _fallbackOrder = BurgerOrder(
  name: 'The Plain Jane',
  stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.topBun],
  baseValue: 4.00,
);

// ── Stop Definition ───────────────────────────────────────────────────────────

class StopDefinition {
  final int stopNumber;
  final String stopName;
  final String venueEmoji;
  final String venueType;
  final double buyPrice;
  final double incomePerDay;
  final String tagline;
  final String lore;
  final List<BurgerOrder> menu;

  const StopDefinition({
    required this.stopNumber, required this.stopName, required this.venueEmoji,
    required this.venueType, required this.buyPrice, required this.incomePerDay,
    required this.tagline, required this.lore, required this.menu,
  });
}

// ── Stop Registry ─────────────────────────────────────────────────────────────

class StopRegistry {
  static const List<StopDefinition> all = [
    _stop1, _stop2, _stop3, _stop4, _stop5,
    _stop6, _stop7, _stop8, _stop9, _stop10,
  ];

  static StopDefinition forStop(int number) {
    try { return all.firstWhere((s) => s.stopNumber == number); }
    catch (_) { return all.last; }
  }

  static BurgerOrder fallbackOrder = _fallbackOrder;
}

// ── Stop 1 — Bun Hollow ───────────────────────────────────────────────────────
const _stop1 = StopDefinition(
  stopNumber: 1, stopName: 'Bun Hollow', venueEmoji: '🛖',
  venueType: 'Burger Stand', buyPrice: 120, incomePerDay: 18,
  tagline: 'Where every bite tells a story.',
  lore: 'A sleepy riverside town where locals take their burgers very seriously. The Bun Hollow stand has been here since 1967, and the regulars have strong opinions about pickle placement.',
  menu: [
    BurgerOrder(name: 'The Plain Jane',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.topBun], baseValue: 4.00),
    BurgerOrder(name: 'The Cheesy',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.topBun], baseValue: 5.50),
  ],
);

// ── Stop 2 — Gristle Creek ────────────────────────────────────────────────────
const _stop2 = StopDefinition(
  stopNumber: 2, stopName: 'Gristle Creek', venueEmoji: '🏚️',
  venueType: 'Burger Stand', buyPrice: 200, incomePerDay: 30,
  tagline: 'Rugged town, rugged appetites.',
  lore: 'A former mining town that never quite gave up. The creek runs orange from the old iron works, but the beef is 100% local — and somehow that gives it character.',
  menu: [
    BurgerOrder(name: 'The Plain Jane',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.topBun], baseValue: 4.00),
    BurgerOrder(name: 'The Cheesy',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.topBun], baseValue: 5.50),
    BurgerOrder(name: 'Ketchup Classic',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.ketchup, Ingredient.topBun], baseValue: 6.50),
  ],
);

// ── Stop 3 — Sauceton ─────────────────────────────────────────────────────────
const _stop3 = StopDefinition(
  stopNumber: 3, stopName: 'Sauceton', venueEmoji: '🏠',
  venueType: 'Burger Joint', buyPrice: 400, incomePerDay: 55,
  tagline: 'The sauce capital of the heartland.',
  lore: 'Sauceton takes fierce pride in its sauce recipes, passed down through three generations of condiment enthusiasts. Ordering a dry burger here is considered a personal insult.',
  menu: [
    BurgerOrder(name: 'The Cheesy',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.topBun], baseValue: 5.50),
    BurgerOrder(name: 'Sauceton Special',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.ketchup, Ingredient.topBun], baseValue: 8.00),
    BurgerOrder(name: 'The Mayo Run',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.mayo, Ingredient.topBun], baseValue: 8.00),
  ],
);

// ── Stop 4 — Patty Flats ──────────────────────────────────────────────────────
const _stop4 = StopDefinition(
  stopNumber: 4, stopName: 'Patty Flats', venueEmoji: '🏪',
  venueType: 'Burger Joint', buyPrice: 700, incomePerDay: 90,
  tagline: 'Flat land, stacked burgers.',
  lore: 'Windswept plains and premium beef ranches as far as the eye can see. Locals expect a double. Order a single and watch what happens.',
  menu: [
    BurgerOrder(name: 'The Double Down',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.patty, Ingredient.cheese, Ingredient.topBun], baseValue: 9.00),
    BurgerOrder(name: 'The Mustard Belt',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.mustard, Ingredient.topBun], baseValue: 8.50),
    BurgerOrder(name: 'The Saucy Double',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.patty, Ingredient.cheese, Ingredient.ketchup, Ingredient.topBun], baseValue: 10.50),
  ],
);

// ── Stop 5 — Cheeseburg ───────────────────────────────────────────────────────
const _stop5 = StopDefinition(
  stopNumber: 5, stopName: 'Cheeseburg', venueEmoji: '🏬',
  venueType: 'Diner', buyPrice: 1200, incomePerDay: 150,
  tagline: "It's not just a name, it's a calling.",
  lore: "Yes, it's really called Cheeseburg. The annual cheese festival brings 40,000 visitors each August. The diner has a nine-month waiting list and the mayor eats here twice a day.",
  menu: [
    BurgerOrder(name: 'The Double Down',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.patty, Ingredient.cheese, Ingredient.topBun], baseValue: 9.00),
    BurgerOrder(name: 'The Baconer',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.bacon, Ingredient.cheese, Ingredient.topBun], baseValue: 11.00),
    BurgerOrder(name: 'The Bacon Bomb',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.bacon, Ingredient.cheese, Ingredient.ketchup, Ingredient.topBun], baseValue: 13.00),
  ],
);

// ── Stop 6 — Toastville ───────────────────────────────────────────────────────
const _stop6 = StopDefinition(
  stopNumber: 6, stopName: 'Toastville', venueEmoji: '🏢',
  venueType: 'Diner', buyPrice: 2000, incomePerDay: 240,
  tagline: 'Golden from the outside, warm on the inside.',
  lore: 'Toastville grew up around a bread factory that burned down in 1985. They rebuilt, lost it again, and leaned in. The buns are baked fresh every two hours and they will tell you about it.',
  menu: [
    BurgerOrder(name: 'The Cheesy',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.topBun], baseValue: 5.50),
    BurgerOrder(name: 'The Pickle Stack',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.ketchup, Ingredient.pickle, Ingredient.topBun], baseValue: 11.00),
    BurgerOrder(name: 'Garden Fresh',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.lettuce, Ingredient.tomato, Ingredient.topBun], baseValue: 11.50),
  ],
);

// ── Stop 7 — Melton ───────────────────────────────────────────────────────────
const _stop7 = StopDefinition(
  stopNumber: 7, stopName: 'Melton', venueEmoji: '🏨',
  venueType: 'Trendy Burger Bar', buyPrice: 3500, incomePerDay: 380,
  tagline: 'Where craft meets ketchup.',
  lore: 'Melton discovered artisanal everything fifteen years ago and never looked back. Burgers come with handwritten ingredient cards and a suggested beverage pairing. Unironically.',
  menu: [
    BurgerOrder(name: 'The Artisan',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.lettuce, Ingredient.tomato, Ingredient.topBun], baseValue: 13.00),
    BurgerOrder(name: 'The Craft Special',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.patty, Ingredient.bacon, Ingredient.cheese, Ingredient.topBun], baseValue: 15.00),
    BurgerOrder(name: 'The Soirée',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.mayo, Ingredient.lettuce, Ingredient.pickle, Ingredient.topBun], baseValue: 13.50),
  ],
);

// ── Stop 8 — New Grillsburg ───────────────────────────────────────────────────
const _stop8 = StopDefinition(
  stopNumber: 8, stopName: 'New Grillsburg', venueEmoji: '🏦',
  venueType: 'Trendy Burger Bar', buyPrice: 6000, incomePerDay: 600,
  tagline: 'Old-school technique, new-school attitude.',
  lore: 'New Grillsburg rose from the ashes of Old Grillsburg, which burned down spectacularly in the Great Beef Fire of 1992. This city has a chip on its shoulder and something to prove.',
  menu: [
    BurgerOrder(name: 'The Comeback',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.patty, Ingredient.bacon, Ingredient.cheese, Ingredient.ketchup, Ingredient.topBun], baseValue: 16.00),
    BurgerOrder(name: 'Old Faithful',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.onion, Ingredient.pickle, Ingredient.topBun], baseValue: 13.00),
    BurgerOrder(name: 'The Inferno',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.bacon, Ingredient.cheese, Ingredient.onion, Ingredient.mustard, Ingredient.topBun], baseValue: 17.00),
  ],
);

// ── Stop 9 — Sauce Francisco ──────────────────────────────────────────────────
const _stop9 = StopDefinition(
  stopNumber: 9, stopName: 'Sauce Francisco', venueEmoji: '🌆',
  venueType: 'Burger Palace', buyPrice: 10000, incomePerDay: 950,
  tagline: 'West coast, best roast.',
  lore: 'Famous for its sourdough buns, perpetual fog, and extremely vocal opinions about toppings. People queue for two hours and consider it a spiritual experience.',
  menu: [
    BurgerOrder(name: 'The Foghorn',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.bacon, Ingredient.cheese, Ingredient.lettuce, Ingredient.tomato, Ingredient.topBun], baseValue: 16.00),
    BurgerOrder(name: 'The Egg on Top',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.cheese, Ingredient.friedEgg, Ingredient.topBun], baseValue: 14.50),
    BurgerOrder(name: 'The Full Fog',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.bacon, Ingredient.patty, Ingredient.cheese, Ingredient.pickle, Ingredient.mayo, Ingredient.topBun], baseValue: 20.00),
  ],
);

// ── Stop 10 — The Big Bun ─────────────────────────────────────────────────────
const _stop10 = StopDefinition(
  stopNumber: 10, stopName: 'The Big Bun', venueEmoji: '🌇',
  venueType: 'Burger Empire', buyPrice: 18000, incomePerDay: 1500,
  tagline: 'The city that never stops eating.',
  lore: 'The ultimate destination for any burger entrepreneur. The line outside stretches four city blocks at 3am on a Tuesday. If you can make it here, you have made it everywhere.',
  menu: [
    BurgerOrder(name: 'The Empire',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.patty, Ingredient.bacon, Ingredient.fancyCheese, Ingredient.lettuce, Ingredient.tomato, Ingredient.ketchup, Ingredient.topBun], baseValue: 24.00),
    BurgerOrder(name: 'The City Special',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.bacon, Ingredient.fancyCheese, Ingredient.onion, Ingredient.pickle, Ingredient.mayo, Ingredient.topBun], baseValue: 22.00),
    BurgerOrder(name: 'The Skyline',
        stack: [Ingredient.bottomBun, Ingredient.patty, Ingredient.friedEgg, Ingredient.patty, Ingredient.fancyCheese, Ingredient.bacon, Ingredient.mustard, Ingredient.topBun], baseValue: 26.00),
  ],
);