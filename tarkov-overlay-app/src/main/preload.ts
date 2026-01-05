import { contextBridge, ipcRenderer } from 'electron';

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Position updates from screenshot monitor
  onPositionUpdate: (callback: (data: any) => void) => {
    ipcRenderer.on('position-update', (_, data) => callback(data));
  },

  // Quest updates
  onQuestUpdate: (callback: (data: any) => void) => {
    ipcRenderer.on('quest-update', (_, data) => callback(data));
  },

  // Get quests
  getQuests: () => ipcRenderer.invoke('get-quests'),

  // Toggle quest active status
  toggleQuest: (questId: string) => ipcRenderer.invoke('toggle-quest', questId),

  // Get app path
  getAppPath: () => ipcRenderer.invoke('get-app-path'),

  // Toggle overlay window
  toggleOverlay: () => ipcRenderer.invoke('toggle-overlay'),

  // Settings
  getSetting: (key: string) => ipcRenderer.invoke('get-setting', key),
  setSetting: (key: string, value: any) => ipcRenderer.invoke('set-setting', key, value),

  // Remove listener
  removeListener: (channel: string, callback: any) => {
    ipcRenderer.removeListener(channel, callback);
  }
});

// Type definitions for window.electronAPI
export interface ElectronAPI {
  onPositionUpdate: (callback: (data: any) => void) => void;
  onQuestUpdate: (callback: (data: any) => void) => void;
  getQuests: () => Promise<any[]>;
  toggleQuest: (questId: string) => Promise<void>;
  getAppPath: () => Promise<string>;
  toggleOverlay: () => Promise<boolean>;
  getSetting: (key: string) => Promise<any>;
  setSetting: (key: string, value: any) => Promise<void>;
  removeListener: (channel: string, callback: any) => void;
}

declare global {
  interface Window {
    electronAPI: ElectronAPI;
  }
}
