import http from 'node:http';
let activeProject = null;
let currentServer = null;
export function setActiveProject(project) {
    activeProject = project;
}
export function getActiveProject() {
    return activeProject;
}
export async function getOrStartBridgeServer(preferredPort = 4004) {
    if (currentServer)
        return currentServer;
    return new Promise((resolve, reject) => {
        const server = http.createServer((req, res) => {
            // Enable CORS for all origins (local dev, hosted webapp, etc.)
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
            res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Accept');
            // Lets an https page (the hosted app) read this loopback server under
            // Chrome's Private Network Access preflight.
            res.setHeader('Access-Control-Allow-Private-Network', 'true');
            if (req.method === 'OPTIONS') {
                res.writeHead(204);
                res.end();
                return;
            }
            const url = new URL(req.url || '/', `http://127.0.0.1:${preferredPort}`);
            if (url.pathname === '/health') {
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ok', server: 'mokuply-mcp-bridge' }));
                return;
            }
            if (url.pathname === '/session.mokuply' || url.pathname === '/api/session.zip') {
                if (!activeProject || !activeProject.zipBuffer) {
                    res.writeHead(404, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'No active Mokuply project session available' }));
                    return;
                }
                res.writeHead(200, {
                    'Content-Type': 'application/zip',
                    'Content-Disposition': 'attachment; filename="mokuply_ai_project.zip"',
                    'Content-Length': activeProject.zipBuffer.length,
                });
                res.end(activeProject.zipBuffer);
                return;
            }
            if (url.pathname === '/api/session') {
                if (!activeProject) {
                    res.writeHead(404, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'No active session' }));
                    return;
                }
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(activeProject.templateJson));
                return;
            }
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Not Found');
        });
        server.on('error', err => {
            reject(err);
        });
        server.listen(preferredPort, '127.0.0.1', () => {
            const bridgeUrl = `http://127.0.0.1:${preferredPort}`;
            currentServer = {
                port: preferredPort,
                url: bridgeUrl,
                close: () => new Promise(cb => server.close(() => cb())),
                setActiveProject,
                getActiveProject,
            };
            resolve(currentServer);
        });
    });
}
//# sourceMappingURL=server.js.map