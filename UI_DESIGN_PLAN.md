# Bin Management App - UI Design Plan

## Color Scheme

### Primary Colors
- **Primary Blue**: `#2563EB` (Blue-600) - Main actions, primary buttons
- **Primary Light**: `#3B82F6` (Blue-500) - Active states, highlights
- **Primary Dark**: `#1D4ED8` (Blue-700) - Pressed states

### Status Colors
- **Active/Success**: `#10B981` (Green-500) - Active bins, successful actions
- **Missing/Error**: `#EF4444` (Red-500) - Missing bins, errors
- **Warning**: `#F59E0B` (Amber-500) - High fill percentage, attention needed
- **Info**: `#06B6D4` (Cyan-500) - Information, neutral states

### Neutrals
- **Surface**: `#FFFFFF` (White) - Card backgrounds
- **Background**: `#F9FAFB` (Gray-50) - Screen background
- **Border**: `#E5E7EB` (Gray-200) - Borders, dividers
- **Text Primary**: `#111827` (Gray-900)
- **Text Secondary**: `#6B7280` (Gray-500)

### Dark Mode
- **Surface**: `#1F2937` (Gray-800)
- **Background**: `#111827` (Gray-900)
- **Border**: `#374151` (Gray-700)

## Typography Scale
- **Display**: 32px / Bold - Page titles
- **Headline**: 24px / Semibold - Section headers
- **Title**: 20px / Semibold - Card titles
- **Body**: 16px / Regular - Body text
- **Caption**: 14px / Regular - Secondary text
- **Label**: 12px / Medium - Labels, badges

---

## Login Screen ✅ (Completed)
**Current Implementation:**
- Clean, centered layout
- Large icon (delete/bin symbol)
- Password field with show/hide toggle
- Loading states
- Error display
- Professional, minimal design

---

## Driver Dashboard (Map View)

### Layout Structure
```
┌─────────────────────────────┐
│  AppBar                     │
│  - Title: "My Route"        │
│  - Profile Icon             │
│  - Notifications Badge      │
└─────────────────────────────┘
┌─────────────────────────────┐
│                             │
│    MAP (Full Height)        │
│    - Custom bin markers     │
│    - User location dot      │
│    - Route polyline         │
│    - Cluster for bins       │
│                             │
│  ┌───────────────────────┐  │
│  │ Bottom Sheet          │  │
│  │ - Quick Stats Card    │  │
│  │ - Recommended Bins    │  │
│  │ - Swipe up for list   │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
┌─────────────────────────────┐
│ Bottom Nav Bar              │
│ [Map] [Route] [History]     │
└─────────────────────────────┘
```

### Key Components

**1. Map Markers**
- **Assigned Bin**: Blue pin with bin number
- **High Priority**: Red pin (>80% full)
- **Medium Priority**: Amber pin (50-80% full)
- **Low Priority**: Green pin (<50% full)
- **Current Location**: Pulsing blue dot with accuracy circle

**2. Bottom Sheet (Draggable)**
- **Collapsed State** (180px):
  - Quick stats: Bins today, Distance, Fill %
  - "Best 5 Bins" horizontal scroll
  - Swipe up indicator

- **Expanded State** (70% screen):
  - Full bin list with filters
  - Sort options (distance, fill %, priority)
  - Search bar

**3. Bin Card (in list)**
```
┌─────────────────────────────────┐
│ 🗑️ BIN #23         [85%] 🔴   │
│ 470 Blossom Hill Rd             │
│ San Jose, CA 95123              │
│ ├─ 2.3 mi away                  │
│ └─ Last checked: 2h ago         │
│          [Navigate] [Check In]  │
└─────────────────────────────────┘
```

**4. Bottom Navigation**
- **Map** (default): Shows map view
- **Route**: Today's route list, stats, navigation
- **History**: Past checks/moves

---

## Manager Dashboard (Map View)

### Layout Structure
```
┌─────────────────────────────┐
│  AppBar                     │
│  - Title: "All Bins"        │
│  - Filter Icon              │
│  - Add Bin Icon             │
└─────────────────────────────┘
┌─────────────────────────────┐
│   Stat Cards (horizontal)   │
│ [Total] [Active] [Missing]  │
└─────────────────────────────┘
┌─────────────────────────────┐
│                             │
│    MAP (Full Height)        │
│    - All bins               │
│    - Driver locations       │
│    - Heatmap overlay        │
│    - Cluster markers        │
│                             │
│  ┌───────────────────────┐  │
│  │ Bottom Sheet          │  │
│  │ - Driver List         │  │
│  │ - Bin Status          │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
┌─────────────────────────────┐
│ Bottom Nav Bar              │
│ [Map] [Drivers] [Analytics] │
└─────────────────────────────┘
```

### Key Components

**1. Stat Cards (Horizontal Scroll)**
```
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ Total Bins     │  │ Active         │  │ Missing        │
│ 44             │  │ 39 🟢         │  │ 5 🔴          │
└────────────────┘  └────────────────┘  └────────────────┘
```

**2. Driver Tracking**
- Real-time driver dots on map
- Tap driver = show route + assigned bins
- ETA to each bin

