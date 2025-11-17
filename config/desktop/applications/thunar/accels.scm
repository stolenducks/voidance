;; Thunar Keyboard Shortcuts Configuration
;; Default keyboard shortcuts for Voidance desktop environment
;; Educational: Each shortcut includes explanation for learning

;; =============================================================================
;; FILE OPERATIONS
;; =============================================================================

;; Open file/folder
;; Traditional Enter key for opening selected items
(gtk_accel_path "<Actions>/ThunarWindow/open" "Return")

;; Open in new tab
;; Ctrl+Enter opens selected item in new tab
(gtk_accel_path "<Actions>/ThunarWindow/open-in-new-tab" "<Primary>Return")

;; Open with other application
;; Right-click context menu alternative
(gtk_accel_path "<Actions>/ThunarWindow/open-in-other-application" "<Primary><Shift>o")

;; Rename file
;; F2 is the standard for renaming files
(gtk_accel_path "<Actions>/ThunarWindow/rename" "F2")

;; Delete file
;; Delete key moves to trash (with confirmation)
(gtk_accel_path "<Actions>/ThunarWindow/trash-delete" "Delete")

;; Permanent delete
;; Shift+Delete bypasses trash (use with caution)
(gtk_accel_path "<Actions>/ThunarWindow/delete" "<Shift>Delete")

;; =============================================================================
;; NAVIGATION
;; =============================================================================

;; Go back
;; Alt+Left arrow for backward navigation
(gtk_accel_path "<Actions>/ThunarWindow/back" "<Alt>Left")

;; Go forward
;; Alt+Right arrow for forward navigation
(gtk_accel_path "<Actions>/ThunarWindow/forward" "<Alt>Right")

;; Go up one level
;; Alt+Up arrow for parent directory
(gtk_accel_path "<Actions>/ThunarWindow/up" "<Alt>Up")

;; Go home
;; Alt+Home for user's home directory
(gtk_accel_path "<Actions>/ThunarWindow/home" "<Alt>Home")

;; Reload directory
;; F5 or Ctrl+R to refresh directory listing
(gtk_accel_path "<Actions>/ThunarWindow/reload" "F5")
(gtk_accel_path "<Actions>/ThunarWindow/reload" "<Primary>r")

;; =============================================================================
;; TAB MANAGEMENT
;; =============================================================================

;; New tab
;; Ctrl+T for new tab (browser-like behavior)
(gtk_accel_path "<Actions>/ThunarWindow/new-tab" "<Primary>t")

;; Close tab
;; Ctrl+W or Ctrl+F4 to close current tab
(gtk_accel_path "<Actions>/ThunarWindow/close-tab" "<Primary>w")
(gtk_accel_path "<Actions>/ThunarWindow/close-tab" "<Primary>F4")

;; Next tab
;; Ctrl+Tab to switch to next tab
(gtk_accel_path "<Actions>/ThunarWindow/next-tab" "<Primary>Tab")

;; Previous tab
;; Ctrl+Shift+Tab to switch to previous tab
(gtk_accel_path "<Actions>/ThunarWindow/prev-tab" "<Primary><Shift>Tab")

;; =============================================================================
;; WINDOW MANAGEMENT
;; =============================================================================

;; New window
;; Ctrl+N for new file manager window
(gtk_accel_path "<Actions>/ThunarWindow/new-window" "<Primary>n")

;; Close window
;; Ctrl+Q to quit application
(gtk_accel_path "<Actions>/ThunarWindow/close" "<Primary>q")

;; =============================================================================
;; VIEW MODES
;; =============================================================================

;; Icon view
;; Ctrl+1 for icon view mode
(gtk_accel_path "<Actions>/ThunarWindow/icon-view" "<Primary>1")

;; List view
;; Ctrl+2 for detailed list view
(gtk_accel_path "<Actions>/ThunarWindow/detailed-list-view" "<Primary>2")

;; Compact view
;; Ctrl+3 for compact list view
(gtk_accel_path "<Actions>/ThunarWindow/compact-view" "<Primary>3")

;; =============================================================================
;; SEARCH AND SELECTION
;; =============================================================================

;; Find files
;; Ctrl+F to open file search
(gtk_accel_path "<Actions>/ThunarWindow/find" "<Primary>f")

;; Select all
;; Ctrl+A to select all files in current directory
(gtk_accel_path "<Actions>/ThunarWindow/select-all" "<Primary>a")

;; Invert selection
;; Ctrl+I to invert current selection
(gtk_accel_path "<Actions>/ThunarWindow/invert-selection" "<Primary>i")

;; =============================================================================
;; BOOKMARKS
;; =============================================================================

;; Add bookmark
;; Ctrl+D to bookmark current directory
(gtk_accel_path "<Actions>/ThunarWindow/add-bookmark" "<Primary>d")

;; Edit bookmarks
;; Ctrl+B to manage bookmarks
(gtk_accel_path "<Actions>/ThunarWindow/edit-bookmarks" "<Primary>b")

;; =============================================================================
;; FILE OPERATIONS (ADVANCED)
;; =============================================================================

;; Copy
;; Ctrl+C to copy selected files
(gtk_accel_path "<Actions>/ThunarWindow/copy" "<Primary>c")

;; Cut
;; Ctrl+X to cut selected files
(gtk_accel_path "<Actions>/ThunarWindow/cut" "<Primary>x")

;; Paste
;; Ctrl+V to paste files
(gtk_accel_path "<Actions>/ThunarWindow/paste" "<Primary>v")

;; Select by pattern
;; Ctrl+S to select files by pattern
(gtk_accel_path "<Actions>/ThunarWindow/select-by-pattern" "<Primary>s")

;; =============================================================================
;; PROPERTIES AND INFORMATION
;; =============================================================================

;; File properties
;; Alt+Enter or Ctrl+I for file properties dialog
(gtk_accel_path "<Actions>/ThunarWindow/file-properties" "<Primary>i")
(gtk_accel_path "<Actions>/ThunarWindow/file-properties" "<Alt>Return")

;; =============================================================================
;; EDUCATIONAL NOTES
;; =============================================================================

;; This keyboard shortcut configuration is designed to be educational:
;; - Follows standard desktop conventions (Ctrl+C for copy, etc.)
;; - Browser-like tab management for familiarity
;; - Traditional navigation keys (Alt+Left/Right for back/forward)
;; - Function keys for common operations (F2 rename, F5 refresh)
;; - Consistent with other desktop applications

;; Learning tips:
;; - Primary means Ctrl key on most keyboards
;; - These shortcuts work across most GTK applications
;; - Tab management follows web browser conventions
;; - File operations use standard shortcuts (copy/paste/cut)
;; - Navigation shortcuts work in most file managers

;; Customization:
;; - Modify this file to change keyboard shortcuts
;; - Use Thunar's preferences dialog to customize shortcuts
;; - Some shortcuts may conflict with system-wide shortcuts
;; - Consider your workflow when customizing shortcuts