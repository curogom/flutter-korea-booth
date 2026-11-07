// Keep one writer per origin/project/environment for the document's lifetime.
// Web Locks releases ownership automatically when its tab closes or crashes.
export function createBoothSession(lockManager) {
  let owned = null;
  let pending = null;
  let releaseLock = null;
  return {
    acquire(name) {
      if (owned === name) return Promise.resolve('acquired');
      if (owned !== null) return Promise.resolve('unavailable');
      if (!lockManager?.request) return Promise.resolve('unavailable');
      if (pending) return pending;
      pending = new Promise(resolve => {
        const request = lockManager.request(name, {ifAvailable: true}, lock => {
          if (!lock) { resolve('alreadyOpen'); return; }
          owned = name;
          resolve('acquired');
          return new Promise(release => { releaseLock = release; });
        });
        Promise.resolve(request).catch(() => resolve('unavailable'));
      }).catch(() => 'unavailable').finally(() => { pending = null; });
      return pending;
    },
    release() {
      owned = null;
      releaseLock?.();
      releaseLock = null;
    },
  };
}
