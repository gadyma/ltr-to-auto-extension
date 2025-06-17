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
          '*.smartsuite.com': { enabled: true, timestamp: Date.now() },
          '*.monday.com': { enabled: true, timestamp: Date.now() }
        };
        domainMode = 'custom';
        
        // Save defaults
        await chrome.storage.local.set({ 
          domainSettings: domainSettings,
          domainMode: domainMode 
        });
        
        console.log('Set default domain settings for smartsuite.com and monday.com');
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
