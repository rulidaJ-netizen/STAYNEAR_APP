const {applicationDefault, initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {
  AUTHENTICATED_ROLE,
  withAuthenticatedRole,
} = require("../authenticated-role");

async function backfill(pageToken) {
  const auth = getAuth();
  const page = await auth.listUsers(1000, pageToken);
  let updated = 0;

  for (const user of page.users) {
    const claims = user.customClaims ?? {};
    if (claims.role === AUTHENTICATED_ROLE) continue;

    await auth.setCustomUserClaims(user.uid, withAuthenticatedRole(claims));
    updated += 1;
  }

  console.log(`Scanned ${page.users.length} users; updated ${updated}.`);
  if (page.pageToken) await backfill(page.pageToken);
}

if (require.main === module) {
  initializeApp({credential: applicationDefault()});
  backfill().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

module.exports = {backfill};
