import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { readFile } from 'node:fs/promises';

const [action, projectId] = process.argv.slice(2);
const endpoints = [process.env.FIRESTORE_EMULATOR_HOST, process.env.FIREBASE_AUTH_EMULATOR_HOST];
const local = value => typeof value === 'string' && /^127\.0\.0\.1:\d+$/.test(value);
if (!['seed', 'bootstrap-emulator'].includes(action) || !projectId?.startsWith('demo-') || !endpoints.every(local)) {
  throw new Error('Demo credentials may only be used with seed/bootstrap-emulator, a demo-* project, and both loopback emulator endpoints.');
}
initializeApp({projectId});
if (action === 'seed' || action === 'bootstrap-emulator') {
  const questions = JSON.parse(await readFile(new URL('../assets/data/questions.json', import.meta.url), 'utf8'));
  for (const {id, ...question} of questions) {
    try {
      await getFirestore().collection('questions').doc(id).create({...question, updatedAt: FieldValue.serverTimestamp()});
      console.log(`Created: ${id}`);
    } catch (error) {
      if (error.code === 6) console.log(`Kept existing: ${id}`); else throw error;
    }
  }
}
if (action === 'bootstrap-emulator') {
  const demoEmail = 'host@example.test';
  let user;
  try { user = await getAuth().getUserByEmail(demoEmail); }
  catch (error) { if (error.code !== 'auth/user-not-found') throw error; user = await getAuth().createUser({email: demoEmail, password: 'LocalDemoOnly123!'}); }
  await getAuth().setCustomUserClaims(user.uid, {...user.customClaims, quizAdmin: true});
  console.log('Local-only editor: host@example.test / LocalDemoOnly123!');
}
