import React, { useState, useEffect } from 'react';

const App: React.FC = () => {
  const [status, setStatus] = useState<string>('Initializing...');
  const [overlayVisible, setOverlayVisible] = useState<boolean>(false);

  useEffect(() => {
    // Check if electronAPI is available
    if (window.electronAPI) {
      setStatus('Ready - Waiting for Tarkov screenshots...');

      // Listen for position updates
      window.electronAPI.onPositionUpdate((data) => {
        console.log('Position update:', data);
        setStatus(`Position: Map ${data.map}, X: ${data.coordinates?.x}, Y: ${data.coordinates?.y}`);
      });
    } else {
      setStatus('Error: Electron API not available');
    }
  }, []);

  const handleToggleOverlay = async () => {
    if (window.electronAPI) {
      const visible = await window.electronAPI.toggleOverlay();
      setOverlayVisible(visible);
    }
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>🎮 Tarkov Overlay</h1>
        <p className="subtitle">Real-time Position Tracking & Quest Helper</p>
      </header>

      <main className="app-main">
        <div className="status-card">
          <h2>Status</h2>
          <div className="status-indicator">
            <span className="status-dot"></span>
            <span>{status}</span>
          </div>
        </div>

        <div className="controls-card">
          <h2>Controls</h2>
          <div className="button-group">
            <button
              className="btn btn-primary"
              onClick={handleToggleOverlay}
            >
              {overlayVisible ? '🔽 Hide Overlay' : '🔼 Show Overlay'}
            </button>
            <button className="btn btn-secondary">
              ⚙️ Settings
            </button>
          </div>
          <div className="hotkeys">
            <p><kbd>F11</kbd> - Toggle Overlay</p>
            <p><kbd>F12</kbd> - Take Screenshot (Tarkov)</p>
          </div>
        </div>

        <div className="info-card">
          <h2>Quick Start</h2>
          <ol className="steps-list">
            <li>Bind screenshot key in Tarkov (F12 recommended)</li>
            <li>Start a raid and press your screenshot key</li>
            <li>Your position will appear on the map!</li>
            <li>Press F11 to toggle overlay mode</li>
          </ol>
        </div>

        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">📍</div>
            <h3>Position Tracking</h3>
            <p>Real-time location from screenshots</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🗺️</div>
            <h3>Interactive Maps</h3>
            <p>All Tarkov maps with zoom/pan</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">✅</div>
            <h3>Quest Tracking</h3>
            <p>Mark and track active quests</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">📱</div>
            <h3>Mobile Sync</h3>
            <p>View on phone/tablet</p>
          </div>
        </div>
      </main>

      <footer className="app-footer">
        <p>Version 0.1.0 - Development Build</p>
        <p>Not affiliated with Battlestate Games</p>
      </footer>
    </div>
  );
};

export default App;
