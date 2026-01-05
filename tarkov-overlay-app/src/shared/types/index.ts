/**
 * Shared type definitions used across main and renderer processes
 */

export interface Coordinates {
  x: number;
  y: number;
  z: number;
}

export interface ScreenshotData {
  filename: string;
  timestamp: Date;
  map?: string;
  coordinates?: Coordinates;
}

export interface PositionUpdate {
  map: string;
  coordinates: Coordinates;
  timestamp: Date;
}

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
  location?: QuestLocation[];
}

export interface QuestLocation {
  map: string;
  x: number;
  y: number;
  description?: string;
}

export interface QuestRequirement {
  type: 'level' | 'quest' | 'loyalty';
  value: number | string;
}

export interface MapData {
  id: string;
  name: string;
  imagePath: string;
  width: number;
  height: number;
  bounds: MapBounds;
  calibrationPoints: CalibrationPoint[];
}

export interface MapBounds {
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
}

export interface CalibrationPoint {
  gameX: number;
  gameY: number;
  pixelX: number;
  pixelY: number;
}

export interface AppSettings {
  screenshotsPath?: string;
  logsPath?: string;
  overlayHotkey?: string;
  overlayOpacity?: number;
  enableLogMonitoring?: boolean;
  enableMobileSync?: boolean;
  apiPort?: number;
}
