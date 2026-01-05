/**
 * Test script for ScreenshotMonitor
 * Run with: node test-screenshot-monitor.js
 */

// Test the parsing logic without running the full app
const testFilenames = [
  // Standard format
  '2024-01-15_12-30-45_customs_150.5_200.3_10.2.png',
  '2026-01-05_18-00-00_woods_-100.0_50.5_15.0.png',
  '2024-12-25_23-59-59_shoreline_300.123_-200.456_5.789.png',

  // Simple format
  'screenshot_customs_150.5_200.3_10.2.png',
  'screenshot_factory_0.0_0.0_0.0.png',

  // Alternative format
  'EFT_2024_01_15_customs_150.5_200.3_10.2.png',
  'EFT_2026_01_05_interchange_500.0_-300.0_20.0.png',

  // Invalid formats (should return null)
  'random_screenshot.png',
  'not_a_valid_format_123.png',
  'customs.png',
  '2024-01-15_customs.png',
  'screenshot_customs.png'
];

// Parse function (copied from ScreenshotMonitor)
function parseScreenshotFilename(filename) {
  const nameWithoutExt = filename.replace(/\.png$/i, '');
  const parts = nameWithoutExt.split('_');

  // Try standard format
  let result = tryStandardFormat(parts, filename);
  if (result) return result;

  // Try simple format
  result = trySimpleFormat(parts, filename);
  if (result) return result;

  // Try alternative format
  result = tryAlternativeFormat(parts, filename);
  if (result) return result;

  return null;
}

function tryStandardFormat(parts, filename) {
  if (parts.length < 6) return null;

  try {
    const datePart = parts[0];
    const timePart = parts[1];
    const map = parts[2];
    const x = parseFloat(parts[3]);
    const y = parseFloat(parts[4]);
    const z = parseFloat(parts[5]);

    if (isNaN(x) || isNaN(y) || isNaN(z)) {
      return null;
    }

    const dateTimeStr = `${datePart.replace(/-/g, '/')} ${timePart.replace(/-/g, ':')}`;
    const timestamp = new Date(dateTimeStr);

    if (isNaN(timestamp.getTime())) {
      return null;
    }

    return {
      filename,
      timestamp,
      map: map.toLowerCase(),
      coordinates: { x, y, z }
    };
  } catch (error) {
    return null;
  }
}

function trySimpleFormat(parts, filename) {
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
      map: map.toLowerCase(),
      coordinates: { x, y, z }
    };
  } catch (error) {
    return null;
  }
}

function tryAlternativeFormat(parts, filename) {
  if (parts.length < 8 || parts[0] !== 'EFT') return null;

  try {
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
      map: map.toLowerCase(),
      coordinates: { x, y, z }
    };
  } catch (error) {
    return null;
  }
}

// Run tests
console.log('🧪 Testing ScreenshotMonitor filename parsing\n');
console.log('='.repeat(80));

let passedCount = 0;
let failedCount = 0;

testFilenames.forEach((filename, index) => {
  const result = parseScreenshotFilename(filename);
  const isValid = result !== null;

  // Expected valid filenames (first 7)
  const shouldBeValid = index < 7;

  const passed = isValid === shouldBeValid;

  if (passed) {
    passedCount++;
    console.log(`\n✅ TEST ${index + 1} PASSED: ${filename}`);
  } else {
    failedCount++;
    console.log(`\n❌ TEST ${index + 1} FAILED: ${filename}`);
  }

  if (result) {
    console.log(`   Map: ${result.map}`);
    console.log(`   Coordinates: (${result.coordinates.x}, ${result.coordinates.y}, ${result.coordinates.z})`);
    console.log(`   Timestamp: ${result.timestamp.toISOString()}`);
  } else {
    console.log(`   Result: null (could not parse)`);
  }
});

console.log('\n' + '='.repeat(80));
console.log(`\n📊 Test Results: ${passedCount} passed, ${failedCount} failed (${testFilenames.length} total)`);

if (failedCount === 0) {
  console.log('\n🎉 All tests passed!');
  process.exit(0);
} else {
  console.log('\n⚠️ Some tests failed');
  process.exit(1);
}
