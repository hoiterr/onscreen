import { app, BrowserWindow, ipcMain, globalShortcut } from 'electron';
import * as path from 'path';

let mainWindow: BrowserWindow | null = null;
let overlayWindow: BrowserWindow | null = null;

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

// App lifecycle
app.on('ready', () => {
  createMainWindow();
  createOverlayWindow();
  registerHotkeys();

  console.log('Tarkov Overlay started');
  console.log('Press F11 to toggle overlay');
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
});

// Handle errors
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});
