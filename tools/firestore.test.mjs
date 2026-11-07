import assert from 'node:assert/strict';
import { requireTestEmulators } from './test_support.mjs';
import { before, after, beforeEach, test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, query, where, serverTimestamp, updateDoc, deleteDoc, setLogLevel } from 'firebase/firestore';

setLogLevel('silent'); // Denied requests remain visible as failed assertions if unexpected.
let env;
const text = {prompt: 'Question?', explanation: 'Explanation.', options: {a: 'A', b: 'B', c: 'C', d: 'D'}};
const valid = () => ({active: true, order: 1, correctOptionId: 'b', translations: {ko: text, en: text}, updatedAt: serverTimestamp()});
before(async () => {
  requireTestEmulators();
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  env = await initializeTestEnvironment({projectId: 'demo-quiz-tests', firestore: {host, port: Number(port), rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8')}});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'questions/public'), valid());
    await setDoc(doc(context.firestore(), 'questions/draft'), {...valid(), active: false});
  });
});
after(async () => { await env?.cleanup(); });
test('public users read published questions and a filtered catalog', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(db, 'questions/public')));
  await assertSucceeds(getDocs(query(collection(db, 'questions'), where('active', '==', true))));
});
test('public users cannot read drafts or unfiltered question collections', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'questions/draft')));
  await assertFails(getDocs(collection(db, 'questions')));
});
test('only a claimed question editor can write', async () => {
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'questions/new'), valid()));
  await assertFails(setDoc(doc(env.authenticatedContext('ordinary-user').firestore(), 'questions/new'), valid()));
  await assertSucceeds(setDoc(doc(env.authenticatedContext('editor', {quizAdmin: true}).firestore(), 'questions/new'), valid()));
});
test('editors can read unpublished questions', async () => {
  await assertSucceeds(getDoc(doc(env.authenticatedContext('editor', {quizAdmin: true}).firestore(), 'questions/draft')));
});

test('all 17 reviewed bilingual questions publish through the existing rules', async () => {
  const bank = JSON.parse(await readFile(new URL('../assets/data/questions.json', import.meta.url), 'utf8'));
  assert.equal(bank.length, 17);
  const editor = env.authenticatedContext('reviewed-bank-editor', {quizAdmin:true}).firestore();
  for (const {id,...question} of bank) {
    await assertSucceeds(setDoc(doc(editor, 'questions', id), {...question, updatedAt:serverTimestamp()}));
  }
  const visitor = env.unauthenticatedContext().firestore();
  const published = await getDocs(query(collection(visitor,'questions'),where('active','==',true)));
  const documents = new Map(published.docs.map(document=>[document.id,document.data()]));
  for (const {id,...question} of bank) {
    const {updatedAt,...actual} = documents.get(id);
    assert.deepEqual(actual,question);
  }
  assert.equal(documents.has('nullable-type'),false);
  assert.equal(documents.has('desktop-impeller-3-47'),false);
});
test('invalid correct option and incomplete translations are rejected', async () => {
  const db = env.authenticatedContext('editor', {quizAdmin: true}).firestore();
  await assertFails(setDoc(doc(db, 'questions/invalid-option'), {...valid(), correctOptionId: 'z'}));
  await assertFails(setDoc(doc(db, 'questions/missing-en'), {...valid(), translations: {ko: text}}));
  await assertFails(setDoc(doc(db, 'questions/missing-choice'), {...valid(), translations: {ko: {...text, options: {a: 'A'}}, en: text}}));
});
test('unknown fields, forged timestamps and unrelated collections are rejected', async () => {
  const db = env.authenticatedContext('editor', {quizAdmin: true}).firestore();
  await assertFails(setDoc(doc(db, 'questions/extra'), {...valid(), owner: 'someone'}));
  await assertFails(setDoc(doc(db, 'questions/time'), {...valid(), updatedAt: new Date(0)}));
  await assertFails(setDoc(doc(db, 'users/editor'), {quizAdmin: true}));
});

test('public reads return the published documents without drafts', async () => {
  const db = env.unauthenticatedContext().firestore();
  const snapshot = await getDocs(query(collection(db, 'questions'), where('active', '==', true)));
  assert.deepEqual(snapshot.docs.map(item => item.id), ['public']);
  await assertFails(getDocs(query(collection(db, 'questions'), where('active', '==', false))));
});
test('ordinary users cannot update or delete; editors can update and delete', async () => {
  for (const context of [env.unauthenticatedContext(), env.authenticatedContext('participant')]) {
    const ref = doc(context.firestore(), 'questions/public');
    await assertFails(updateDoc(ref, {active: false, updatedAt: serverTimestamp()}));
    await assertFails(deleteDoc(ref));
  }
  const ref = doc(env.authenticatedContext('editor', {quizAdmin: true}).firestore(), 'questions/public');
  await assertSucceeds(updateDoc(ref, {active: false, updatedAt: serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});
for (const claim of [false, 'true', 1, null]) {
  test(`quizAdmin claim ${JSON.stringify(claim)} does not grant editor access`, async () => {
    await assertFails(setDoc(doc(env.authenticatedContext('fake-editor', {quizAdmin: claim}).firestore(), 'questions/new'), valid()));
  });
}
const invalidData = {
  'negative order': () => ({...valid(), order: -1}),
  'order over limit': () => ({...valid(), order: 1000001}),
  'fractional order': () => ({...valid(), order: 1.5}),
  'non-boolean visibility': () => ({...valid(), active: 'true'}),
  'blank prompt': () => ({...valid(), translations: {ko: {...text, prompt: ' \t\n '}, en: text}}),
  'blank explanation': () => ({...valid(), translations: {ko: text, en: {...text, explanation: '   '}}}),
  'blank choice': () => ({...valid(), translations: {ko: {...text, options: {...text.options, b: ' \t '}}, en: text}}),
  'prompt over limit': () => ({...valid(), translations: {ko: {...text, prompt: 'x'.repeat(501)}, en: text}}),
  'explanation over limit': () => ({...valid(), translations: {ko: text, en: {...text, explanation: 'x'.repeat(1001)}}}),
  'choice over limit': () => ({...valid(), translations: {ko: {...text, options: {...text.options, a: 'x'.repeat(121)}}, en: text}}),
  'extra language': () => ({...valid(), translations: {ko: text, en: text, fr: text}}),
  'extra choice': () => ({...valid(), translations: {ko: {...text, options: {...text.options, e: 'E'}}, en: text}}),
  'missing visibility': () => { const data = valid(); delete data.active; return data; },
};
for (const [label, create] of Object.entries(invalidData)) {
  test(`schema rejects ${label}`, async () => {
    await assertFails(setDoc(doc(env.authenticatedContext('editor', {quizAdmin: true}).firestore(), 'questions/invalid'), create()));
  });
}
test('schema accepts exact field length and order limits with Korean and English content', async () => {
  const content = {prompt: '가'.repeat(500), explanation: 'x'.repeat(1000), options: {a: '가'.repeat(120), b: 'x'.repeat(120), c: 'C', d: 'D'}};
  await assertSucceeds(setDoc(doc(env.authenticatedContext('editor', {quizAdmin: true}).firestore(), 'questions/maximum'), {...valid(), order: 1000000, translations: {ko: content, en: content}}));
});
