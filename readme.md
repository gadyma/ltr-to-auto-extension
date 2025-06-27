# Smart Direction Changer with Domain Control

A Chrome extension that changes text direction in fields from default (LTR) to Auto or RTL with right alignment, with advanced domain control for precise website management.

## Features

- 🔄 Automatic text direction change from default (LTR) to Auto or RTL
- 🎯 Smart detection of a wide range of text fields and editable elements
- 👀 Dynamic tracking of page changes
- 🔧 Enable/disable toggle
- ⚙️ Choice between AUTO and RTL+Right-Align modes
- 🎨 RTL mode includes proper right text alignment
- 📝 Custom CSS selectors support
- 🌐 **Advanced domain control system**
- 🚫 **Per-domain enable/disable functionality**
- 🎛️ **Global domain modes (Custom, Allow All, Block All)**
- 📋 **Domain management interface**
- 💾 User preferences saved
- 🔄 Ability to restore original direction

## Domain Control Features

### **Current Domain Control**
- Quick enable/disable for the current website
- Visual status indicator (enabled/disabled)
- Instant feedback on domain status
- **Default**: Only enabled on *.smartsuite.com and *.monday.com

### **Global Domain Modes**
1. **Custom** - Use per-domain settings with manual control (default)
2. **Allow All** - Extension works on all websites
3. **Block All** - Extension disabled on all websites

**Default Configuration**: The extension is pre-configured to work only on:
- `*.smartsuite.com` (all Smartsuit domains)
- `*.monday.com` (all Monday.com domains)

### **Domain Management**
- View all configured domains
- See status of each domain (enabled/disabled)
- Remove individual domain settings
- Clear all domain configurations
- Wildcard pattern support (e.g., `*.google.com`)

## How it works

The extension searches for fields that have default LTR direction (like regular text fields without explicit direction settings) and changes them based on your selected mode, allowing proper display of Hebrew/Arabic text.

### **Domain Control Logic**
1. **Global Mode Check**: First checks the global domain mode setting
2. **Custom Domain Check**: If in custom mode, checks per-domain settings
3. **Default Behavior**: If no specific setting exists, defaults to disabled (except for pre-configured domains)
4. **Pattern Matching**: Supports wildcards and subdomain matching

### **Direction Modes**

#### **AUTO Mode** (Default)
- Sets `direction: auto`
- Browser automatically detects text direction based on content
- **"שלום world"** → correctly displays as **"שלום world"**
- **"Hello שלום"** → correctly displays as **"Hello שלום"**

#### **RTL Mode**
- Sets `direction: rtl` + `text-align: right`
- Forces right-to-left direction with right alignment
- Always displays text aligned to the right
- Perfect for RTL-heavy content

## Installation

### Quick Install with Script

1. **Download and run the build script:**
   ```bash
   curl -o build-extension.sh [SCRIPT_URL]
   chmod +x build-extension.sh
   ./build-extension.sh
   ```

