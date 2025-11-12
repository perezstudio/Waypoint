# Waypoint Implementation Plan
## Using NSSplitView for Three-Column Layout

**Created**: November 11, 2025
**Status**: Ready for Implementation

---

## Overview

This plan outlines the implementation approach for Waypoint, focusing on using Objective-C's `NSSplitView` to create the custom three-column window architecture as specified in the RFP.

---

## Architecture Strategy

### Window Structure Approach

We'll use a hybrid approach combining:
- **Objective-C/AppKit**: For custom window management and NSSplitView layout
- **SwiftUI**: For view content within each split pane
- **NSHostingView**: To bridge SwiftUI views into AppKit split view panes

### Three-Column Layout with NSSplitView

```
┌──────────────────────────────────────────────────────────┐
│  Custom Title Bar (NSWindow)                             │
│  [Team Picker ▾]                    [Traffic Lights]     │
├──────────────┬───────────────────────┬───────────────────┤
│              │                       │                   │
│   Sidebar    │   Main Content        │  Details Panel    │
│   250pt      │   flexible            │   300pt          │
│              │                       │                   │
│  SwiftUI     │   SwiftUI             │   SwiftUI        │
│  in          │   in                  │   in             │
│  NSHosting   │   NSHosting           │   NSHosting      │
│  View        │   View                │   View           │
│              │                       │                   │
└──────────────┴───────────────────────┴───────────────────┘
```

---

## Phase 1: Foundation & Window Architecture

### Step 1.1: Create Objective-C Window Controller
**Files to create:**
- `WaypointWindowController.h`
- `WaypointWindowController.m`

**Implementation:**
```objc
@interface WaypointWindowController : NSWindowController <NSSplitViewDelegate>

@property (nonatomic, strong) NSSplitView *splitView;
@property (nonatomic, strong) NSView *sidebarContainer;
@property (nonatomic, strong) NSView *contentContainer;
@property (nonatomic, strong) NSView *detailsContainer;

@property (nonatomic, assign) BOOL sidebarVisible;
@property (nonatomic, assign) BOOL detailsVisible;
@property (nonatomic, assign) CGFloat sidebarWidth;
@property (nonatomic, assign) CGFloat detailsWidth;

- (void)toggleSidebar;
- (void)toggleDetailsPanel;

@end
```

**Key Features:**
- Configure three-column NSSplitView with dividers
- Set up split view constraints and minimum widths
- Implement collapse/expand animations
- Handle split view delegate methods for resize constraints

### Step 1.2: Configure NSSplitView Layout

**Split View Configuration:**
```objc
// In WaypointWindowController.m
- (void)setupSplitView {
    self.splitView = [[NSSplitView alloc] init];
    self.splitView.vertical = YES;
    self.splitView.dividerStyle = NSSplitViewDividerStyleThin;
    self.splitView.delegate = self;

    // Create three container views
    self.sidebarContainer = [[NSView alloc] init];
    self.contentContainer = [[NSView alloc] init];
    self.detailsContainer = [[NSView alloc] init];

    [self.splitView addArrangedSubview:self.sidebarContainer];
    [self.splitView addArrangedSubview:self.contentContainer];
    [self.splitView addArrangedSubview:self.detailsContainer];

    // Set initial widths
    [self.sidebarContainer setFrameSize:NSMakeSize(250, 0)];
    [self.detailsContainer setFrameSize:NSMakeSize(300, 0)];

    self.window.contentView = self.splitView;
}
```

**Delegate Methods:**
```objc
- (CGFloat)splitView:(NSSplitView *)splitView
constrainMinCoordinate:(CGFloat)proposedMin
         ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0) {
        return 200.0; // Minimum sidebar width
    } else if (dividerIndex == 1) {
        return splitView.frame.size.width - 600.0; // Min content + details
    }
    return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView
constrainMaxCoordinate:(CGFloat)proposedMax
         ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0) {
        return 400.0; // Maximum sidebar width
    } else if (dividerIndex == 1) {
        return splitView.frame.size.width - 250.0; // Min details width
    }
    return proposedMax;
}

- (BOOL)splitView:(NSSplitView *)splitView
canCollapseSubview:(NSSubview *)subview {
    return (subview == self.sidebarContainer ||
            subview == self.detailsContainer);
}
```

### Step 1.3: SwiftUI Bridge Integration

**Create Swift wrapper:**
- `WindowBridge.swift` - Exposes Objective-C window controller to SwiftUI

