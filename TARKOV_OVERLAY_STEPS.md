# Tarkov Overlay Application - Step-by-Step Implementation Guide

## Prerequisites Setup

### Step 1: Install Development Tools
```bash
# Install Node.js (v18+) and npm
# Download from: https://nodejs.org/

# Install Git
# Download from: https://git-scm.com/

# Install VS Code (recommended)
# Download from: https://code.visualstudio.com/
```

### Step 2: Set Up Development Environment
```bash
# Create project directory
mkdir tarkov-overlay
cd tarkov-overlay

# Initialize git repository
git init

# Create .gitignore
echo "node_modules/
dist/
.env
*.log
.DS_Store
Thumbs.db
*.db
*.sqlite" > .gitignore
```

---

## Phase 1: Project Foundation (Days 1-3)

### Step 3: Initialize Electron + React Project
```bash
# Use electron-vite template
npm create @quick-start/electron tarkov-overlay-app
cd tarkov-overlay-app

# Or manual setup:
npm init -y
npm install electron electron-builder
npm install react react-dom
npm install --save-dev @types/react @types/react-dom
npm install --save-dev typescript @types/node
npm install --save-dev webpack webpack-cli webpack-dev-server
```

### Step 4: Configure TypeScript
```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020", "DOM"],
    "jsx": "react",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "outDir": "./dist"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

### Step 5: Set Up Project Structure
```bash
mkdir -p src/{main,renderer,shared}
mkdir -p src/main/{services,utils}
mkdir -p src/renderer/{components,hooks,contexts}
mkdir -p src/shared/{types,constants}
mkdir -p resources/{maps,icons}
mkdir -p data/{quests,calibrations}

# Create main entry point
touch src/main/main.ts
touch src/main/preload.ts
touch src/renderer/index.tsx
touch src/renderer/App.tsx
```

### Step 6: Create Basic Electron Window
```typescript
// src/main/main.ts
import { app, BrowserWindow } from 'electron';
import * as path from 'path';

let mainWindow: BrowserWindow | null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true
    }
  });

  mainWindow.loadFile('index.html');
  mainWindow.on('closed', () => { mainWindow = null; });
}

app.on('ready', createWindow);
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
```

### Step 7: Create Basic React App
```tsx
// src/renderer/App.tsx
import React from 'react';

function App() {
  return (
    <div className="app">
      <h1>Tarkov Overlay</h1>
      <p>Setup complete!</p>
    </div>
  );
}

export default App;
```

### Step 8: Test Basic App Launch
```bash
# Add to package.json scripts:
"scripts": {
  "start": "electron .",
  "build": "tsc && webpack",
  "dev": "webpack serve --mode development"
}

# Run the app
npm start
```

---

## Phase 2: Screenshot Monitoring (Days 4-7)

### Step 9: Install File Watching Dependencies
```bash
npm install chokidar
npm install --save-dev @types/node
```

### Step 10: Create Screenshot Monitor Service
```typescript
// src/main/services/ScreenshotMonitor.ts
import * as chokidar from 'chokidar';
import * as path from 'path';
import * as fs from 'fs';
import { EventEmitter } from 'events';

export interface ScreenshotData {
  filename: string;
  timestamp: Date;
  map?: string;
  coordinates?: {
    x: number;
    y: number;
    z: number;
  };
}

export class ScreenshotMonitor extends EventEmitter {
  private watcher: chokidar.FSWatcher | null = null;
  private screenshotPath: string;

  constructor(screenshotPath: string) {
    super();
    this.screenshotPath = screenshotPath;
  }

  start() {
    this.watcher = chokidar.watch(this.screenshotPath, {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: {
        stabilityThreshold: 1000,
        pollInterval: 100
      }
    });

    this.watcher.on('add', (filePath) => {
      this.handleNewScreenshot(filePath);
    });

    console.log(`Monitoring: ${this.screenshotPath}`);
  }

  stop() {
    if (this.watcher) {
      this.watcher.close();
      this.watcher = null;
    }
  }

  private handleNewScreenshot(filePath: string) {
    const filename = path.basename(filePath);
    const data = this.parseScreenshotFilename(filename);

    if (data) {
      this.emit('screenshot', data);
    }
  }

