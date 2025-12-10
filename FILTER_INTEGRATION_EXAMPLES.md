# Filter Integration Examples

This document shows how to integrate your existing `CategoryProductController` and `CategoryProductsWithParentsController` with the custom filter component.

## Understanding the Refinements Format

Your controllers expect `refinementsJSON` in this format:

```json
[
  {
    "nameOrId": "Shape__c",           // Field API name
    "attributeType": "Custom",         // Type: Standard, Custom, or ProductAttribute
    "values": ["Round", "Square"]      // Selected values
  },
  {
    "nameOrId": "Rush_Ready__c",
    "attributeType": "Custom",
    "values": ["true"]
  }
]
```

## Example: Custom Results Component Integration

Here's how to update one of your custom results components to work with the filter:

### JavaScript (customQuickTurnResults.js)

```javascript
import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCategoryProducts from '@salesforce/apex/CategoryProductController.getCategoryProducts';
// OR use the parent variation controller:
// import getCategoryProductsWithParents from '@salesforce/apex/CategoryProductsWithParentsController.getCategoryProductsWithParents';

export default class CustomQuickTurnResults extends LightningElement {
    // Public properties
    @api categoryId;
    @api categoryName = 'Quick Turn';
    @api webstoreId;
    @api effectiveAccountId;
    @api pageSize = 20;
    @api sortRuleId;

    // Tracked properties
    @track products = [];
    @track isLoading = false;
    @track error;

    // Filter state - maps filter IDs to selected values
    currentFilters = {};

    // Current page number
    currentPage = 1;

    /**
     * Connected callback - set up event listeners
     */
    connectedCallback() {
        // Listen for filter events from customResultsFilter
        this.addEventListener('filterchange', this.handleFilterChange.bind(this));
        this.addEventListener('clearallfilters', this.handleClearAllFilters.bind(this));

        // Load initial products
        this.loadProducts();
    }

    /**
     * Handle filter value change
     */
    handleFilterChange(event) {
        // Only process if this is the right category
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

        // Reset to page 1 when filters change
        this.currentPage = 1;

        // Reload products with updated filters
        this.loadProducts();
    }

    /**
     * Handle clear all filters
     */
    handleClearAllFilters(event) {
        // Only process if this is the right category
        if (event.detail.category !== this.categoryName) {
            return;
        }

        // Clear all filters
        this.currentFilters = {};
        this.currentPage = 1;
        this.loadProducts();
    }

    /**
     * Build refinements JSON for Apex controller
     * Converts our filter format to the format expected by CategoryProductController
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

        return refinements.length > 0 ? JSON.stringify(refinements) : null;
    }

    /**
     * Map filter IDs to actual Salesforce field API names
     */
    mapFilterIdToFieldName(filterId) {
        const fieldMapping = {
            'productCode': 'ProductCode',
            'shape': 'Shape__c',
            'rushReady': 'Rush_Ready__c',
            'endUser': 'End_User__c'
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

    /**
     * Load products from Apex
     */
    loadProducts() {
        this.isLoading = true;
        this.error = undefined;

        const refinementsJSON = this.buildRefinementsJSON();

        getCategoryProducts({
            categoryId: this.categoryId,
            webstoreId: this.webstoreId,
            effectiveAccountId: this.effectiveAccountId,
            pageSize: this.pageSize,
            pageNumber: this.currentPage,
            sortRuleId: this.sortRuleId,
            refinementsJSON: refinementsJSON
        })
            .then(result => {
                const parsed = JSON.parse(result);
                this.products = this.processProducts(parsed);
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.products = [];
                this.isLoading = false;
                console.error('Error loading products:', error);
            });
    }

    /**
     * Process product data from Apex response
     */
    processProducts(response) {
        if (!response || !response.searchResults) {
            return [];
        }

        const searchResults = response.searchResults;
        const products = searchResults.productsPage?.products || [];

        // Add pricebook data if needed
        const pricebookEntries = response.pricebookEntries || {};

        return products.map(product => ({
            ...product,
            prices: pricebookEntries[product.id] || []
        }));
    }

    /**
     * Handle page change
     */
    handlePageChange(event) {
        this.currentPage = event.detail.pageNumber;
        this.loadProducts();
    }
}
```

### HTML Template (customQuickTurnResults.html)

