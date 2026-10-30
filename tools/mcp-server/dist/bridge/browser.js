import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
const execFileAsync = promisify(execFile);
export async function openBrowser(url) {
    const platform = process.platform;
    try {
        if (platform === 'darwin') {
            await execFileAsync('open', [url]);
        }
        else if (platform === 'win32') {
            await execFileAsync('cmd.exe', ['/c', 'start', '""', url]);
        }
        else {
            // Linux, FreeBSD, OpenBSD, etc.
            await execFileAsync('xdg-open', [url]);
        }
    }
    catch (err) {
        console.error(`Failed to open browser automatically:`, err);
    }
}
//# sourceMappingURL=browser.js.map