// Default to Auto Direction Changer - Popup Script

class PopupController {
  constructor() {
    this.toggleSwitch = null;
    this.status = null;
    this.currentUrl = null;
    
    this.init();
  }
  
  async init() {
    try {
      // חכה שה-DOM יטען לגמרי
      await this.waitForDOM();
      
      // קבל רפרנסים לאלמנטים
      this.toggleSwitch = document.getElementById('toggleSwitch');
      this.status = document.getElementById('status');
      this.currentUrl = document.getElementById('currentUrl');
      
      if (!this.toggleSwitch || !this.status || !this.currentUrl) {
        throw new Error('Required DOM elements not found');
      }
      
      // הגדרת event listeners
      this.toggleSwitch.addEventListener('click', () => this.toggle());
      
      // Custom selectors
      const saveBtn = document.getElementById('saveCustomSelectors');
      const customTextarea = document.getElementById('customSelectors');
      
      if (saveBtn && customTextarea) {
        saveBtn.addEventListener('click', () => this.saveCustomSelectors());
        
        // טעינת בוחרים מותאמים
        await this.loadCustomSelectors();
      }
      
      // קבלת המצב הנוכחי
      await this.updateStatus();
      
      // הצגת URL הנוכחי
      this.showCurrentTab();
      
    } catch (error) {
      console.error('Error initializing popup:', error);
      this.showError('שגיאה באתחול הממשק: ' + error.message);
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
      this.setToggleState(isEnabled);
      
    } catch (error) {
      console.log('Could not get status:', error);
      // ברירת מחדל
      this.setToggleState(true);
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
      
      // אם אין content script, נציג הודעה למשתמש
      this.showError('יש לרענן את הדף כדי שהתוסף יפעל');
    }
  }
  
  setToggleState(enabled) {
    if (enabled) {
      this.toggleSwitch.classList.add('active');
      this.status.textContent = 'פעיל';
      this.status.className = 'status active';
    } else {
      this.toggleSwitch.classList.remove('active');
      this.status.textContent = 'לא פעיל';
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
      this.currentUrl.textContent = 'לא זמין';
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
      
      // עדכון התוסף בכל הטאבים הפתוחים
      const tabs = await chrome.tabs.query({});
      for (const tab of tabs) {
        try {
          await chrome.tabs.sendMessage(tab.id, { 
            action: 'updateSelectors', 
            customSelectors: customSelectors
          });
        } catch (e) {
          // התעלם מטאבים שאין בהם content script
        }
      }
      
      statusDiv.textContent = '✅ נשמר בהצלחה';
      statusDiv.style.color = '#155724';
      
      setTimeout(() => {
        statusDiv.textContent = '';
      }, 2000);
      
    } catch (error) {
      statusDiv.textContent = '❌ שגיאה בשמירה';
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

// אתחול הממשק כשהדף נטען
document.addEventListener('DOMContentLoaded', () => {
  try {
    new PopupController();
  } catch (error) {
    console.error('Failed to initialize PopupController:', error);
    // הצגת הודעת שגיאה למשתמש אם יש בעיה קריטית
    document.body.innerHTML = `
      <div style="padding: 20px; text-align: center; color: #721c24; background: #f8d7da; border-radius: 8px; margin: 10px;">
        <h3>שגיאה באתחול התוסף</h3>
        <p>אנא רענן את הדף או פתח מחדש את התוסף</p>
        <small>שגיאה: ${error.message}</small>
      </div>
    `;
  }
});