// Moves the app code and assets of a Flutter web build into a folder named
// after their content hash, so every release is fetched from new URLs.
//
// Flutter keeps the same file names in every build (main.dart.js, its
// deferred parts, assets/...). A browser holding an older copy would keep
// running the old app, or mix an old main.dart.js with a new editor part.
// flutter_bootstrap.js is never cached (see firebase.json), so pointing it
// at app/<hash>/ is enough to switch everyone to the new build.
//
//   flutter build web --release
//   node tools/fingerprint_web.mjs [build/web]
import { createHash } from 'node:crypto';
import { mkdir, readdir, readFile, rename, stat, writeFile } from 'node:fs/promises';
import { join, relative } from 'node:path';

const root = process.argv[2] ?? 'build/web';
const bootstrapPath = join(root, 'flutter_bootstrap.js');

const entries = await readdir(root);
const moved = [...entries.filter((f) => /^main\.dart\.js/.test(f)), 'assets'];
if (!entries.includes('main.dart.js') || !entries.includes('assets')) {
  throw new Error(`${root} is not a fresh Flutter web build (or was already fingerprinted)`);
}

/** Every file under [path] (or [path] itself when it is a file). */
async function files(path) {
  if (!(await stat(path)).isDirectory()) return [path];
  const nested = await Promise.all((await readdir(path)).map((name) => files(join(path, name))));
  return nested.flat();
}

// Paths and contents, in a stable order.
const hash = createHash('sha256');
const all = (await Promise.all(moved.map((name) => files(join(root, name))))).flat();
for (const file of all.map((f) => relative(root, f).replaceAll('\\', '/')).sort()) {
  hash.update(file);
  hash.update(await readFile(join(root, file)));
}
const dir = `app/${hash.digest('hex').slice(0, 12)}/`;

await mkdir(join(root, dir), { recursive: true });
for (const name of moved) await rename(join(root, name), join(root, dir, name));

// The entry point and the asset base both move to the new folder; deferred
// parts load from the same folder as main.dart.js.
let bootstrap = await readFile(bootstrapPath, 'utf8');
const patches = [
  ['"mainJsPath":"main.dart.js"', `"mainJsPath":"${dir}main.dart.js"`],
  ['_flutter.loader.load({', `_flutter.loader.load({\n  config: { assetBase: "${dir}" },`],
];
for (const [from, to] of patches) {
  if (!bootstrap.includes(from)) throw new Error(`flutter_bootstrap.js no longer contains ${from}`);
  bootstrap = bootstrap.replace(from, to);
}
await writeFile(bootstrapPath, bootstrap);
console.log(`App files moved to ${dir}`);
