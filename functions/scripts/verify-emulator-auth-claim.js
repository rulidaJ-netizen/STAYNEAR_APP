const assert = require("node:assert/strict");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");

if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("This check must only run against the Auth emulator.");
}

initializeApp({projectId: process.env.GCLOUD_PROJECT ?? "demo-staynear"});

async function verify() {
  const auth = getAuth();
  const user = await auth.createUser({
    email: `claim-check-${Date.now()}@example.test`,
    password: "Password123!",
  });

  try {
    for (let attempt = 0; attempt < 40; attempt += 1) {
      const current = await auth.getUser(user.uid);
      if (current.customClaims?.role === "authenticated") {
        assert.equal(current.customClaims.role, "authenticated");
        console.log("Auth create trigger assigned role: authenticated");
        return;
      }
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
    throw new Error("Timed out waiting for the Auth create trigger.");
  } finally {
    await auth.deleteUser(user.uid);
  }
}

verify().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
