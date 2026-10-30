import { CapturedDevice } from '../types/mokuply.js';
export declare function listBootedIosSimulators(): Promise<CapturedDevice[]>;
export declare function captureIosSimulator(deviceId?: string, destinationDir?: string): Promise<{
    filePath: string;
    deviceName: string;
}>;
