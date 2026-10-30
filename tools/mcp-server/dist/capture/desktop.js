import path from 'node:path';
import fs from 'node:fs/promises';
import { existsSync } from 'node:fs';
export async function findWorkspaceScreenshots(searchDir = process.cwd()) {
    const commonFolders = [
        'screenshots',
        'screenshot',
        'fastlane/screenshots',
        'assets/screenshots',
        'assets/images',
        'docs/screenshots',
        'test/screenshots',
    ];
    const results = [];
    for (const folder of commonFolders) {
        const fullPath = path.resolve(searchDir, folder);
        if (existsSync(fullPath)) {
            try {
                const files = await fs.readdir(fullPath);
                for (const file of files) {
                    if (/\.(png|jpe?g|webp)$/i.test(file)) {
                        results.push(path.join(fullPath, file));
                    }
                }
            }
            catch {
                // Continue
            }
        }
    }
    return results;
}
//# sourceMappingURL=desktop.js.map