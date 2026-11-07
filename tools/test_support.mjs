export const testProjectId = 'demo-quiz-tests';

// These tests clear emulator data. Refuse production projects or preview ports.
export function requireTestEmulators(environment = process.env) {
  if (environment.GCLOUD_PROJECT !== testProjectId ||
      environment.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8085' ||
      environment.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9095') {
    throw new Error('Use npm --prefix tools run test:emulators. Tests require demo-quiz-tests on 127.0.0.1:8085 / :9095.');
  }
}