```swift
import SwiftUI
import AppKit

class WindowBridge: ObservableObject {
    var windowController: WaypointWindowController?

    @Published var sidebarVisible: Bool = true
    @Published var detailsVisible: Bool = true

    func toggleSidebar() {
        windowController?.toggleSidebar()
        sidebarVisible.toggle()
    }

    func toggleDetails() {
        windowController?.toggleDetailsPanel()
        detailsVisible.toggle()
    }

    func setSidebarContent(_ view: NSView) {
        windowController?.sidebarContainer.subviews.forEach { $0.removeFromSuperview() }
        windowController?.sidebarContainer.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: windowController!.sidebarContainer.topAnchor),
            view.bottomAnchor.constraint(equalTo: windowController!.sidebarContainer.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: windowController!.sidebarContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: windowController!.sidebarContainer.trailingAnchor)
        ])
    }

    // Similar methods for content and details
}
```

### Step 1.4: Custom Title Bar & Traffic Lights

**Customize NSWindow:**
```objc
// In WaypointWindowController init
NSWindow *window = [[NSWindow alloc]
    initWithContentRect:NSMakeRect(0, 0, 1200, 800)
    styleMask:(NSWindowStyleMaskTitled |
               NSWindowStyleMaskClosable |
               NSWindowStyleMaskMiniaturizable |
               NSWindowStyleMaskResizable |
               NSWindowStyleMaskFullSizeContentView)
    backing:NSBackingStoreBuffered
    defer:NO];

window.titlebarAppearsTransparent = YES;
window.titleVisibility = NSWindowTitleHidden;

// Add team picker to title bar area via accessory view
NSTitlebarAccessoryViewController *accessory = [[NSTitlebarAccessoryViewController alloc] init];
// Configure with SwiftUI team picker
```

---

## Phase 2: SwiftUI View Structure

### Step 2.1: Create Core View Components

**Sidebar View:**
```swift
// Views/Sidebar/SidebarView.swift
struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]

    @State private var selectedView: SidebarItem = .inbox

    var body: some View {
        VStack(spacing: 0) {
            // Team Picker
            TeamPickerView()
                .padding()

            Divider()

            // Navigation Items
            List(selection: $selectedView) {
                Section {
                    SidebarRow(icon: "tray.fill", title: "Inbox", badge: 12)
                    SidebarRow(icon: "calendar", title: "Today", badge: 5)
                    SidebarRow(icon: "calendar.badge.clock", title: "Scheduled")
                    SidebarRow(icon: "list.bullet", title: "All Issues", badge: 47)
                    SidebarRow(icon: "book.closed", title: "Logbook")
                    SidebarRow(icon: "folder", title: "Projects", badge: 8)
                }

                Section("Favorites") {
                    // Dynamic favorite projects
                }

                Section("Labels") {
                    // Dynamic labels
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)
    }
}
```

**Main Content View:**
```swift
// Views/Content/MainContentView.swift
struct MainContentView: View {
    @Binding var selectedView: SidebarItem

    var body: some View {
        Group {
            switch selectedView {
            case .inbox:
                InboxView()
            case .today:
                TodayView()
            case .scheduled:
                ScheduledView()
            case .allIssues:
                AllIssuesView()
            case .logbook:
                LogbookView()
            case .projects:
                ProjectsListView()
            case .project(let id):
                ProjectDetailView(projectId: id)
            }
        }
        .frame(minWidth: 400)
    }
}
```

**Details Panel View:**
```swift
// Views/Details/DetailsPanelView.swift
struct DetailsPanelView: View {
    @Binding var selectedIssue: Issue?
    @Binding var selectedProject: Project?

    var body: some View {
        Group {
            if let issue = selectedIssue {
                IssueDetailView(issue: issue)
            } else if let project = selectedProject {
                ProjectSummaryView(project: project)
            } else {
                EmptyDetailView()
            }
        }
        .frame(minWidth: 250, idealWidth: 300, maxWidth: 500)
    }
}
```

### Step 2.2: Update App Entry Point

**Modify WaypointApp.swift:**
```swift
@main
struct WaypointApp: App {
    let container: ModelContainer

    init() {
        // Setup SwiftData with all models from RFP
        let schema = Schema([
            Team.self,
            Project.self,
            Issue.self,
            Milestone.self,
            Label.self,
            Status.self,
            Checklist.self,
            Comment.self,
            ProjectLink.self,
            ProjectUpdate.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.waypoint.app")
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        // Use NSApplicationDelegateAdaptor to bridge to Objective-C window
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

// Bridge view that connects to Objective-C window controller
struct RootView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        let windowController = WaypointWindowController()

        // Create SwiftUI views
        let sidebar = NSHostingView(rootView: SidebarView())
        let content = NSHostingView(rootView: MainContentView(selectedView: .constant(.inbox)))
        let details = NSHostingView(rootView: DetailsPanelView(
            selectedIssue: .constant(nil),
            selectedProject: .constant(nil)
        ))

        // Inject into window controller
        context.coordinator.setupViews(
            windowController: windowController,
            sidebar: sidebar,
            content: content,
            details: details
        )

        return windowController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        func setupViews(
            windowController: WaypointWindowController,
            sidebar: NSView,
            content: NSView,
            details: NSView
        ) {
            // Add views to split view containers
            windowController.addViewToSidebar(sidebar)
            windowController.addViewToContent(content)
            windowController.addViewToDetails(details)
        }
    }
}
```

