import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const env = {...process.env};
// Firebase's Firestore emulator needs Java 21+. Prefer the user's JAVA_HOME.
if (!env.JAVA_HOME && process.platform === 'darwin') {
  const candidates = ['/Applications/Android Studio.app/Contents/jbr/Contents/Home', '/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home'];
  env.JAVA_HOME = candidates.find(candidate => existsSync(path.join(candidate, 'bin/java')));
}
if (env.JAVA_HOME) env.PATH = `${path.join(env.JAVA_HOME, 'bin')}${path.delimiter}${env.PATH ?? ''}`;
const child = spawn('firebase', ['emulators:exec', '--config', 'firebase.test.json', '--project', 'demo-quiz-tests', '--only', 'firestore,auth', 'npm --prefix tools test'], {cwd: root, env, stdio: 'inherit', shell: process.platform === 'win32'});
child.on('error', error => { console.error(error.message); process.exitCode = 1; });
child.on('exit', (code, signal) => { process.exitCode = code ?? (signal ? 1 : 0); });
