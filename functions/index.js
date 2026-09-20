const {onCall, HttpsError} = require("firebase-functions/v2/https");
const functionsV1 = require("firebase-functions/v1");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {
  AUTHENTICATED_ROLE,
  withAuthenticatedRole,
} = require("./authenticated-role");

initializeApp();

async function assignAuthenticatedRole(uid, knownClaims) {
  const auth = getAuth();
  const claims = knownClaims ?? (await auth.getUser(uid)).customClaims ?? {};

  if (claims.role === AUTHENTICATED_ROLE) return false;

  // setCustomUserClaims replaces the entire claims object, so retain claims
  // owned by other trusted backend processes.
  await auth.setCustomUserClaims(uid, withAuthenticatedRole(claims));
  return true;
}

// Covers accounts created through Firebase Auth, not only through this app.
exports.assignAuthenticatedRoleOnCreate = functionsV1.auth
  .user()
  .onCreate((user) => assignAuthenticatedRole(user.uid, user.customClaims));

// Lets a newly registered Flutter user wait until the server-side assignment
// has completed before force-refreshing its ID token.
exports.ensureAuthenticatedRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const changed = await assignAuthenticatedRole(request.auth.uid);
  return {role: AUTHENTICATED_ROLE, changed};
});
