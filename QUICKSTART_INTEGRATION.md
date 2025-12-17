# Quick Start: Connect Filters to customCategoryProductGrid

This guide shows exactly what to add to your `customCategoryProductGrid` component to connect the filters.

## Step 1: Add Event Listeners (JavaScript)

Add this to your `customCategoryProductGrid.js` file:

### In connectedCallback():

```javascript
connectedCallback() {
    // Listen for filter events
    this.addEventListener('filterchange', this.handleFilterChange.bind(this));
    this.addEventListener('clearallfilters', this.handleClearAllFilters.bind(this));

    // ... rest of your existing connectedCallback code
}
```

### Add Filter State Property:

```javascript
// Add this property to track current filters
currentFilters = {};
```

### Add Event Handler Methods:

```javascript
/**
 * Handle filter value change from customResultsFilter
 */
handleFilterChange(event) {
    // Only process if this is the right category
    if (event.detail.category !== this.categoryName) {
        return;
    }

    console.log('customCategoryProductGrid: Received filterchange event', event.detail);

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

    console.log('customCategoryProductGrid: Current filters:', this.currentFilters);

    // Reset to page 1 when filters change
    this.currentPage = 1;

    // Reload products with updated filters
    this.loadProducts();
}

/**
 * Handle clear all filters
 */
handleClearAllFilters(event) {
    console.log('customCategoryProductGrid: Clearing all filters');

    // Clear all filters
    this.currentFilters = {};
    this.currentPage = 1;
    this.loadProducts();
}

/**
 * Build refinements JSON for CategoryProductController
 */
buildRefinementsJSON() {
    const refinements = [];

    for (const [filterId, values] of Object.entries(this.currentFilters)) {
        if (values && values.length > 0) {
            const refinement = {
                nameOrId: this.mapFilterIdToFieldName(filterId),
                attributeType: this.getAttributeType(filterId),
                values: values
            };
            refinements.push(refinement);
        }
    }

    const json = refinements.length > 0 ? JSON.stringify(refinements) : null;
    console.log('customCategoryProductGrid: Built refinementsJSON:', json);
    return json;
}

/**
 * Map filter IDs to actual Salesforce field API names
 * UPDATE THESE WITH YOUR ACTUAL FIELD NAMES!
 */
mapFilterIdToFieldName(filterId) {
    const fieldMapping = {
        'productCode': 'ProductCode',      // Standard field
        'shape': 'Shape__c',               // TODO: Replace with your actual Shape field API name
        'rushReady': 'Rush_Ready__c',      // TODO: Replace with your actual Rush Ready field API name
        'endUser': 'End_User__c'           // TODO: Replace with your actual End User field API name
    };

    return fieldMapping[filterId] || filterId;
}

/**
 * Get attribute type for a field
 */
getAttributeType(filterId) {
    const typeMapping = {
        'productCode': 'Standard',      // Standard Salesforce field
        'shape': 'Custom',              // Custom field
        'rushReady': 'Custom',          // Custom field
        'endUser': 'Custom'             // Custom field
    };

    return typeMapping[filterId] || 'Custom';
}
```

## Step 2: Update Your loadProducts() Method

Modify your existing `loadProducts()` method to include the refinementsJSON:

```javascript
loadProducts() {
    this.isLoading = true;
    this.error = undefined;

    // Build refinements JSON from current filters
    const refinementsJSON = this.buildRefinementsJSON();

    getCategoryProducts({
        categoryId: this.categoryId,
        webstoreId: this.webstoreId,
        effectiveAccountId: this.effectiveAccountId,
        pageSize: this.pageSize,
        pageNumber: this.currentPage,
        sortRuleId: this.sortRuleId,
        refinementsJSON: refinementsJSON  // Add this parameter
    })
        .then(result => {
            // ... your existing result handling code
        })
        .catch(error => {
            // ... your existing error handling code
        });
}
```

## Step 3: Update Field Mappings

In the `mapFilterIdToFieldName()` method above, replace the placeholder field names with your actual Salesforce field API names:

1. **Shape field**: Replace `Shape__c` with your actual field name
2. **Rush Ready field**: Replace `Rush_Ready__c` with your actual field name
3. **End User field**: Replace `End_User__c` with your actual field name

You can find these by going to Setup > Object Manager > Product2 > Fields & Relationships

## Step 4: Verify Event Flow

After deploying these changes, open your browser console and filter by "custom" to see these logs:

1. When you click a checkbox:
   ```
   customResultsFilter: Received filterchange, re-dispatching with category: {...}
   customCategoryProductGrid: Received filterchange event {...}
   customCategoryProductGrid: Current filters: {shape: ['Dad Hat']}
   customCategoryProductGrid: Built refinementsJSON: [{"nameOrId":"Shape__c","attributeType":"Custom","values":["Dad Hat"]}]
   ```

2. Products should reload with the applied filters

## Troubleshooting

### Events not reaching customCategoryProductGrid?

**Check your page structure** - the `customResultsFilter` must be a parent/ancestor of `customCategoryProductGrid` for events to bubble up.

Your page structure should look like:
```html
<div>
    <c-custom-results-filter ...>
        <!-- Filters are inside here -->
    </c-custom-results-filter>

    <c-custom-category-product-grid ...>
        <!-- Products are here -->
    </c-custom-category-product-grid>
</div>
```

If your components are siblings (side-by-side), events won't bubble from one to the other. You'll need to either:
1. **Recommended**: Wrap both in a parent component that listens for events and passes data down
2. Use Lightning Message Service (LMS) for cross-component communication

### Products not filtering?

1. Check console logs to verify refinementsJSON is being built correctly
2. Verify field API names match your actual Salesforce fields
3. Check that CategoryProductController is receiving the refinementsJSON parameter
4. Verify the products actually have values in those fields

### Native Salesforce results component also on the page?

If you're using the native `commerce_builder-search-results` component alongside your custom component, you'll need to modify the event listener to only process events for your specific category:

```javascript
if (event.detail.category !== this.categoryName) {
    return; // Ignore events for other categories
}
```

This prevents both components from responding to the same filter events.
