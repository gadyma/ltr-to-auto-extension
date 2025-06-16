#!/bin/bash

# Smart Direction Changer Chrome Extension Builder with Domain Control
# This script reconstructs all extension files

# Set extension directory name
EXTENSION_DIR="smart-direction-changer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Building Smart Direction Changer Chrome Extension with Domain Control${NC}"
echo -e "${YELLOW}==========================================================================${NC}"

# Create extension directory
if [ -d "$EXTENSION_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory $EXTENSION_DIR already exists. Removing...${NC}"
    rm -rf "$EXTENSION_DIR"
fi

echo -e "${BLUE}📁 Creating directory: $EXTENSION_DIR${NC}"
mkdir -p "$EXTENSION_DIR"
cd "$EXTENSION_DIR"

# Create manifest.json
echo -e "${GREEN}📄 Creating manifest.json${NC}"
cat > manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "Smart Direction Changer",
  "version": "1.21",
  "description": "Changes text direction in fields from default (LTR) to Auto or RTL for proper Hebrew/Arabic text display",
  "permissions": [
    "activeTab",
    "storage"
  ],
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "run_at": "document_end"
    }
  ],
  "action": {
    "default_popup": "popup.html",
    "default_title": "Smart Direction Changer"
  },
  "icons": {
    "16": "icon16.png",
    "48": "icon48.png",
    "128": "icon128.png"
  }
}
EOF

# Create content.js with domain control
echo -e "${GREEN}📄 Creating content.js (with domain control)${NC}"
cat > content.js << 'EOF'
// Default to Auto/RTL Direction Changer - Content Script

class DirectionChanger {
  constructor() {
    this.enabled = true;
    this.mode = 'auto'; // 'auto' or 'rtl'
    this.currentDomain = this.getCurrentDomain();
    this.domainEnabled = true;
    this.targetSelectors = [
      // Basic input fields
      'input[type="text"]',
      'input[type="search"]',
      'input[type="email"]',
      'input[type="password"]',
      'input[type="url"]',
      'input[type="tel"]',
      'input[type="number"]',
      
      // Textarea elements
      'textarea',
      
      // Contenteditable elements
      '[contenteditable="true"]',
      '[contenteditable=""]',
      
      // Input without type (defaults to text)
      'input:not([type])',
      
      // Common form elements
      'input[type="date"]',
      'input[type="time"]',
      'input[type="datetime-local"]',
      'input[type="month"]',
      'input[type="week"]',
      
      // Custom application selectors
      '.ProseMirror',
      '.edit-record-field',
      '.text-field-control',
      '.single-select-control',
      '.grid-view-cell',
      '.record-modal-title__title',
      '.record-list__scrollbar-body',
      '.record-field-section .select-list-items__in',
      '.record-layout-item',
      '.r-textarea',
      '.text--ellipsis',
      '.rct-sidebar-row',
      '.ellipsis',
      '.linked-record-field-control',
      
      // Rich text editors
      '.ql-editor',        // Quill editor
      '.note-editable',    // Summernote editor
      '.fr-element',       // Froala editor
      '.cke_editable',     // CKEditor
      '.mce-content-body', // TinyMCE editor
      '.ace_text-input',   // Ace editor
      '.monaco-editor .view-lines', // Monaco editor
      
      // Social media & messaging
      '[data-testid="tweetTextarea_0"]', // Twitter/X
      '[aria-label*="message"]',          // Generic message inputs
      '[placeholder*="type"]',            // Fields with "type" in placeholder
      '[placeholder*="write"]',           // Fields with "write" in placeholder
      '[placeholder*="enter"]',           // Fields with "enter" in placeholder
      '[placeholder*="search"]',          // Search fields
      
      // Comment systems
      '.comment-input',
      '.reply-input',
      '[name*="comment"]',
      '[id*="comment"]',
      
      // Chat applications
      '[data-testid*="message"]',
      '[aria-label*="chat"]',
      '.chat-input',
      '.message-input',
      
      // LTR explicitly set
      '.ltr',
      '[dir="ltr"]',
      '[style*="direction: ltr"]',
      '[style*="direction:ltr"]',
      
      // Fields without direction set
      'input:not([dir]):not([style*="direction"])',
      'textarea:not([dir]):not([style*="direction"])',
      '[contenteditable]:not([dir]):not([style*="direction"])',
      
      // WordPress & CMS editors
      '#wp-content-editor-container textarea',
      '.wp-editor-area',
      '#content_ifr',      // WordPress TinyMCE iframe
      
      // Google services
      '[aria-label*="Search"]',
      '[data-initial-dir]',
      
      // Generic text containers
      '.text-input',
      '.input-field',
      '.form-control',
      '.form-input',
      '[role="textbox"]',
      
      // Email clients
      '[aria-label*="compose"]',
      '[aria-label*="reply"]',
      '.compose-area',
      
      // Forums & discussion
      '.post-editor',
      '.topic-input',
      '.discussion-input'
    ];
    this.observer = null;
    this.init();
  }

  getCurrentDomain() {
    try {
      return window.location.hostname;
    } catch (error) {
      console.log('Could not get domain:', error);
      return 'unknown';
    }
  }

  async init() {
    // Check if extension is enabled and get mode
    const result = await chrome.storage.local.get([
      'enabled', 
      'mode', 
      'customSelectors',
      'domainSettings',
      'domainMode'
    ]);
    
    this.enabled = result.enabled !== false; // Default: enabled
    this.mode = result.mode || 'auto'; // Default: auto
    
    // Check domain settings
    await this.checkDomainSettings();
    
    // Load custom selectors
    await this.loadCustomSelectors();
    
    if (this.enabled && this.domainEnabled) {
      this.changeDirections();
      this.observeChanges();
    }
    
    console.log(`Extension loaded on ${this.currentDomain}:`, {
      enabled: this.enabled,
      domainEnabled: this.domainEnabled,
      mode: this.mode
    });
  }

  async checkDomainSettings() {
    try {
      const result = await chrome.storage.local.get(['domainSettings', 'domainMode']);
      let domainSettings = result.domainSettings;
      let domainMode = result.domainMode;
      
      // Set defaults on first run
      if (!domainSettings && !domainMode) {
        domainSettings = {
          '*.smartsuit.com': { enabled: true, timestamp: Date.now() },
          '*.monday.com': { enabled: true, timestamp: Date.now() }
        };
        domainMode = 'custom';
        
        // Save defaults
        await chrome.storage.local.set({ 
          domainSettings: domainSettings,
          domainMode: domainMode 
        });
        
        console.log('Set default domain settings for smartsuit.com and monday.com');
      }
      
      // Use defaults if still not set
      domainSettings = domainSettings || {};
      domainMode = domainMode || 'custom';
      
      switch (domainMode) {
        case 'allow-all':
          this.domainEnabled = true;
          break;
          
        case 'block-all':
          this.domainEnabled = false;
          break;
          
        case 'custom':
          // Check if current domain is in settings
          const setting = this.findDomainSetting(domainSettings, this.currentDomain);
          this.domainEnabled = setting ? setting.enabled : false; // Default deny if not specified in custom mode
          break;
          
        default:
          this.domainEnabled = false; // Default to disabled
      }
      
    } catch (error) {
      console.log('Could not load domain settings:', error);
      this.domainEnabled = false; // Default: disabled
    }
  }

  findDomainSetting(domainSettings, domain) {
    // Check exact match first
    if (domainSettings[domain]) {
      return domainSettings[domain];
    }
    
    // Check wildcard patterns
    for (const pattern in domainSettings) {
      if (this.matchesDomainPattern(domain, pattern)) {
        return domainSettings[pattern];
      }
    }
    
    return null;
  }

