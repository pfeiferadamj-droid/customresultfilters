# Integration Guide: Custom Filters with Results Components

This guide explains how to integrate the `customResultsFilter` component with native Salesforce results components and custom results components using visibility rules.

## Page Structure

Your Experience Cloud page will have this structure:

```
┌─────────────────────────────────────────┐
│  customResultsFilter (always visible)   │
│  - Detects category from URL            │
│  - Displays category-specific filters   │
│  - Dispatches filter events             │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  resultsFilterBridge                    │
│  - Invisible bridge component           │
│  - Translates events for native comp    │
│  Visibility: category == 'Some Category'│
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Native Salesforce Results Component    │
│  Visibility: category == 'Some Category'│
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Custom Results Component A              │
│  Visibility: category == 'Quick Turn'   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Custom Results Component B              │
│  Visibility: category == 'My Products'  │
└─────────────────────────────────────────┘
```

## Integration Approaches

### Approach 1: Using the Bridge Component (For Native Salesforce Components)

Use this approach when you need to integrate with **native Salesforce search/results components** that you cannot modify.

#### Step 1: Add Components to Page

In Experience Builder:

1. Add `customResultsFilter` component (always visible)
2. Add `resultsFilterBridge` component for each native results component
3. Add your native Salesforce results component
4. Set up visibility rules

#### Step 2: Configure the Bridge

For the `resultsFilterBridge` component:
- **Category Name**: Match this to your category (e.g., "Quick Turn")
- **Visibility Rule**: Same as your native results component

Example visibility rule:
```
{!CurrentPage.parameters.category} = "Quick Turn"
```

#### Step 3: Update Field Mapping

Edit `resultsFilterBridge.js` at line 110 to map your filter IDs to actual field API names:

```javascript
mapFilterIdToFieldName(filterId) {
    const fieldMapping = {
        'productCode': 'ProductCode',
        'shape': 'Shape__c',
        'rushReady': 'Rush_Ready__c',
        'endUser': 'End_User__c'
    };

    return fieldMapping[filterId] || filterId;
}
```

#### How It Works

1. User selects a filter in `customResultsFilter`
2. Component dispatches `filterchange` event
3. `resultsFilterBridge` captures event and updates URL parameters
4. Native results component reads updated URL and refreshes

---

### Approach 2: Direct Event Handling (For Custom Components)

Use this approach for **your custom results components** where you control the code.

#### Step 1: Add Event Listeners

In your custom results component JavaScript:

```javascript
// customQuickTurnResults.js
import { LightningElement, api, track } from 'lwc';
import getProducts from '@salesforce/apex/ProductController.getProducts';

export default class CustomQuickTurnResults extends LightningElement {
    @api categoryName = 'Quick Turn';
    @track products = [];
    @track currentFilters = {};

    connectedCallback() {
        // Listen for filter events
        this.addEventListener('filterchange', this.handleFilterChange.bind(this));
        this.addEventListener('clearallfilters', this.handleClearAllFilters.bind(this));

        // Initial load
        this.loadProducts();
    }

    handleFilterChange(event) {
        // Only process events for this category
        if (event.detail.category !== this.categoryName) {
            return;
        }

        const { filterId, value, checked } = event.detail;

        // Initialize filter array if needed
        if (!this.currentFilters[filterId]) {
            this.currentFilters[filterId] = [];
        }

        // Update filter values
        if (checked) {
            // Add value if not already present
            if (!this.currentFilters[filterId].includes(value)) {
                this.currentFilters[filterId].push(value);
            }
        } else {
            // Remove value
            this.currentFilters[filterId] = this.currentFilters[filterId].filter(v => v !== value);

            // Remove filter key if empty
            if (this.currentFilters[filterId].length === 0) {
                delete this.currentFilters[filterId];
            }
        }

        // Reload products with updated filters
        this.loadProducts();
    }

    handleClearAllFilters(event) {
        // Only process events for this category
        if (event.detail.category !== this.categoryName) {
            return;
        }

        // Clear all filters
        this.currentFilters = {};
        this.loadProducts();
    }

    loadProducts() {
        // Build filter criteria for Apex
        const filterCriteria = this.buildFilterCriteria();

        getProducts({
            category: this.categoryName,
            filters: filterCriteria
        })
            .then(result => {
                this.products = result;
            })
            .catch(error => {
                console.error('Error loading products:', error);
            });
    }

    buildFilterCriteria() {
        // Convert currentFilters object to format your Apex expects
        // Example format: { 'Shape__c': ['Round', 'Square'], 'Rush_Ready__c': ['true'] }
        const criteria = {};

        for (const [filterId, values] of Object.entries(this.currentFilters)) {
            const fieldName = this.mapFilterIdToField(filterId);
            criteria[fieldName] = values;
        }

        return criteria;
    }

    mapFilterIdToField(filterId) {
        const mapping = {
            'productCode': 'ProductCode',
            'shape': 'Shape__c',
            'rushReady': 'Rush_Ready__c',
            'endUser': 'End_User__c'
        };

        return mapping[filterId] || filterId;
    }
}
```

#### Step 2: Update Your Apex Controller

Make sure your Apex controller can handle the filter criteria:

