import * as chokidar from 'chokidar';
import * as path from 'path';
import * as fs from 'fs';
import { EventEmitter } from 'events';
import { ScreenshotData, Coordinates } from '../../shared/types';

export interface ScreenshotMonitorConfig {
  screenshotsPath: string;
  pollInterval?: number;
  awaitWriteFinish?: boolean;
}

/**
 * Monitors Tarkov screenshots folder and extracts position data from filenames
 *
 * Screenshot filename formats supported:
 * - Standard: YYYY-MM-DD_HH-MM-SS_mapname_x_y_z.png
 * - Alternative: screenshot_mapname_x_y_z.png
 */
export class ScreenshotMonitor extends EventEmitter {
  private watcher: chokidar.FSWatcher | null = null;
  private config: ScreenshotMonitorConfig;
  private isRunning: boolean = false;
  private processedFiles: Set<string> = new Set();

  constructor(config: ScreenshotMonitorConfig) {
    super();
    this.config = {
      pollInterval: 100,
      awaitWriteFinish: true,
      ...config
    };
  }

  /**
   * Start monitoring the screenshots folder
   */
  start(): void {
    if (this.isRunning) {
      console.warn('⚠️ ScreenshotMonitor already running');
      return;
    }

    if (!fs.existsSync(this.config.screenshotsPath)) {
      throw new Error(`Screenshots path does not exist: ${this.config.screenshotsPath}`);
    }

    console.log(`🔍 Starting screenshot monitor: ${this.config.screenshotsPath}`);

    this.watcher = chokidar.watch(this.config.screenshotsPath, {
      persistent: true,
      ignoreInitial: true, // Don't process existing files on startup
      awaitWriteFinish: this.config.awaitWriteFinish ? {
        stabilityThreshold: 1000,
        pollInterval: this.config.pollInterval
      } : false,
      depth: 0 // Only watch the immediate directory
    });

    this.watcher.on('add', (filePath: string) => {
      this.handleNewScreenshot(filePath);
    });

    this.watcher.on('error', (error: Error) => {
      console.error('❌ Screenshot monitor error:', error);
      this.emit('error', error);
    });

    this.isRunning = true;
    this.emit('started');
    console.log('✅ Screenshot monitor started');
  }

  /**
   * Stop monitoring
   */
  stop(): void {
    if (!this.isRunning) {
      return;
    }

    console.log('🛑 Stopping screenshot monitor...');

    if (this.watcher) {
      this.watcher.close();
      this.watcher = null;
    }

    this.isRunning = false;
    this.processedFiles.clear();
    this.emit('stopped');
    console.log('✅ Screenshot monitor stopped');
  }

  /**
   * Handle new screenshot file
   */
  private handleNewScreenshot(filePath: string): void {
    const filename = path.basename(filePath);

    // Skip if already processed
    if (this.processedFiles.has(filename)) {
      return;
    }

    // Only process PNG files
    if (!filename.toLowerCase().endsWith('.png')) {
      return;
    }

    console.log(`📸 New screenshot: ${filename}`);
    this.processedFiles.add(filename);

    const data = this.parseScreenshotFilename(filename);

    if (data) {
      console.log(`✅ Parsed position: Map=${data.map}, X=${data.coordinates?.x}, Y=${data.coordinates?.y}`);
      this.emit('screenshot', data);
    } else {
      console.log(`⚠️ Could not parse filename: ${filename}`);
      this.emit('parse-error', { filename, error: 'Invalid format' });
    }
  }

