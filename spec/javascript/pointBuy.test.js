import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  POINT_BUY_COST, POINT_BUY_BUDGET, POINT_BUY_MIN, POINT_BUY_MAX,
  pointBuyFloor, pointBuySpent, pointBuyRemaining, canPointBuyChange
} from '../../app/javascript/applications/CharKeeperApp/helpers/pointBuy.js';

const STANDARD_ARRAY = { str: 15, dex: 14, con: 13, int: 12, wis: 10, cha: 8 };

test('the cost table is PH 2024 p.38, not a uniform one point per step', () => {
  assert.deepEqual(POINT_BUY_COST, { 8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9 });
  assert.equal(POINT_BUY_BUDGET, 27);
  assert.equal(POINT_BUY_MIN, 8);
  assert.equal(POINT_BUY_MAX, 15);
  // The two steps that cost 2, the whole reason callers cannot count points.
  assert.equal(POINT_BUY_COST[14] - POINT_BUY_COST[13], 2);
  assert.equal(POINT_BUY_COST[15] - POINT_BUY_COST[14], 2);
});

test('pointBuySpent prices a spread and pointBuyRemaining counts the rest', () => {
  assert.equal(pointBuySpent(pointBuyFloor()), 0);
  assert.equal(pointBuyRemaining(pointBuyFloor()), 27);
  assert.equal(pointBuySpent(STANDARD_ARRAY), 27);
  assert.equal(pointBuyRemaining(STANDARD_ARRAY), 0);
  // Three 15s cost exactly 27 -- lopsided but legal; the fourth is what breaks it.
  assert.equal(pointBuySpent({ str: 15, dex: 15, con: 15, int: 8, wis: 8, cha: 8 }), 27);
  assert.equal(pointBuyRemaining({ str: 15, dex: 15, con: 15, int: 15, wis: 8, cha: 8 }), -9);
});

test('a score off the table poisons the total instead of costing nothing', () => {
  // NaN, so `remaining >= 0` is false: an unpriceable spread can never look affordable.
  assert.ok(Number.isNaN(pointBuySpent({ str: 16, dex: 8, con: 8, int: 8, wis: 8, cha: 8 })));
  assert.ok(Number.isNaN(pointBuySpent({ str: 7, dex: 8, con: 8, int: 8, wis: 8, cha: 8 })));
  assert.equal(canPointBuyChange({ str: 16, dex: 8, con: 8, int: 8, wis: 8, cha: 8 }, 'dex', 1), false);
});

test('canPointBuyChange holds both the 8..15 range and the 27-point budget', () => {
  const floor = pointBuyFloor();

  assert.equal(canPointBuyChange(floor, 'str', 1), true);
  assert.equal(canPointBuyChange(floor, 'str', -1), false, '8 is the floor');
  assert.equal(canPointBuyChange({ ...floor, str: 15 }, 'str', 1), false, '15 is the ceiling');
  assert.equal(canPointBuyChange({ ...floor, str: 15 }, 'str', -1), true);
  // Fully spent: the cheapest remaining step (8 -> 9, one point) is unaffordable.
  assert.equal(canPointBuyChange(STANDARD_ARRAY, 'cha', 1), false);
  assert.equal(canPointBuyChange(STANDARD_ARRAY, 'cha', -1), false, 'cha is already at 8');
  assert.equal(canPointBuyChange(STANDARD_ARRAY, 'wis', -1), true, 'giving points back is always allowed');
  // 2 points left: enough for a 13 -> 14 step, and nothing left after it.
  const twoLeft = { str: 13, dex: 13, con: 13, int: 13, wis: 13, cha: 8 };
  assert.equal(pointBuyRemaining(twoLeft), 2);
  assert.equal(canPointBuyChange(twoLeft, 'str', 1), true);
  assert.equal(canPointBuyChange({ ...twoLeft, str: 14 }, 'str', 1), false);
});

test('pointBuyFloor hands out a fresh object every call', () => {
  const first = pointBuyFloor();
  first.str = 15;

  // Solid's createStore writes through the object it is handed: a shared floor
  // would leak one form's spend into the next mount (issue #67 footgun).
  assert.equal(pointBuyFloor().str, 8);
});
