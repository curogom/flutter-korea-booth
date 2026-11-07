import assert from 'node:assert/strict';
import {before,after,beforeEach,test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,updateDoc,deleteDoc,serverTimestamp,Timestamp,setLogLevel} from 'firebase/firestore';
import {requireTestEmulators,testProjectId} from './test_support.mjs';
setLogLevel('silent');
let env;
const startedAt=Timestamp.fromMillis(1700000000000);
const run=(completed=false)=>({environment:'development',startedAt,finishedAt:completed?Timestamp.fromMillis(1700000008000):null,language:'ko',status:completed?'completed':'started',questionIds:['q1','q2','q3','q4'],correctAnswers:['b','b','b','b'],answers:completed?['b','b','b','a']:[],version:completed?6:1,durationMs:completed?8000:0,catalogRevision:'revision',score:completed?3:0,passed:completed,updatedAt:serverTimestamp()});
const editor=(uid='operator')=>env.authenticatedContext(uid,{quizAdmin:true}).firestore();
before(async()=>{requireTestEmulators(); env=await initializeTestEnvironment({projectId:testProjectId,firestore:{host:'127.0.0.1',port:8085,rules:await readFile(new URL('../firestore.rules',import.meta.url),'utf8')}});});
beforeEach(async()=>{await env.clearFirestore();});
after(async()=>{await env?.cleanup();});
test('only operators can write and read private participation records',async()=>{
  await assertSucceeds(setDoc(doc(editor(),'booth_runs/run'),run()));
  for(const context of [env.unauthenticatedContext(),env.authenticatedContext('participant')]) {
    await assertFails(setDoc(doc(context.firestore(),'booth_runs/new'),run()));
    await assertFails(getDoc(doc(context.firestore(),'booth_runs/run')));
  }
  await assertSucceeds(getDoc(doc(editor(),'booth_runs/run')));
});
test('completed records require four answers and a matching score/pass result',async()=>{
  const db=editor();
  await assertFails(setDoc(doc(db,'booth_runs/score'),{...run(true),score:4}));
  await assertFails(setDoc(doc(db,'booth_runs/pass'),{...run(true),passed:false}));
  await assertFails(setDoc(doc(db,'booth_runs/short'),{...run(true),answers:['b','b','b']}));
  await assertSucceeds(setDoc(doc(db,'booth_runs/valid'),run(true)));
});
test('records reject malformed answer IDs, environments and unknown fields',async()=>{
  for(const [key,override] of Object.entries({choice:{correctAnswers:['z','b','b','b']},environment:{environment:'unknown'},extra:{owner:'outsider'},time:{updatedAt:Timestamp.fromMillis(0)}})) {
    await assertFails(setDoc(doc(editor(),`booth_runs/${key}`),{...run(),...override}));
  }
});
test('progress may append answers and finish but preserves the question snapshot',async()=>{
  const ref=doc(editor(),'booth_runs/progress'); await setDoc(ref,run());
  await assertSucceeds(updateDoc(ref,{answers:['b'],score:1,version:2,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{questionIds:['new','q2','q3','q4'],version:3,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{answers:['a'],score:0,version:3,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{version:2,updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(ref,{...run(true)}));
  await assertFails(updateDoc(ref,{...run(),version:7}));
});
test('new participation records cannot contain collection metadata',async()=>{
  for(const extra of [{claimedAt:serverTimestamp()},{claimedBy:'operator'},{claimedAt:serverTimestamp(),claimedBy:'operator'}]) {
    await assertFails(setDoc(doc(editor(),'booth_runs/preclaimed'),{...run(true),...extra}));
  }
});
test('no run status accepts manual collection confirmation',async()=>{
  const db=editor();
  for(const [id,value] of Object.entries({started:run(),passed:run(true),failed:{...run(true),answers:['b','b','a','a'],score:2,passed:false}})) {
    const ref=doc(db,`booth_runs/${id}`);await setDoc(ref,value);
    await assertFails(updateDoc(ref,{claimedAt:serverTimestamp(),claimedBy:'operator',updatedAt:serverTimestamp()}));
    assert.equal((await getDoc(ref)).data().claimedAt,undefined);
  }
});
test('legacy collection metadata stays readable but cannot be changed',async()=>{
  await env.withSecurityRulesDisabled(async context=>{
    await setDoc(doc(context.firestore(),'booth_runs/legacy'),{...run(true),claimedAt:startedAt,claimedBy:'old-operator'});
  });
  const ref=doc(editor(),'booth_runs/legacy');
  assert.equal((await getDoc(ref)).data().claimedBy,'old-operator');
  await assertFails(updateDoc(ref,{claimedBy:'new-operator',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{claimedAt:serverTimestamp(),updatedAt:serverTimestamp()}));
});
test('operator records cannot be deleted through the app',async()=>{
  const ref=doc(editor(),'booth_runs/audit');await setDoc(ref,run(true));
  await assertFails(deleteDoc(ref));
});
