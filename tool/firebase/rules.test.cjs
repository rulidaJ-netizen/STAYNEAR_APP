const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc, getDoc, serverTimestamp, increment } = require('firebase/firestore');

let env;
const profile = (uid, role = 'boarder') => ({ uid, role, fullName: uid, firstName: uid, middleName: '', lastName: '',
  email: `${uid}@example.test`, birthday: '', gender: '', phoneNumber: '09123456789', address: 'Clarin',
  profilePhotoUrl: null, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
const listing = (uid = 'owner', id = 'house') => ({ listingId: id, landownerId: uid, propertyName: 'Garden House',
  description: 'Quiet rooms', contactNumber: '09123456789', monthlyRent: 4000, totalRooms: 4, availableRooms: 2,
  amenities: ['WiFi'], imageUrls: [], fullAddress: 'Clarin', distanceFromUniversity: null, latitude: 9.96,
  longitude: 124.02, googleMapsUrl: null, status: 'Available', views: 0, billingInfo: '', houseInformation: {},
  createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
const db = (uid) => env.authenticatedContext(uid, { email: `${uid}@example.test` }).firestore();
const review = (uid = 'boarder', id = 'r') => ({ reviewId: id, listingId: 'house', boarderId: uid, boarderName: uid,
  rating: 5, comment: 'Clean room', createdAt: serverTimestamp() });

before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-staynear',
    firestore: { rules: fs.readFileSync('../../firestore.rules', 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const admin = context.firestore();
    for (const [uid, role] of [['owner', 'landowner'], ['other', 'landowner'], ['boarder', 'boarder']]) {
      await setDoc(doc(admin, 'users', uid), profile(uid, role));
    }
    await setDoc(doc(admin, 'listings', 'house'), listing());
  });
});

test('profiles: self create and update, private reads, no password or role escalation', async () => {
  await assertSucceeds(setDoc(doc(db('new'), 'users/new'), profile('new')));
  await assertSucceeds(updateDoc(doc(db('boarder'), 'users/boarder'), { fullName: 'Edited', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(db('other'), 'users/boarder')));
  await assertFails(updateDoc(doc(db('boarder'), 'users/boarder'), { role: 'landowner', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db('boarder'), 'users/boarder'), { password: 'secret', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db('boarder'), 'users/boarder'), { email: 'unverified@example.test', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('new'), 'users/another'), profile('new')));
});

test('listings: owner creates, edits same record, other accounts cannot modify or impersonate', async () => {
  await assertSucceeds(setDoc(doc(db('owner'), 'listings/new'), listing('owner', 'new')));
  await assertSucceeds(updateDoc(doc(db('owner'), 'listings/house'), { propertyName: 'Edited', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('boarder'), 'listings/new-boarder'), listing('boarder', 'new-boarder')));
  await assertFails(setDoc(doc(db('other'), 'listings/forged'), listing('owner', 'forged')));
  await assertFails(updateDoc(doc(db('other'), 'listings/house'), { propertyName: 'Stolen', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db('owner'), 'listings/house'), { landownerId: 'other', updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(db('other'), 'listings/house')));
  await assertSucceeds(deleteDoc(doc(db('owner'), 'listings/new')));
  assert.equal((await getDoc(doc(db('owner'), 'listings/house'))).exists(), true);
});

test('listing validation: optional distance, photo limit, room bounds, coordinates', async () => {
  await assertSucceeds(updateDoc(doc(db('owner'), 'listings/house'), { distanceFromUniversity: '', updatedAt: serverTimestamp() }));
  for (const bad of [{availableRooms: 99}, {imageUrls: ['1','2','3','4','5']}, {latitude: 91}, {monthlyRent: -1}]) {
    await assertFails(updateDoc(doc(db('owner'), 'listings/house'), {...bad, updatedAt: serverTimestamp()}));
  }
});

test('views: atomic increments only, no forged statistics or injected edits', async () => {
  await assertSucceeds(updateDoc(doc(db('boarder'), 'listings/house'), { views: increment(1) }));
  await assertFails(updateDoc(doc(db('boarder'), 'listings/house'), { views: 1000 }));
  await assertFails(updateDoc(doc(db('boarder'), 'listings/house'), { views: increment(1), propertyName: 'Hacked' }));
  await assertFails(updateDoc(doc(db('owner'), 'listings/house'), { views: 100, updatedAt: serverTimestamp() }));
});

test('favorites: private, boarder-only, existing listing, removable after deletion', async () => {
  const data = { listingId: 'house', createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(db('boarder'), 'users/boarder/favorites/house'), data));
  await assertFails(setDoc(doc(db('owner'), 'users/owner/favorites/house'), data));
  await assertFails(setDoc(doc(db('other'), 'users/boarder/favorites/house'), data));
  await assertFails(getDoc(doc(db('other'), 'users/boarder/favorites/house')));
  await assertSucceeds(deleteDoc(doc(db('owner'), 'listings/house')));
  await assertSucceeds(deleteDoc(doc(db('boarder'), 'users/boarder/favorites/house')));
});

test('reviews: boarder authorship, real rating, landowners read only, cleanup on deletion', async () => {
  await assertSucceeds(setDoc(doc(db('boarder'), 'listings/house/reviews/r'), review()));
  await assertSucceeds(getDoc(doc(db('owner'), 'listings/house/reviews/r')));
  await assertFails(setDoc(doc(db('owner'), 'listings/house/reviews/owner'), review('owner', 'owner')));
  await assertFails(setDoc(doc(db('boarder'), 'listings/house/reviews/forged'), {...review('boarder', 'forged'), boarderName: 'other'}));
  await assertFails(setDoc(doc(db('boarder'), 'listings/house/reviews/bad'), {...review('boarder', 'bad'), rating: 6}));
  await assertFails(deleteDoc(doc(db('owner'), 'listings/house/reviews/r')));
  await assertSucceeds(updateDoc(doc(db('owner'), 'listings/house'), { status: 'Deleting', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('boarder'), 'listings/house/reviews/late'), review('boarder', 'late')));
  await assertSucceeds(deleteDoc(doc(db('owner'), 'listings/house/reviews/r')));
});

test('unauthenticated database reads and writes are denied', async () => {
  const anon = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anon, 'listings/house')));
  await assertFails(setDoc(doc(anon, 'listings/new'), listing('owner', 'new')));
});

test('Auth emulator registration/login/reset and session token use', async () => {
  const base = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/';
  const call = async (method, data) => {
    const response = await fetch(`${base}${method}?key=demo-key`, {method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(data)});
    const json = await response.json();
    assert.equal(response.status, 200, JSON.stringify(json));
    return json;
  };
  const email = `integration-${Date.now()}@example.test`;
  const signedUp = await call('accounts:signUp', {email, password:'Password123!', returnSecureToken:true});
  assert.ok(signedUp.localId);
  const loggedIn = await call('accounts:signInWithPassword', {email, password:'Password123!', returnSecureToken:true});
  assert.equal(loggedIn.localId, signedUp.localId);
  await call('accounts:sendOobCode', {email, requestType:'PASSWORD_RESET'});
  const codes = await (await fetch('http://127.0.0.1:9099/emulator/v1/projects/demo-staynear/oobCodes')).json();
  assert.ok(codes.oobCodes.some(code => code.email === email && code.requestType === 'PASSWORD_RESET'));
  await call('accounts:delete', {idToken:loggedIn.idToken});
});
