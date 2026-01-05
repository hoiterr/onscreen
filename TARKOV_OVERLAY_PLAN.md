# Tarkov Map Overlay Application - Implementation Plan

## Project Overview
Build a Windows desktop application similar to TarkovQuestie that provides:
- Real-time player position tracking via screenshot analysis
- Interactive map overlay with quest markers
- Quest progress tracking and synchronization
- Cross-device support (desktop + mobile web interface)

---

## Technology Stack Options

### Option 1: Electron + React/Vue (Recommended for MVP)
**Pros:**
- Fast development with web technologies
- Cross-platform (Windows, Mac, Linux)
- Rich UI component libraries
- Easy to build web interface for mobile
- Built-in overlay support

**Cons:**
- Larger memory footprint (~150-200MB)
- Slower startup time
- Not as performant as native

**Stack:**
- Electron (app framework)
- React/Vue (UI)
- Node.js (backend logic)
- SQLite (local database)
- Express (API server for mobile sync)

### Option 2: .NET WPF + C# (Best Performance)
**Pros:**
- Native Windows performance
- Excellent overlay capabilities
- Lower memory usage (~50-80MB)
- Fast file system monitoring
- Strong typing with C#

**Cons:**
- Windows-only
- Steeper learning curve
- Separate web app needed for mobile

**Stack:**
- WPF (UI framework)
- .NET 8 (runtime)
- Entity Framework Core (database)
- ASP.NET Core (API for mobile)
- SignalR (real-time sync)

### Option 3: Tauri + Rust (Modern Alternative)
**Pros:**
- Smallest bundle size (~3-5MB)
- Best performance
- Low memory usage
- Cross-platform
- Secure by default

**Cons:**
- Newer technology (smaller community)
- Rust learning curve
- Less mature ecosystem

**Recommended:** Start with **Electron** for rapid development, can port to .NET later for performance if needed.

---

## Core Features Breakdown

### 1. Screenshot Monitoring & Position Detection
**Requirements:**
- Monitor Tarkov screenshots folder for new files
- Parse GPS coordinates from screenshot filenames
- Extract position data in real-time
- Handle different coordinate encoding formats

**Implementation:**
```
- FileSystemWatcher to monitor screenshots folder
- Parse filename pattern: {timestamp}_{map}_{x}_{y}_{z}.png
- Convert coordinates to map pixel positions
- Update position every ~100ms when new screenshot detected
```

