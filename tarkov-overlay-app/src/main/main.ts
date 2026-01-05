import { app, BrowserWindow, ipcMain, globalShortcut, dialog } from 'electron';
import * as path from 'path';
import { ScreenshotMonitor } from './services/ScreenshotMonitor';
import { TarkovPathDetector } from './utils/TarkovPathDetector';
import { ScreenshotData } from '../shared/types';

let mainWindow: BrowserWindow | null = null;
let overlayWindow: BrowserWindow | null = null;
let screenshotMonitor: ScreenshotMonitor | null = null;

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true
    },
    title: 'Tarkov Overlay',
    backgroundColor: '#1a1a1a'
  });

  // Load the index.html
  mainWindow.loadFile(path.join(__dirname, '../../index.html'));

  // Open DevTools in development
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function createOverlayWindow() {
  overlayWindow = new BrowserWindow({
    width: 400,
    height: 400,
    transparent: true,
    frame: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true
    }
  });

  overlayWindow.loadFile(path.join(__dirname, '../../overlay.html'));
  overlayWindow.hide(); // Hidden by default

  overlayWindow.on('closed', () => {
    overlayWindow = null;
  });
}

function registerHotkeys() {
  // Toggle overlay with F11
  globalShortcut.register('F11', () => {
    if (overlayWindow) {
      if (overlayWindow.isVisible()) {
        overlayWindow.hide();
      } else {
        overlayWindow.show();
      }
    }
  });

  console.log('Hotkeys registered (F11 = Toggle Overlay)');
}

/**
 * Initialize screenshot monitoring
 */
function initializeScreenshotMonitor() {
  console.log('\n🔍 Initializing screenshot monitor...');

  // Detect Tarkov paths
  const paths = TarkovPathDetector.detectAllPaths();

  console.log('📁 Detected paths:', {
    install: paths.installPath || 'Not found',
    screenshots: paths.screenshotsPath || 'Not found',
    logs: paths.logsPath || 'Not found'
  });

  if (!paths.screenshotsPath) {
    console.log('⚠️ Screenshots folder not found. User will need to manually configure.');

    // Notify renderer
    if (mainWindow) {
      mainWindow.webContents.send('monitor-status', {
        status: 'not-configured',
        message: 'Screenshots folder not found. Please configure manually.'
      });
    }
    return;
  }

  // Create and start monitor
  try {
    screenshotMonitor = new ScreenshotMonitor({
      screenshotsPath: paths.screenshotsPath
    });

    screenshotMonitor.on('screenshot', (data: ScreenshotData) => {
      console.log(`📍 Position update: ${data.map} (${data.coordinates?.x}, ${data.coordinates?.y})`);

      // Send to both windows
      if (mainWindow && !mainWindow.isDestroyed()) {
        mainWindow.webContents.send('position-update', data);
      }

      if (overlayWindow && !overlayWindow.isDestroyed()) {
        overlayWindow.webContents.send('position-update', data);
      }
    });

    screenshotMonitor.on('parse-error', ({ filename, error }) => {
      console.log(`⚠️ Parse error for ${filename}: ${error}`);
    });

    screenshotMonitor.on('error', (error: Error) => {
      console.error('❌ Screenshot monitor error:', error);
    });

    screenshotMonitor.start();

    // Notify renderer
    if (mainWindow) {
      mainWindow.webContents.send('monitor-status', {
        status: 'running',
        path: paths.screenshotsPath
      });
    }
  } catch (error) {
    console.error('❌ Failed to start screenshot monitor:', error);

    if (mainWindow) {
      mainWindow.webContents.send('monitor-status', {
        status: 'error',
        message: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }
}

// IPC Handlers
ipcMain.handle('get-app-path', () => {
  return app.getPath('userData');
});

ipcMain.handle('toggle-overlay', () => {
  if (overlayWindow) {
    if (overlayWindow.isVisible()) {
      overlayWindow.hide();
      return false;
    } else {
      overlayWindow.show();
      return true;
    }
  }
  return false;
});

ipcMain.handle('detect-tarkov-paths', () => {
  return TarkovPathDetector.detectAllPaths();
});

ipcMain.handle('browse-screenshots-folder', async () => {
  const result = await dialog.showOpenDialog({
    properties: ['openDirectory'],
    title: 'Select Tarkov Screenshots Folder'
  });

  if (!result.canceled && result.filePaths.length > 0) {
    return result.filePaths[0];
  }

  return null;
});

ipcMain.handle('set-screenshots-path', (_, screenshotsPath: string) => {
  try {
    // Stop existing monitor
    if (screenshotMonitor) {
      screenshotMonitor.stop();
    }

    // Start new monitor with provided path
    screenshotMonitor = new ScreenshotMonitor({
      screenshotsPath
    });

    screenshotMonitor.on('screenshot', (data: ScreenshotData) => {
      if (mainWindow && !mainWindow.isDestroyed()) {
        mainWindow.webContents.send('position-update', data);
      }
      if (overlayWindow && !overlayWindow.isDestroyed()) {
        overlayWindow.webContents.send('position-update', data);
      }
    });

    screenshotMonitor.start();

    return { success: true, path: screenshotsPath };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

ipcMain.handle('get-monitor-status', () => {
  if (screenshotMonitor) {
    return screenshotMonitor.getStatus();
  }
  return { isRunning: false, path: '', processedCount: 0 };
});

// App lifecycle
app.on('ready', () => {
  createMainWindow();
  createOverlayWindow();
  registerHotkeys();

  console.log('🚀 Tarkov Overlay started');
  console.log('⌨️  Press F11 to toggle overlay');

  // Initialize screenshot monitor after windows are ready
  setTimeout(() => {
    initializeScreenshotMonitor();
  }, 1000);
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createMainWindow();
  }
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();

  // Stop screenshot monitor
  if (screenshotMonitor) {
    screenshotMonitor.stop();
  }
});

// Handle errors
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});
