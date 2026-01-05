# Tarkov Overlay Application

Real-time position tracking and quest helper for Escape from Tarkov.

## Features (In Development)

- ✅ Real-time position tracking via screenshot analysis
- ✅ Overlay mode (transparent, always-on-top)
- 🚧 Interactive maps with markers
- 🚧 Quest tracking system
- 🚧 Log file monitoring
- 🚧 Mobile sync

## Current Status

**Phase 1 Complete:** Basic Electron + React application structure

### What's Working
- Electron window setup
- React UI with styling
- Overlay window (transparent, always-on-top)
- Hotkey support (F11 to toggle overlay)
- IPC communication between main and renderer

### Next Steps
1. Implement screenshot monitoring
2. Add coordinate parsing
3. Integrate map display
4. Build quest database

## Development Setup

### Prerequisites
- Node.js 18+
- npm or yarn
- Windows 10/11

### Installation

```bash
# Install dependencies
npm install

# Compile TypeScript
npm run build

# Run the application
npm start
```

### Development Mode

```bash
# Watch TypeScript files
npm run watch

# In another terminal, run webpack dev server
npm run dev

# In another terminal, run Electron
npm start
```

## Usage

1. Launch the application
2. Press **F11** to toggle overlay mode
3. Bind screenshot key in Tarkov (F12 recommended)
4. Take screenshots during raids to see your position

## Project Structure

```
tarkov-overlay-app/
├── src/
│   ├── main/          # Electron main process
│   │   ├── services/  # Screenshot monitor, quest service, etc.
│   │   ├── utils/     # Helper functions
│   │   └── main.ts    # Main entry point
│   ├── renderer/      # React UI
│   │   ├── components/
│   │   ├── App.tsx
│   │   └── index.tsx
│   └── shared/        # Shared types and constants
├── resources/         # Map images, icons
├── data/             # Quest data, calibrations
└── dist/             # Compiled output
```

## Roadmap

### Phase 1: Foundation ✅
- [x] Project setup
- [x] Basic Electron window
- [x] React UI
- [x] Overlay mode

### Phase 2: Screenshot Monitoring 🚧
- [ ] File system watcher
- [ ] Screenshot parser
- [ ] Tarkov path detection
- [ ] Coordinate extraction

### Phase 3: Maps 📋
- [ ] Map display with Leaflet
- [ ] Coordinate transformation
- [ ] Player position marker
- [ ] Zoom/pan controls

### Phase 4: Quests 📋
- [ ] SQLite database
- [ ] Quest data import
- [ ] Quest list UI
- [ ] Map markers

### Phase 5: Advanced Features 📋
- [ ] Log monitoring
- [ ] Mobile API
- [ ] Settings panel
- [ ] Auto-updater

## License

MIT

## Disclaimer

This tool is not affiliated with or endorsed by Battlestate Games. Use at your own risk. The tool only reads screenshots and log files - it does not modify game files or memory.
