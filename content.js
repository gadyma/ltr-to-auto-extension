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