**Technical Challenges:**
- Finding Tarkov screenshots folder (registry/config file parsing)
- Handling different screenshot naming conventions
- Coordinate system conversion (in-game coords → map pixels)
- Performance (don't lag when monitoring)

### 2. Interactive Map Display
**Requirements:**
- Display high-resolution Tarkov maps
- Show player position marker with rotation
- Zoom and pan controls
- Quest markers and objectives
- Loot spawn locations
- Extract points

**Implementation:**
```
- Leaflet.js or custom canvas renderer for maps
- Map tiles stored locally (100-200MB per map)
- Vector overlays for markers
- Real-time position updates
- Minimap mode (always-on-top overlay)
```

**Technical Challenges:**
- Map calibration (game coords → pixel coords)
- High-res map tile management
- Smooth position interpolation
- Performance with many markers

### 3. Quest Tracking System
**Requirements:**
- Display all Tarkov quests
- Mark quests as active/complete
- Show quest objectives on map
- Filter markers by active quests
- Quest chain visualization
- Progress tracking

**Implementation:**
```
- Local quest database (quests.json from TarkovData)
- User progress stored in SQLite
- Quest objective markers linked to map locations
- Auto-show relevant quests per map
- Completion tracking via logs or manual
```

**Data Sources:**
- TarkovData repository (static quest data)
- Tarkov.dev API (up-to-date quest info)
- User's own progress database

### 4. Log File Monitoring (Auto Quest Completion)
**Requirements:**
- Monitor Tarkov log files
- Detect quest completion events
- Auto-mark quests complete
- Parse player profile data

**Implementation:**
```
- FileSystemWatcher on Tarkov logs folder
- Parse log entries for quest events
- Pattern matching for completion messages
- Background thread to avoid blocking UI
```

**Technical Challenges:**
- Log format changes with game updates
- Finding log file location
- Parsing Russian text (quest names)
- Event deduplication

### 5. Overlay Mode
**Requirements:**
- Always-on-top transparent window
- Click-through mode (optional)
- Hotkey to show/hide
- Resize and reposition
- Opacity control

**Implementation (Electron):**
```javascript
const overlayWindow = new BrowserWindow({
  transparent: true,
  frame: false,
  alwaysOnTop: true,
  skipTaskbar: true,
  resizable: true,
  webPreferences: {
    nodeIntegration: true
  }
});

// Click-through mode
overlayWindow.setIgnoreMouseEvents(true, { forward: true });
```

**Implementation (WPF):**
```csharp
WindowStyle = WindowStyle.None;
AllowsTransparency = true;
Topmost = true;
ShowInTaskbar = false;
```

### 6. Cross-Device Sync
**Requirements:**
- Web interface accessible on mobile
- Real-time position updates
- Quest progress sync
- Cloud save of user data

**Implementation:**
```
- REST API + WebSocket server
- JWT authentication
- SQLite → Cloud sync
- Mobile-responsive web UI
- QR code pairing for easy connection
```

**Tech:**
- Express.js + Socket.io (Electron)
- ASP.NET Core + SignalR (.NET)
- PostgreSQL/Firebase for cloud storage

---

## Architecture Design

### High-Level Architecture
```
┌─────────────────────────────────────────────────┐
│              Desktop Application                │
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │    UI    │  │ Overlay  │  │   Settings   │ │
│  │  Layer   │  │  Window  │  │    Panel     │ │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘ │
│       │             │                │         │
│  ┌────┴─────────────┴────────────────┴───────┐ │
│  │          Application Core                 │ │
│  │  - State Management                       │ │
│  │  - Event Bus                              │ │
│  │  - Configuration                          │ │
│  └────┬──────────┬──────────┬────────────┬──┘ │
│       │          │          │            │    │
│  ┌────▼────┐ ┌──▼─────┐ ┌──▼──────┐ ┌──▼───┐ │
│  │Position │ │ Quest  │ │   Log   │ │ Map  │ │
│  │Detector │ │Manager │ │ Monitor │ │Engine│ │
│  └────┬────┘ └───┬────┘ └───┬─────┘ └──┬───┘ │
│       │          │           │          │     │
│  ┌────▼──────────▼───────────▼──────────▼───┐ │
│  │          File System Watchers             │ │
│  │  - Screenshots Monitor                    │ │
│  │  - Log Files Monitor                      │ │
│  └────────────────────────────────────────────┘ │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │         Local Database (SQLite)          │  │
│  │  - Quest Progress                        │  │
│  │  - User Settings                         │  │
│  │  - Map Calibrations                      │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                       │
                       │ HTTP/WebSocket
                       │
         ┌─────────────▼─────────────┐
         │     API Server            │
         │  - REST endpoints         │
         │  - WebSocket server       │
         │  - Authentication         │
         └─────────────┬─────────────┘
                       │
         ┌─────────────▼─────────────┐
         │   Mobile Web Interface    │
         │  - Responsive UI          │
         │  - Real-time updates      │
         │  - Quest management       │
         └───────────────────────────┘
```

### Component Details

#### 1. Position Detector
```
Responsibilities:
- Monitor screenshots folder
- Parse screenshot filenames
- Extract GPS coordinates
- Convert to map positions
- Emit position update events

Key Classes:
- ScreenshotMonitor
- CoordinateParser
- MapCalibrator
- PositionEmitter
```

#### 2. Quest Manager
```
Responsibilities:
- Load quest database
- Track user progress
- Filter by active quests
- Generate map markers
- Handle quest completion

Key Classes:
- QuestDatabase
- ProgressTracker
- QuestFilter
- MarkerGenerator
```

#### 3. Log Monitor
```
Responsibilities:
- Watch Tarkov log files
- Parse log entries
- Detect quest completions
- Emit completion events

Key Classes:
- LogFileWatcher
- LogParser
- EventDetector
```

#### 4. Map Engine
```
Responsibilities:
- Render map tiles
- Display markers
- Handle zoom/pan
- Update player position
- Manage overlays

Key Classes:
- MapRenderer
- TileManager
- MarkerLayer
- PositionMarker
```

---

## Data Requirements

### 1. Map Data
**Source:** Extract from game files or use community resources

**Structure:**
```json
{
  "maps": [
    {
      "id": "customs",
      "name": "Customs",
      "imageUrl": "maps/customs.png",
      "width": 4096,
      "height": 4096,
      "bounds": {
        "minX": -500,
        "maxX": 500,
        "minY": -500,
        "maxY": 500
      },
      "calibrationPoints": [
        {"gameX": 100, "gameY": 200, "pixelX": 1024, "pixelY": 2048},
        {"gameX": -100, "gameY": -200, "pixelX": 3072, "pixelY": 1024}
      ]
    }
  ]
}
```

### 2. Quest Data
**Source:** [TarkovData GitHub](https://github.com/TarkovTracker/tarkovdata)

**Structure:**
```json
{
  "quests": [
    {
      "id": "5936d90786f7742b1420ba5b",
      "name": "Debut",
      "trader": "Prapor",
      "objectives": [
        {
          "type": "kill",
          "target": "Scav",
          "count": 5,
          "location": "customs",
          "positions": [
            {"x": 150, "y": 200, "description": "Gas station"}
          ]
        }
      ],
      "rewards": {
        "experience": 600,
        "items": [...]
      }
    }
  ]
}
```

### 3. User Progress Database
**Schema (SQLite):**
```sql
CREATE TABLE quest_progress (
  quest_id TEXT PRIMARY KEY,
  status TEXT CHECK(status IN ('locked', 'active', 'completed', 'failed')),
  objectives_completed TEXT, -- JSON array
  started_at DATETIME,
  completed_at DATETIME
);

CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);

CREATE TABLE position_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  map_id TEXT,
  x REAL,
  y REAL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)
**Goal:** Set up project foundation and basic monitoring

**Tasks:**
1. Set up Electron project with React/TypeScript
2. Implement file system watcher for screenshots
3. Create screenshot filename parser
4. Build basic coordinate extraction
5. Set up SQLite database
6. Create configuration management
7. Implement settings UI

**Deliverable:** App that can monitor screenshots folder and parse coordinates

### Phase 2: Map Display (Week 2-3)
**Goal:** Display interactive maps with position tracking

**Tasks:**
1. Integrate Leaflet.js or build custom renderer
2. Load and display map tiles
3. Implement zoom/pan controls
4. Add player position marker
5. Create coordinate transformation logic
6. Calibrate maps (game coords → pixels)
7. Test with sample screenshot data

**Deliverable:** Interactive map showing player position from screenshots

### Phase 3: Quest System (Week 3-4)
**Goal:** Quest tracking and marker display

**Tasks:**
1. Import TarkovData quest database
2. Build quest list UI
3. Implement quest filtering (by map, trader, status)
4. Create quest marker system
5. Add quest objective details
6. Build progress tracking
7. Manual quest completion UI

**Deliverable:** Full quest tracking with map markers

### Phase 4: Log Monitoring (Week 4-5)
**Goal:** Auto-detect quest completions

**Tasks:**
1. Locate Tarkov log files
2. Implement log file watcher
3. Build log parser
4. Pattern match quest completions
5. Auto-update quest progress
6. Add notification system
7. Error handling for log format changes

**Deliverable:** Automatic quest completion detection

### Phase 5: Overlay Mode (Week 5-6)
**Goal:** Always-on-top overlay window

**Tasks:**
1. Create transparent overlay window
2. Implement minimap mode
3. Add hotkey support (show/hide)
4. Build click-through toggle
5. Opacity controls
6. Position/size persistence
7. Performance optimization

**Deliverable:** Functional overlay mode

### Phase 6: API & Web Interface (Week 6-8)
**Goal:** Cross-device sync and mobile access

**Tasks:**
1. Build REST API with Express
2. Implement WebSocket server
3. Add authentication (JWT)
4. Create mobile-responsive web UI
5. Real-time position sync
6. Quest progress sync
7. QR code pairing system

**Deliverable:** Mobile web interface with real-time sync

### Phase 7: Polish & Features (Week 8-10)
**Goal:** Enhanced user experience

**Tasks:**
1. Add loot spawn markers
2. Implement extract point display
3. Build route planning
4. Add quest helper tooltips
5. Create onboarding tutorial
6. Performance optimization
7. Error handling & logging
8. Auto-update system

**Deliverable:** Production-ready application

### Phase 8: Testing & Release (Week 10-12)
**Goal:** Stable public release

**Tasks:**
1. Comprehensive testing
2. Bug fixes
3. Documentation
4. Installer creation (NSIS)
5. Auto-update setup
6. Website/landing page
7. Community feedback
8. Initial release

**Deliverable:** v1.0 public release

---

## Key Technical Challenges & Solutions

### Challenge 1: Finding Tarkov Installation
**Problem:** Need to locate screenshots and log folders

**Solutions:**
1. Check registry keys: `HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\EscapeFromTarkov`
2. Search common install paths: `C:\Games\Escape from Tarkov`, `C:\Battlestate Games\`
3. Parse launcher config: `%APPDATA%\Battlestate Games\BsgLauncher\`
4. Let user manually select folder
5. Save location in settings

### Challenge 2: Coordinate Calibration
**Problem:** Converting in-game coordinates to map pixels

**Solution:**
```javascript
// Use multiple calibration points (minimum 3)
const calibrationPoints = [
  { gameX: 100, gameY: 200, pixelX: 1024, pixelY: 2048 },
  { gameX: -100, gameY: -200, pixelX: 3072, pixelY: 1024 },
  { gameX: 0, gameY: 0, pixelX: 2048, pixelY: 2048 }
];

// Calculate transformation matrix
function gameToPixel(gameX, gameY) {
  // Use affine transformation or polynomial regression
  const scaleX = (maxPixelX - minPixelX) / (maxGameX - minGameX);
  const scaleY = (maxPixelY - minPixelY) / (maxGameY - minGameY);

  const pixelX = (gameX - minGameX) * scaleX + minPixelX;
  const pixelY = (gameY - minGameY) * scaleY + minPixelY;

  return { pixelX, pixelY };
}
```

### Challenge 3: Performance with Large Maps
**Problem:** High-res maps (4096x4096+) can lag

**Solutions:**
1. Tile maps into chunks (256x256 tiles)
2. Lazy load tiles based on viewport
3. Use canvas rendering instead of DOM
4. Implement virtual scrolling for markers
5. Debounce position updates (100ms)
6. Web Workers for heavy computation

### Challenge 4: Game Updates Breaking Compatibility
**Problem:** Log format or screenshot naming changes

**Solutions:**
1. Version detection from logs
2. Multiple parser strategies
3. Fallback to manual input
4. Auto-update system
5. Community reporting
6. Graceful degradation

### Challenge 5: Cross-Platform File Paths
**Problem:** Different OS path conventions

**Solution:**
```javascript
const path = require('path');
const os = require('os');

function getTarkovPath() {
  const platform = os.platform();

  if (platform === 'win32') {
    return path.join(process.env.USERPROFILE, 'Documents', 'Escape from Tarkov', 'Screenshots');
  } else if (platform === 'darwin') {
    return path.join(process.env.HOME, 'Library', 'Application Support', 'com.battlestate.EscapeFromTarkov', 'Screenshots');
  }

  // Fallback to user selection
  return null;
}
```

---

## Resource Requirements

### Development
- 1-2 developers (full-stack)
- 10-12 weeks initial development
- Ongoing maintenance

### Infrastructure
- GitHub repository (free)
- CI/CD pipeline (GitHub Actions - free)
- Domain + hosting for API (~$10/month)
- Database hosting (PostgreSQL - $15/month or self-hosted)
- CDN for map tiles (optional - $20/month)

### Assets Needed
1. High-resolution map images (all Tarkov maps)
2. Quest data (TarkovData repository)
3. Icon set for markers
4. UI assets (buttons, panels)
5. Sound effects (optional)

### Legal Considerations
- Don't distribute game assets (maps)
- Have users extract their own maps or use community versions
- Clear ToS stating no game modification
- Disclaimer about ban risks (even if minimal)

---

## Testing Strategy

### Unit Tests
- Coordinate parser
- Transformation functions
- Quest filtering logic
- Database operations

### Integration Tests
- File watcher + parser
- API endpoints
- WebSocket connections
- Database sync

### E2E Tests
- Screenshot detection flow
- Quest marking workflow
- Overlay interaction
- Mobile sync

### Manual Testing
- Test with actual Tarkov screenshots
- Verify map accuracy
- Performance testing (long sessions)
- Multi-monitor setup testing

---

## Success Metrics

### Technical
- < 100MB memory usage (idle)
- < 1s screenshot processing time
- 60 FPS UI performance
- < 500ms API response time

### User Experience
- < 2 minutes from install to first use
- < 5 clicks to mark a quest
- Zero game performance impact
- Works on Windows 10/11

### Adoption
- 1000+ downloads in first month
- < 5% crash rate
- > 4.0 star rating
- Active community feedback

---

## Future Enhancements (v2.0+)

1. **Team Coordination**
   - Share positions with squad
   - Voice channel integration
   - Waypoint system

2. **Analytics Dashboard**
   - Survival rate tracking
   - Heat maps of deaths
   - Quest completion stats
   - Time spent per map

3. **Enhanced Overlays**
   - Custom marker creation
   - Drawing tools
   - Screenshot annotation
   - Loot value calculator

4. **AI Features**
   - Route optimization
   - Quest order suggestions
   - Risk assessment
   - Spawn prediction

5. **Community Features**
   - Share custom markers
   - Community maps
   - User-submitted calibrations
   - Plugin system

---

## Alternatives & Similar Projects to Study

1. **TarkovQuestie** - Study their UI/UX
2. **TarkovTracker** - Learn from their API design
3. **Rat Scanner** - Screenshot analysis techniques
4. **Overwolf Apps** - Overlay best practices
5. **PoE Overlay** - Similar game overlay app

---

## Recommended First Steps

1. **Research Phase** (1 week)
   - Study TarkovQuestie (if you can access it)
   - Download and test similar tools
   - Analyze Tarkov screenshot format
   - Test log file monitoring

2. **Prototype** (1 week)
   - Build basic screenshot parser
   - Display single map
   - Show position from sample data
   - Validate concept

3. **MVP Decision Point**
   - If prototype works: proceed to Phase 1
   - If blockers found: reassess approach
   - Get early user feedback

4. **Set Up Development Environment**
   - Initialize Electron project
   - Set up TypeScript + React
   - Configure ESLint + Prettier
   - Set up Git repository
   - Create CI/CD pipeline

---

## Conclusion

This is an ambitious but achievable project. The key is to:
- Start with MVP (Phases 1-3)
- Focus on screenshot monitoring (proven safe approach)
- Use existing community data sources
- Build incrementally
- Test with real Tarkov gameplay
- Engage community early for feedback

Estimated timeline: **10-12 weeks** for v1.0 with 1-2 developers

The biggest risks are:
1. Game updates breaking compatibility
2. Finding/calibrating maps accurately
3. Performance with overlay mode
4. User adoption in competitive market

But with the research done and proven similar apps existing, this is definitely feasible!