  private parseScreenshotFilename(filename: string): ScreenshotData | null {
    // Example format: 2024-01-15_12-30-45_customs_150.5_200.3_10.2.png
    const pattern = /(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})_([a-z]+)_([-\d.]+)_([-\d.]+)_([-\d.]+)\.png/i;
    const match = filename.match(pattern);

    if (!match) return null;

    return {
      filename,
      timestamp: new Date(match[1].replace(/_/g, ' ').replace(/-/g, ':')),
      map: match[2],
      coordinates: {
        x: parseFloat(match[3]),
        y: parseFloat(match[4]),
        z: parseFloat(match[5])
      }
    };
  }
}
```

### Step 11: Create Tarkov Path Detector
```typescript
// src/main/utils/TarkovPathDetector.ts
import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

export class TarkovPathDetector {
  private static COMMON_PATHS = [
    'C:\\Battlestate Games\\BsgLauncher\\games\\EscapeFromTarkov',
    'C:\\Games\\Escape from Tarkov',
    'D:\\Escape from Tarkov',
    'E:\\Escape from Tarkov'
  ];

  static detectInstallPath(): string | null {
    // Method 1: Check registry (Windows)
    if (process.platform === 'win32') {
      try {
        const regPath = execSync(
          'reg query "HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\EscapeFromTarkov" /v InstallLocation',
          { encoding: 'utf-8' }
        );
        const match = regPath.match(/InstallLocation\s+REG_SZ\s+(.+)/);
        if (match) return match[1].trim();
      } catch (e) {
        // Registry key not found
      }
    }

    // Method 2: Check common paths
    for (const commonPath of this.COMMON_PATHS) {
      if (fs.existsSync(commonPath)) {
        return commonPath;
      }
    }

    // Method 3: Check Documents folder
    const documentsPath = path.join(
      process.env.USERPROFILE || process.env.HOME || '',
      'Documents',
      'Escape from Tarkov'
    );
    if (fs.existsSync(documentsPath)) {
      return documentsPath;
    }

    return null;
  }

  static getScreenshotsPath(installPath?: string): string | null {
    if (!installPath) {
      installPath = this.detectInstallPath();
    }
    if (!installPath) return null;

    const screenshotsPath = path.join(installPath, 'Screenshots');
    return fs.existsSync(screenshotsPath) ? screenshotsPath : null;
  }

  static getLogsPath(installPath?: string): string | null {
    if (!installPath) {
      installPath = this.detectInstallPath();
    }
    if (!installPath) return null;

    const logsPath = path.join(installPath, 'Logs');
    return fs.existsSync(logsPath) ? logsPath : null;
  }
}
```

### Step 12: Integrate Screenshot Monitor with Main Process
```typescript
// src/main/main.ts (add to existing code)
import { ScreenshotMonitor } from './services/ScreenshotMonitor';
import { TarkovPathDetector } from './utils/TarkovPathDetector';

let screenshotMonitor: ScreenshotMonitor | null = null;

function initializeScreenshotMonitor() {
  const screenshotsPath = TarkovPathDetector.getScreenshotsPath();

  if (!screenshotsPath) {
    console.error('Could not find Tarkov screenshots folder');
    return;
  }

  screenshotMonitor = new ScreenshotMonitor(screenshotsPath);

  screenshotMonitor.on('screenshot', (data) => {
    console.log('New position:', data);
    // Send to renderer process
    if (mainWindow) {
      mainWindow.webContents.send('position-update', data);
    }
  });

  screenshotMonitor.start();
}

// Call after app is ready
app.on('ready', () => {
  createWindow();
  initializeScreenshotMonitor();
});
```

### Step 13: Set Up IPC Communication
```typescript
// src/main/preload.ts
import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('electronAPI', {
  onPositionUpdate: (callback: (data: any) => void) => {
    ipcRenderer.on('position-update', (_, data) => callback(data));
  }
});
```

### Step 14: Test Screenshot Detection
```bash
# Create a test screenshot in the detected folder with correct naming
# Run the app and verify console output
npm start
```

---

## Phase 3: Map Display (Days 8-12)

### Step 15: Install Map Library
```bash
npm install leaflet
npm install react-leaflet
npm install --save-dev @types/leaflet
```

### Step 16: Download/Prepare Map Images
```bash
# Create map structure
mkdir -p resources/maps/customs
mkdir -p resources/maps/woods
mkdir -p resources/maps/shoreline
# etc...

