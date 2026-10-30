import { CapturedDevice } from '../types/mokuply.js';
export declare function listConnectedAndroidDevices(): Promise<CapturedDevice[]>;
export declare function captureAndroidDevice(deviceId?: string, destinationDir?: string): Promise<{
    filePath: string;
    deviceName: string;
}>;