---

## Phase 3: Data Models Implementation

### Step 3.1: Create SwiftData Models

**Priority Order:**
1. `Team.swift` - Base entity
2. `Status.swift` - Required for issues
3. `Label.swift` - Can be created independently
4. `Project.swift` - Depends on Team
5. `Milestone.swift` - Depends on Project
6. `Issue.swift` - Depends on Team, Project, Milestone, Status, Label
7. Supporting entities (Checklist, Comment, ProjectLink, ProjectUpdate)

**Implementation Reference:**
See RFP lines 33-275 for complete model definitions with relationships and validation rules.

### Step 3.2: Default Data Seeding

**Create DefaultDataService.swift:**
```swift
class DefaultDataService {
    static func seedDefaultData(context: ModelContext) {
        // Create default team
        let team = Team(name: "Personal", isDefault: true)
        context.insert(team)

        // Create default statuses for each parent status
        let statuses = [
            Status(name: "Backlog", parentStatus: .backlog, sortOrder: 0, team: team),
            Status(name: "To Do", parentStatus: .planned, sortOrder: 0, team: team),
            Status(name: "In Progress", parentStatus: .inProgress, sortOrder: 0, team: team),
            Status(name: "Done", parentStatus: .completed, sortOrder: 0, team: team),
            Status(name: "Canceled", parentStatus: .canceled, sortOrder: 0, team: team)
        ]
        statuses.forEach { context.insert($0) }

        // Create default labels
        let labels = [
            Label(name: "Bug", color: "#FF5630", team: team),
            Label(name: "Feature", color: "#0065FF", team: team),
            Label(name: "Enhancement", color: "#36B37E", team: team)
        ]
        labels.forEach { context.insert($0) }

        try? context.save()
    }
}
```

---

## Phase 4: View Implementation Details

### Step 4.1: Issue Views Priority
1. **InboxView** - Simplest, good starting point
2. **AllIssuesView** - Core list/board functionality
3. **TodayView** - Date filtering variation
4. **ScheduledView** - Calendar integration (more complex)
5. **LogbookView** - Archive view

### Step 4.2: Project Views Priority
1. **ProjectsListView** - Grid/list of projects
2. **ProjectDetailView** - Tabbed interface
3. **ProjectOverviewTab** - Metadata + Markdown editor
4. **ProjectIssuesTab** - Filtered issue view
5. **ProjectUpdatesTab** - Timeline feed

---

## Phase 5: Key Technical Challenges

### Challenge 1: NSHostingView Performance
**Issue**: SwiftUI views in NSHostingView can have layout issues
**Solution**:
- Use explicit frame modifiers
- Avoid implicit sizing when possible
- Test with large datasets early

### Challenge 2: Split View State Restoration
**Issue**: User's panel sizes should persist between sessions
**Solution**:
```objc
- (void)saveWindowState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:self.sidebarWidth forKey:@"sidebarWidth"];
    [defaults setFloat:self.detailsWidth forKey:@"detailsWidth"];
    [defaults setBool:self.sidebarVisible forKey:@"sidebarVisible"];
    [defaults setBool:self.detailsVisible forKey:@"detailsVisible"];
}

- (void)restoreWindowState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.sidebarWidth = [defaults floatForKey:@"sidebarWidth"] ?: 250.0;
    // ... restore other properties
}
```

### Challenge 3: SwiftUI/Objective-C Communication
**Issue**: Passing state between SwiftUI and Objective-C
**Solution**:
- Use `@Observable` macro in Swift 6
- Bridge through `WindowBridge` class
- Use NotificationCenter for events that don't need to be observed

---

## Implementation Timeline

### Week 1-2: Window Architecture
- [ ] Create Objective-C window controller and split view setup
- [ ] Implement basic three-column layout
- [ ] Test split view resizing and constraints
- [ ] Add collapse/expand functionality
- [ ] Integrate custom title bar