  /**
   * Parse screenshot filename to extract position data
   *
   * Supported formats:
   * 1. 2024-01-15_12-30-45_customs_150.5_200.3_10.2.png
   * 2. screenshot_customs_150.5_200.3_10.2.png
   * 3. EFT_2024_01_15_customs_150.5_200.3_10.2.png
   */
  parseScreenshotFilename(filename: string): ScreenshotData | null {
    // Remove .png extension
    const nameWithoutExt = filename.replace(/\.png$/i, '');
    const parts = nameWithoutExt.split('_');

    // Try different parsing strategies
    let parseResult = this.tryStandardFormat(parts, filename);
    if (parseResult) return parseResult;

    parseResult = this.trySimpleFormat(parts, filename);
    if (parseResult) return parseResult;

    parseResult = this.tryAlternativeFormat(parts, filename);
    if (parseResult) return parseResult;

    return null;
  }

  /**
   * Standard format: YYYY-MM-DD_HH-MM-SS_mapname_x_y_z
   */
  private tryStandardFormat(parts: string[], filename: string): ScreenshotData | null {
    if (parts.length < 6) return null;

    try {
      // parts[0] = YYYY-MM-DD
      // parts[1] = HH-MM-SS
      // parts[2] = mapname
      // parts[3] = x
      // parts[4] = y
      // parts[5] = z

      const datePart = parts[0];
      const timePart = parts[1];
      const map = parts[2];
      const x = parseFloat(parts[3]);
      const y = parseFloat(parts[4]);
      const z = parseFloat(parts[5]);

      if (isNaN(x) || isNaN(y) || isNaN(z)) {
        return null;
      }

      // Parse timestamp
      const dateTimeStr = `${datePart.replace(/-/g, '/')} ${timePart.replace(/-/g, ':')}`;
      const timestamp = new Date(dateTimeStr);

      if (isNaN(timestamp.getTime())) {
        return null;
      }

      return {
        filename,
        timestamp,
        map: this.normalizeMapName(map),
        coordinates: { x, y, z }
      };
    } catch (error) {
      return null;
    }
  }

  /**
   * Simple format: screenshot_mapname_x_y_z
   */
  private trySimpleFormat(parts: string[], filename: string): ScreenshotData | null {
    if (parts.length < 5 || parts[0] !== 'screenshot') return null;

    try {
      const map = parts[1];
      const x = parseFloat(parts[2]);
      const y = parseFloat(parts[3]);
      const z = parseFloat(parts[4]);

      if (isNaN(x) || isNaN(y) || isNaN(z)) {
        return null;
      }

      return {
        filename,
        timestamp: new Date(),
        map: this.normalizeMapName(map),
        coordinates: { x, y, z }
      };
    } catch (error) {
      return null;
    }
  }

  /**
   * Alternative format: EFT_YYYY_MM_DD_mapname_x_y_z
   */
  private tryAlternativeFormat(parts: string[], filename: string): ScreenshotData | null {
    if (parts.length < 8 || parts[0] !== 'EFT') return null;

    try {
      // parts[0] = EFT
      // parts[1] = YYYY
      // parts[2] = MM
      // parts[3] = DD
      // parts[4] = mapname
      // parts[5] = x
      // parts[6] = y
      // parts[7] = z

      const map = parts[4];
      const x = parseFloat(parts[5]);
      const y = parseFloat(parts[6]);
      const z = parseFloat(parts[7]);

      if (isNaN(x) || isNaN(y) || isNaN(z)) {
        return null;
      }

      const timestamp = new Date(`${parts[1]}-${parts[2]}-${parts[3]}`);

      return {
        filename,
        timestamp,
        map: this.normalizeMapName(map),
        coordinates: { x, y, z }
      };
    } catch (error) {
      return null;
    }
  }

  /**
   * Normalize map name to lowercase and standard format
   */
  private normalizeMapName(mapName: string): string {
    return mapName.toLowerCase().trim();
  }

  /**
   * Get monitoring status
   */
  getStatus(): { isRunning: boolean; path: string; processedCount: number } {
    return {
      isRunning: this.isRunning,
      path: this.config.screenshotsPath,
      processedCount: this.processedFiles.size
    };
  }

  /**
   * Clear processed files cache (useful for testing)
   */
  clearCache(): void {
    this.processedFiles.clear();
  }
}
