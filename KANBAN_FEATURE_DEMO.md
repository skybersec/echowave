# 🎯 Survey Kanban Board Feature

## Overview
Your surveys page now includes a powerful SCRUM/JIRA-style Kanban board view! You can easily manage your surveys by dragging and dropping them between different status columns or using dropdown menus.

## Features

### 📋 Four Status Columns
- **Draft** - Surveys being created
- **Published** - Ready but not active  
- **Live** - Actively collecting responses
- **Completed** - Finished collecting responses

### 🎯 How to Use

#### View Toggle
- Click the **List** button for traditional list view
- Click the **Board** button for Kanban board view
- The toggle is located next to the "My Surveys" title

#### Drag & Drop (Just like JIRA!)
1. In board view, simply **click and drag** any survey card
2. **Drop it** into any column to change its status
3. The survey status will update automatically in the database

#### Status Dropdown
1. Click the **"Status"** dropdown on any survey card
2. Select the desired status:
   - Draft
   - Published  
   - Live
   - Completed
3. Status updates immediately

#### Additional Actions
- **Edit** surveys (except completed ones)
- **Share** surveys with the share button
- **Delete** surveys with confirmation
- **View** survey details and response progress

### 🎨 Visual Indicators
- **Color-coded columns** for easy status identification
- **Progress bars** showing response collection progress
- **Response counters** (current/target responses)
- **Template icons** for different survey types
- **Drag effects** with rotation and scaling during drag operations

### 💡 Pro Tips
- The board view automatically adjusts to a wider layout for better column visibility
- Completed surveys are protected from accidental editing
- Real-time updates ensure your team sees changes immediately
- Empty states guide you when columns are empty

### 🔄 Status Flow
Typical workflow: **Draft** → **Published** → **Live** → **Completed**

You can move surveys between any states as needed for your workflow!

## Tech Details
- Built with `@hello-pangea/dnd` for smooth drag & drop
- Responsive design works on desktop and tablets
- Real-time database updates via Supabase
- Maintains all existing functionality from list view

---

Navigate to `/surveys` and toggle to "Board" view to try it out! 🚀 