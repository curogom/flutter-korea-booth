import {createBoothSession} from './booth_session.mjs';
const boothSession = createBoothSession(navigator.locks);
window.boothAcquireSession = name => boothSession.acquire(name);
window.boothReleaseSession = () => boothSession.release();

// Called only by an explicitly configured Firebase build, never sample mode.
// Match firebase_core_web's locked SDK version. Auth is memory-only from its
// first initialization, before any persisted identity can be restored.
window.boothLoadFirebase = async () => {
  const base = 'https://www.gstatic.com/firebasejs/13.1.0/';
  const [core, auth, firestore, analytics] = await Promise.all([
    import(base + 'firebase-app.js'),
    import(base + 'firebase-auth.js'),
    import(base + 'firebase-firestore-pipelines.js'),
    import(base + 'firebase-analytics.js'),
  ]);
  const memoryAuth = {...auth, initializeAuth(app, options) {
    const instance = auth.initializeAuth(app, {...options, persistence: auth.inMemoryPersistence});
    if (app.options.projectId === 'demo-quiz' && app.options.apiKey === 'demo-api-key' &&
        !instance.emulatorConfig && ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname)) {
      auth.connectAuthEmulator(instance, 'http://127.0.0.1:9099', {disableWarnings: true});
    }
    return instance;
  }};
  Object.assign(window, {firebase_core: core, firebase_auth: memoryAuth,
    firebase_firestore: firestore, firebase_analytics: analytics});
};
const bootstrap = document.createElement('script');
bootstrap.src = 'flutter_bootstrap.js';
document.body.appendChild(bootstrap);