  matchesDomainPattern(domain, pattern) {
    // Simple wildcard matching
    if (pattern.includes('*')) {
      const regexPattern = pattern
        .replace(/\./g, '\\.')
        .replace(/\*/g, '.*');
      const regex = new RegExp(`^${regexPattern});
      return regex.test(domain);
    }
    
    // Subdomain matching (e.g., "example.com" matches "sub.example.com")
    if (pattern.startsWith('.')) {
      return domain.endsWith(pattern) || domain === pattern.slice(1);
    }
    
    return domain === pattern;
  }
  
  async loadCustomSelectors() {
    try {
      const result = await chrome.storage.local.get(['customSelectors']);
      const customSelectors = result.customSelectors || '';
      
      if (customSelectors.trim()) {
        // Add custom selectors to the list
        const customArray = customSelectors.split(',').map(s => s.trim()).filter(s => s);
        this.targetSelectors = [...this.targetSelectors, ...customArray];
        console.log('Added custom selectors:', customArray);
      }
    } catch (error) {
      console.log('Could not load custom selectors:', error);
    }
  }

  changeDirections() {
    if (!this.domainEnabled) {
      console.log(`Extension disabled for domain: ${this.currentDomain}`);
      return;
    }

    const elements = document.querySelectorAll(this.targetSelectors.join(','));
    
    elements.forEach(element => {
      const computedStyle = window.getComputedStyle(element);
      const currentDirection = computedStyle.direction;
      const dirAttribute = element.getAttribute('dir');
      const styleDirection = element.style.direction;
      
      // Check if the field needs change:
      // 1. If computed direction is LTR (default or explicit)
      // 2. If no direction setting at all (browser assumes LTR)
      // 3. If explicitly set as LTR
      const needsChange = (
        currentDirection === 'ltr' || 
        (!dirAttribute && !styleDirection) ||
        dirAttribute === 'ltr' ||
        styleDirection === 'ltr'
      );
      
      // Ensure we haven't already changed this element
      const alreadyChanged = element.classList.contains('direction-changed-by-extension');
      
      if (needsChange && !alreadyChanged) {
        // Save original state
        if (!element.hasAttribute('data-original-direction')) {
          element.setAttribute('data-original-direction', currentDirection);
          element.setAttribute('data-original-dir-attr', dirAttribute || 'none');
          element.setAttribute('data-original-style-dir', styleDirection || 'none');
          element.setAttribute('data-original-text-align', computedStyle.textAlign || 'none');
        }
        
        // Apply changes based on mode
        if (this.mode === 'auto') {
          element.style.direction = 'auto';
          element.setAttribute('dir', 'auto');
        } else if (this.mode === 'rtl') {
          element.style.direction = 'rtl';
          element.style.textAlign = 'right';
          element.setAttribute('dir', 'rtl');
        }
        
        // Mark element as changed
        element.classList.add('direction-changed-by-extension');
        
        console.log(`Changed direction to ${this.mode}:`, {
          element: element,
          originalDirection: currentDirection,
          originalDirAttr: dirAttribute,
          tagName: element.tagName,
          type: element.type,
          mode: this.mode,
          domain: this.currentDomain
        });
      }
    });
  }

  observeChanges() {
    // Track dynamic changes in the page
    this.observer = new MutationObserver((mutations) => {
      let shouldProcess = false;
      
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          shouldProcess = true;
        } else if (mutation.type === 'attributes' && 
                   (mutation.attributeName === 'dir' || 
                    mutation.attributeName === 'style')) {
          shouldProcess = true;
        }
      });
      
      if (shouldProcess && this.domainEnabled) {
        setTimeout(() => this.changeDirections(), 100);
      }
    });
    
    this.observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['dir', 'style', 'class']
    });
  }

  restoreDirections() {
    const changedElements = document.querySelectorAll('.direction-changed-by-extension');
    
    changedElements.forEach(element => {
      const originalDirection = element.getAttribute('data-original-direction');
      const originalDirAttr = element.getAttribute('data-original-dir-attr');
      const originalStyleDir = element.getAttribute('data-original-style-dir');
      const originalTextAlign = element.getAttribute('data-original-text-align');
      
      // Restore original direction
      if (originalStyleDir && originalStyleDir !== 'none') {
        element.style.direction = originalStyleDir;
      } else {
        element.style.direction = '';
      }
      
      // Restore original text-align
      if (originalTextAlign && originalTextAlign !== 'none') {
        element.style.textAlign = originalTextAlign;
      } else {
        element.style.textAlign = '';
      }
      
      if (originalDirAttr && originalDirAttr !== 'none') {
        element.setAttribute('dir', originalDirAttr);
      } else {
        element.removeAttribute('dir');
      }
      
      // Clean up saved data
      element.classList.remove('direction-changed-by-extension');
      element.removeAttribute('data-original-direction');
      element.removeAttribute('data-original-dir-attr');
      element.removeAttribute('data-original-style-dir');
      element.removeAttribute('data-original-text-align');
    });
  }

  updateCustomSelectors(customSelectors) {
    // Reset selectors to base list (keeping the full list from constructor)
    this.targetSelectors = [
      'input[type="text"]', 'input[type="search"]', 'input[type="email"]', 'input[type="password"]',
      'input[type="url"]', 'input[type="tel"]', 'input[type="number"]', 'textarea',
      '[contenteditable="true"]', '[contenteditable=""]', 'input:not([type])',
      'input[type="date"]', 'input[type="time"]', 'input[type="datetime-local"]',
      'input[type="month"]', 'input[type="week"]', '.ProseMirror', '.edit-record-field',
      '.text-field-control', '.single-select-control', '.grid-view-cell',
      '.record-modal-title__title', '.record-list__scrollbar-body',
      '.record-field-section .select-list-items__in', '.record-layout-item',
      '.r-textarea', '.text--ellipsis', '.rct-sidebar-row', '.ellipsis',
      '.linked-record-field-control', '.ql-editor', '.note-editable', '.fr-element',
      '.cke_editable', '.mce-content-body', '.ace_text-input', '.monaco-editor .view-lines',
      '[data-testid="tweetTextarea_0"]', '[aria-label*="message"]', '[placeholder*="type"]',
      '[placeholder*="write"]', '[placeholder*="enter"]', '[placeholder*="search"]',
      '.comment-input', '.reply-input', '[name*="comment"]', '[id*="comment"]',
      '[data-testid*="message"]', '[aria-label*="chat"]', '.chat-input', '.message-input',
      '.ltr', '[dir="ltr"]', '[style*="direction: ltr"]', '[style*="direction:ltr"]',
      'input:not([dir]):not([style*="direction"])', 'textarea:not([dir]):not([style*="direction"])',
      '[contenteditable]:not([dir]):not([style*="direction"])',
      '#wp-content-editor-container textarea', '.wp-editor-area', '#content_ifr',
      '[aria-label*="Search"]', '[data-initial-dir]', '.text-input', '.input-field',
      '.form-control', '.form-input', '[role="textbox"]', '[aria-label*="compose"]',
      '[aria-label*="reply"]', '.compose-area', '.post-editor', '.topic-input', '.discussion-input'
    ];
    
    // Add custom selectors
    if (customSelectors && customSelectors.trim()) {
      const customArray = customSelectors.split(',').map(s => s.trim()).filter(s => s);
      this.targetSelectors = [...this.targetSelectors, ...customArray];
      console.log('Updated with custom selectors:', customArray);
    }
    
    // Re-apply changes
    if (this.enabled && this.domainEnabled) {
      this.changeDirections();
    }
  }

  setMode(newMode) {
    this.mode = newMode;
    chrome.storage.local.set({ mode: newMode });
    
    if (this.enabled && this.domainEnabled) {
      // First restore all elements
      this.restoreDirections();
      // Then re-apply with new mode
      setTimeout(() => this.changeDirections(), 100);
    }
  }

  async setDomainEnabled(enabled) {
    this.domainEnabled = enabled;
    
    // Update domain settings
    const result = await chrome.storage.local.get(['domainSettings', 'domainMode']);
    const domainSettings = result.domainSettings || {};
    
    domainSettings[this.currentDomain] = {
      enabled: enabled,
      timestamp: Date.now()
    };
    
    await chrome.storage.local.set({ 
      domainSettings: domainSettings,
      domainMode: 'custom'
    });
    
    if (enabled && this.enabled) {
      this.changeDirections();
      this.observeChanges();
    } else {
      this.restoreDirections();
      if (this.observer) {
        this.observer.disconnect();
        this.observer = null;
      }
    }
    
    console.log(`Domain ${this.currentDomain} ${enabled ? 'enabled' : 'disabled'}`);
  }

  toggle() {
    this.enabled = !this.enabled;
    
    if (this.enabled && this.domainEnabled) {
      this.changeDirections();
      this.observeChanges();
    } else {
      this.restoreDirections();
      if (this.observer) {
        this.observer.disconnect();
      }
    }
    
    // Save state
    chrome.storage.local.set({ enabled: this.enabled });
  }
}

// Listen for messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'toggle') {
    directionChanger.toggle();
    sendResponse({ enabled: directionChanger.enabled });
  } else if (request.action === 'getStatus') {
    sendResponse({ 
      enabled: directionChanger.enabled,
      mode: directionChanger.mode,
      domain: directionChanger.currentDomain,
      domainEnabled: directionChanger.domainEnabled
    });
  } else if (request.action === 'updateSelectors') {
    // Update custom selectors
    directionChanger.updateCustomSelectors(request.customSelectors);
    sendResponse({ success: true });
  } else if (request.action === 'setMode') {
    // Set direction mode
    directionChanger.setMode(request.mode);
    sendResponse({ success: true, mode: request.mode });
  } else if (request.action === 'setDomainEnabled') {
    // Set domain enabled/disabled
    directionChanger.setDomainEnabled(request.enabled);
    sendResponse({ success: true, enabled: request.enabled });
  }
});

// Create instance
const directionChanger = new DirectionChanger();

// Log that extension loaded
console.log('Smart Direction Changer loaded with domain control');
EOF

# Create popup.html with domain control UI
echo -e "${GREEN}📄 Creating popup.html (with domain control)${NC}"
cat > popup.html << 'EOF'
<!DOCTYPE html>
<html dir="rtl" lang="he">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Direction Changer Extension</title>
  <style>
    body {
      width: 340px;
      padding: 20px;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 0;
      direction: rtl;
      text-align: right;
    }
    
    .header {
      text-align: center;
      margin-bottom: 20px;
      border-bottom: 1px solid #e0e0e0;
      padding-bottom: 15px;
    }
    
    .header h1 {
      font-size: 18px;
      margin: 0;
      color: #333;
    }
    
    .header p {
      font-size: 12px;
      color: #666;
      margin: 5px 0 0 0;
    }
    
    .control-section {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 15px;
      padding: 15px;
      background: #f8f9fa;
      border-radius: 8px;
    }
    
    .control-label {
      font-weight: 500;
      color: #333;
    }
    
    .toggle-switch {
      position: relative;
      width: 50px;
      height: 24px;
      background: #ccc;
      border-radius: 12px;
      cursor: pointer;
      transition: background 0.3s;
    }
    
    .toggle-switch.active {
      background: #4CAF50;
    }
    
    .toggle-switch::after {
      content: '';
      position: absolute;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background: white;
      top: 2px;
      left: 2px;
      transition: transform 0.3s;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    
    .toggle-switch.active::after {
      transform: translateX(26px);
    }

    .domain-section {
      margin-bottom: 15px;
      padding: 15px;
      background: #fff3cd;
      border-radius: 8px;
      border-right: 4px solid #ffc107;
    }

    .domain-section.enabled {
      background: #d4edda;
      border-right-color: #28a745;
    }

    .domain-section.disabled {
      background: #f8d7da;
      border-right-color: #dc3545;
    }

    .domain-section h3 {
      margin: 0 0 10px 0;
      color: #856404;
      font-size: 14px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .domain-section.enabled h3 {
      color: #155724;
    }

    .domain-section.disabled h3 {
      color: #721c24;
    }

    .domain-info {
      font-size: 12px;
      color: #666;
      margin-bottom: 10px;
      word-break: break-all;
      direction: ltr;
      text-align: left;
      background: rgba(255,255,255,0.7);
      padding: 8px;
      border-radius: 4px;
      font-family: monospace;
    }

    .domain-controls {
      display: flex;
      gap: 8px;
    }

    .domain-btn {
      flex: 1;
      padding: 6px 12px;
      border: 1px solid;
      background: white;
      border-radius: 4px;
      cursor: pointer;
      font-size: 11px;
      font-weight: 500;
      text-align: center;
      transition: all 0.3s ease;
    }

    .domain-btn.enable {
      border-color: #28a745;
      color: #28a745;
    }

    .domain-btn.enable:hover, .domain-btn.enable.active {
      background: #28a745;
      color: white;
    }

    .domain-btn.disable {
      border-color: #dc3545;
      color: #dc3545;
    }

    .domain-btn.disable:hover, .domain-btn.disable.active {
      background: #dc3545;
      color: white;
    }
    
    .mode-section {
      margin-bottom: 15px;
      padding: 15px;
      background: #e8f4fd;
      border-radius: 8px;
      border-right: 4px solid #4285f4;
    }
    
    .mode-section h3 {
      margin: 0 0 10px 0;
      color: #1a73e8;
      font-size: 14px;
    }
    
    .mode-options {
      display: flex;
      gap: 10px;
    }
    
    .mode-button {
      flex: 1;
      padding: 8px 12px;
      border: 1px solid #4285f4;
      background: white;
      color: #4285f4;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
      font-weight: 500;
      text-align: center;
      transition: all 0.3s ease;
    }
    
    .mode-button.active {
      background: #4285f4;
      color: white;
    }
    
    .mode-button:hover {
      transform: translateY(-1px);
      box-shadow: 0 2px 8px rgba(66, 133, 244, 0.3);
    }
    
    .mode-description {
      font-size: 11px;
      color: #666;
      margin-top: 8px;
      text-align: center;
    }
    
    .info-section {
      font-size: 12px;
      color: #666;
      background: #e8f4fd;
      padding: 12px;
      border-radius: 6px;
      margin-bottom: 15px;
    }
    
    .stats {
      font-size: 11px;
      color: #888;
      text-align: center;
      border-top: 1px solid #e0e0e0;
      padding-top: 10px;
    }
    
    .status {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 11px;
      font-weight: 500;
      margin-right: 10px;
    }
    
    .status.active {
      background: #d4edda;
      color: #155724;
    }
    
    .status.inactive {
      background: #f8d7da;
      color: #721c24;
    }
    
    .advanced-section {
      margin-top: 15px;
      padding: 15px;
      background: #f8f9fa;
      border-radius: 8px;
      border-top: 1px solid #e0e0e0;
    }
    
    .advanced-section details {
      cursor: pointer;
    }
    
    .advanced-section summary {
      font-weight: bold;
      color: #333;
      margin-bottom: 10px;
      outline: none;
    }
    
    .advanced-section label {
      display: block;
      font-size: 12px;
      color: #666;
      margin-bottom: 5px;
    }
    
    .advanced-section textarea {
      width: 100%;
      height: 60px;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 11px;
      resize: vertical;
      direction: ltr;
      text-align: left;
    }

    .domain-management {
      margin-top: 15px;
      padding-top: 15px;
      border-top: 1px solid #ddd;
    }

    .domain-mode-select {
      margin-bottom: 15px;
    }

    .domain-mode-select select {
      width: 100%;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 12px;
      background: white;
    }

    .domain-list {
      max-height: 120px;
      overflow-y: auto;
      border: 1px solid #ddd;
      border-radius: 4px;
      background: white;
    }

    .domain-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 12px;
      border-bottom: 1px solid #eee;
      font-size: 11px;
    }

    .domain-item:last-child {
      border-bottom: none;
    }

    .domain-name {
      font-family: monospace;
      direction: ltr;
      text-align: left;
      flex-grow: 1;
    }

    .domain-status {
      padding: 2px 6px;
      border-radius: 3px;
      font-size: 10px;
      font-weight: bold;
      margin-left: 8px;
    }

    .domain-status.enabled {
      background: #d4edda;
      color: #155724;
    }

    .domain-status.disabled {
      background: #f8d7da;
      color: #721c24;
    }

    .domain-remove {
      background: none;
      border: none;
      color: #dc3545;
      cursor: pointer;
      font-size: 14px;
      padding: 2px 4px;
    }

    .domain-remove:hover {
      background: #f8d7da;
      border-radius: 3px;
    }
    
    .save-btn {
      background: linear-gradient(45deg, #4285f4, #34a853);
      color: white;
      border: none;
      padding: 6px 12px;
      border-radius: 25px;
      cursor: pointer;
      font-weight: bold;
      font-size: 11px;
      transition: all 0.3s ease;
      margin-top: 8px;
    }
    
    .save-btn:hover {
      transform: scale(1.05);
      box-shadow: 0 5px 15px rgba(66, 133, 244, 0.4);
    }

    .clear-btn {
      background: #dc3545;
      color: white;
      border: none;
      padding: 4px 8px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 10px;
      margin-right: 8px;
    }

    .clear-btn:hover {
      background: #c82333;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🔄 Direction Changer</h1>
    <p>Smart Text Direction Control</p>
  </div>
  
  <div class="control-section">
    <span class="control-label">Enable Extension</span>
    <div class="toggle-switch" id="toggleSwitch"></div>
  </div>

  <div class="domain-section" id="domainSection">
    <h3>
      Current Domain
      <span id="domainStatus">Unknown</span>
    </h3>
    <div class="domain-info" id="currentDomain">Loading...</div>
    <div class="domain-controls">
      <button class="domain-btn enable" id="enableDomainBtn">Enable Here</button>
      <button class="domain-btn disable" id="disableDomainBtn">Disable Here</button>
    </div>
  </div>
  
  <div class="mode-section">
    <h3>Direction Mode</h3>
    <div class="mode-options">
      <div class="mode-button" id="autoMode" data-mode="auto">
        AUTO
      </div>
      <div class="mode-button" id="rtlMode" data-mode="rtl">
        RTL + Right Align
      </div>
    </div>
    <div class="mode-description" id="modeDescription">
      AUTO: Browser decides direction based on content
    </div>
  </div>
  
  <div class="info-section">
    <strong>How it works:</strong><br>
    The extension finds fields with default LTR direction and changes them based on your selected mode for proper Hebrew/Arabic text display.
    <br><br>
    <details>
      <summary><strong>Supported Field Types (click to expand)</strong></summary>
      <div style="margin-top: 10px; font-size: 11px; color: #555;">
        ✅ Regular text fields (input, textarea)<br>
        ✅ Search and email fields<br>
        ✅ Rich text editors (Word, Google Docs)<br>
        ✅ Social media platforms (Twitter, Facebook)<br>
        ✅ Comment systems and forums<br>
        ✅ Chat and messaging apps<br>
        ✅ WordPress and CMS editors<br>
        ✅ Google services<br>
        ✅ Email clients<br>
        ✅ Custom application fields
      </div>
    </details>
  </div>
  
  <div class="stats">
    <span class="status" id="status">Inactive</span>
    <span id="currentUrl"></span>
  </div>
  
  <div class="advanced-section">
    <details>
      <summary>⚙️ Advanced Settings</summary>
      <div style="margin-top: 10px;">
        <label>
          Add custom CSS selectors:
        </label>
        <textarea id="customSelectors" 
                  placeholder="Example: .my-input, #special-field"
        ></textarea>
        <button id="saveCustomSelectors" class="save-btn">
          Save Selectors
        </button>
        <div id="customSelectorsStatus" style="margin-top: 5px; font-size: 10px;"></div>

        <div class="domain-management">
          <label>Domain Control Mode:</label>
          <div class="domain-mode-select">
            <select id="domainModeSelect">
              <option value="custom">Custom domain settings</option>
              <option value="allow-all">Allow on all domains</option>
              <option value="block-all">Block on all domains</option>
            </select>
          </div>

          <div id="domainListContainer" style="display: none;">
            <label>
              Managed Domains:
              <button class="clear-btn" id="clearDomainsBtn">Clear All</button>
            </label>
            <div class="domain-list" id="domainList">
              <!-- Domain items will be populated here -->
            </div>
          </div>
        </div>
      </div>
    </details>
  </div>

  <script src="popup.js"></script>
</body>
</html>
EOF

# Create popup.js with domain control logic
echo -e "${GREEN}📄 Creating popup.js (with domain control)${NC}"
cat > popup.js << 'EOF'
// Smart Direction Changer with Domain Control - Popup Script

class PopupController {
  constructor() {
    this.toggleSwitch = null;
    this.status = null;
    this.currentUrl = null;
    this.currentMode = 'auto';
    this.currentDomain = null;
    this.domainEnabled = true;
    
    this.init();
  }
  
  async init() {
    try {
      // Wait for DOM to load completely
      await this.waitForDOM();
      
      // Get references to elements
      this.toggleSwitch = document.getElementById('toggleSwitch');
      this.status = document.getElementById('status');
      this.currentUrl = document.getElementById('currentUrl');
      
      if (!this.toggleSwitch || !this.status || !this.currentUrl) {
        throw new Error('Required DOM elements not found');
      }
      
      // Set up event listeners
      this.toggleSwitch.addEventListener('click', () => this.toggle());
      
      // Mode buttons
      const autoModeBtn = document.getElementById('autoMode');
      const rtlModeBtn = document.getElementById('rtlMode');
      
      if (autoModeBtn && rtlModeBtn) {
        autoModeBtn.addEventListener('click', () => this.setMode('auto'));
        rtlModeBtn.addEventListener('click', () => this.setMode('rtl'));
      }

      // Domain control buttons
      const enableDomainBtn = document.getElementById('enableDomainBtn');
      const disableDomainBtn = document.getElementById('disableDomainBtn');
      
      if (enableDomainBtn && disableDomainBtn) {
        enableDomainBtn.addEventListener('click', () => this.setDomainEnabled(true));
        disableDomainBtn.addEventListener('click', () => this.setDomainEnabled(false));
      }

      // Domain mode select
      const domainModeSelect = document.getElementById('domainModeSelect');
      if (domainModeSelect) {
        domainModeSelect.addEventListener('change', () => this.setDomainMode(domainModeSelect.value));
      }

      // Clear domains button
      const clearDomainsBtn = document.getElementById('clearDomainsBtn');
      if (clearDomainsBtn) {
        clearDomainsBtn.addEventListener('click', () => this.clearAllDomains());
      }
      
      // Custom selectors
      const saveBtn = document.getElementById('saveCustomSelectors');
      const customTextarea = document.getElementById('customSelectors');
      
      if (saveBtn && customTextarea) {
        saveBtn.addEventListener('click', () => this.saveCustomSelectors());
        
        // Load custom selectors
        await this.loadCustomSelectors();
      }

      // Load domain settings
      await this.loadDomainSettings();
      
      // Get current status
      await this.updateStatus();
      
      // Show current tab URL
      this.showCurrentTab();
      
    } catch (error) {
      console.error('Error initializing popup:', error);
      this.showError('Error initializing interface: ' + error.message);
    }
  }
  
  waitForDOM() {
    return new Promise((resolve) => {
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', resolve);
      } else {
        resolve();
      }
    });
  }
  
  async updateStatus() {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      
      const response = await chrome.tabs.sendMessage(tab.id, { 
        action: 'getStatus' 
      });
      
      const isEnabled = response && response.enabled !== undefined ? response.enabled : true;
      const mode = response && response.mode ? response.mode : 'auto';
      const domain = response && response.domain ? response.domain : 'unknown';
      const domainEnabled = response && response.domainEnabled !== undefined ? response.domainEnabled : true;
      
      this.currentDomain = domain;
      this.domainEnabled = domainEnabled;
      
      this.setToggleState(isEnabled);
      this.updateModeDisplay(mode);
      this.updateDomainDisplay(domain, domainEnabled);
      
    } catch (error) {
      console.log('Could not get status:', error);
      // Default values
      this.setToggleState(true);
      this.updateModeDisplay('auto');
      this.updateDomainDisplay('unknown', true);
    }
  }

  updateDomainDisplay(domain, enabled) {
    const domainSection = document.getElementById('domainSection');
    const domainStatus = document.getElementById('domainStatus');
    const currentDomainEl = document.getElementById('currentDomain');
    const enableBtn = document.getElementById('enableDomainBtn');
    const disableBtn = document.getElementById('disableDomainBtn');

    if (domainSection && domainStatus && currentDomainEl && enableBtn && disableBtn) {
      // Update domain info
      currentDomainEl.textContent = domain;
      
      // Update section styling and status
      domainSection.className = 'domain-section';
      enableBtn.classList.remove('active');
      disableBtn.classList.remove('active');
      
      if (enabled) {
        domainSection.classList.add('enabled');
        domainStatus.textContent = '✅ Enabled';
        enableBtn.classList.add('active');
      } else {
        domainSection.classList.add('disabled');
        domainStatus.textContent = '❌ Disabled';
        disableBtn.classList.add('active');
      }
    }
  }

  async setDomainEnabled(enabled) {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      
      await chrome.tabs.sendMessage(tab.id, { 
        action: 'setDomainEnabled',
        enabled: enabled
      });
      
      this.domainEnabled = enabled;
      this.updateDomainDisplay(this.currentDomain, enabled);
      
      // Refresh domain list
      await this.loadDomainSettings();
      
    } catch (error) {
      console.error('Error setting domain status:', error);
      this.showError('Please refresh the page for domain change to work');
    }
  }

  async loadDomainSettings() {
    try {
      const result = await chrome.storage.local.get(['domainSettings', 'domainMode']);
      let domainSettings = result.domainSettings;
      let domainMode = result.domainMode;
      
      // Set defaults on first run
      if (!domainSettings && !domainMode) {
        domainSettings = {
          '*.smartsuit.com': { enabled: true, timestamp: Date.now() },
          '*.monday.com': { enabled: true, timestamp: Date.now() }
        };
        domainMode = 'custom';
        
        // Save defaults
        await chrome.storage.local.set({ 
          domainSettings: domainSettings,
          domainMode: domainMode 
        });
        
        console.log('Set default domain settings for smartsuit.com and monday.com');
      }
      
      // Use defaults if still not set
      domainSettings = domainSettings || {};
      domainMode = domainMode || 'custom';
      
      // Update domain mode select
      const domainModeSelect = document.getElementById('domainModeSelect');
      if (domainModeSelect) {
        domainModeSelect.value = domainMode;
        
        // Show/hide domain list based on mode
        const domainListContainer = document.getElementById('domainListContainer');
        if (domainListContainer) {
          domainListContainer.style.display = domainMode === 'custom' ? 'block' : 'none';
        }
      }
      
      // Update domain list
      this.updateDomainList(domainSettings);
      
    } catch (error) {
      console.log('Could not load domain settings:', error);
    }
  }

  updateDomainList(domainSettings) {
    const domainList = document.getElementById('domainList');
    if (!domainList) return;
    
    domainList.innerHTML = '';
    
    if (Object.keys(domainSettings).length === 0) {
      domainList.innerHTML = '<div class="domain-item" style="justify-content: center; color: #666;">No domains configured</div>';
      return;
    }
    
    Object.entries(domainSettings).forEach(([domain, settings]) => {
      const domainItem = document.createElement('div');
      domainItem.className = 'domain-item';
      
      const domainName = document.createElement('span');
      domainName.className = 'domain-name';
      domainName.textContent = domain;
      
      const domainStatus = document.createElement('span');
      domainStatus.className = `domain-status ${settings.enabled ? 'enabled' : 'disabled'}`;
      domainStatus.textContent = settings.enabled ? 'Enabled' : 'Disabled';
      
      const removeBtn = document.createElement('button');
      removeBtn.className = 'domain-remove';
      removeBtn.innerHTML = '×';
      removeBtn.title = 'Remove domain';
      removeBtn.addEventListener('click', () => this.removeDomain(domain));
      
      domainItem.appendChild(domainName);
      domainItem.appendChild(domainStatus);
      domainItem.appendChild(removeBtn);
      
      domainList.appendChild(domainItem);
    });
  }

  async setDomainMode(mode) {
    try {
      await chrome.storage.local.set({ domainMode: mode });
      
      // Show/hide domain list
      const domainListContainer = document.getElementById('domainListContainer');
      if (domainListContainer) {
        domainListContainer.style.display = mode === 'custom' ? 'block' : 'none';
      }
      
      // Notify all tabs of the change
      const tabs = await chrome.tabs.query({});
      for (const tab of tabs) {
        try {
          await chrome.tabs.sendMessage(tab.id, { action: 'getStatus' });
        } catch (e) {
          // Ignore tabs without content script
        }
      }
      
    } catch (error) {
      console.error('Error setting domain mode:', error);
    }
  }

  async removeDomain(domain) {
    try {
      const result = await chrome.storage.local.get(['domainSettings']);
      const domainSettings = result.domainSettings || {};
      
      delete domainSettings[domain];
      
      await chrome.storage.local.set({ domainSettings });
      
      // Update display
      this.updateDomainList(domainSettings);
      
    } catch (error) {
      console.error('Error removing domain:', error);
    }
  }

  async clearAllDomains() {
    if (confirm('Are you sure you want to clear all domain settings?')) {
      try {
        await chrome.storage.local.set({ 
          domainSettings: {},
          domainMode: 'allow-all'
        });
        
        // Reset UI
        const domainModeSelect = document.getElementById('domainModeSelect');
        if (domainModeSelect) {
          domainModeSelect.value = 'allow-all';
        }
        
        const domainListContainer = document.getElementById('domainListContainer');
        if (domainListContainer) {
          domainListContainer.style.display = 'none';
        }
        
        this.updateDomainList({});
        
      } catch (error) {
        console.error('Error clearing domains:', error);
      }
    }
  }
  
  async toggle() {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      
      const response = await chrome.tabs.sendMessage(tab.id, { 
        action: 'toggle' 
      });
      
      this.setToggleState(response.enabled);
      
    } catch (error) {
      console.error('Error toggling extension:', error);
      
      // If no content script, show message to user
      this.showError('Please refresh the page for the extension to work');
    }
  }
  
  async setMode(mode) {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      
      await chrome.tabs.sendMessage(tab.id, { 
        action: 'setMode',
        mode: mode
      });
      
      this.updateModeDisplay(mode);
      
    } catch (error) {
      console.error('Error setting mode:', error);
      this.showError('Please refresh the page for mode change to work');
    }
  }
  
  updateModeDisplay(mode) {
    this.currentMode = mode;
    
    // Update button states
    const autoBtn = document.getElementById('autoMode');
    const rtlBtn = document.getElementById('rtlMode');
    const description = document.getElementById('modeDescription');
    
    if (autoBtn && rtlBtn && description) {
      // Reset button states
      autoBtn.classList.remove('active');
      rtlBtn.classList.remove('active');
      
      // Set active button
      if (mode === 'auto') {
        autoBtn.classList.add('active');
        description.textContent = 'AUTO: Browser decides direction based on content';
      } else if (mode === 'rtl') {
        rtlBtn.classList.add('active');
        description.textContent = 'RTL: Force right-to-left direction with right alignment';
      }
    }
  }
  
  setToggleState(enabled) {
    if (enabled) {
      this.toggleSwitch.classList.add('active');
      this.status.textContent = 'Active';
      this.status.className = 'status active';
    } else {
      this.toggleSwitch.classList.remove('active');
      this.status.textContent = 'Inactive';
      this.status.className = 'status inactive';
    }
  }
  
  async showCurrentTab() {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      const url = new URL(tab.url);
      this.currentUrl.textContent = url.hostname;
    } catch (error) {
      this.currentUrl.textContent = 'Not available';
    }
  }
  
  async loadCustomSelectors() {
    try {
      const result = await chrome.storage.local.get(['customSelectors']);
      const customSelectors = result.customSelectors || '';
      const customTextarea = document.getElementById('customSelectors');
      if (customTextarea) {
        customTextarea.value = customSelectors;
      }
    } catch (error) {
      console.log('Could not load custom selectors:', error);
    }
  }
  
  async saveCustomSelectors() {
    const customTextarea = document.getElementById('customSelectors');
    const statusDiv = document.getElementById('customSelectorsStatus');
    
    if (!customTextarea || !statusDiv) {
      console.error('Custom selectors elements not found');
      return;
    }
    
    const customSelectors = customTextarea.value.trim();
    
    try {
      await chrome.storage.local.set({ customSelectors: customSelectors });
      
      // Update extension in all open tabs
      const tabs = await chrome.tabs.query({});
      for (const tab of tabs) {
        try {
          await chrome.tabs.sendMessage(tab.id, { 
            action: 'updateSelectors', 
            customSelectors: customSelectors
          });
        } catch (e) {
          // Ignore tabs without content script
        }
      }
      
      statusDiv.textContent = '✅ Saved successfully';
      statusDiv.style.color = '#155724';
      
      setTimeout(() => {
        statusDiv.textContent = '';
      }, 2000);
      
    } catch (error) {
      statusDiv.textContent = '❌ Save error';
      statusDiv.style.color = '#721c24';
      console.error('Error saving custom selectors:', error);
    }
  }
  
  showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.style.cssText = `
      background: #f8d7da;
      color: #721c24;
      padding: 10px;
      border-radius: 4px;
      margin-top: 10px;
      font-size: 12px;
      text-align: center;
    `;
    errorDiv.textContent = message;
    
    document.body.appendChild(errorDiv);
    
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.parentNode.removeChild(errorDiv);
      }
    }, 3000);
  }
}

// Initialize interface when page loads
document.addEventListener('DOMContentLoaded', () => {
  try {
    new PopupController();
  } catch (error) {
    console.error('Failed to initialize PopupController:', error);
    // Show error message to user if there's a critical issue
    document.body.innerHTML = `
      <div style="padding: 20px; text-align: center; color: #721c24; background: #f8d7da; border-radius: 8px; margin: 10px;">
        <h3>Extension Initialization Error</h3>
        <p>Please refresh the page or reopen the extension</p>
        <small>Error: ${error.message}</small>
      </div>
    `;
  }
});
EOF

# Create updated README.md with domain control features
echo -e "${GREEN}📄 Creating README.md (with domain control)${NC}"
cat > README.md << 'EOF'
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
- 🌐 **NEW!** Advanced domain control system
- 🚫 **NEW!** Per-domain enable/disable functionality
- 🎛️ **NEW!** Global domain modes (Allow All, Block All, Custom)
- 📋 **NEW!** Domain management interface
- 💾 User preferences saved
- 🔄 Ability to restore original direction

## Domain Control Features

### **Current Domain Control**
- Quick enable/disable for the current website
- Visual status indicator (enabled/disabled)
- Instant feedback on domain status

### **Global Domain Modes**
1. **Custom** - Use per-domain settings with manual control (default)
2. **Allow All** - Extension works on all websites
3. **Block All** - Extension disabled on all websites

**Default Configuration**: The extension is pre-configured to work only on:
- `*.smartsuit.com` (all Smartsuit domains)
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
3. **Default Behavior**: If no specific setting exists, defaults to enabled
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

#### **Advanced Domain Management**
1. **Open Advanced Settings** in the extension popup
2. **Choose Domain Control Mode:**
   - **Allow on all domains** - Works everywhere (default)
   - **Custom domain settings** - Manual per-domain control
   - **Block on all domains** - Disabled everywhere

3. **Manage Custom Domains:**
   - View list of all configured domains
   - See enabled/disabled status for each
   - Remove individual domains with ×
   - Clear all settings with "Clear All"

#### **Domain Pattern Examples**
```
example.com          # Exact domain match
*.google.com         # All Google subdomains
.github.com          # GitHub and all subdomains
```

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
    "example.com": {
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

### Version 1.21
- ✅ Added comprehensive domain control system
- ✅ Per-domain enable/disable functionality
- ✅ Global domain modes (Allow All, Block All, Custom)
- ✅ Domain management interface
- ✅ Wildcard pattern support
- ✅ Improved UI with domain status indicators
- ✅ Enhanced error handling and user feedback

### Version 1.0
- ✅ Initial release with AUTO/RTL modes
- ✅ Custom CSS selectors support
- ✅ Comprehensive field type support
- ✅ Dynamic content tracking
EOF

# Create .gitignore
echo -e "${GREEN}📄 Creating .gitignore${NC}"
cat > .gitignore << 'EOF'
# Chrome Extension Package
*.crx
*.pem

# Logs
*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Temporary files
*~
*.tmp
*.temp

# Node modules (if using build tools)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build output
dist/
build/

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
EOF

# Create installation instructions
echo -e "${GREEN}📄 Creating INSTALL.md${NC}"
cat > INSTALL.md << 'EOF'
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
2. **Set your preferred mode** (AUTO or RTL)
3. **Configure domain settings** if needed:
   - Use "Allow on all domains" for simple setup
   - Use "Custom domain settings" for fine-grained control
4. **Test on a website** with text input fields

## Domain Control Setup

### For Simple Use:
- Keep "Allow on all domains" selected
- Extension will work on all websites

### For Advanced Control:
1. **Change to "Custom domain settings"**
2. **Visit websites** where you want the extension
3. **Use "Enable Here" or "Disable Here"** for each site
4. **Manage domains** in Advanced Settings

## Troubleshooting

- **Extension not loading**: Check that all files are in the correct folder
- **Not working on pages**: Refresh the page after enabling the extension
- **Popup not opening**: Check browser console for errors
- **Domain settings not working**: Ensure you're in "Custom domain settings" mode
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

## Features Overview

After installation, you'll have access to:

- ✅ **Global enable/disable** toggle
- ✅ **AUTO vs RTL** mode selection
- ✅ **Current domain** quick controls
- ✅ **Global domain modes** (Allow All, Custom, Block All)
- ✅ **Custom CSS selectors** for unsupported fields
- ✅ **Domain management** interface
- ✅ **Visual status indicators** for all settings

## Support

If you need help with installation or setup, check the main README.md file or create an issue.
EOF

# Return to parent directory
cd ..

# Success message
echo -e "${GREEN}✅ Extension build completed successfully!${NC}"
echo -e "${BLUE}📁 Extension files created in: ${YELLOW}$EXTENSION_DIR${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "1. ${GREEN}cd $EXTENSION_DIR${NC}"
echo -e "2. ${GREEN}Open Chrome → chrome://extensions/${NC}"
echo -e "3. ${GREEN}Enable Developer mode${NC}"
echo -e "4. ${GREEN}Click 'Load unpacked' → Select the $EXTENSION_DIR folder${NC}"
echo ""
echo -e "${BLUE}📄 Files created:${NC}"
echo -e "   ${GREEN}✓${NC} manifest.json (v1.21)"
echo -e "   ${GREEN}✓${NC} content.js (with domain control)"
echo -e "   ${GREEN}✓${NC} popup.html (with domain management UI)"
echo -e "   ${GREEN}✓${NC} popup.js (with domain control logic)"
echo -e "   ${GREEN}✓${NC} README.md (updated with domain features)"
echo -e "   ${GREEN}✓${NC} .gitignore"
echo -e "   ${GREEN}✓${NC} INSTALL.md"
echo ""
echo -e "${YELLOW}🎉 Your Smart Direction Changer extension with Domain Control is ready!${NC}"
echo ""
echo -e "${BLUE}🆕 NEW Domain Control Features:${NC}"
echo -e "   ${GREEN}✓${NC} Per-domain enable/disable"
echo -e "   ${GREEN}✓${NC} Global domain modes (Custom, Allow All, Block All)"
echo -e "   ${GREEN}✓${NC} Domain management interface"
echo -e "   ${GREEN}✓${NC} Visual domain status indicators"
echo -e "   ${GREEN}✓${NC} Wildcard pattern support"
echo -e "   ${GREEN}✓${NC} Quick domain controls in popup"
echo ""
echo -e "${YELLOW}🎯 Default Configuration:${NC}"
echo -e "   ${GREEN}✓${NC} Pre-configured for *.smartsuit.com"
echo -e "   ${GREEN}✓${NC} Pre-configured for *.monday.com"
echo -e "   ${BLUE}ℹ️${NC}  Extension will only work on these domains by default"
echo -e "   ${BLUE}ℹ️${NC}  Use 'Enable Here' button to add other domains"#!/bin/bash

# Smart Direction Changer Chrome Extension Builder
# This script reconstructs all extension files

# Set extension directory name
EXTENSION_DIR="smart-direction-changer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Building Smart Direction Changer Chrome Extension${NC}"
echo -e "${YELLOW}===============================================${NC}"

# Create extension directory
if [ -d "$EXTENSION_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory $EXTENSION_DIR already exists. Removing...${NC}"
    rm -rf "$EXTENSION_DIR"
fi

echo -e "${BLUE}📁 Creating directory: $EXTENSION_DIR${NC}"
mkdir -p "$EXTENSION_DIR"
cd "$EXTENSION_DIR"

# Create manifest.json
echo -e "${GREEN}📄 Creating manifest.json${NC}"
cat > manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "Smart Direction Changer",
  "version": "1.21",
  "description": "Changes text direction in fields from default (LTR) to Auto or RTL for proper Hebrew/Arabic text display",
  "permissions": [
    "activeTab",
    "storage"
  ],
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "run_at": "document_end"
    }
  ],
  "action": {
    "default_popup": "popup.html",
    "default_title": "Smart Direction Changer"
  },
  "icons": {
    "16": "icon16.png",
    "48": "icon48.png",
    "128": "icon128.png"
  }
}
EOF

# Create content.js
echo -e "${GREEN}📄 Creating content.js${NC}"
cat > content.js << 'EOF'
// Default to Auto/RTL Direction Changer - Content Script

class DirectionChanger {
  constructor() {
    this.enabled = true;
    this.mode = 'auto'; // 'auto' or 'rtl'
    this.targetSelectors = [
      // Basic input fields
      'input[type="text"]',
      'input[type="search"]',
      'input[type="email"]',
      'input[type="password"]',
      'input[type="url"]',
      'input[type="tel"]',
      'input[type="number"]',
      
      // Textarea elements
      'textarea',
      
      // Contenteditable elements
      '[contenteditable="true"]',
      '[contenteditable=""]',
      
      // Input without type (defaults to text)
      'input:not([type])',
      
      // Common form elements
      'input[type="date"]',
      'input[type="time"]',
      'input[type="datetime-local"]',
      'input[type="month"]',
      'input[type="week"]',
      
      // Custom application selectors
      '.ProseMirror',
      '.edit-record-field',
      '.text-field-control',
      '.single-select-control',
      '.grid-view-cell',
      '.record-modal-title__title',
      '.record-list__scrollbar-body',
      '.record-field-section .select-list-items__in',
      '.record-layout-item',
      '.r-textarea',
      '.text--ellipsis',
      '.rct-sidebar-row',
      '.ellipsis',
      '.linked-record-field-control',
      
      // Rich text editors
      '.ql-editor',        // Quill editor
      '.note-editable',    // Summernote editor
      '.fr-element',       // Froala editor
      '.cke_editable',     // CKEditor
      '.mce-content-body', // TinyMCE editor
      '.ace_text-input',   // Ace editor
      '.monaco-editor .view-lines', // Monaco editor
      
      // Social media & messaging
      '[data-testid="tweetTextarea_0"]', // Twitter/X
      '[aria-label*="message"]',          // Generic message inputs
      '[placeholder*="type"]',            // Fields with "type" in placeholder
      '[placeholder*="write"]',           // Fields with "write" in placeholder
      '[placeholder*="enter"]',           // Fields with "enter" in placeholder
      '[placeholder*="search"]',          // Search fields
      
      // Comment systems
      '.comment-input',
      '.reply-input',
      '[name*="comment"]',
      '[id*="comment"]',
      
      // Chat applications
      '[data-testid*="message"]',
      '[aria-label*="chat"]',
      '.chat-input',
      '.message-input',
      
      // LTR explicitly set
      '.ltr',
      '[dir="ltr"]',
      '[style*="direction: ltr"]',
      '[style*="direction:ltr"]',
      
      // Fields without direction set
      'input:not([dir]):not([style*="direction"])',
      'textarea:not([dir]):not([style*="direction"])',
      '[contenteditable]:not([dir]):not([style*="direction"])',
      
      // WordPress & CMS editors
      '#wp-content-editor-container textarea',
      '.wp-editor-area',
      '#content_ifr',      // WordPress TinyMCE iframe
      
      // Google services
      '[aria-label*="Search"]',
      '[data-initial-dir]',
      
      // Generic text containers
      '.text-input',
      '.input-field',
      '.form-control',
      '.form-input',
      '[role="textbox"]',
      
      // Email clients
      '[aria-label*="compose"]',
      '[aria-label*="reply"]',
      '.compose-area',
      
      // Forums & discussion
      '.post-editor',
      '.topic-input',
      '.discussion-input'
    ];
    this.observer = null;
    this.init();
  }

  async init() {
    // Check if extension is enabled and get mode
    const result = await chrome.storage.local.get(['enabled', 'mode', 'customSelectors']);
    this.enabled = result.enabled !== false; // Default: enabled
    this.mode = result.mode || 'auto'; // Default: auto
    
    // Load custom selectors
    await this.loadCustomSelectors();
    
    if (this.enabled) {
      this.changeDirections();
      this.observeChanges();
    }
  }
  
  async loadCustomSelectors() {
    try {
      const result = await chrome.storage.local.get(['customSelectors']);
      const customSelectors = result.customSelectors || '';
      
      if (customSelectors.trim()) {
        // Add custom selectors to the list
        const customArray = customSelectors.split(',').map(s => s.trim()).filter(s => s);
        this.targetSelectors = [...this.targetSelectors, ...customArray];
        console.log('Added custom selectors:', customArray);
      }
    } catch (error) {
      console.log('Could not load custom selectors:', error);
    }
  }

  changeDirections() {
    const elements = document.querySelectorAll(this.targetSelectors.join(','));
    
    elements.forEach(element => {
      const computedStyle = window.getComputedStyle(element);
      const currentDirection = computedStyle.direction;
      const dirAttribute = element.getAttribute('dir');
      const styleDirection = element.style.direction;
      
      // Check if the field needs change:
      // 1. If computed direction is LTR (default or explicit)
      // 2. If no direction setting at all (browser assumes LTR)
      // 3. If explicitly set as LTR
      const needsChange = (
        currentDirection === 'ltr' || 
        (!dirAttribute && !styleDirection) ||
        dirAttribute === 'ltr' ||
        styleDirection === 'ltr'
      );
      
      // Ensure we haven't already changed this element
      const alreadyChanged = element.classList.contains('direction-changed-by-extension');
      
      if (needsChange && !alreadyChanged) {
        // Save original state
        if (!element.hasAttribute('data-original-direction')) {
          element.setAttribute('data-original-direction', currentDirection);
          element.setAttribute('data-original-dir-attr', dirAttribute || 'none');
          element.setAttribute('data-original-style-dir', styleDirection || 'none');
          element.setAttribute('data-original-text-align', computedStyle.textAlign || 'none');
        }
        
        // Apply changes based on mode
        if (this.mode === 'auto') {
          element.style.direction = 'auto';
          element.setAttribute('dir', 'auto');
        } else if (this.mode === 'rtl') {
          element.style.direction = 'rtl';
          element.style.textAlign = 'right';
          element.setAttribute('dir', 'rtl');
        }
        
        // Mark element as changed
        element.classList.add('direction-changed-by-extension');
        
        console.log(`Changed direction to ${this.mode}:`, {
          element: element,
          originalDirection: currentDirection,
          originalDirAttr: dirAttribute,
          tagName: element.tagName,
          type: element.type,
          mode: this.mode
        });
      }
    });
  }

  observeChanges() {
    // Track dynamic changes in the page
    this.observer = new MutationObserver((mutations) => {
      let shouldProcess = false;
      
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          shouldProcess = true;
        } else if (mutation.type === 'attributes' && 
                   (mutation.attributeName === 'dir' || 
                    mutation.attributeName === 'style')) {
          shouldProcess = true;
        }
      });
      
      if (shouldProcess) {
        setTimeout(() => this.changeDirections(), 100);
      }
    });
    
    this.observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['dir', 'style', 'class']
    });
  }

  restoreDirections() {
    const changedElements = document.querySelectorAll('.direction-changed-by-extension');
    
    changedElements.forEach(element => {
      const originalDirection = element.getAttribute('data-original-direction');
      const originalDirAttr = element.getAttribute('data-original-dir-attr');
      const originalStyleDir = element.getAttribute('data-original-style-dir');
      const originalTextAlign = element.getAttribute('data-original-text-align');
      
      // Restore original direction
      if (originalStyleDir && originalStyleDir !== 'none') {
        element.style.direction = originalStyleDir;
      } else {
        element.style.direction = '';
      }
      
      // Restore original text-align
      if (originalTextAlign && originalTextAlign !== 'none') {
        element.style.textAlign = originalTextAlign;
      } else {
        element.style.textAlign = '';
      }
      
      if (originalDirAttr && originalDirAttr !== 'none') {
        element.setAttribute('dir', originalDirAttr);
      } else {
        element.removeAttribute('dir');
      }
      
      // Clean up saved data
      element.classList.remove('direction-changed-by-extension');
      element.removeAttribute('data-original-direction');
      element.removeAttribute('data-original-dir-attr');
      element.removeAttribute('data-original-style-dir');
      element.removeAttribute('data-original-text-align');
    });
  }

  updateCustomSelectors(customSelectors) {
    // Reset selectors to base list
    this.targetSelectors = [
      // Basic input fields
      'input[type="text"]',
      'input[type="search"]',
      'input[type="email"]',
      'input[type="password"]',
      'input[type="url"]',
      'input[type="tel"]',
      'input[type="number"]',
      
      // Textarea elements
      'textarea',
      
      // Contenteditable elements
      '[contenteditable="true"]',
      '[contenteditable=""]',
      
      // Input without type (defaults to text)
      'input:not([type])',
      
      // Common form elements
      'input[type="date"]',
      'input[type="time"]',
      'input[type="datetime-local"]',
      'input[type="month"]',
      'input[type="week"]',
      
      // Custom application selectors
      '.ProseMirror',
      '.edit-record-field',
      '.text-field-control',
      '.single-select-control',
      '.grid-view-cell',
      '.record-modal-title__title',
      '.record-list__scrollbar-body',
      '.record-field-section .select-list-items__in',
      '.record-layout-item',
      '.r-textarea',
      '.text--ellipsis',
      '.rct-sidebar-row',
      '.ellipsis',
      '.linked-record-field-control',
      
      // Rich text editors
      '.ql-editor',        // Quill editor
      '.note-editable',    // Summernote editor
      '.fr-element',       // Froala editor
      '.cke_editable',     // CKEditor
      '.mce-content-body', // TinyMCE editor
      '.ace_text-input',   // Ace editor
      '.monaco-editor .view-lines', // Monaco editor
      
      // Social media & messaging
      '[data-testid="tweetTextarea_0"]', // Twitter/X
      '[aria-label*="message"]',          // Generic message inputs
      '[placeholder*="type"]',            // Fields with "type" in placeholder
      '[placeholder*="write"]',           // Fields with "write" in placeholder
      '[placeholder*="enter"]',           // Fields with "enter" in placeholder
      '[placeholder*="search"]',          // Search fields
      
      // Comment systems
      '.comment-input',
      '.reply-input',
      '[name*="comment"]',
      '[id*="comment"]',
      
      // Chat applications
      '[data-testid*="message"]',
      '[aria-label*="chat"]',
      '.chat-input',
      '.message-input',
      
      // LTR explicitly set
      '.ltr',
      '[dir="ltr"]',
      '[style*="direction: ltr"]',
      '[style*="direction:ltr"]',
      
      // Fields without direction set
      'input:not([dir]):not([style*="direction"])',
      'textarea:not([dir]):not([style*="direction"])',
      '[contenteditable]:not([dir]):not([style*="direction"])',
      
      // WordPress & CMS editors
      '#wp-content-editor-container textarea',
      '.wp-editor-area',
      '#content_ifr',      // WordPress TinyMCE iframe
      
      // Google services
      '[aria-label*="Search"]',
      '[data-initial-dir]',
      
      // Generic text containers
      '.text-input',
      '.input-field',
      '.form-control',
      '.form-input',
      '[role="textbox"]',
      
      // Email clients
      '[aria-label*="compose"]',
      '[aria-label*="reply"]',
      '.compose-area',
      
      // Forums & discussion
      '.post-editor',
      '.topic-input',
      '.discussion-input'
    ];
    
    // Add custom selectors
    if (customSelectors && customSelectors.trim()) {
      const customArray = customSelectors.split(',').map(s => s.trim()).filter(s => s);
      this.targetSelectors = [...this.targetSelectors, ...customArray];
      console.log('Updated with custom selectors:', customArray);
    }
    
    // Re-apply changes
    if (this.enabled) {
      this.changeDirections();
    }
  }

  setMode(newMode) {
    this.mode = newMode;
    chrome.storage.local.set({ mode: newMode });
    
    if (this.enabled) {
      // First restore all elements
      this.restoreDirections();
      // Then re-apply with new mode
      setTimeout(() => this.changeDirections(), 100);
    }
  }

  toggle() {
    this.enabled = !this.enabled;
    
    if (this.enabled) {
      this.changeDirections();
      this.observeChanges();
    } else {
      this.restoreDirections();
      if (this.observer) {
        this.observer.disconnect();
      }
    }
    
    // Save state
    chrome.storage.local.set({ enabled: this.enabled });
  }
}

// Listen for messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'toggle') {
    directionChanger.toggle();
    sendResponse({ enabled: directionChanger.enabled });
  } else if (request.action === 'getStatus') {
    sendResponse({ 
      enabled: directionChanger.enabled,
      mode: directionChanger.mode 
    });
  } else if (request.action === 'updateSelectors') {
    // Update custom selectors
    directionChanger.updateCustomSelectors(request.customSelectors);
    sendResponse({ success: true });
  } else if (request.action === 'setMode') {
    // Set direction mode
    directionChanger.setMode(request.mode);
    sendResponse({ success: true, mode: request.mode });
  }
});

// Create instance
const directionChanger = new DirectionChanger();

// Log that extension loaded
console.log('Default to Auto/RTL Direction Changer loaded');
EOF

# Create popup.html
echo -e "${GREEN}📄 Creating popup.html${NC}"
cat > popup.html << 'EOF'
<!DOCTYPE html>
<html dir="rtl" lang="he">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Direction Changer Extension</title>
  <style>
    body {
      width: 320px;
      padding: 20px;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 0;
      direction: rtl;
      text-align: right;
    }
    
    .header {
      text-align: center;
      margin-bottom: 20px;
      border-bottom: 1px solid #e0e0e0;
      padding-bottom: 15px;
    }
    
    .header h1 {
      font-size: 18px;
      margin: 0;
      color: #333;
    }
    
    .header p {
      font-size: 12px;
      color: #666;
      margin: 5px 0 0 0;
    }
    
    .control-section {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 15px;
      padding: 15px;
      background: #f8f9fa;
      border-radius: 8px;
    }
    
    .control-label {
      font-weight: 500;
      color: #333;
    }
    
    .toggle-switch {
      position: relative;
      width: 50px;
      height: 24px;
      background: #ccc;
      border-radius: 12px;
      cursor: pointer;
      transition: background 0.3s;
    }
    
    .toggle-switch.active {
      background: #4CAF50;
    }
    
    .toggle-switch::after {
      content: '';
      position: absolute;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background: white;
      top: 2px;
      left: 2px;
      transition: transform 0.3s;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    
    .toggle-switch.active::after {
      transform: translateX(26px);
    }
    
    .mode-section {
      margin-bottom: 15px;
      padding: 15px;
      background: #e8f4fd;
      border-radius: 8px;
      border-right: 4px solid #4285f4;
    }
    
    .mode-section h3 {
      margin: 0 0 10px 0;
      color: #1a73e8;
      font-size: 14px;
    }
    
    .mode-options {
      display: flex;
      gap: 10px;
    }
    
    .mode-button {
      flex: 1;
      padding: 8px 12px;
      border: 1px solid #4285f4;
      background: white;
      color: #4285f4;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
      font-weight: 500;
      text-align: center;
      transition: all 0.3s ease;
    }
    
    .mode-button.active {
      background: #4285f4;
      color: white;
    }
    
    .mode-button:hover {
      transform: translateY(-1px);
      box-shadow: 0 2px 8px rgba(66, 133, 244, 0.3);
    }
    
    .mode-description {
      font-size: 11px;
      color: #666;
      margin-top: 8px;
      text-align: center;
    }
    
    .info-section {
      font-size: 12px;
      color: #666;
      background: #e8f4fd;
      padding: 12px;
      border-radius: 6px;
      margin-bottom: 15px;
    }
    
    .stats {
      font-size: 11px;
      color: #888;
      text-align: center;
      border-top: 1px solid #e0e0e0;
      padding-top: 10px;
    }
    
    .status {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 11px;
      font-weight: 500;
      margin-right: 10px;
    }
    
    .status.active {
      background: #d4edda;
      color: #155724;
    }
    
    .status.inactive {
      background: #f8d7da;
      color: #721c24;
    }
    
    .custom-selectors-section {
      margin-top: 15px;
      padding: 15px;
      background: #f8f9fa;
      border-radius: 8px;
      border-top: 1px solid #e0e0e0;
    }
    
    .custom-selectors-section details {
      cursor: pointer;
    }
    
    .custom-selectors-section summary {
      font-weight: bold;
      color: #333;
      margin-bottom: 10px;
      outline: none;
    }
    
    .custom-selectors-section label {
      display: block;
      font-size: 12px;
      color: #666;
      margin-bottom: 5px;
    }
    
    .custom-selectors-section textarea {
      width: 100%;
      height: 60px;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 11px;
      resize: vertical;
      direction: ltr;
      text-align: left;
    }
    
    .save-btn {
      background: linear-gradient(45deg, #4285f4, #34a853);
      color: white;
      border: none;
      padding: 6px 12px;
      border-radius: 25px;
      cursor: pointer;
      font-weight: bold;
      font-size: 11px;
      transition: all 0.3s ease;
      margin-top: 8px;
    }
    
    .save-btn:hover {
      transform: scale(1.05);
      box-shadow: 0 5px 15px rgba(66, 133, 244, 0.4);
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🔄 Direction Changer</h1>
    <p>Smart Text Direction Control</p>
  </div>
  
  <div class="control-section">
    <span class="control-label">Enable Extension</span>
    <div class="toggle-switch" id="toggleSwitch"></div>
  </div>
  
  <div class="mode-section">
    <h3>Direction Mode</h3>
    <div class="mode-options">
      <div class="mode-button" id="autoMode" data-mode="auto">
        AUTO
      </div>
      <div class="mode-button" id="rtlMode" data-mode="rtl">
        RTL + Right Align
      </div>
    </div>
    <div class="mode-description" id="modeDescription">
      AUTO: Browser decides direction based on content
    </div>
  </div>
  
  <div class="info-section">
    <strong>How it works:</strong><br>
    The extension finds fields with default LTR direction and changes them based on your selected mode for proper Hebrew/Arabic text display.
    <br><br>
    <details>
      <summary><strong>Supported Field Types (click to expand)</strong></summary>
      <div style="margin-top: 10px; font-size: 11px; color: #555;">
        ✅ Regular text fields (input, textarea)<br>
        ✅ Search and email fields<br>
        ✅ Rich text editors (Word, Google Docs)<br>
        ✅ Social media platforms (Twitter, Facebook)<br>
        ✅ Comment systems and forums<br>
        ✅ Chat and messaging apps<br>
        ✅ WordPress and CMS editors<br>
        ✅ Google services<br>
        ✅ Email clients<br>
        ✅ Custom application fields
      </div>
    </details>
  </div>
  
  <div class="stats">
    <span class="status" id="status">Inactive</span>
    <span id="currentUrl"></span>
  </div>
  
  <div class="custom-selectors-section">
    <details>
      <summary>⚙️ Advanced Settings</summary>
      <div style="margin-top: 10px;">
        <label>
          Add custom CSS selectors:
        </label>
        <textarea id="customSelectors" 
                  placeholder="Example: .my-input, #special-field"
        ></textarea>
        <button id="saveCustomSelectors" class="save-btn">
          Save Selectors
        </button>
        <div id="customSelectorsStatus" style="margin-top: 5px; font-size: 10px;"></div>
      </div>
    </details>
  </div>

  <script src="popup.js"></script>
</body>
</html>
EOF

# Create popup.js
echo -e "${GREEN}📄 Creating popup.js${NC}"
cat > popup.js << 'EOF'
// Default to Auto/RTL Direction Changer - Popup Script

class PopupController {
  constructor() {
    this.toggleSwitch = null;
    this.status = null;
    this.currentUrl = null;
    this.currentMode = 'auto';
    
    this.init();
  }
  
  async init() {
    try {
      // Wait for DOM to load completely
      await this.waitForDOM();
      
      // Get references to elements
      this.toggleSwitch = document.getElementById('toggleSwitch');
      this.status = document.getElementById('status');
      this.currentUrl = document.getElementById('currentUrl');
      
      if (!this.toggleSwitch || !this.status || !this.currentUrl) {
        throw new Error('Required DOM elements not found');
      }
      
      // Set up event listeners
      this.toggleSwitch.addEventListener('click', () => this.toggle());
      
      // Mode buttons
      const autoModeBtn = document.getElementById('autoMode');
      const rtlModeBtn = document.getElementById('rtlMode');
      
      if (autoModeBtn && rtlModeBtn) {
        autoModeBtn.addEventListener('click', () => this.setMode('auto'));
        rtlModeBtn.addEventListener('click', () => this.setMode('rtl'));
      }
      
      // Custom selectors
      const saveBtn = document.getElementById('saveCustomSelectors');
      const customTextarea = document.getElementById('customSelectors');
      
      if (saveBtn && customTextarea) {
        saveBtn.addEventListener('click', () => this.saveCustomSelectors());
        
        // Load custom selectors
        await this.loadCustomSelectors();
      }
      
      // Get current status
      await this.updateStatus();
      
      // Show current tab URL
      this.showCurrentTab();
      
    } catch (error) {
      console.error('Error initializing popup:', error);
      this.showError('Error initializing interface: ' + error.message);
    }
  }
  
  waitForDOM() {
    return new Promise((resolve) => {
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', resolve);
      } else {
        resolve();
      }
    });
  }
  
  async updateStatus() {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      
      const response = await chrome.tabs.sendMessage(tab.id, { 
        action: 'getStatus' 
      });
      
      const isEnabled = response && response.enabled !== undefined ? response.enabled : true;
      const mode = response && response.mode ? response.mode : 'auto';
      
      this.setToggleState(isEnabled);
      this.updateModeDisplay(mode);
      
    } catch (error) {
      console.log('Could not get status:', error);
      // Default values
      this.setToggleState(true);
      this.updateModeDisplay('auto');
    }
  }
  
  async toggle() {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      
      const response = await chrome.tabs.sendMessage(tab.id, { 
        action: 'toggle' 
      });
      
      this.setToggleState(response.enabled);
      
    } catch (error) {
      console.error('Error toggling extension:', error);
      
      // If no content script, show message to user
      this.showError('Please refresh the page for the extension to work');
    }
  }
  
  async setMode(mode) {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      
      await chrome.tabs.sendMessage(tab.id, { 
        action: 'setMode',
        mode: mode
      });
      
      this.updateModeDisplay(mode);
      
    } catch (error) {
      console.error('Error setting mode:', error);
      this.showError('Please refresh the page for mode change to work');
    }
  }
  
  updateModeDisplay(mode) {
    this.currentMode = mode;
    
    // Update button states
    const autoBtn = document.getElementById('autoMode');
    const rtlBtn = document.getElementById('rtlMode');
    const description = document.getElementById('modeDescription');
    
    if (autoBtn && rtlBtn && description) {
      // Reset button states
      autoBtn.classList.remove('active');
      rtlBtn.classList.remove('active');
      
      // Set active button
      if (mode === 'auto') {
        autoBtn.classList.add('active');
        description.textContent = 'AUTO: Browser decides direction based on content';
      } else if (mode === 'rtl') {
        rtlBtn.classList.add('active');
        description.textContent = 'RTL: Force right-to-left direction with right alignment';
      }
    }
  }
  
  setToggleState(enabled) {
    if (enabled) {
      this.toggleSwitch.classList.add('active');
      this.status.textContent = 'Active';
      this.status.className = 'status active';
    } else {
      this.toggleSwitch.classList.remove('active');
      this.status.textContent = 'Inactive';
      this.status.className = 'status inactive';
    }
  }
  
  async showCurrentTab() {
    try {
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      const tab = tabs[0];
      const url = new URL(tab.url);
      this.currentUrl.textContent = url.hostname;
    } catch (error) {
      this.currentUrl.textContent = 'Not available';
    }
  }
  
  async loadCustomSelectors() {
    try {
      const result = await chrome.storage.local.get(['customSelectors']);
      const customSelectors = result.customSelectors || '';
      const customTextarea = document.getElementById('customSelectors');
      if (customTextarea) {
        customTextarea.value = customSelectors;
      }
    } catch (error) {
      console.log('Could not load custom selectors:', error);
    }
  }
  
  async saveCustomSelectors() {
    const customTextarea = document.getElementById('customSelectors');
    const statusDiv = document.getElementById('customSelectorsStatus');
    
    if (!customTextarea || !statusDiv) {
      console.error('Custom selectors elements not found');
      return;
    }
    
    const customSelectors = customTextarea.value.trim();
    
    try {
      await chrome.storage.local.set({ customSelectors: customSelectors });
      
      // Update extension in all open tabs
      const tabs = await chrome.tabs.query({});
      for (const tab of tabs) {
        try {
          await chrome.tabs.sendMessage(tab.id, { 
            action: 'updateSelectors', 
            customSelectors: customSelectors
          });
        } catch (e) {
          // Ignore tabs without content script
        }
      }
      
      statusDiv.textContent = '✅ Saved successfully';
      statusDiv.style.color = '#155724';
      
      setTimeout(() => {
        statusDiv.textContent = '';
      }, 2000);
      
    } catch (error) {
      statusDiv.textContent = '❌ Save error';
      statusDiv.style.color = '#721c24';
      console.error('Error saving custom selectors:', error);
    }
  }
  
  showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.style.cssText = `
      background: #f8d7da;
      color: #721c24;
      padding: 10px;
      border-radius: 4px;
      margin-top: 10px;
      font-size: 12px;
      text-align: center;
    `;
    errorDiv.textContent = message;
    
    document.body.appendChild(errorDiv);
    
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.parentNode.removeChild(errorDiv);
      }
    }, 3000);
  }
}

// Initialize interface when page loads
document.addEventListener('DOMContentLoaded', () => {
  try {
    new PopupController();
  } catch (error) {
    console.error('Failed to initialize PopupController:', error);
    // Show error message to user if there's a critical issue
    document.body.innerHTML = `
      <div style="padding: 20px; text-align: center; color: #721c24; background: #f8d7da; border-radius: 8px; margin: 10px;">
        <h3>Extension Initialization Error</h3>
        <p>Please refresh the page or reopen the extension</p>
        <small>Error: ${error.message}</small>
      </div>
    `;
  }
});
EOF

# Create README.md
echo -e "${GREEN}📄 Creating README.md${NC}"
cat > README.md << 'EOF'
# Smart Direction Changer

A Chrome extension that changes text direction in fields from default (LTR) to Auto or RTL with right alignment, enabling proper display of mixed Hebrew/Arabic and English text.

## Features

- 🔄 Automatic text direction change from default (LTR) to Auto or RTL
- 🎯 Smart detection of a wide range of text fields and editable elements
- 👀 Dynamic tracking of page changes
- 🔧 Enable/disable toggle
- ⚙️ Choice between AUTO and RTL+Right-Align modes
- 🎨 RTL mode includes proper right text alignment
- 📝 Custom CSS selectors support
- 💾 User preferences saved
- 🔄 Ability to restore original direction

## Quick Installation

1. **Download and run the build script:**
   ```bash
   curl -o build-extension.sh https://your-url/build-extension.sh
   chmod +x build-extension.sh
   ./build-extension.sh
   ```

2. **Load in Chrome:**
   - Open Chrome and go to: `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select the `smart-direction-changer` folder

## Manual Installation

### Method 1: From External Sources
1. Download all files to a local folder
2. Open Chrome and go to: `chrome://extensions/`
3. Enable "Developer mode"
4. Click "Load unpacked"
5. Select the folder with the extension files

### Method 2: Manual Creation
1. Create a new folder named `smart-direction-changer`
2. Create the following files in the folder:

#### Required Files:
- `manifest.json` - Extension configuration
- `content.js` - Main script
- `popup.html` - User interface
- `popup.js` - Interface logic

## Usage

1. After installing the extension, you'll see a new icon in Chrome's toolbar
2. Click on the icon to open the control interface
3. Use the toggle to enable/disable the extension
4. **Select your preferred mode:**
   - **AUTO**: Browser automatically detects direction based on content
   - **RTL + Right Align**: Forces RTL direction with right text alignment
5. The extension will work automatically on all websites where it's enabled

### How it works

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
- Refresh the page (F5)
- Ensure the extension is enabled via the interface button

### Changes not saved
- Ensure the extension has site permissions
- Check that the extension is enabled in `chrome://extensions/`

### Error messages in console
- Open Developer Tools (F12)
- Go to Console tab
- Look for messages from the extension

## Development

### Build Script Usage
```bash
# Make script executable
chmod +x build-extension.sh

# Run the build script
./build-extension.sh

# The script will create a 'smart-direction-changer' directory with all files
```

### Manual Development
If you want to modify the extension:

1. Edit the source files in the extension directory
2. Reload the extension in `chrome://extensions/`
3. Test your changes

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

## License

The extension is available for free use and further development.

## Support

If you encounter issues or have suggestions for improvement, please create an issue or send feedback.
EOF

# Create .gitignore
echo -e "${GREEN}📄 Creating .gitignore${NC}"
cat > .gitignore << 'EOF'
# Chrome Extension Package
*.crx
*.pem

# Logs
*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Temporary files
*~
*.tmp
*.temp

# Node modules (if using build tools)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build output
dist/
build/

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
EOF

# Create installation instructions
echo -e "${GREEN}📄 Creating INSTALL.md${NC}"
cat > INSTALL.md << 'EOF'
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
EOF

# Return to parent directory
cd ..

# Success message
echo -e "${GREEN}✅ Extension build completed successfully!${NC}"
echo -e "${BLUE}📁 Extension files created in: ${YELLOW}$EXTENSION_DIR${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "1. ${GREEN}cd $EXTENSION_DIR${NC}"
echo -e "2. ${GREEN}Open Chrome → chrome://extensions/${NC}"
echo -e "3. ${GREEN}Enable Developer mode${NC}"
echo -e "4. ${GREEN}Click 'Load unpacked' → Select the $EXTENSION_DIR folder${NC}"
echo ""
echo -e "${BLUE}📄 Files created:${NC}"
echo -e "   ${GREEN}✓${NC} manifest.json"
echo -e "   ${GREEN}✓${NC} content.js"
echo -e "   ${GREEN}✓${NC} popup.html"
echo -e "   ${GREEN}✓${NC} popup.js"
echo -e "   ${GREEN}✓${NC} README.md"
echo -e "   ${GREEN}✓${NC} .gitignore"
echo -e "   ${GREEN}✓${NC} INSTALL.md"
echo ""
echo -e "${YELLOW}🎉 Your Smart Direction Changer extension is ready to use!${NC}"
EOF

# Make the script executable
chmod +x build-extension.sh

echo -e "${GREEN}✅ Build script created successfully!${NC}"
echo -e "${BLUE}📁 Script name: build-extension.sh${NC}"
echo ""
echo -e "${YELLOW}To use the script:${NC}"
echo -e "1. ${GREEN}chmod +x build-extension.sh${NC}"
echo -e "2. ${GREEN}./build-extension.sh${NC}"