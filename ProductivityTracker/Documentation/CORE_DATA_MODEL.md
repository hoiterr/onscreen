# Core Data Model Definition

This document describes the Core Data model for Productivity Tracker. Use this as a reference when creating the `.xcdatamodeld` file in Xcode.

## Model Name
**ProductivityTracker.xcdatamodeld**

## Entities

### 1. SessionEntity

Represents a single activity session (time spent in a specific app/window).

#### Attributes

| Attribute | Type | Optional | Default | Indexed | Description |
|-----------|------|----------|---------|---------|-------------|
| `id` | UUID | No | UUID() | Yes | Unique identifier |
| `appName` | String | Yes | - | Yes | Display name of the application |
| `bundleID` | String | Yes | - | Yes | Bundle identifier (e.g., com.apple.Safari) |
| `windowTitle` | String | Yes | - | No | Title of the active window |
| `url` | String | Yes | - | No | Browser URL if applicable |
| `category` | String | Yes | - | Yes | Activity category (work, leisure, etc.) |
| `startTime` | Date | Yes | - | Yes | Session start timestamp |
| `endTime` | Date | Yes | - | Yes | Session end timestamp |
| `duration` | Double | No | 0.0 | No | Duration in seconds |

#### Relationships
None

#### Fetch Request Indexes

Create a compound index for efficient time-based queries:
- **Index 1**: `startTime` (ascending)
- **Index 2**: `category` (ascending)

This enables fast queries like:
```swift
NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate, endDate)
```

#### Code Generation
- **Codegen**: `Manual/None`
- **Module**: Current Product Module
- **Class**: `SessionEntity`

The entity class is defined in `Data/Entities/SessionEntity.swift`.

---

### 2. RuleEntity

Represents a categorization rule defined by the user.

#### Attributes

| Attribute | Type | Optional | Default | Indexed | Description |
|-----------|------|----------|---------|---------|-------------|
| `id` | UUID | No | UUID() | Yes | Unique identifier |
| `name` | String | Yes | - | No | User-friendly rule name |
| `conditionType` | String | Yes | - | No | Type: "app", "url", or "title" |
| `pattern` | String | Yes | - | No | Pattern to match (supports wildcards) |
| `category` | String | Yes | - | Yes | Target category for matches |
| `priority` | Int16 | No | 0 | Yes | Rule evaluation order (lower = higher priority) |
| `isEnabled` | Boolean | No | true | No | Whether rule is active |
| `createdAt` | Date | Yes | - | No | Rule creation timestamp |

#### Relationships
None

#### Fetch Request Indexes

Create an index on priority for ordered rule evaluation:
- **Index 1**: `priority` (ascending)

This enables fast ordered queries:
```swift
NSSortDescriptor(keyPath: \RuleEntity.priority, ascending: true)
```

#### Code Generation
- **Codegen**: `Manual/None`
- **Module**: Current Product Module
- **Class**: `RuleEntity`

The entity class is defined in `Data/Entities/RuleEntity.swift`.

---

## Model Configuration

### Configurations
- **Default Configuration**: Includes both entities

### Store Type
- **SQLite** (default)
- Location: `~/Library/Application Support/com.yourcompany.productivitytracker/`

### Migrations
- **Lightweight Migration**: Enabled
- **Automatic Migration**: Enabled

Add to `PersistenceController`:
```swift
container.persistentStoreDescriptions.first?.setOption(
    true as NSNumber,
    forKey: NSPersistentStoreRemoveUbiquitousMetadataOption
)
```

---

## Creating the Model in Xcode

### Step-by-Step Instructions

1. **Create Data Model File**
   ```
   File → New → File...
   → Core Data → Data Model
   → Name: ProductivityTracker.xcdatamodeld
   → Create
   ```

2. **Add SessionEntity**
   - Click "Add Entity" button
   - Rename to `SessionEntity`
   - Add attributes (see table above)
   - Set attribute types and optionality
   - Enable indexes on `id`, `appName`, `bundleID`, `category`, `startTime`, `endTime`

3. **Add RuleEntity**
   - Click "Add Entity" button
   - Rename to `RuleEntity`
   - Add attributes (see table above)
   - Set attribute types and optionality
   - Enable indexes on `id`, `priority`, `category`

4. **Configure Code Generation**
   - Select each entity
   - In Data Model Inspector:
     - Set **Codegen** to `Manual/None`
     - Set **Module** to `Current Product Module`
     - Set **Class Name** to entity name

5. **Create Indexes**
   - Select `SessionEntity`
   - Click "+" under "Indexes" section
   - Add index on `startTime`
   - (Optional) Add compound index: `startTime + category`

   - Select `RuleEntity`
   - Add index on `priority`

6. **Verify Model**
   - Build project (⌘B)
   - Ensure no Core Data compilation errors

---

## Example Queries

### Fetch Today's Sessions
```swift
let calendar = Calendar.current
let startOfDay = calendar.startOfDay(for: Date())
let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

let request = SessionEntity.fetchRequest()
request.predicate = NSPredicate(
    format: "startTime >= %@ AND startTime <= %@",
    startOfDay as NSDate,
    endOfDay as NSDate
)
request.sortDescriptors = [
    NSSortDescriptor(keyPath: \SessionEntity.startTime, ascending: false)
]

let sessions = try viewContext.fetch(request)
```

