import { PackageResult } from '../generator/packager.js';
export interface BridgeServer {
    port: number;
    url: string;
    close: () => Promise<void>;
    setActiveProject: (project: PackageResult) => void;
    getActiveProject: () => PackageResult | null;
}
export declare function setActiveProject(project: PackageResult): void;
export declare function getActiveProject(): PackageResult | null;
export declare function getOrStartBridgeServer(preferredPort?: number): Promise<BridgeServer>;