# Download map images from community sources or extract from game
# Place in: resources/maps/{mapName}/{mapName}.png
```

### Step 17: Create Map Calibration Data
```typescript
// data/calibrations/maps.json
{
  "customs": {
    "id": "customs",
    "name": "Customs",
    "imagePath": "resources/maps/customs/customs.png",
    "width": 4096,
    "height": 4096,
    "bounds": {
      "minX": -500,
      "maxX": 500,
      "minY": -500,
      "maxY": 500
    },
    "calibrationPoints": [
      { "gameX": 0, "gameY": 0, "pixelX": 2048, "pixelY": 2048 },
      { "gameX": 200, "gameY": 300, "pixelX": 2500, "pixelY": 2800 },
      { "gameX": -150, "gameY": -200, "pixelX": 1600, "pixelY": 1500 }
    ]
  }
}
```

### Step 18: Create Coordinate Transformer
```typescript
// src/shared/utils/CoordinateTransformer.ts
export interface CalibrationPoint {
  gameX: number;
  gameY: number;
  pixelX: number;
  pixelY: number;
}

export class CoordinateTransformer {
  private scaleX: number;
  private scaleY: number;
  private offsetX: number;
  private offsetY: number;

  constructor(calibrationPoints: CalibrationPoint[]) {
    // Use first two points to calculate transformation
    const p1 = calibrationPoints[0];
    const p2 = calibrationPoints[1];

    this.scaleX = (p2.pixelX - p1.pixelX) / (p2.gameX - p1.gameX);
    this.scaleY = (p2.pixelY - p1.pixelY) / (p2.gameY - p1.gameY);
    this.offsetX = p1.pixelX - (p1.gameX * this.scaleX);
    this.offsetY = p1.pixelY - (p1.gameY * this.scaleY);
  }

  gameToPixel(gameX: number, gameY: number): { x: number; y: number } {
    return {
      x: (gameX * this.scaleX) + this.offsetX,
      y: (gameY * this.scaleY) + this.offsetY
    };
  }

  pixelToGame(pixelX: number, pixelY: number): { x: number; y: number } {
    return {
      x: (pixelX - this.offsetX) / this.scaleX,
      y: (pixelY - this.offsetY) / this.scaleY
    };
  }
}
```

### Step 19: Create Map Component
```tsx
// src/renderer/components/MapView.tsx
import React, { useEffect, useState } from 'react';
import { MapContainer, ImageOverlay, Marker } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

interface Position {
  x: number;
  y: number;
  map: string;
}

export const MapView: React.FC = () => {
  const [position, setPosition] = useState<Position | null>(null);
  const [bounds] = useState(L.latLngBounds([0, 0], [4096, 4096]));

  useEffect(() => {
    window.electronAPI.onPositionUpdate((data) => {
      if (data.coordinates) {
        // Transform game coordinates to pixel coordinates
        setPosition({
          x: data.coordinates.x,
          y: data.coordinates.y,
          map: data.map
        });
      }
    });
  }, []);

  return (
    <div style={{ width: '100%', height: '100vh' }}>
      <MapContainer
        center={[2048, 2048]}
        zoom={1}
        maxZoom={5}
        minZoom={0}
        crs={L.CRS.Simple}
        bounds={bounds}
        style={{ width: '100%', height: '100%' }}
      >
        <ImageOverlay
          url="resources/maps/customs/customs.png"
          bounds={bounds}
        />

        {position && (
          <Marker position={[position.y, position.x]}>
            <div className="player-marker" />
          </Marker>
        )}
      </MapContainer>
    </div>
  );
};
```

### Step 20: Update App to Use Map Component
```tsx
// src/renderer/App.tsx
import React from 'react';
import { MapView } from './components/MapView';

function App() {
  return (
    <div className="app">
      <MapView />
    </div>
  );
}

export default App;
```

### Step 21: Test Map Display with Mock Data
```bash
# Run app and verify map displays
npm start