### Fetch Enabled Rules by Priority
```swift
let request = RuleEntity.fetchRequest()
request.predicate = NSPredicate(format: "isEnabled == true")
request.sortDescriptors = [
    NSSortDescriptor(keyPath: \RuleEntity.priority, ascending: true)
]

let rules = try viewContext.fetch(request)
```

### Fetch Sessions by Category
```swift
let request = SessionEntity.fetchRequest()
request.predicate = NSPredicate(
    format: "category == %@ AND startTime >= %@",
    "work",
    Date().addingTimeInterval(-86400) as NSDate // Last 24 hours
)

let workSessions = try viewContext.fetch(request)
```

### Calculate Total Duration by Category
```swift
let request = SessionEntity.fetchRequest()
request.predicate = NSPredicate(format: "category == %@", "work")

let sessions = try viewContext.fetch(request)
let totalDuration = sessions.reduce(0.0) { $0 + $1.duration }
```

---

## Data Validation

### SessionEntity Validation
- `id` must not be nil
- `startTime` must be <= `endTime`
- `duration` must be >= 0
- `category` must be a valid `ActivityCategory` raw value

### RuleEntity Validation
- `id` must not be nil
- `conditionType` must be "app", "url", or "title"
- `pattern` must not be empty
- `priority` must be >= 0
- `category` must be a valid `ActivityCategory` raw value

### Implementing Validation

Add to entity classes:

```swift
extension SessionEntity {
    public override func validateForInsert() throws {
        try super.validateForInsert()

        guard id != nil else {
            throw NSError(domain: "SessionEntity", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "ID must not be nil"
            ])
        }

        if let start = startTime, let end = endTime, start > end {
            throw NSError(domain: "SessionEntity", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Start time must be before end time"
            ])
        }
    }
}
```

---

## Migration Strategy

### Version 1 (Current)
- Initial model with `SessionEntity` and `RuleEntity`

### Future Migrations

#### Adding New Attributes (Lightweight)
Example: Add `notes` field to `SessionEntity`
- Add optional String attribute `notes`
- Core Data handles migration automatically
- No manual migration code needed

#### Adding New Entities (Lightweight)
Example: Add `GoalEntity` for productivity goals
- Add new entity to model
- Core Data creates new table automatically

#### Renaming Attributes (Manual)
Example: Rename `windowTitle` to `title`
- Create new model version
- Use mapping model
- Implement custom migration if needed

### Testing Migrations

```bash
# Backup user data before migration
cp ~/Library/Application\ Support/com.yourcompany.productivitytracker/*.sqlite ~/Desktop/backup.sqlite

# Test migration by:
1. Install old version
2. Create test data
3. Install new version
4. Verify data integrity
```

---

## Performance Optimization

### Batch Operations
For large deletions:
```swift
let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SessionEntity")
fetchRequest.predicate = NSPredicate(format: "startTime < %@", oldDate as NSDate)

let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
try context.execute(batchDeleteRequest)
```

### Fetch Limits
For paginated views:
```swift
request.fetchLimit = 100
request.fetchOffset = currentPage * 100
```

### Faulting
Core Data uses faulting for memory efficiency. For large result sets:
```swift
request.returnsObjectsAsFaults = true // Default behavior
```

For immediate access to attributes:
```swift
request.returnsObjectsAsFaults = false
```

---

## Debugging

### Enable SQL Logging
Add launch argument in Xcode:
```
-com.apple.CoreData.SQLDebug 1
```

Levels:
- `1`: Basic SQL logging
- `2`: Verbose logging
- `3`: Very verbose

### View Database
Use SQLite browser to inspect:
```bash
open ~/Library/Application\ Support/com.yourcompany.productivitytracker/ProductivityTracker.sqlite
```

Recommended tool: **DB Browser for SQLite**

### Common Issues

**Issue**: "Could not cast value of type NSManagedObject to SessionEntity"
- **Cause**: Codegen conflict
- **Solution**: Ensure Codegen is set to `Manual/None`

**Issue**: "Entity not found in model"
- **Cause**: Model file not in target
- **Solution**: Add `.xcdatamodeld` to target's "Compile Sources"

**Issue**: "Migration failed"
- **Cause**: Model change not compatible
- **Solution**: Create new model version or delete and recreate store

---

## Schema Diagram

```
┌─────────────────────────────────────────────────┐
│                  SessionEntity                   │
├─────────────────────────────────────────────────┤
│ id: UUID                                  [PK]  │
│ appName: String?                          [IX]  │
│ bundleID: String?                         [IX]  │
│ windowTitle: String?                            │
│ url: String?                                    │
│ category: String?                         [IX]  │
│ startTime: Date?                          [IX]  │
│ endTime: Date?                            [IX]  │
│ duration: Double                                │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│                   RuleEntity                     │
├─────────────────────────────────────────────────┤
│ id: UUID                                  [PK]  │
│ name: String?                                   │
│ conditionType: String?                          │
│ pattern: String?                                │
│ category: String?                         [IX]  │
│ priority: Int16                           [IX]  │
│ isEnabled: Bool                                 │
│ createdAt: Date?                                │
└─────────────────────────────────────────────────┘

[PK] = Primary Key (implied via id)
[IX] = Indexed for query performance
```

---

## Summary

The Core Data model is designed for:
- **Efficient time-based queries** via indexed `startTime`
- **Fast rule evaluation** via indexed `priority`
- **Category analytics** via indexed `category`
- **Scalability** to handle years of tracking data
- **Migration flexibility** for future features

When creating the model in Xcode, ensure all indexes are properly configured for optimal query performance.