```apex
@AuraEnabled(cacheable=true)
public static List<Product2> getProducts(String category, Map<String, List<String>> filters) {
    String query = 'SELECT Id, Name, ProductCode, Shape__c, Rush_Ready__c FROM Product2 WHERE ';

    List<String> conditions = new List<String>();

    // Add category condition if needed
    if (String.isNotBlank(category)) {
        conditions.add('Category__c = :category');
    }

    // Build filter conditions
    for (String fieldName : filters.keySet()) {
        List<String> values = filters.get(fieldName);

        if (values != null && !values.isEmpty()) {
            if (fieldName == 'Rush_Ready__c') {
                // Handle checkbox
                conditions.add(fieldName + ' = true');
            } else if (fieldName == 'ProductCode') {
                // Handle text search
                conditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(values[0]) + '%\'');
            } else {
                // Handle picklist/multi-select
                String valueList = '\'' + String.join(values, '\',\'') + '\'';
                conditions.add(fieldName + ' IN (' + valueList + ')');
            }
        }
    }

    if (!conditions.isEmpty()) {
        query += String.join(conditions, ' AND ');
    } else {
        query += '1=1'; // Always true condition if no filters
    }

    query += ' ORDER BY Name LIMIT 100';

    return Database.query(query);
}
```

---

## Setup in Experience Builder

### Step 1: Add Components to Page

1. **Add customResultsFilter**
   - Drag to your filter sidebar/section
   - No visibility rules (always visible)
   - Leave "Category Override" blank (auto-detect from URL)

2. **For Native Results Component:**
   - Add `resultsFilterBridge` (invisible, used for event handling)
   - Set **Category Name** property
   - Add visibility rule matching the category
   - Add your native results component below it
   - Same visibility rule

3. **For Custom Results Components:**
   - Add your custom component
   - Set **categoryName** property
   - Add visibility rule matching the category

### Step 2: Set Visibility Rules

Example visibility rules for Quick Turn category:

**Expression-based rule:**
```javascript
{!CurrentPage.parameters.category} = "Quick Turn"
```

Or use the URL pattern if using path-based URLs:
```javascript
{!CurrentPage.url} CONTAINS "/category/quick-turn"
```

### Step 3: Test

Navigate to your category URLs and verify:
1. Correct results component is visible
2. Filters appear based on category
3. Selecting filters updates results
4. Clear all works correctly

---

## Advanced: Sharing Filter State

If you need to persist filter state across category changes or page reloads, consider:

### Option 1: URL Parameters

Store filters in URL parameters (already implemented in `resultsFilterBridge`):

```
/category/quick-turn/ID?refinement=Shape__c:Round,Square|Rush_Ready__c:true
```

### Option 2: Session Storage

Store filter state in browser session storage:

```javascript
// In your results component
saveFilterState() {
    sessionStorage.setItem(
        `filters_${this.categoryName}`,
        JSON.stringify(this.currentFilters)
    );
}

loadFilterState() {
    const saved = sessionStorage.getItem(`filters_${this.categoryName}`);
    if (saved) {
        this.currentFilters = JSON.parse(saved);
    }
}
```

### Option 3: Lightning Message Service (LMS)

For complex multi-component communication, use LMS:

1. Create a message channel
2. Publish filter changes
3. Subscribe in results components

---

## Troubleshooting

### Filters not affecting results

**Check:**
1. Event listener is properly bound in `connectedCallback()`
2. Category name matches exactly
3. Field API names are correct in mapping
4. Apex controller is receiving filter parameters

**Debug:**
```javascript
handleFilterChange(event) {
    console.log('Filter event received:', JSON.stringify(event.detail));
    console.log('Current category:', this.categoryName);
    console.log('Event category:', event.detail.category);
    console.log('Match:', event.detail.category === this.categoryName);
}
```

### Multiple components responding to events

**Solution:** Always check category in event handlers:
```javascript
if (event.detail.category !== this.categoryName) {
    return; // Ignore events for other categories
}
```

### Bridge component not working

**Check:**
1. Bridge component is on the page
2. Category name property is set correctly
3. Bridge has same visibility rule as results component
4. Field mapping is correct

---

## Performance Considerations

1. **Debounce filter changes** - Don't query on every keystroke
2. **Use cacheable Apex** - Enable caching when appropriate
3. **Limit initial results** - Don't load all products upfront
4. **Lazy load filters** - Only load filter options when needed

---

## Example Page Configuration

Here's a complete example for a page with 3 result components:

```
Components on page:

┌─────────────────────────────────────────────────┐
│ customResultsFilter                             │
│ - No visibility rule                            │
│ - Category Override: (blank)                    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ customQuickTurnResults                          │
│ - Visibility: {!CurrentPage.url} CONTAINS       │
│   "/category/quick-turn"                        │
│ - Category Name: "Quick Turn"                   │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ customMyProductsResults                         │
│ - Visibility: {!CurrentPage.url} CONTAINS       │
│   "/category/my-products"                       │
│ - Category Name: "My Products"                  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ resultsFilterBridge                             │
│ - Visibility: {!CurrentPage.url} CONTAINS       │
│   "/category/all-products"                      │
│ - Category Name: "All Products"                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ commerce_builder:searchResults (native)         │
│ - Visibility: {!CurrentPage.url} CONTAINS       │
│   "/category/all-products"                      │
└─────────────────────────────────────────────────┘
```

This setup gives you complete control over which results component displays for each category while sharing the same filter component.