```html
<template>
    <div class="custom-results-container">
        <!-- Loading Spinner -->
        <template if:true={isLoading}>
            <lightning-spinner alternative-text="Loading products..." size="medium"></lightning-spinner>
        </template>

        <!-- Error Message -->
        <template if:true={error}>
            <div class="slds-box slds-theme_error slds-m-bottom_medium">
                <p>Error loading products: {error.body.message}</p>
            </div>
        </template>

        <!-- Product Grid -->
        <template if:false={isLoading}>
            <div class="slds-grid slds-wrap slds-gutters">
                <template for:each={products} for:item="product">
                    <div key={product.id} class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3 slds-large-size_1-of-4">
                        <c-product-card product={product}></c-product-card>
                    </div>
                </template>
            </div>

            <!-- No Results Message -->
            <template if:false={products.length}>
                <div class="slds-text-align_center slds-m-vertical_large">
                    <p class="slds-text-heading_medium">No products found</p>
                    <p class="slds-text-body_regular slds-m-top_small">
                        Try adjusting your filters
                    </p>
                </div>
            </template>
        </template>
    </div>
</template>
```

## Example: Using the Variation Parent Controller

If you want to use the `CategoryProductsWithParentsController` instead (for categories that should only show parent products):

```javascript
import getCategoryProductsWithParents from '@salesforce/apex/CategoryProductsWithParentsController.getCategoryProductsWithParents';

// ... in loadProducts method:

getCategoryProductsWithParents({
    categoryId: this.categoryId,
    webstoreId: this.webstoreId,
    effectiveAccountId: this.effectiveAccountId,
    pageSize: this.pageSize,
    pageNumber: this.currentPage,
    sortRuleId: this.sortRuleId,
    refinementsJSON: refinementsJSON,
    restrictToParents: true,           // NEW: Only show variation parents
    parentFieldName: 'Quick_Turn__c'   // NEW: Optional - field that must equal 'Yes'
})
    .then(result => {
        const parsed = JSON.parse(result);
        // Note: This controller returns a simpler format
        this.products = parsed.products || [];
        this.pricebookEntries = parsed.pricebookEntries || {};
        this.isLoading = false;
    })
```

## Filter ID to Field Mapping Reference

Make sure your `mapFilterIdToFieldName()` method matches the filter IDs used in `CustomFilterController.cls`:

| Filter ID (from CustomFilterController) | Field API Name | Attribute Type |
|----------------------------------------|----------------|----------------|
| `productCode` | `ProductCode` | `Standard` |
| `shape` | `Shape__c` | `Custom` |
| `rushReady` | `Rush_Ready__c` | `Custom` |
| `endUser` | `End_User__c` | `Custom` |

## Complete Flow

1. User selects a filter (e.g., Shape = "Round")
2. `customResultsFilter` dispatches `filterchange` event
3. Your results component catches the event
4. Component updates `currentFilters` object
5. Component calls `buildRefinementsJSON()` to convert to expected format:
   ```json
   [{"nameOrId": "Shape__c", "attributeType": "Custom", "values": ["Round"]}]
   ```
6. Component calls Apex controller with refinementsJSON
7. Apex controller executes search with filters
8. Results are returned and displayed

## Page Setup in Experience Builder

Your page should have:

```
1. customResultsFilter (always visible)
   - Auto-detects category from URL

2. customQuickTurnResults
   - Visibility: {!CurrentPage.url} CONTAINS "/category/quick-turn"
   - Properties:
     * categoryName: "Quick Turn"
     * categoryId: Your Quick Turn category ID
     * webstoreId: Your webstore ID
     * effectiveAccountId: Current user's account ID

3. customMyProductsResults
   - Visibility: {!CurrentPage.url} CONTAINS "/category/my-products"
   - Properties:
     * categoryName: "My Products"
     * categoryId: Your My Products category ID
     * webstoreId: Your webstore ID
     * effectiveAccountId: Current user's account ID
```

## Testing

1. Navigate to `/shop/category/quick-turn/YOUR_CATEGORY_ID`
2. Verify filters appear in sidebar
3. Select a filter value (e.g., Shape = "Round")
4. Check browser console for filter event
5. Verify products refresh with filtered results
6. Click "Clear All" and verify filters reset

## Debugging

Add console logging to track the filter flow:

```javascript
handleFilterChange(event) {
    console.log('Filter event received:', JSON.stringify(event.detail));
    console.log('Current filters before update:', JSON.stringify(this.currentFilters));

    // ... update logic ...

    console.log('Current filters after update:', JSON.stringify(this.currentFilters));
    console.log('Refinements JSON:', this.buildRefinementsJSON());
}
```

This will help you verify:
- Events are being received
- Filters are updating correctly
- JSON format matches what Apex expects
