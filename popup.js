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
