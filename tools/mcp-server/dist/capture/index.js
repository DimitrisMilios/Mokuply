import { listBootedIosSimulators, captureIosSimulator } from './ios.js';
import { listConnectedAndroidDevices, captureAndroidDevice } from './android.js';
export async function listAllDevices() {
    const [ios, android] = await Promise.all([
        listBootedIosSimulators(),
        listConnectedAndroidDevices(),
    ]);
    return [...ios, ...android];
}
export async function captureSimulator(options) {
    const platform = options?.platform ?? 'auto';
    if (platform === 'ios') {
        const res = await captureIosSimulator(options?.deviceId, options?.outputDir);
        return { ...res, platform: 'ios' };
    }
    if (platform === 'android') {
        const res = await captureAndroidDevice(options?.deviceId, options?.outputDir);
        return { ...res, platform: 'android' };
    }
    // Auto-detect: check what devices are running
    const devices = await listAllDevices();
    if (devices.length === 0) {
        if (process.platform === 'darwin') {
            // Attempt iOS booted capture anyway (sometimes simctl reports lag)
            try {
                const res = await captureIosSimulator('booted', options?.outputDir);
                return { ...res, platform: 'ios' };
            }
            catch {
                // Fallback to error below
            }
        }
        throw new Error(`No active iOS Simulator or Android Emulator detected.\n` +
            `- On macOS: Please start an iOS Simulator via Xcode Simulator.app or an Android Emulator.\n` +
            `- On Linux & Windows: Please launch an Android Emulator via Android Studio or 'emulator -avd <name>', and ensure adb is connected.`);
    }
    const target = options?.deviceId
        ? devices.find(d => d.id === options.deviceId) ?? devices[0]
        : devices[0];
    if (target.platform === 'ios') {
        const res = await captureIosSimulator(target.id, options?.outputDir);
        return { ...res, platform: 'ios' };
    }
    else {
        const res = await captureAndroidDevice(target.id, options?.outputDir);
        return { ...res, platform: 'android' };
    }
}
//# sourceMappingURL=index.js.map