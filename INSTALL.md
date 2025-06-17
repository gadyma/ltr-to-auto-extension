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

## Initial Setup

1. **Click the extension icon**
2. **The extension is pre-configured** for smartsuite.com and Monday.com
3. **Set your preferred mode** (AUTO or RTL)
4. **Test on Smartsuit or Monday** - should work immediately!

## Domain Control Setup

### For Smartsuit/Monday Users:
- **No setup needed** - works automatically on these platforms

### For Additional Sites:
1. **Visit the website** you want to add
2. **Click extension icon**
3. **Click "Enable Here"** to add the domain
4. **Repeat for other sites** as needed

### For Global Use:
1. **Go to Advanced Settings**
2. **Change to "Allow on all domains"**
3. **Extension will work everywhere**

## Troubleshooting

- **Extension not loading**: Check that all files are in the correct folder
- **Not working on pages**: Refresh the page after enabling the extension
- **Popup not opening**: Check browser console for errors
- **Domain settings not working**: Ensure you're in "Custom domain settings" mode
- **Custom selectors not working**: Verify CSS selector syntax

## Default Configuration

The extension comes pre-configured with:
- **Domain Mode**: Custom domain settings
- **Enabled Domains**: 
  - `*.smartsuite.com` (all Smartsuit domains)
  - `*.monday.com` (all Monday.com domains)
- **Direction Mode**: AUTO
- **Global Toggle**: Enabled

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

## Features Overview

After installation, you'll have access to:

- ✅ **Global enable/disable** toggle
- ✅ **AUTO vs RTL** mode selection
- ✅ **Current domain** quick controls
- ✅ **Global domain modes** (Custom, Allow All, Block All)
- ✅ **Custom CSS selectors** for unsupported fields
- ✅ **Domain management** interface
- ✅ **Visual status indicators** for all settings
- ✅ **Pre-configured** for Smartsuit and Monday.com

## Support

If you need help with installation or setup, check the main README.md file or create an issue.
