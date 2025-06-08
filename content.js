// Default to Auto Direction Changer - Content Script

class DirectionChanger {
  constructor() {
    this.enabled = true;
    this.targetSelectors = [
      // Input fields - סוגי שדות קלט בסיסיים
      'input[type="text"]',
      'input[type="search"]',
      'input[type="email"]',
      'input[type="password"]',
      'input[type="url"]',
      'input[type="tel"]',
      'input[type="number"]',
      
      // Textarea - אזורי טקסט
      'textarea',
      
      // Contenteditable elements - אלמנטים עריכים
      '[contenteditable="true"]',
      '[contenteditable=""]',
      
      // Input without type (defaults to text) - שדות ללא type מוגדר
      'input:not([type])',
      
      // Common form elements - אלמנטים נפוצים בטפסים
      'input[type="date"]',
      'input[type="time"]',
      'input[type="datetime-local"]',
      'input[type="month"]',
      'input[type="week"]',
      
      // Custom application selectors - בוחרים ספציפיים לאפליקציה
      '.ProseMirror',
      '.edit-record-field',
      '.text-field-control',
      '.single-select-control',
      '.grid-view-cell',
      '.grid-cell-field',
      '.field-gutters',
      '.record-modal-title__title',
      '.record-list__scrollbar-body',
      '.record-field-section',
      '.select-list-items__in',
      '.record-layout-item',
      '.r-textarea',
      '.text--ellipsis',
      '.rct-sidebar-row',
      '.ellipsis',
      '.linked-record-field-control',
      
      // Rich text editors - עורכי טקסט עשיר
      '.ql-editor',        // Quill editor
      '.note-editable',    // Summernote editor
      '.fr-element',       // Froala editor
      '.cke_editable',     // CKEditor
      '.mce-content-body', // TinyMCE editor
      '.ace_text-input',   // Ace editor
      '.monaco-editor .view-lines', // Monaco editor
      
      // Social media & messaging - רשתות חברתיות והודעות
      '[data-testid="tweetTextarea_0"]', // Twitter/X
      '[aria-label*="message"]',          // Generic message inputs
      '[placeholder*="type"]',            // Fields with "type" in placeholder
      '[placeholder*="write"]',           // Fields with "write" in placeholder
      '[placeholder*="enter"]',           // Fields with "enter" in placeholder
      '[placeholder*="search"]',          // Search fields
      
      // Comment systems - מערכות תגובות
      '.comment-input',
      '.reply-input',
      '[name*="comment"]',
      '[id*="comment"]',
      
      // Chat applications - אפליקציות צ'אט
      '[data-testid*="message"]',
      '[aria-label*="chat"]',
      '.chat-input',
      '.message-input',
      
      // LTR explicitly set - מוגדר מפורשות כ-LTR
      '.ltr',
      '[dir="ltr"]',
      '[style*="direction: ltr"]',
      '[style*="direction:ltr"]',
      
      // Fields without direction set - שדות ללא הגדרת כיוון
      'input:not([dir]):not([style*="direction"])',
      'textarea:not([dir]):not([style*="direction"])',
      '[contenteditable]:not([dir]):not([style*="direction"])',
      
      // WordPress & CMS editors - עורכי וורדפרס ו-CMS
      '#wp-content-editor-container textarea',
      '.wp-editor-area',
      '#content_ifr',      // WordPress TinyMCE iframe
      
      // Google services - שירותי גוגל
      '[aria-label*="Search"]',
      '[data-initial-dir]',
      
      // Generic text containers - מכילי טקסט כלליים
      '.text-input',
      '.input-field',
      '.form-control',
      '.form-input',
      '[role="textbox"]',
      
      // Email clients - לקוחות דואר
      '[aria-label*="compose"]',
      '[aria-label*="reply"]',
      '.compose-area',
      
      // Forums & discussion - פורומים ודיונים
      '.post-editor',
      '.topic-input',
      '.discussion-input'
    ];
    this.observer = null;
    this.init();
  }

