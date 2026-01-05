import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

export interface TarkovPaths {
  installPath: string | null;
  screenshotsPath: string | null;
  logsPath: string | null;
}

export class TarkovPathDetector {
  private static COMMON_INSTALL_PATHS = [
    'C:\\Battlestate Games\\BsgLauncher\\games\\EscapeFromTarkov',
    'C:\\Games\\Escape from Tarkov',
    'D:\\Battlestate Games\\EscapeFromTarkov',
    'D:\\Games\\Escape from Tarkov',
    'E:\\Battlestate Games\\EscapeFromTarkov',
    'E:\\Games\\Escape from Tarkov'
  ];

  /**
   * Attempts to detect Tarkov installation path using multiple methods
   */
  static detectInstallPath(): string | null {
    console.log('🔍 Detecting Tarkov installation path...');

    // Method 1: Check Windows registry
    if (process.platform === 'win32') {
      const registryPath = this.checkRegistry();
      if (registryPath) {
        console.log('✅ Found via registry:', registryPath);
        return registryPath;
      }
    }

    // Method 2: Check common installation paths
    for (const commonPath of this.COMMON_INSTALL_PATHS) {
      if (fs.existsSync(commonPath)) {
        const executable = path.join(commonPath, 'EscapeFromTarkov.exe');
        if (fs.existsSync(executable)) {
          console.log('✅ Found via common path:', commonPath);
          return commonPath;
        }
      }
    }

    // Method 3: Check Documents folder (screenshots are sometimes here)
    const documentsPath = this.checkDocumentsFolder();
    if (documentsPath) {
      console.log('✅ Found screenshots in Documents:', documentsPath);
      return documentsPath;
    }

    console.log('❌ Could not auto-detect Tarkov installation');
    return null;
  }

  /**
   * Check Windows registry for installation path
   */
  private static checkRegistry(): string | null {
    if (process.platform !== 'win32') return null;

    try {
      // Try multiple registry keys
      const registryKeys = [
        'HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\EscapeFromTarkov',
        'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\EscapeFromTarkov'
      ];

      for (const key of registryKeys) {
        try {
          const result = execSync(
            `reg query "${key}" /v InstallLocation`,
            { encoding: 'utf-8', windowsHide: true }
          );

          const match = result.match(/InstallLocation\s+REG_SZ\s+(.+)/);
          if (match && match[1]) {
            const installPath = match[1].trim();
            if (fs.existsSync(installPath)) {
              return installPath;
            }
          }
        } catch (e) {
          // This key doesn't exist, try next one
          continue;
        }
      }
    } catch (error) {
      // Registry query failed
    }

    return null;
  }

  /**
   * Check Documents folder for Tarkov data
   */
  private static checkDocumentsFolder(): string | null {
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

  /**
   * Get screenshots folder path
   */
  static getScreenshotsPath(installPath?: string): string | null {
    const detectedPath = installPath || this.detectInstallPath();
    if (!detectedPath) return null;

    // Try multiple possible locations
    const possiblePaths = [
      path.join(detectedPath, 'Screenshots'),
      path.join(detectedPath, 'EscapeFromTarkov_Data', 'Screenshots'),
      detectedPath // Documents folder might contain screenshots directly
    ];

    for (const screenshotsPath of possiblePaths) {
      if (fs.existsSync(screenshotsPath)) {
        // Verify it's actually a screenshots folder
        const files = fs.readdirSync(screenshotsPath);
        const hasPngFiles = files.some(f => f.endsWith('.png'));
        if (hasPngFiles || files.length === 0) {
          console.log('📁 Screenshots folder:', screenshotsPath);
          return screenshotsPath;
        }
      }
    }

    console.log('❌ Screenshots folder not found');
    return null;
  }

  /**
   * Get logs folder path
   */
  static getLogsPath(installPath?: string): string | null {
    const detectedPath = installPath || this.detectInstallPath();
    if (!detectedPath) return null;

    const possiblePaths = [
      path.join(detectedPath, 'Logs'),
      path.join(detectedPath, 'EscapeFromTarkov_Data', 'Logs')
    ];

    for (const logsPath of possiblePaths) {
      if (fs.existsSync(logsPath)) {
        console.log('📁 Logs folder:', logsPath);
        return logsPath;
      }
    }

    return null;
  }

  /**
   * Get all Tarkov paths at once
   */
  static detectAllPaths(): TarkovPaths {
    const installPath = this.detectInstallPath();
    const screenshotsPath = this.getScreenshotsPath(installPath || undefined);
    const logsPath = this.getLogsPath(installPath || undefined);

    return {
      installPath,
      screenshotsPath,
      logsPath
    };
  }

  /**
   * Validate a manually provided path
   */
  static validatePath(providedPath: string): boolean {
    if (!fs.existsSync(providedPath)) {
      return false;
    }

    // Check if it looks like a Tarkov folder
    const hasExecutable = fs.existsSync(path.join(providedPath, 'EscapeFromTarkov.exe'));
    const hasScreenshots = fs.existsSync(path.join(providedPath, 'Screenshots'));

    return hasExecutable || hasScreenshots;
  }
}