# Manually trigger position update from dev console
# Should see marker move on map
```

---

## Phase 4: Database & Quest System (Days 13-18)

### Step 22: Install Database Dependencies
```bash
npm install better-sqlite3
npm install --save-dev @types/better-sqlite3
```

### Step 23: Create Database Schema
```typescript
// src/main/database/schema.ts
import Database from 'better-sqlite3';

export function initializeDatabase(dbPath: string): Database.Database {
  const db = new Database(dbPath);

  // Quest progress table
  db.exec(`
    CREATE TABLE IF NOT EXISTS quest_progress (
      quest_id TEXT PRIMARY KEY,
      status TEXT CHECK(status IN ('locked', 'available', 'active', 'completed', 'failed')),
      objectives_completed TEXT,
      started_at INTEGER,
      completed_at INTEGER
    );
  `);

  // Settings table
  db.exec(`
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );
  `);

  // Position history table
  db.exec(`
    CREATE TABLE IF NOT EXISTS position_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      map_id TEXT,
      x REAL,
      y REAL,
      z REAL,
      timestamp INTEGER DEFAULT (strftime('%s', 'now'))
    );
  `);

  return db;
}
```

### Step 24: Download Quest Data
```bash
# Clone TarkovData repository
git clone https://github.com/TarkovTracker/tarkovdata.git temp-tarkovdata

# Copy quest data
cp temp-tarkovdata/quests.json data/quests/
cp temp-tarkovdata/maps.json data/maps/

# Clean up
rm -rf temp-tarkovdata
```

### Step 25: Create Quest Service
```typescript
// src/main/services/QuestService.ts
import Database from 'better-sqlite3';
import * as fs from 'fs';
import * as path from 'path';

export interface Quest {
  id: string;
  name: string;
  trader: string;
  map?: string;
  objectives: QuestObjective[];
  requirements?: QuestRequirement[];
}

export interface QuestObjective {
  id: string;
  type: string;
  description: string;
  optional: boolean;
  location?: { map: string; x: number; y: number }[];
}

export class QuestService {
  private db: Database.Database;
  private quests: Map<string, Quest> = new Map();

  constructor(db: Database.Database, questDataPath: string) {
    this.db = db;
    this.loadQuests(questDataPath);
  }

  private loadQuests(questDataPath: string) {
    const questData = JSON.parse(fs.readFileSync(questDataPath, 'utf-8'));

    for (const quest of questData) {
      this.quests.set(quest.id, quest);
    }
  }

  getAllQuests(): Quest[] {
    return Array.from(this.quests.values());
  }

  getQuestsByMap(mapId: string): Quest[] {
    return Array.from(this.quests.values())
      .filter(q => q.map === mapId || q.objectives.some(o => o.location?.some(l => l.map === mapId)));
  }

  getQuestProgress(questId: string) {
    const stmt = this.db.prepare('SELECT * FROM quest_progress WHERE quest_id = ?');
    return stmt.get(questId);
  }

