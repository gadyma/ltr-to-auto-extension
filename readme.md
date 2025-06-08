# Default to Auto Direction Changer

תוסף כרום שמשנה את כיוון הטקסט בשדות שברירת המחדל שלהם היא LTR (כמו שדות טקסט רגילים) ל-Auto, מה שמאפשר הצגה נכונה של טקסט מעורב (עברית ואנגלית).

## תכונות

- 🔄 שינוי אוטומטי של כיוון טקסט מברירת מחדל (LTR) ל-Auto
- 🎯 זיהוי חכם של מגוון רחב של שדות טקסט ואלמנטים עריכים
- 👀 מעקב אחרי שינויים דינמיים בעמוד
- 🔧 אפשרות להפעיל/לכבות את התוסף
- ⚙️ **חדש!** הוספת בוחרים מותאמים אישית (Custom CSS Selectors)
- 💾 שמירת העדפות משתמש
- 🔄 אפשרות לשחזר את הכיוון המקורי

## איך זה עובד

## סוגי שדות נתמכים

התוסף מחפש ועובד על המגוון הרחב הבא של אלמנטים:

### 📝 שדות קלט בסיסיים
- שדות טקסט רגילים (`input[type="text"]`, `input[type="search"]`)
- שדות אימייל, סיסמה, URL (`input[type="email/password/url"]`)
- שדות טלפון ומספרים (`input[type="tel/number"]`)
- אזורי טקסט (`textarea`)
- שדות ללא type מוגדר (`input` ללא attribute)

### 📅 שדות תאריך ושעה
- `input[type="date/time/datetime-local/month/week"]`

### ✏️ עורכי טקסט עשיר
- **Quill Editor** (`.ql-editor`)
- **Summernote** (`.note-editable`)
- **Froala** (`.fr-element`)
- **CKEditor** (`.cke_editable`)
- **TinyMCE** (`.mce-content-body`)
- **Ace Editor** (`.ace_text-input`)
- **Monaco Editor** (`.monaco-editor .view-lines`)

### 🌐 רשתות חברתיות והודעות
- **Twitter/X** (`[data-testid="tweetTextarea_0"]`)
- שדות הודעות כלליים (`[aria-label*="message"]`)
- שדות עם placeholder מתאים (`[placeholder*="type/write/enter"]`)

### 💬 מערכות תגובות וצ'אט
- שדות תגובות (`.comment-input`, `[name*="comment"]`)
- שדות צ'אט (`.chat-input`, `.message-input`)
- אלמנטים עם aria-label של צ'אט

### 📰 WordPress ו-CMS
- עורך WordPress (`#wp-content-editor-container textarea`)
- TinyMCE של WordPress (`#content_ifr`)
- שדות עריכה כלליים (`.wp-editor-area`)

### 🔍 שירותי Google
- שדות חיפוש (`[aria-label*="Search"]`)
- אלמנטים עם `[data-initial-dir]`

### ✉️ לקוחות דואר אלקטרוני
- שדות כתיבה (`[aria-label*="compose/reply"]`)
- אזורי כתיבה (`.compose-area`)

### 🗣️ פורומים ודיונים
- עורכי פוסטים (`.post-editor`)
- שדות נושא (`.topic-input`)
- שדות דיון (`.discussion-input`)

### 🎛️ אלמנטים כלליים
- ContentEditable (`[contenteditable="true"]`)
- TextBox Role (`[role="textbox"]`)
- שדות עם classes נפוצים (`.text-input`, `.form-control`)

### 🔧 אלמנטים ספציפיים לאפליקציות
- **ProseMirror Editor** (`.ProseMirror`)
- **Record Management** (`.edit-record-field`, `.record-modal-title__title`)
- **Grid & List Views** (`.grid-view-cell`, `.record-list__scrollbar-body`)
- **Text Controls** (`.text-field-control`, `.single-select-control`)
- **Layout Items** (`.record-layout-item`, `.record-field-section .select-list-items__in`)
- **Text Areas** (`.r-textarea`)
- **Text Display** (`.text--ellipsis`, `.ellipsis`)
- **Sidebar Rows** (`.rct-sidebar-row`)
- **Linked Records** (`.linked-record-field-control`)