2. **Load in Chrome:**
   - Open Chrome and go to `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select the `smart-direction-changer` folder

## Usage

### Basic Usage
1. After installing the extension, you'll see a new icon in Chrome's toolbar
2. Click on the icon to open the control interface
3. Use the main toggle to enable/disable the extension globally
4. **Select your preferred mode:**
   - **AUTO**: Browser automatically detects direction based on content
   - **RTL + Right Align**: Forces RTL direction with right text alignment

### Domain Control Usage

#### **Quick Domain Control**
- **Current Domain Section** shows the active website
- Click **"Enable Here"** or **"Disable Here"** for instant control
- Status indicator shows current state (✅ Enabled / ❌ Disabled)
- **Default**: Only enabled on *.smartsuite.com and *.monday.com

#### **Advanced Domain Management**
1. **Open Advanced Settings** in the extension popup
2. **Choose Domain Control Mode:**
   - **Custom domain settings** - Manual per-domain control (default)
   - **Allow on all domains** - Works everywhere
   - **Block on all domains** - Disabled everywhere

3. **Manage Custom Domains:**
   - View list of all configured domains
   - See enabled/disabled status for each
   - Remove individual domains with ×
   - Clear all settings with "Clear All"

#### **Domain Pattern Examples**
```
smartsuite.com          # Exact domain match
*.monday.com           # All Monday subdomains
.github.com            # GitHub and all subdomains
```

## 🚀 **Quick Start Guide:**

### **Simple Setup (Pre-configured):**
1. Install extension
2. **Automatically works on Smartsuit and Monday.com** ✅
3. Use AUTO mode (default)
4. Done! Ready for smartsuite.com and Monday.com

### **Expand to Other Sites:**
1. Visit any other website
2. Click extension icon
3. Click **"Enable Here"** for that domain
4. Repeat for other sites as needed

### **Advanced Setup:**
1. Install extension
2. Go to Advanced Settings → Domain Control Mode
3. Choose **"Allow on all domains"** for global use
4. Or manage individual domains in "Custom domain settings"

## Supported Field Types

The extension works on a comprehensive range of elements including:

- **Basic Input Fields**: text, search, email, password, URL, tel, number
- **Text Areas**: textarea elements
- **Rich Text Editors**: Quill, Summernote, Froala, CKEditor, TinyMCE, Ace, Monaco
- **Social Media**: Twitter/X, Facebook, generic message fields
- **Chat Applications**: Various chat and messaging interfaces
- **WordPress & CMS**: WordPress editors, TinyMCE
- **Email Clients**: Compose areas and reply fields
- **Custom Applications**: ProseMirror, record management systems, grid views
- **And many more...**

### Custom CSS Selectors

Add your own field selectors through the extension's advanced settings!

## Troubleshooting

### Extension not working on a specific page
- Check if the domain is disabled in settings
- Refresh the page (F5)
- Ensure the extension is globally enabled

### Domain settings not taking effect
- Refresh the page after changing domain settings
- Check that you're in "Custom domain settings" mode
- Verify the domain name matches exactly

### Changes not saved
- Ensure the extension has site permissions
- Check that the extension is enabled in `chrome://extensions/`

### Error messages in console
- Open Developer Tools (F12)
- Go to Console tab
- Look for messages from the extension

## Advanced Usage

### Domain Patterns
The extension supports several domain matching patterns:

```javascript
// Exact match
"example.com"

// Wildcard subdomain
"*.example.com"  // matches sub.example.com, api.example.com, etc.

// Domain and subdomain
".example.com"   // matches example.com and all subdomains
```

### Storage Structure
Domain settings are stored as:
```javascript
{
  "domainMode": "custom",  // "allow-all", "block-all", "custom"
  "domainSettings": {
    "*.smartsuite.com": {
      "enabled": true,
      "timestamp": 1640995200000
    },
    "*.monday.com": {
      "enabled": true,
      "timestamp": 1640995200000
    }
  }
}
```

## Development

### Build Script Usage
```bash
# Make script executable
chmod +x build-extension.sh

# Run the build script
./build-extension.sh

# The script will create a 'smart-direction-changer' directory with all files
```

### Adding Custom Field Types
Edit `content.js` and add selectors to the `targetSelectors` array:

```javascript
this.targetSelectors = [
  // Add your new selectors here
  '.your-new-selector',
  '[data-your-attribute]',
  // ...
];
```

### Domain Control API
The extension exposes these actions for domain control:

```javascript
// Get current status
chrome.tabs.sendMessage(tabId, { action: 'getStatus' });

// Set domain enabled/disabled
chrome.tabs.sendMessage(tabId, { 
  action: 'setDomainEnabled', 
  enabled: true 
});
```

## License

The extension is available for free use and further development.

## Support

If you encounter issues or have suggestions for improvement, please create an issue or send feedback.

---

## Changelog

### Version 1.23
- ✅ Added comprehensive domain control system
- ✅ Per-domain enable/disable functionality
- ✅ Global domain modes (Custom, Allow All, Block All)
- ✅ Domain management interface
- ✅ Wildcard pattern support
- ✅ Pre-configured for smartsuite.com and Monday.com
- ✅ Improved UI with domain status indicators
- ✅ Enhanced error handling and user feedback

### Version 1.0
- ✅ Initial release with AUTO/RTL modes
- ✅ Custom CSS selectors support
- ✅ Comprehensive field type support
- ✅ Dynamic content tracking
