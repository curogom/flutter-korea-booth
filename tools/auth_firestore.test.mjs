import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';
import { promisify } from 'node:util';
import { execFile } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, terminate, collection, doc, setDoc, updateDoc, deleteDoc, getDocFromServer, query, where, onSnapshot, serverTimestamp, setLogLevel } from 'firebase/firestore';
import { initializeApp as initializeAdminApp, deleteApp as deleteAdminApp } from 'firebase-admin/app';
import { getAuth as getAdminAuth } from 'firebase-admin/auth';
import { requireTestEmulators, testProjectId } from './test_support.mjs';

setLogLevel('silent'); // Expected permission denials are asserted below.
const exec = promisify(execFile);
const clients = [];
const password = 'LocalTestPassword2026!';
const operatorEmail = 'operator@example.test';
const ordinaryEmail = 'participant@example.test';
let adminApp, adminAuth, editor, ordinary, visitor;
const translation = {prompt: '질문 / Question?', explanation: '설명 / Explanation.', options: {a: 'A', b: 'B', c: 'C', d: 'D'}};
const question = (active = false) => ({active, order: 1, correctOptionId: 'b', translations: {ko: {...translation}, en: {...translation}}, updatedAt: serverTimestamp()});

function client(name) {
  const app = initializeApp({projectId: testProjectId, apiKey: 'demo-api-key', appId: `1:123456:web:${name}`}, name);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, {disableWarnings: true});
  const db = getFirestore(app);
  connectFirestoreEmulator(db, '127.0.0.1', 8085);
  const value = {app, auth, db};
  clients.push(value);
  return value;
}
async function login(target, email = operatorEmail) {
  return (await signInWithEmailAndPassword(target.auth, email, password)).user;
}
async function permissionDenied(operation) {
  await assert.rejects(operation, error => error.code === 'permission-denied');
}
async function catalogAfter(db, expectedIds, action) {
  let stop, timeout;
  let started=false, mutationDone=false, latest=[];
  const expected=JSON.stringify(expectedIds.toSorted());
  const changed=new Promise((resolve,reject)=>{
    const finish=()=>{if(mutationDone && JSON.stringify(latest)===expected) resolve(latest);};
    timeout=setTimeout(()=>reject(new Error(`Published catalog did not become ${expectedIds}`)),8000);
    stop=onSnapshot(query(collection(db,'questions'),where('active','==',true)),{includeMetadataChanges:true},snapshot=>{
      latest=snapshot.docs.map(item=>item.id).sort();
      if(!snapshot.metadata.fromCache && !started) {
        started=true;
        Promise.resolve().then(action).then(()=>{mutationDone=true;finish();},reject);
      }
      finish();
    },reject);
  });
  try { return await changed; } finally {clearTimeout(timeout);stop?.();}
}

before(async () => {
  requireTestEmulators();
  adminApp = initializeAdminApp({projectId: testProjectId, credential: {getAccessToken: async () => ({access_token: 'owner', expires_in: 3600})}}, 'integration-admin');
  adminAuth = getAdminAuth(adminApp);
  // Only the guarded, isolated test project is reset.
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${testProjectId}/accounts`, {method: 'DELETE'});
  assert.equal(response.ok, true);
  await adminAuth.createUser({uid: 'operator', email: operatorEmail, password});
  await adminAuth.createUser({uid: 'participant', email: ordinaryEmail, password});
  editor = client('operator-client'); ordinary = client('participant-client'); visitor = client('visitor-client');
});
beforeEach(async () => {
  await Promise.all(clients.map(value => signOut(value.auth)));
  await adminAuth.setCustomUserClaims('operator', {quizAdmin: true});
  await adminAuth.setCustomUserClaims('participant', {});
  const response = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${testProjectId}/databases/(default)/documents`, {method: 'DELETE'});
  assert.equal(response.ok, true);
});
after(async () => {
  for (const value of clients) { await terminate(value.db); await deleteApp(value.app); }
  if (adminApp) await deleteAdminApp(adminApp);
});

test('Auth emulator rejects an incorrect password and signs in an existing operator', async () => {
  await assert.rejects(signInWithEmailAndPassword(editor.auth, operatorEmail, 'incorrect-password'), error => ['auth/wrong-password', 'auth/invalid-credential', 'auth/invalid-login-credentials'].includes(error.code));
  const user = await login(editor);
  assert.equal(user.email, operatorEmail);
  assert.equal((await user.getIdTokenResult()).claims.quizAdmin, true);
});

test('a signed-in participant cannot read drafts, write questions or grant their own access', async () => {
  await login(editor); await setDoc(doc(editor.db, 'questions/private'), question());
  const user = await login(ordinary, ordinaryEmail);
  assert.notEqual((await user.getIdTokenResult()).claims.quizAdmin, true);
  await permissionDenied(getDocFromServer(doc(ordinary.db, 'questions/private')));
  await permissionDenied(setDoc(doc(ordinary.db, 'questions/new'), question(true)));
  await permissionDenied(setDoc(doc(ordinary.db, 'users/participant'), {quizAdmin: true}));
});

