const test = require("node:test");
const assert = require("node:assert/strict");
const {
  AUTHENTICATED_ROLE,
  withAuthenticatedRole,
} = require("./authenticated-role");

test("adds the authenticated role", () => {
  assert.deepEqual(withAuthenticatedRole(), {role: "authenticated"});
});

test("preserves other trusted custom claims", () => {
  const existing = {feature: "beta", paid: true};

  assert.deepEqual(withAuthenticatedRole(existing), {
    feature: "beta",
    paid: true,
    role: AUTHENTICATED_ROLE,
  });
  assert.deepEqual(existing, {feature: "beta", paid: true});
});
