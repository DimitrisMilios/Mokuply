import { CapturedDevice } from '../types/mokuply.js';
export declare function listAllDevices(): Promise<CapturedDevice[]>;
export declare function captureSimulator(options?: {
    platform?: 'ios' | 'android' | 'auto';
    deviceId?: string;
    outputDir?: string;
}): Promise<{
    filePath: string;
    deviceName: string;
    platform: 'ios' | 'android';
}>;
