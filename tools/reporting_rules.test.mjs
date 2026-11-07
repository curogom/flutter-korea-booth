import assert from 'node:assert/strict';
import {before,after,beforeEach,test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,getDocs,collection,query,where,orderBy,deleteDoc,serverTimestamp,Timestamp,setLogLevel,writeBatch} from 'firebase/firestore';
import {requireTestEmulators,testProjectId} from './test_support.mjs';
setLogLevel('silent');
let env;
const start=Timestamp.fromDate(new Date('2026-11-07T01:00:00Z'));
const end=Timestamp.fromDate(new Date('2026-11-07T09:00:00Z'));
const period=()=>({timeZone:'Asia/Seoul',environment:'production',startsAt:start,endsAt:end,updatedAt:serverTimestamp()});
const editor=()=>env.authenticatedContext('operator',{quizAdmin:true}).firestore();
before(async()=>{requireTestEmulators();env=await initializeTestEnvironment({projectId:testProjectId,firestore:{host:'127.0.0.1',port:8085,rules:await readFile(new URL('../firestore.rules',import.meta.url),'utf8')}});});
beforeEach(async()=>{await env.clearFirestore();});
after(async()=>{await env?.cleanup();});
test('only an operator can read and save reporting settings',async()=>{
  await assertSucceeds(setDoc(doc(editor(),'event_settings/reporting'),period()));
  await assertSucceeds(getDoc(doc(editor(),'event_settings/reporting')));
  for(const context of [env.unauthenticatedContext(),env.authenticatedContext('participant')]) {
    await assertFails(getDoc(doc(context.firestore(),'event_settings/reporting')));
    await assertFails(setDoc(doc(context.firestore(),'event_settings/reporting'),period()));
  }
  await assertFails(getDocs(collection(editor(),'event_settings')));
});
test('reporting settings reject reversed times, unrecognized fields and invalid environments',async()=>{
  for(const override of [{startsAt:end},{endsAt:start},{timeZone:'UTC'},{environment:'unknown'},{enabled:false},{updatedAt:start},{startsAt:'2026-11-07'}]) {
    await assertFails(setDoc(doc(editor(),'event_settings/reporting'),{...period(),...override}));
  }
  await assertSucceeds(setDoc(doc(editor(),'event_settings/reporting'),{...period(),environment:'development'}));
});
test('operators can extend the period but cannot delete settings',async()=>{
  const ref=doc(editor(),'event_settings/reporting');
  await setDoc(ref,period());
  await assertSucceeds(setDoc(ref,{...period(),endsAt:Timestamp.fromMillis(end.toMillis()+3600000)}));
  await assertFails(deleteDoc(ref));
});
test('a period query includes more than 500 matching runs, with exact boundaries and environment',async()=>{
  await env.withSecurityRulesDisabled(async context=>{
    const db=context.firestore();
    const rows=Array.from({length:503},(_,i)=>({id:`inside-${i}`,environment:'production',startedAt:Timestamp.fromMillis(start.toMillis()+i)}));
    rows.push({id:'before',environment:'production',startedAt:Timestamp.fromMillis(start.toMillis()-1)},
      {id:'end',environment:'production',startedAt:end},
      {id:'test',environment:'development',startedAt:start});
    for(let i=0;i<rows.length;i+=450){const batch=writeBatch(db);for(const {id,...data} of rows.slice(i,i+450))batch.set(doc(db,`booth_runs/${id}`),data);await batch.commit();}
  });
  const scope=query(collection(editor(),'booth_runs'),where('environment','==','production'),
    where('startedAt','>=',start),where('startedAt','<',end),orderBy('startedAt','desc'));
  const result=await assertSucceeds(getDocs(scope));
  assert.equal(result.size,503);
  assert.equal(result.docs.at(-1).id,'inside-0');
});
