import assert from "node:assert/strict";
import test from "node:test";

import { distanceKm, gameCenter } from "../.test-build/web-push.js";

test("calculates nearby distance in kilometres", () => {
  assert.equal(distanceKm(52.37, 4.9, 52.37, 4.9), 0);
  const almereToAmsterdam = distanceKm(52.3508, 5.2647, 52.3676, 4.9041);
  assert.ok(almereToAmsterdam > 20 && almereToAmsterdam < 25);
});

test("calculates a game area centre from D1 JSON coordinates", () => {
  assert.deepEqual(gameCenter("[[52,5],[54,5],[54,7],[52,7]]"), [53, 6]);
  assert.equal(gameCenter("not-json"), null);
  assert.equal(gameCenter("[]"), null);
});
