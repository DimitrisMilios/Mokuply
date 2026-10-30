import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import path from 'node:path';
import os from 'node:os';
import fs from 'node:fs/promises';
const execFileAsync = promisify(execFile);
export async function listBootedIosSimulators() {
    if (process.platform !== 'darwin')
        return [];
    try {
        const { stdout } = await execFileAsync('xcrun', ['simctl', 'list', 'devices', 'available', '-j']);
        const data = JSON.parse(stdout);
        const devices = [];
        const deviceMap = data.devices || {};
        for (const runtime of Object.keys(deviceMap)) {
            for (const dev of deviceMap[runtime]) {
                if (dev.state === 'Booted') {
                    devices.push({
                        id: dev.udid,
                        name: `${dev.name} (${runtime.split('.').pop() || 'iOS'})`,
                        platform: 'ios',
                        state: 'booted',
                        details: dev.deviceTypeIdentifier,
                    });
                }
            }
        }
        return devices;
    }
    catch {
        return [];
    }
}
export async function captureIosSimulator(deviceId = 'booted', destinationDir) {
    if (process.platform !== 'darwin') {
        throw new Error('iOS Simulator capture is only supported on macOS with Xcode installed.');
    }
    const dir = destinationDir ? path.resolve(destinationDir) : path.join(os.tmpdir(), 'mokuply_captures');
    await fs.mkdir(dir, { recursive: true });
    const filename = `ios_sim_${Date.now()}.png`;
    const filePath = path.join(dir, filename);
    try {
        await execFileAsync('xcrun', ['simctl', 'io', deviceId, 'screenshot', filePath]);
        return { filePath, deviceName: deviceId };
    }
    catch (err) {
        const error = err;
        throw new Error(`Failed to capture iOS Simulator screenshot: ${error.message || String(err)}`);
    }
}
//# sourceMappingURL=ios.js.map