**3. Analytics Tab**
- Charts: Fill % over time, Check frequency
- Driver performance
- Bin utilization heatmap

---

## Bin Detail Page

### Layout (Scrollable)
```
┌─────────────────────────────┐
│ ← BIN #23           [Edit]  │
└─────────────────────────────┘
┌─────────────────────────────┐
│   Status: Active 🟢         │
│   Fill: 85%                 │
│   [██████████████████░░░░]  │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 📍 Location                 │
│ 470 Blossom Hill Rd         │
│ San Jose, CA 95123          │
│ [View on Map]               │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 📅 Last Activity            │
│ Checked: 2 hours ago        │
│ Moved: 4 days ago           │
└─────────────────────────────┘
┌─────────────────────────────┐
│ Actions                     │
│ [Check Bin] [Move Bin]      │
│ [Mark Missing]              │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 📊 Check History            │
│ ┌─ Aug 26: 2% ─────────┐   │
│ ├─ Aug 22: 2% ─────────┤   │
│ ├─ Aug 20: 40% ████────┤   │
│ └─ Aug 15: 5% ─────────┘   │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 🚚 Move History             │
│ Aug 20: 3255 Mission...     │
│         → 470 Blossom...    │
└─────────────────────────────┘
```

---

## Check-In Flow (Driver)

### Step 1: Scan/Select Bin
```
┌─────────────────────────────┐
│ Check In                    │
│                             │
│    [Camera Preview]         │
│    Scan bin QR code         │
│                             │
│    or                       │
│    [Select from list ▼]     │
└─────────────────────────────┘
```

### Step 2: Fill Percentage
```
┌─────────────────────────────┐
│ BIN #23                     │
│                             │
│ How full is it?             │
│                             │
│   [██████████░░░░░░░░░░]   │
│          75%                │
│                             │
│ 0%  [slider]  100%          │
│                             │
│ [Take Photo] (optional)     │
│                             │
│      [Submit Check]         │
└─────────────────────────────┘
```

### Step 3: Confirmation
```
┌─────────────────────────────┐
│      ✓ Check Recorded!      │
│                             │
│  Bin #23 updated to 75%     │
│                             │
│  [View Next Bin]            │
│  [Back to Map]              │
└─────────────────────────────┘
```

---

## Route Optimization Screen (Driver)

```
┌─────────────────────────────┐
│ ← Recommended Route         │
└─────────────────────────────┘
┌─────────────────────────────┐
│ Based on your location:     │
│ Current: 123 Main St        │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 📍 Best 5 Bins              │
│                             │
│ 1. BIN #9  [100%] 🔴        │
│    5524 Monterey Rd         │
│    0.8 mi → 3 min           │
│    [Navigate]               │
│                             │
│ 2. BIN #6  [90%] 🟠         │
│    2161 Monterey Rd         │
│    1.2 mi → 4 min           │
│    [Navigate]               │
│                             │
│ ... (3 more)                │
│                             │
│ Total Distance: 5.2 mi      │
│ Estimated Time: 18 min      │
│                             │
│ [Start Route Navigation]    │
└─────────────────────────────┘
```

---

## Design Principles

### 1. Information Hierarchy
- **Most important**: Current action (check-in, navigate)
- **Secondary**: Status, fill percentage
- **Tertiary**: History, metadata

### 2. Touch Targets
- Minimum 48x48dp for all buttons
- Cards: 56dp minimum height
- FAB: 56x56dp

### 3. Spacing System
- **4dp base unit**
- xs: 4dp, sm: 8dp, md: 16dp, lg: 24dp, xl: 32dp

### 4. Motion
- **Fast**: 200ms - Simple transitions
- **Medium**: 300ms - Page transitions
- **Slow**: 400ms - Complex animations

### 5. Accessibility
- All text minimum 16sp
- Color contrast ratio 4.5:1
- Screen reader support
- Haptic feedback on actions

---

## Component Library

### Buttons
- **Primary**: Filled button, blue background
- **Secondary**: Outlined button, blue border
- **Tertiary**: Text button, blue text

### Cards
- Elevation: 0
- Border: 1px gray-200
- Radius: 12dp
- Padding: 16dp

### Badges
- **Status**: Pill shape, colored background
- **Count**: Circle, red background
- Size: 20x20dp minimum

### Progress Indicators
- **Linear**: 4dp height, rounded caps
- **Circular**: 24dp diameter, 3dp stroke
- Colors match status (red >80%, amber 50-80%, green <50%)

---

## Implementation Phases

### ✅ Phase 1: Foundation (Current)
- Authentication
- Role-based routing
- Color system
- Base layout

### 🚧 Phase 2: Core Map Features (Next)
- Google Maps integration
- Bin markers
- User location
- Basic bottom sheet

### 📋 Phase 3: Driver Features
- Check-in flow
- Route optimization
- Navigation integration
- History

### 📋 Phase 4: Manager Features
- Driver tracking
- Analytics dashboard
- Bin management (add/edit)
- Heatmap

### 📋 Phase 5: Polish & Advanced
- Offline support
- Push notifications
- Photo uploads
- Performance optimization
