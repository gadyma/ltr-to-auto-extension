# Installation Instructions

## Quick Install with Script

1. **Download and run the build script:**
   ```bash
   # Download the build script
   curl -o build-extension.sh [SCRIPT_URL]
   
   # Make it executable
   chmod +x build-extension.sh
   
   # Run the script
   ./build-extension.sh
   ```

2. **Load in Chrome:**
   - Open Chrome
   - Go to `chrome://extensions/`
   - Enable "Developer mode" (toggle in top right)
   - Click "Load unpacked"
   - Select the `smart-direction-changer` folder created by the script

## Manual Installation

1. **Create extension folder:**
   ```bash
   mkdir smart-direction-changer
   cd smart-direction-changer
   ```

2. **Copy all the files from the artifacts into this folder:**
   - manifest.json
   - content.js
   - popup.html
   - popup.js
   - README.md

3. **Load in Chrome:**
   - Open Chrome and navigate to `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select your `smart-direction-changer` folder

## Verification

After installation, you should see:
- A new extension icon in Chrome's toolbar
- The extension listed in `chrome://extensions/`
- Clicking the icon opens the extension popup

## Usage

1. Click the extension icon
2. Toggle the extension on/off
3. Choose between AUTO and RTL modes
4. Add custom selectors if needed
5. The extension will automatically work on supported fields

## Troubleshooting

- **Extension not loading**: Check that all files are in the correct folder
- **Not working on pages**: Refresh the page after enabling the extension
- **Popup not opening**: Check browser console for errors
- **Custom selectors not working**: Verify CSS selector syntax

## Updating

To update the extension:
1. Run the build script again to get the latest files
2. Go to `chrome://extensions/`
3. Click the refresh button on the extension card

## Uninstalling

1. Go to `chrome://extensions/`
2. Find "Smart Direction Changer"
3. Click "Remove"
4. Confirm removal