### Week 3-4: Data Layer
- [ ] Implement all SwiftData models per RFP
- [ ] Add validation and business logic
- [ ] Create default data seeding service
- [ ] Test CloudKit sync configuration
- [ ] Build data access repositories

### Week 5-6: Core Views (Sidebar + Basic List)
- [ ] Implement SidebarView with navigation
- [ ] Create InboxView (simplest)
- [ ] Build reusable IssueRow component
- [ ] Implement basic IssueDetailView
- [ ] Connect views to split view containers

### Week 7-8: Issue Management
- [ ] Complete all issue list views (Today, Scheduled, All, Logbook)
- [ ] Add filtering and sorting
- [ ] Implement issue CRUD operations
- [ ] Build checklist and comment functionality
- [ ] Add label and status pickers

### Week 9-10: Project Management
- [ ] Implement ProjectsListView
- [ ] Create ProjectDetailView with tabs
- [ ] Build Markdown editor for plans
- [ ] Add milestone management
- [ ] Implement project updates feed

### Week 11: Polish & Settings
- [ ] Create settings window
- [ ] Implement keyboard shortcuts
- [ ] Add drag-and-drop support
- [ ] Build board view for issues
- [ ] Accessibility audit

### Week 12: Testing & Bug Fixes
- [ ] Unit tests for models and business logic
- [ ] Integration tests for data layer
- [ ] UI tests for critical paths
- [ ] Performance testing with large datasets
- [ ] CloudKit sync verification

---

## Development Best Practices

### Code Organization
```
Waypoint/
├── App/
│   ├── WaypointApp.swift
│   ├── AppDelegate.swift (if needed)
│   └── WindowBridge.swift
├── Window/
│   ├── WaypointWindowController.h
│   ├── WaypointWindowController.m
│   └── WindowCoordinator.swift
├── Models/
│   ├── Team.swift
│   ├── Project.swift
│   ├── Issue.swift
│   └── ... (all SwiftData models)
├── Views/
│   ├── Sidebar/
│   │   ├── SidebarView.swift
│   │   └── SidebarRow.swift
│   ├── Content/
│   │   ├── MainContentView.swift
│   │   ├── Inbox/
│   │   ├── Projects/
│   │   └── Issues/
│   ├── Details/
│   │   ├── DetailsPanelView.swift
│   │   └── IssueDetail/
│   └── Shared/
│       └── Components/
├── Services/
│   ├── DefaultDataService.swift
│   ├── DataRepository.swift
│   └── CloudKitService.swift
└── Utilities/
    ├── Extensions/
    └── Helpers/
```

### Testing Strategy
1. **Unit Tests**: All model validation logic
2. **Integration Tests**: SwiftData CRUD operations
3. **UI Tests**: Critical navigation paths
4. **Manual Tests**: Split view behavior, CloudKit sync

### Git Workflow
- Feature branches for each major component
- PR reviews for data model changes
- Commit window architecture before building on it
- Tag major milestones

---

## Next Immediate Steps

1. **Set up Objective-C bridge** (Start here!)
   - Add Objective-C bridging header to Xcode project
   - Create WaypointWindowController files
   - Verify Swift can import Objective-C classes

2. **Prototype split view**
   - Implement basic three-column layout
   - Add colored placeholder views
   - Test resizing and collapsing

3. **First SwiftUI integration**
   - Create simple SwiftUI views
   - Wrap in NSHostingView
   - Inject into split view containers

4. **Validate approach**
   - Run app and verify layout
   - Test window resizing
   - Confirm SwiftUI updates properly

---

## Success Criteria

### Phase 1 Complete When:
- ✅ Three-column layout renders correctly
- ✅ Split views resize within constraints
- ✅ Sidebar and details can collapse/expand
- ✅ SwiftUI views render in all three panes
- ✅ Custom title bar integrated
- ✅ Window state persists between launches

### Full MVP Complete When:
- ✅ All data models implemented and syncing via CloudKit
- ✅ All core views functional (Inbox, Projects, etc.)
- ✅ Full CRUD operations for issues and projects
- ✅ Markdown editor working for project plans
- ✅ Keyboard navigation throughout app
- ✅ Settings window functional
- ✅ No critical bugs, smooth performance

---

## Resources & References

- **Apple Docs**:
  - NSSplitView Programming Guide
  - NSHostingView documentation
  - SwiftData relationships guide
  - CloudKit best practices

- **Example Projects**:
  - Look at Mail.app for split view inspiration
  - Notes.app for custom title bar examples
  - Reminders.app for sidebar patterns

---

**Ready to Start**: Begin with Step 1.1 - Create WaypointWindowController files
