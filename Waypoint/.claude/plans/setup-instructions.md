# Waypoint Setup Instructions

## What We've Built

We've successfully implemented the three-column window architecture for Waypoint using Objective-C NSSplitView and SwiftUI views. Here's what was created:

### Files Created

**Objective-C Window Management:**
- `Window/WaypointWindowController.h` - Header for custom window controller
- `Window/WaypointWindowController.m` - Implementation with NSSplitView setup
- `Waypoint-Bridging-Header.h` - Bridge for Swift to access Objective-C

**Swift Bridge:**
- `Window/WindowBridge.swift` - Observable class for SwiftUI/Objective-C communication

**SwiftUI Views:**
- `Views/Sidebar/SidebarView.swift` - Left panel navigation
- `Views/Content/MainContentView.swift` - Center content area
- `Views/Details/DetailsPanelView.swift` - Right details panel

**Updated Files:**
- `WaypointApp.swift` - Now uses AppDelegate to create custom window

## Next Steps: Add Files to Xcode Project

Since we created these files outside of Xcode, you'll need to add them to your Xcode project:

### Step 1: Add Files to Xcode

1. Open `Waypoint.xcodeproj` in Xcode
2. Right-click on the project navigator and select "Add Files to Waypoint..."
3. Add the following folders:
   - `Window/` folder (contains Objective-C and Swift files)
   - `Views/` folder (contains SwiftUI views)
4. Make sure "Copy items if needed" is **unchecked** (files are already in place)
5. Make sure "Create groups" is selected
6. Ensure "Waypoint" target is checked
7. Add the `Waypoint-Bridging-Header.h` file to the project root

### Step 2: Configure Bridging Header

1. Select the Waypoint project in the navigator
2. Select the "Waypoint" target
3. Go to "Build Settings" tab
4. Search for "Objective-C Bridging Header"
5. Set the value to: `Waypoint/Waypoint-Bridging-Header.h`

### Step 3: Build and Run

1. Select "Waypoint" scheme
2. Press `Cmd+B` to build
3. If build succeeds, press `Cmd+R` to run

### Expected Result

When you run the app, you should see:
- A window with three columns
- Left sidebar with navigation items
- Center content area with welcome message
- Right details panel with empty state
- Resizable dividers between columns
- Collapsible sidebar and details panel (double-click dividers)

## Architecture Overview

```
┌────────────────────────────────────────────────────────┐
│  Window (NSWindow)                                     │
│  ├─ NSSplitView (vertical, 3 columns)                 │
│  │   ├─ Sidebar Container (NSView)                    │
│  │   │   └─ NSHostingView(SidebarView)               │
│  │   ├─ Content Container (NSView)                    │
│  │   │   └─ NSHostingView(MainContentView)           │
│  │   └─ Details Container (NSView)                    │
│  │       └─ NSHostingView(DetailsPanelView)          │
└────────────────────────────────────────────────────────┘
```

## Key Features Implemented

### Window Controller (Objective-C)
- ✅ Three-column NSSplitView layout
- ✅ Resizable columns with min/max constraints
- ✅ Collapsible sidebar and details panel
- ✅ Window state persistence (saves panel widths/visibility)
- ✅ Custom title bar configuration
- ✅ Methods to add SwiftUI views to each panel

### SwiftUI Views
- ✅ Sidebar with navigation structure
- ✅ Main content area with welcome screen
- ✅ Details panel with empty state
- ✅ Basic styling matching macOS design patterns

### Integration
- ✅ AppDelegate creates window controller on launch
- ✅ NSHostingView bridges SwiftUI into AppKit
- ✅ WindowBridge class for state management

## Testing the Layout

Once running, test these features:

1. **Resize columns**: Drag the dividers between panels
2. **Collapse sidebar**: Double-click left divider
3. **Collapse details**: Double-click right divider
4. **Window resize**: Verify columns resize proportionally
5. **Quit and relaunch**: Verify panel sizes are restored

## Troubleshooting

### Build Error: "Cannot find 'WaypointWindowController' in scope"
- **Solution**: Make sure bridging header path is set correctly in Build Settings

### Build Error: "No such file or directory"
- **Solution**: Verify all files were added to the Xcode target

### Runtime Error: Black/empty window
- **Solution**: Check that NSHostingView views are being added correctly in AppDelegate

### Panels won't resize
- **Solution**: Check NSSplitView delegate methods in WaypointWindowController.m

## What's Next

After verifying the basic layout works, the next steps are:

1. **Data Models**: Implement SwiftData models (Team, Project, Issue, etc.)
2. **Navigation**: Make sidebar items functional
3. **Issue Views**: Build inbox, today, all issues views
4. **Details Panel**: Show issue/project details when selected
5. **CRUD Operations**: Add, edit, delete issues and projects

Refer to `implementation-plan.md` for the full roadmap.

## File Structure

```
Waypoint/
├── Waypoint-Bridging-Header.h
├── WaypointApp.swift (updated)
├── Window/
│   ├── WaypointWindowController.h
│   ├── WaypointWindowController.m
│   └── WindowBridge.swift
└── Views/
    ├── Sidebar/
    │   └── SidebarView.swift
    ├── Content/
    │   └── MainContentView.swift
    └── Details/
        └── DetailsPanelView.swift
```

## Support

If you encounter issues:
1. Clean build folder: `Cmd+Shift+K`
2. Clean derived data: `Cmd+Option+Shift+K`
3. Restart Xcode
4. Check all files are added to target (file inspector, right panel)