### ⚙️ בוחרים מותאמים אישית
אפשרות להוסיף CSS selectors משלך דרך ההגדרות המתקדמות בתוסף!

כאשר הוא מוצא אלמנט שברירת המחדל שלו היא LTR (או שמוגדר מפורשות כ-LTR), הוא משנה את הכיוון ל-`direction: auto`, מה שמאפשר לדפדפן להחליט על הכיוון בהתאם לתוכן הטקסט בפועל.

## התקנה

### שיטה 1: ממקורות חיצוניים
1. הורד את כל הקבצים למחיצה מקומית
2. פתח את Chrome ועבור ל: `chrome://extensions/`
3. הפעל "מצב מפתח" (Developer mode)
4. לחץ "טען תוסף לא ארוז" (Load unpacked)
5. בחר את התיקייה עם קבצי התוסף

### שיטה 2: יצירה ידנית
1. צור תיקייה חדשה בשם `default-to-auto-extension`
2. צור את הקבצים הבאים בתיקייה:

#### קבצים נדרשים:
- `manifest.json` - קובץ התצורה
- `content.js` - הסקריפט הראשי
- `popup.html` - ממשק המשתמש
- `popup.js` - לוגיקת הממשק

#### קבצי אייקונים (אופציונלי):
- `icon16.png` (16x16 פיקסלים)
- `icon48.png` (48x48 פיקסלים)  
- `icon128.png` (128x128 פיקסלים)

## שימוש

1. לאחר התקנת התוסף, תראה אייקון חדש בסרגל הכלים של Chrome
2. לחץ על האייקון כדי לפתוח את ממשק הבקרה
3. השתמש במתג כדי להפעיל/לכבות את התוסף
4. התוסף יפעל אוטומטיות על כל האתרים שבהם הוא מופעל

### ⚙️ הגדרות מתקדמות - בוחרים מותאמים

אם התוסף לא עובד על שדה מסוים, תוכל להוסיף אותו בעצמך:

1. **פתח את ממשק התוסף** ולחץ על "הגדרות מתקדמות"
2. **זהה את השדה**: 
   - לחץ F12 (Developer Tools)
   - לחץ על כלי הבחירה (🔍) ובחר את השדה הרצוי
   - תראה משהו כמו: `<input class="my-special-input" id="chat-box">`
3. **הוסף בוחר מתאים**:
   - לפי class: `.my-special-input`
   - לפי ID: `#chat-box`
   - לפי attribute: `[data-message="true"]`
4. **שמור** - התוסף יתחיל לעבוד על השדה מיד!

#### דוגמאות לבוחרים מותאמים:
```css
.my-chat-input, #message-box
[data-role="composer"]
.custom-editor textarea
input[name="comment"]
```

**טיפ**: אפשר להוסיף מספר בוחרים מופרדים בפסיקים.

## פתרון בעיות

### התוסף לא עובד על עמוד מסוים
- רענן את הדף (F5)
- ודא שהתוסף מופעל באמצעות הלחצן במשתמש

### השינויים לא נשמרים
- ודא שלתוסף יש הרשאות גישה לאתר
- בדוק שהתוסף מופעל ב-`chrome://extensions/`

### הודעות שגיאה בקונסול
- פתח את Developer Tools (F12)
- עבור לטאב Console
- חפש הודעות מהתוסף

## פיתוח נוסף

### הוספת סוגי שדות חדשים לקוד
אם אתה מפתח ורוצה להוסיף תמיכה קבועה לסוג שדה חדש, ערוך את `content.js`:

```javascript
this.targetSelectors = [
  // הוסף כאן בוחרים חדשים
  '.your-new-selector',
  '[data-your-attribute]',
  // ...
];
```

### שינוי התנהגות
ניתן לשנות את הלוגיקה ב-`changeDirections()` כדי להתאים לצרכים ספציפיים.

### בדיקת פעילות התוסף
פתח Developer Console (F12) וחפש הודעות:
- `Default to Auto Direction Changer loaded` - התוסף נטען
- `Changed direction to auto: ...` - שדה שונה בהצלחה
- `Updated with custom selectors: ...` - בוחרים מותאמים נוספו

## רישיון

התוסף זמין לשימוש חופשי ופיתוח נוסף.

## תמיכה

אם נתקלת בבעיות או יש לך הצעות לשיפור, צור issue או שלח משוב.