test('sign-out removes editor access to both reads and writes', async () => {
  await login(editor); await setDoc(doc(editor.db, 'questions/private'), question());
  await signOut(editor.auth);
  await permissionDenied(getDocFromServer(doc(editor.db, 'questions/private')));
  await permissionDenied(setDoc(doc(editor.db, 'questions/after-sign-out'), question()));
});

test('claim grant and revocation take effect after a forced ID token refresh', async () => {
  const user = await login(ordinary, ordinaryEmail);
  const ref = doc(ordinary.db, 'questions/claims');
  await permissionDenied(setDoc(ref, question()));
  await adminAuth.setCustomUserClaims(user.uid, {quizAdmin: true});
  await user.getIdToken(true);
  assert.equal((await user.getIdTokenResult()).claims.quizAdmin, true);
  await setDoc(ref, question());
  await adminAuth.setCustomUserClaims(user.uid, {});
  await user.getIdToken(true);
  assert.notEqual((await user.getIdTokenResult()).claims.quizAdmin, true);
  await permissionDenied(updateDoc(ref, {active: true, updatedAt: serverTimestamp()}));
  await permissionDenied(getDocFromServer(ref));
});

test('operator CRUD and publish/unpublish update the public live catalog', async () => {
  await login(editor);
  const ref = doc(collection(editor.db, 'questions'));
  await setDoc(ref, question());
  await permissionDenied(getDocFromServer(doc(visitor.db, ref.path)));
  await catalogAfter(visitor.db, [ref.id], () => updateDoc(ref, {active: true, updatedAt: serverTimestamp()}));
  const initial = (await getDocFromServer(doc(visitor.db, ref.path))).data();
  assert.equal(initial.translations.ko.options.b, 'B');
  assert.equal(initial.translations.en.options.b, 'B');
  assert.equal(initial.correctOptionId, 'b');
  await updateDoc(ref, {'translations.en.prompt': 'Updated English question?', correctOptionId: 'c', updatedAt: serverTimestamp()});
  const updated = (await getDocFromServer(doc(visitor.db, ref.path))).data();
  assert.equal(updated.translations.en.prompt, 'Updated English question?');
  assert.equal(updated.translations.ko.prompt, translation.prompt);
  assert.equal(updated.correctOptionId, 'c');
  await catalogAfter(visitor.db, [], () => updateDoc(ref, {active: false, updatedAt: serverTimestamp()}));
  await permissionDenied(getDocFromServer(doc(visitor.db, ref.path)));
  await deleteDoc(ref);
  assert.equal((await getDocFromServer(ref)).exists(), false);
});

test('a rejected edit leaves the previously published question intact', async () => {
  await login(editor);
  const ref = doc(editor.db, 'questions/atomic');
  await setDoc(ref, question(true));
  await permissionDenied(updateDoc(ref, {correctOptionId: 'z', updatedAt: serverTimestamp()}));
  const saved = (await getDocFromServer(doc(visitor.db, ref.path))).data();
  assert.equal(saved.correctOptionId, 'b');
  assert.equal(saved.active, true);
});

test('seed command is repeatable and preserves existing edited questions', async () => {
  const script = fileURLToPath(new URL('./firebase_admin.mjs', import.meta.url));
  await exec(process.execPath, [script, 'seed', testProjectId], {env: process.env, timeout: 20000});
  await login(editor);
  const ref = doc(editor.db, 'questions/demo-addition-01');
  await updateDoc(ref, {'translations.en.prompt': 'Keep this operator edit', updatedAt: serverTimestamp()});
  const result = await exec(process.execPath, [script, 'seed', testProjectId], {env: process.env, timeout: 20000});
  assert.match(result.stdout, /Kept existing: demo-addition-01/);
  assert.equal((await getDocFromServer(ref)).data().translations.en.prompt, 'Keep this operator edit');
});

test('demo bootstrap refuses a real project or missing emulator endpoints before connecting', async () => {
  const script = fileURLToPath(new URL('./firebase_admin.mjs', import.meta.url));
  await assert.rejects(exec(process.execPath, [script, 'bootstrap-emulator', 'a-real-project'], {env: process.env}), error => /Demo credentials may only/.test(error.stderr));
  const env = {...process.env}; delete env.FIREBASE_AUTH_EMULATOR_HOST;
  await assert.rejects(exec(process.execPath, [script, 'bootstrap-emulator', testProjectId], {env}), error => /Demo credentials may only/.test(error.stderr));
});


test('destructive test setup refuses preview projects and non-test endpoints', () => {
  for (const changed of [
    {GCLOUD_PROJECT: 'demo-quiz'},
    {FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080'},
    {FIREBASE_AUTH_EMULATOR_HOST: undefined},
  ]) {
    assert.throws(() => requireTestEmulators({...process.env, ...changed}), /Tests require demo-quiz-tests/);
  }
});
