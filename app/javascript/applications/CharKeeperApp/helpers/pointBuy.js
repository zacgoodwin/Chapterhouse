// PH 2024 p.38 point buy, the only ability-score method TLC creation offers.
// Mirrors app/platforms/tlc/point_buy.rb, which is what actually gates a create:
// this side only keeps the form honest. Costs are cumulative from 8 and the
// 13->14 / 14->15 steps cost 2, so callers must read the table instead of
// counting one point per step.
export const POINT_BUY_COST = { 8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9 };
export const POINT_BUY_BUDGET = 27;
export const POINT_BUY_MIN = 8;
export const POINT_BUY_MAX = 15;

// Every ability at the floor: the spread a fresh form starts from.
export const pointBuyFloor = () => ({
  str: POINT_BUY_MIN, dex: POINT_BUY_MIN, con: POINT_BUY_MIN,
  int: POINT_BUY_MIN, wis: POINT_BUY_MIN, cha: POINT_BUY_MIN
});

// NaN, not a silent 0, for a score off the table: every comparison against NaN
// is false, so an unpriceable spread can never read as affordable.
export const pointBuySpent = (abilities) =>
  Object.values(abilities).reduce((total, score) => total + POINT_BUY_COST[score], 0);

export const pointBuyRemaining = (abilities) => POINT_BUY_BUDGET - pointBuySpent(abilities);

// Can `slug` move by `step` (+1/-1) without leaving 8..15 or overdrawing the budget?
export const canPointBuyChange = (abilities, slug, step) => {
  const score = abilities[slug] + step;

  if (score < POINT_BUY_MIN || score > POINT_BUY_MAX) return false;

  return pointBuyRemaining({ ...abilities, [slug]: score }) >= 0;
};
