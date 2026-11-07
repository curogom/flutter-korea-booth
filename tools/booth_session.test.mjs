import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createBoothSession} from '../web/booth_session.mjs';

class LockManager {
  held = new Set();
  async request(name, options, callback) {
    assert.equal(options.ifAvailable, true);
    if(this.held.has(name)) return callback(null);
    this.held.add(name);
    try { return await callback({name}); }
    finally { this.held.delete(name); }
  }
}
test('a second tab cannot acquire the active project/environment lock', async()=>{
  const locks=new LockManager();
  const first=createBoothSession(locks), second=createBoothSession(locks);
  assert.equal(await first.acquire('booth-project-production'),'acquired');
  assert.equal(await first.acquire('booth-project-production'),'acquired');
  assert.equal(await second.acquire('booth-project-production'),'alreadyOpen');
  first.release(); await Promise.resolve();
  assert.equal(await second.acquire('booth-project-production'),'acquired');
  second.release();
});
test('different environments do not block each other',async()=>{
  const locks=new LockManager();
  const prod=createBoothSession(locks), dev=createBoothSession(locks);
  assert.equal(await prod.acquire('booth-project-production'),'acquired');
  assert.equal(await dev.acquire('booth-project-development'),'acquired');
  prod.release();dev.release();
});
test('simultaneous acquire calls share one request',async()=>{
  const locks=new LockManager(), tab=createBoothSession(locks);
  assert.deepEqual(await Promise.all([tab.acquire('booth'),tab.acquire('booth')]),['acquired','acquired']);
  assert.equal(locks.held.size,1);tab.release();
});
test('unsupported or denied locks fail closed',async()=>{
  assert.equal(await createBoothSession(undefined).acquire('booth'),'unavailable');
  assert.equal(await createBoothSession({request(){throw new Error('denied');}}).acquire('booth'),'unavailable');
  assert.equal(await createBoothSession({request(){return Promise.reject(new Error('denied'));}}).acquire('booth'),'unavailable');
});