  updateQuestStatus(questId: string, status: string) {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO quest_progress (quest_id, status, started_at)
      VALUES (?, ?, ?)
    `);
    stmt.run(questId, status, Date.now());
  }

  getActiveQuests(): Quest[] {
    const stmt = this.db.prepare('SELECT quest_id FROM quest_progress WHERE status = ?');
    const activeIds = stmt.all('active').map((row: any) => row.quest_id);
    return activeIds.map(id => this.quests.get(id)).filter(Boolean) as Quest[];
  }
}
```

### Step 26: Create Quest UI Components
```tsx
// src/renderer/components/QuestList.tsx
import React, { useState, useEffect } from 'react';

interface Quest {
  id: string;
  name: string;
  trader: string;
  status: string;
}

export const QuestList: React.FC = () => {
  const [quests, setQuests] = useState<Quest[]>([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    // Fetch quests from main process
    window.electronAPI.getQuests().then(setQuests);
  }, []);

  const toggleQuestActive = (questId: string) => {
    window.electronAPI.toggleQuest(questId);
  };

  return (
    <div className="quest-list">
      <div className="quest-filters">
        <button onClick={() => setFilter('all')}>All</button>
        <button onClick={() => setFilter('active')}>Active</button>
        <button onClick={() => setFilter('available')}>Available</button>
      </div>

      <div className="quests">
        {quests
          .filter(q => filter === 'all' || q.status === filter)
          .map(quest => (
            <div key={quest.id} className="quest-item">
              <h3>{quest.name}</h3>
              <p>{quest.trader}</p>
              <button onClick={() => toggleQuestActive(quest.id)}>
                {quest.status === 'active' ? 'Deactivate' : 'Activate'}
              </button>
            </div>
          ))
        }
      </div>
    </div>
  );
};
```

### Step 27: Add Quest Markers to Map
```tsx
// Update src/renderer/components/MapView.tsx
import { Marker, Popup } from 'react-leaflet';

// Add quest markers
{activeQuests.map(quest =>
  quest.objectives.map(obj =>
    obj.location?.map((loc, idx) => (
      <Marker key={`${quest.id}-${idx}`} position={[loc.y, loc.x]}>
        <Popup>
          <strong>{quest.name}</strong>
          <p>{obj.description}</p>
        </Popup>
      </Marker>
    ))
  )
)}
```

---

## Phase 5: Log Monitoring (Days 19-21)

### Step 28: Create Log Monitor Service
```typescript
// src/main/services/LogMonitor.ts
import * as chokidar from 'chokidar';
import * as fs from 'fs';
import { EventEmitter } from 'events';

export class LogMonitor extends EventEmitter {
  private watcher: chokidar.FSWatcher | null = null;
  private logPath: string;
  private lastPosition: number = 0;

  constructor(logPath: string) {
    super();
    this.logPath = logPath;
  }

  start() {
    // Find most recent log file
    const logFiles = fs.readdirSync(this.logPath)
      .filter(f => f.endsWith('.log'))
      .sort()
      .reverse();

    if (logFiles.length === 0) return;

    const latestLog = `${this.logPath}/${logFiles[0]}`;
    this.lastPosition = fs.statSync(latestLog).size;

    this.watcher = chokidar.watch(latestLog, {
      persistent: true
    });

    this.watcher.on('change', () => {
      this.readNewLogLines(latestLog);
    });
  }

  private readNewLogLines(filePath: string) {
    const stats = fs.statSync(filePath);
    const newContent = Buffer.alloc(stats.size - this.lastPosition);

    const fd = fs.openSync(filePath, 'r');
    fs.readSync(fd, newContent, 0, newContent.length, this.lastPosition);
    fs.closeSync(fd);

    this.lastPosition = stats.size;

    const lines = newContent.toString().split('\n');
    lines.forEach(line => this.parseLine(line));
  }

  private parseLine(line: string) {
    // Quest completion pattern
    if (line.includes('Quest completed')) {
      const match = line.match(/Quest completed: (.+)/);
      if (match) {
        this.emit('quest-completed', { questName: match[1] });
      }
    }

    // Raid start pattern
    if (line.includes('Raid started')) {
      const match = line.match(/Map: (.+)/);
      if (match) {
        this.emit('raid-started', { map: match[1] });
      }
    }
  }

  stop() {
    if (this.watcher) {
      this.watcher.close();
    }
  }
}
```

### Step 29: Integrate Log Monitor
```typescript
// Add to src/main/main.ts
import { LogMonitor } from './services/LogMonitor';

let logMonitor: LogMonitor | null = null;

function initializeLogMonitor() {
  const logsPath = TarkovPathDetector.getLogsPath();
  if (!logsPath) return;

  logMonitor = new LogMonitor(logsPath);

  logMonitor.on('quest-completed', (data) => {
    console.log('Quest completed:', data);
    // Auto-mark quest as complete in database
  });

  logMonitor.start();
}
```

---

## Phase 6: Overlay Mode (Days 22-25)

### Step 30: Create Overlay Window
```typescript
// src/main/windows/OverlayWindow.ts
import { BrowserWindow } from 'electron';

export class OverlayWindow {
  private window: BrowserWindow;

  constructor() {
    this.window = new BrowserWindow({
      width: 400,
      height: 400,
      transparent: true,
      frame: false,
      alwaysOnTop: true,
      skipTaskbar: true,
      resizable: true,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true
      }
    });

    this.window.setIgnoreMouseEvents(false);
    this.window.loadFile('overlay.html');
  }

  show() {
    this.window.show();
  }

  hide() {
    this.window.hide();
  }

  setClickThrough(enabled: boolean) {
    this.window.setIgnoreMouseEvents(enabled, { forward: true });
  }

  setOpacity(opacity: number) {
    this.window.setOpacity(opacity);
  }
}
```

### Step 31: Create Minimap Component
```tsx
// src/renderer/components/Minimap.tsx
import React from 'react';
import './Minimap.css';

export const Minimap: React.FC = () => {
  return (
    <div className="minimap-container">
      <div className="minimap">
        {/* Simplified map view */}
        <canvas id="minimap-canvas" width={300} height={300} />
      </div>
    </div>
  );
};
```

### Step 32: Add Hotkey Support
```typescript
// src/main/main.ts
import { globalShortcut } from 'electron';

function registerHotkeys() {
  // Toggle overlay with F11
  globalShortcut.register('F11', () => {
    if (overlayWindow) {
      overlayWindow.isVisible() ? overlayWindow.hide() : overlayWindow.show();
    }
  });

  // Toggle click-through with F10
  globalShortcut.register('F10', () => {
    // Toggle click-through state
  });
}

app.on('ready', () => {
  createWindow();
  registerHotkeys();
});
```

---

## Phase 7: API & Mobile Sync (Days 26-32)

### Step 33: Set Up Express API
```bash
npm install express cors jsonwebtoken
npm install --save-dev @types/express @types/cors @types/jsonwebtoken
```

### Step 34: Create API Server
```typescript
// src/main/api/server.ts
import express from 'express';
import cors from 'cors';
import { Server as SocketIOServer } from 'socket.io';
import http from 'http';

export class APIServer {
  private app: express.Application;
  private server: http.Server;
  private io: SocketIOServer;

  constructor(private port: number = 3000) {
    this.app = express();
    this.server = http.createServer(this.app);
    this.io = new SocketIOServer(this.server, {
      cors: { origin: '*' }
    });

    this.setupMiddleware();
    this.setupRoutes();
    this.setupWebSocket();
  }

  private setupMiddleware() {
    this.app.use(cors());
    this.app.use(express.json());
  }

  private setupRoutes() {
    this.app.get('/api/quests', (req, res) => {
      // Return quests from database
    });

    this.app.get('/api/position', (req, res) => {
      // Return current position
    });
  }

  private setupWebSocket() {
    this.io.on('connection', (socket) => {
      console.log('Client connected');

      socket.on('disconnect', () => {
        console.log('Client disconnected');
      });
    });
  }

  start() {
    this.server.listen(this.port, () => {
      console.log(`API server running on port ${this.port}`);
    });
  }

  broadcastPosition(position: any) {
    this.io.emit('position-update', position);
  }
}
```

### Step 35: Create Mobile Web Interface
```bash
# Create separate React app for mobile
mkdir mobile-web
cd mobile-web
npx create-react-app . --template typescript
npm install socket.io-client react-leaflet leaflet
```

### Step 36: Build Mobile UI
```tsx
// mobile-web/src/App.tsx
import React, { useEffect, useState } from 'react';
import io from 'socket.io-client';
import { MapContainer, Marker } from 'react-leaflet';

function App() {
  const [position, setPosition] = useState(null);
  const [socket, setSocket] = useState(null);

  useEffect(() => {
    const newSocket = io('http://localhost:3000');
    setSocket(newSocket);

    newSocket.on('position-update', (data) => {
      setPosition(data);
    });

    return () => newSocket.close();
  }, []);

  return (
    <div className="mobile-app">
      <h1>Tarkov Overlay Mobile</h1>
      {position && (
        <MapContainer>
          <Marker position={[position.y, position.x]} />
        </MapContainer>
      )}
    </div>
  );
}
```

---

## Phase 8: Polish & Release (Days 33-40)

### Step 37: Add Settings Panel
```tsx
// src/renderer/components/Settings.tsx
export const Settings: React.FC = () => {
  return (
    <div className="settings">
      <h2>Settings</h2>

      <div className="setting-group">
        <label>Screenshot Folder:</label>
        <input type="text" />
        <button>Browse</button>
      </div>

      <div className="setting-group">
        <label>Overlay Hotkey:</label>
        <input type="text" />
      </div>

      <div className="setting-group">
        <label>Opacity:</label>
        <input type="range" min="0" max="100" />
      </div>
    </div>
  );
};
```

### Step 38: Configure Electron Builder
```json
// package.json
{
  "build": {
    "appId": "com.yourname.tarkovoverlay",
    "productName": "Tarkov Overlay",
    "directories": {
      "output": "release"
    },
    "files": [
      "dist/**/*",
      "resources/**/*",
      "data/**/*"
    ],
    "win": {
      "target": "nsis",
      "icon": "resources/icon.ico"
    },
    "nsis": {
      "oneClick": false,
      "allowToChangeInstallationDirectory": true
    }
  }
}
```

### Step 39: Build Installer
```bash
npm install --save-dev electron-builder

# Build for Windows
npm run build
npx electron-builder --win
```

### Step 40: Create Documentation
```markdown
# README.md

## Installation
1. Download latest release
2. Run installer
3. Launch application

## Setup
1. App will auto-detect Tarkov folder
2. Bind screenshot key in Tarkov (F12 recommended)
3. Start a raid and press screenshot key
4. Your position will appear on the map!

## Features
- Real-time position tracking
- Quest markers and tracking
- Overlay mode (F11)
- Mobile sync

## Troubleshooting
...
```

---

## Testing Checklist

### Functional Tests
- [ ] Screenshot detection works
- [ ] Position updates in real-time
- [ ] Maps display correctly
- [ ] Quest markers appear
- [ ] Log monitoring detects completions
- [ ] Overlay mode works
- [ ] Hotkeys function
- [ ] Settings save/load
- [ ] API server starts
- [ ] Mobile sync works

### Performance Tests
- [ ] < 100MB memory usage
- [ ] < 5% CPU usage (idle)
- [ ] No frame drops in overlay
- [ ] Fast screenshot processing (< 1s)

### Compatibility Tests
- [ ] Windows 10 (64-bit)
- [ ] Windows 11
- [ ] Multiple monitors
- [ ] 4K displays

---

## Deployment

### Step 41: Set Up GitHub Repository
```bash
git remote add origin https://github.com/yourusername/tarkov-overlay.git
git push -u origin main
```

### Step 42: Create GitHub Release
```bash
# Tag version
git tag v1.0.0
git push --tags

# Upload installer to GitHub Releases
# Upload to: https://github.com/yourusername/tarkov-overlay/releases
```

### Step 43: Set Up Auto-Updater
```typescript
// src/main/updater.ts
import { autoUpdater } from 'electron-updater';

export function setupAutoUpdater() {
  autoUpdater.checkForUpdatesAndNotify();

  autoUpdater.on('update-available', () => {
    // Notify user
  });
}
```

---

## Post-Launch

### Step 44: Community Engagement
- Create Discord server
- Set up issue tracker
- Write usage guides
- Collect feedback
- Plan v2.0 features

### Step 45: Monitoring & Analytics
- Track crash reports
- Monitor performance
- Analyze usage patterns
- Gather feature requests

---

## Timeline Summary

| Phase | Days | Tasks |
|-------|------|-------|
| Setup | 1-3 | Project initialization, basic window |
| Screenshot Monitoring | 4-7 | File watching, parsing, path detection |
| Map Display | 8-12 | Leaflet integration, coordinate transform |
| Quest System | 13-18 | Database, quest data, UI |
| Log Monitoring | 19-21 | Auto quest completion |
| Overlay Mode | 22-25 | Transparent window, hotkeys |
| API & Mobile | 26-32 | Express server, WebSocket, mobile UI |
| Polish & Release | 33-40 | Settings, installer, docs, testing |

**Total: ~40 days (6-8 weeks) for solo developer**

---

## Essential Resources

- TarkovData: https://github.com/TarkovTracker/tarkovdata
- Tarkov.dev API: https://tarkov.dev/api/
- Electron Docs: https://www.electronjs.org/docs
- React Leaflet: https://react-leaflet.js.org/
- Better SQLite3: https://github.com/WiseLibs/better-sqlite3
