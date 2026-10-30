import { execFile, spawn } from 'node:child_process';
import { promisify } from 'node:util';
import path from 'node:path';
import os from 'node:os';
import fs from 'node:fs/promises';
import { createWriteStream } from 'node:fs';
import { CapturedDevice } from '../types/mokuply.js';

const execFileAsync = promisify(execFile);

function getAdbCommand(): string {
  if (process.platform === 'win32') {
    return 'adb.exe';
  }
  return 'adb';
}

export async function listConnectedAndroidDevices(): Promise<CapturedDevice[]> {
  const adb = getAdbCommand();
  try {
    const { stdout } = await execFileAsync(adb, ['devices', '-l']);
    const lines = stdout.trim().split('\n').slice(1);
    const devices: CapturedDevice[] = [];

    for (const line of lines) {
      const parts = line.trim().split(/\s+/);
      if (parts.length >= 2 && parts[1] === 'device') {
        const id = parts[0];
        const modelMatch = line.match(/model:(\S+)/);
        const deviceMatch = line.match(/device:(\S+)/);
        const name = modelMatch ? modelMatch[1] : (deviceMatch ? deviceMatch[1] : id);

        devices.push({
          id,
          name: `Android: ${name}`,
          platform: 'android',
          state: 'device',
          details: line.trim(),
        });
      }
    }
    return devices;
  } catch {
    return [];
  }
}

export async function captureAndroidDevice(
  deviceId?: string,
  destinationDir?: string
): Promise<{ filePath: string; deviceName: string }> {
  const adb = getAdbCommand();
  const dir = destinationDir ? path.resolve(destinationDir) : path.join(os.tmpdir(), 'mokuply_captures');
  await fs.mkdir(dir, { recursive: true });

  const filename = `android_sim_${Date.now()}.png`;
  const filePath = path.join(dir, filename);

  const args = deviceId ? ['-s', deviceId, 'exec-out', 'screencap', '-p'] : ['exec-out', 'screencap', '-p'];

  return new Promise((resolve, reject) => {
    const child = spawn(adb, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const writeStream = createWriteStream(filePath);

    child.stdout.pipe(writeStream);

    let stderr = '';
    child.stderr.on('data', chunk => {
      stderr += chunk.toString();
    });

    child.on('error', err => {
      reject(new Error(`Failed to run adb. Is Android SDK / platform-tools installed? Details: ${err.message}`));
    });

    child.on('close', code => {
      if (code !== 0) {
        reject(new Error(`adb screencap failed with code ${code}: ${stderr}`));
      } else {
        resolve({
          filePath,
          deviceName: deviceId || 'default-android-device',
        });
      }
    });
  });
}