  async init() {
    // בדיקה אם התוסף מופעל
    const result = await chrome.storage.local.get(['enabled', 'customSelectors']);
    this.enabled = result.enabled !== false; // ברירת מחדל: מופעל
    
    // טעינת בוחרים מותאמים
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
        // הוספת בוחרים מותאמים לרשימה
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
      
      // בדוק אם השדה צריך שינוי:
      // 1. אם הכיוון המחושב הוא LTR (ברירת מחדל או מפורש)
      // 2. אם אין הגדרת כיוון כלל (אז הדפדפן מניח LTR)
      // 3. אם מוגדר מפורשות כ-LTR
      const needsChange = (
        currentDirection === 'ltr' || 
        (!dirAttribute && !styleDirection) ||
        dirAttribute === 'ltr' ||
        styleDirection === 'ltr'
      );
      
      // וודא שלא שינינו כבר את האלמנט
      const alreadyChanged = element.classList.contains('direction-changed-to-auto');
      
      if (needsChange && !alreadyChanged) {
        // שמירת המצב המקורי
        if (!element.hasAttribute('data-original-direction')) {
          element.setAttribute('data-original-direction', currentDirection);
          element.setAttribute('data-original-dir-attr', dirAttribute || 'none');
          element.setAttribute('data-original-style-dir', styleDirection || 'none');
        }
        
        // שינוי הכיוון ל-auto
        element.style.direction = 'auto';
        element.setAttribute('dir', 'auto');
        
        // הוספת class לזיהוי אלמנטים שהשתנו
        element.classList.add('direction-changed-to-auto');
        
        console.log('Changed direction to auto:', {
          element: element,
          originalDirection: currentDirection,
          originalDirAttr: dirAttribute,
          tagName: element.tagName,
          type: element.type
        });
      }
    });
  }

  observeChanges() {
    // מעקב אחרי שינויים דינמיים בעמוד
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
    const changedElements = document.querySelectorAll('.direction-changed-to-auto');
    
    changedElements.forEach(element => {
      const originalDirection = element.getAttribute('data-original-direction');
      const originalDirAttr = element.getAttribute('data-original-dir-attr');
      const originalStyleDir = element.getAttribute('data-original-style-dir');
      
      // שחזור הכיוון המקורי
      if (originalStyleDir && originalStyleDir !== 'none') {
        element.style.direction = originalStyleDir;
      } else {
        element.style.direction = '';
      }
      
      if (originalDirAttr && originalDirAttr !== 'none') {
        element.setAttribute('dir', originalDirAttr);
      } else {
        element.removeAttribute('dir');
      }
      
      // ניקוי המידע שנשמר
      element.classList.remove('direction-changed-to-auto');
      element.removeAttribute('data-original-direction');
      element.removeAttribute('data-original-dir-attr');
      element.removeAttribute('data-original-style-dir');
    });
  }

  updateCustomSelectors(customSelectors) {
    // איפוס הבוחרים לרשימה הבסיסית
    this.targetSelectors = [
      // Input fields - סוגי שדות קלט בסיסיים
      'input[type="text"]',
      'input[type="search"]',
      'input[type="email"]',
      'input[type="password"]',
      'input[type="url"]',
      'input[type="tel"]',
      'input[type="number"]',
      
      // Textarea - אזורי טקסט
      'textarea',
      
      // Contenteditable elements - אלמנטים עריכים
      '[contenteditable="true"]',
      '[contenteditable=""]',
      
      // Input without type (defaults to text) - שדות ללא type מוגדר
      'input:not([type])',
      
      // Common form elements - אלמנטים נפוצים בטפסים
      'input[type="date"]',
      'input[type="time"]',
      'input[type="datetime-local"]',
      'input[type="month"]',
      'input[type="week"]',
      
      // Custom application selectors - בוחרים ספציפיים לאפליקציה
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
      
      // Rich text editors - עורכי טקסט עשיר
      '.ql-editor',        // Quill editor
      '.note-editable',    // Summernote editor
      '.fr-element',       // Froala editor
      '.cke_editable',     // CKEditor
      '.mce-content-body', // TinyMCE editor
      '.ace_text-input',   // Ace editor
      '.monaco-editor .view-lines', // Monaco editor
      
      // Social media & messaging - רשתות חברתיות והודעות
      '[data-testid="tweetTextarea_0"]', // Twitter/X
      '[aria-label*="message"]',          // Generic message inputs
      '[placeholder*="type"]',            // Fields with "type" in placeholder
      '[placeholder*="write"]',           // Fields with "write" in placeholder
      '[placeholder*="enter"]',           // Fields with "enter" in placeholder
      '[placeholder*="search"]',          // Search fields
      
      // Comment systems - מערכות תגובות
      '.comment-input',
      '.reply-input',
      '[name*="comment"]',
      '[id*="comment"]',
      
      // Chat applications - אפליקציות צ'אט
      '[data-testid*="message"]',
      '[aria-label*="chat"]',
      '.chat-input',
      '.message-input',
      
      // LTR explicitly set - מוגדר מפורשות כ-LTR
      '.ltr',
      '[dir="ltr"]',
      '[style*="direction: ltr"]',
      '[style*="direction:ltr"]',
      
      // Fields without direction set - שדות ללא הגדרת כיוון
      'input:not([dir]):not([style*="direction"])',
      'textarea:not([dir]):not([style*="direction"])',
      '[contenteditable]:not([dir]):not([style*="direction"])',
      
      // WordPress & CMS editors - עורכי וורדפרס ו-CMS
      '#wp-content-editor-container textarea',
      '.wp-editor-area',
      '#content_ifr',      // WordPress TinyMCE iframe
      
      // Google services - שירותי גוגל
      '[aria-label*="Search"]',
      '[data-initial-dir]',
      
      // Generic text containers - מכילי טקסט כלליים
      '.text-input',
      '.input-field',
      '.form-control',
      '.form-input',
      '[role="textbox"]',
      
      // Email clients - לקוחות דואר
      '[aria-label*="compose"]',
      '[aria-label*="reply"]',
      '.compose-area',
      
      // Forums & discussion - פורומים ודיונים
      '.post-editor',
      '.topic-input',
      '.discussion-input'
    ];
    
    // הוספת בוחרים מותאמים
    if (customSelectors && customSelectors.trim()) {
      const customArray = customSelectors.split(',').map(s => s.trim()).filter(s => s);
      this.targetSelectors = [...this.targetSelectors, ...customArray];
      console.log('Updated with custom selectors:', customArray);
    }
    
    // הפעלה מחדש של השינויים
    if (this.enabled) {
      this.changeDirections();
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
    
    // שמירת המצב
    chrome.storage.local.set({ enabled: this.enabled });
  }
}

// האזנה להודעות מה-popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'toggle') {
    directionChanger.toggle();
    sendResponse({ enabled: directionChanger.enabled });
  } else if (request.action === 'getStatus') {
    sendResponse({ enabled: directionChanger.enabled });
  } else if (request.action === 'updateSelectors') {
    // עדכון בוחרים מותאמים
    directionChanger.updateCustomSelectors(request.customSelectors);
    sendResponse({ success: true });
  }
});

// יצירת מופע של הקלאס
const directionChanger = new DirectionChanger();

// הודעה לקונסול שהתוסף פועל
console.log('Default to Auto Direction Changer loaded');