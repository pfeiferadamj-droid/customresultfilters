# Custom Results Filter LWC

A custom Lightning Web Component (LWC) solution for Salesforce that provides category-specific filtering capabilities based on URL parameters. Built on the foundation of Salesforce's open-source commerce components (searchFilters and searchFiltersPanel).

## Overview

This project creates a flexible, category-aware filtering system that displays different filter options based on the current category resolved from the URL. It supports two main categories:

1. **Quick Turn** - Filters for rapid product selection
2. **My Products** - Personalized filters with user/account context

## Features

### Quick Turn Category Filters
- **Product Code** - Text search filter
- **Shape** - Custom picklist field filter
- **Rush Ready** - Checkbox filter for rush-ready products

### My Products Category Filters
- **End User** - Lookup field filter to custom End User object
- **Toggle Scope** - Switch between:
  - Products where the user is the contact
  - All products for the user's account

## Architecture

### Components

1. **customResultsFilter** (Parent Component)
   - Main entry point
   - Reads URL parameters to determine category (supports both slug-based and ID-based URLs)
   - Manages filter data loading from Apex
   - Handles filter change events
   - Publishes filter changes via Lightning Message Service (LMS)

2. **customFilterPanel** (Child Component)
   - Displays filter header and clear all button
   - Renders the End User scope toggle for My Products
   - Manages individual filter facets

3. **customFilterFacet** (Grandchild Component)
   - Renders individual filter controls
   - Supports multiple field types: text, picklist, checkbox, lookup
   - Collapsible sections
   - Black checkbox styling when selected

4. **resultsFilterBridge** (Integration Component)
   - Bridges custom filters with native Salesforce results components
   - Listens for filter changes via Lightning Message Service
   - Updates URL parameters with refinements
   - Translates custom filter format to Salesforce Commerce ConnectApi format

5. **customCategoryProductGrid** (Integration Target)
   - Custom product grid component that responds to filter changes
   - Subscribes to Lightning Message Service for filter updates
   - Merges custom filter refinements with URL parameters
   - Persists filter state to sessionStorage

### Apex Controller

**CustomFilterController.cls**
- Provides filter data based on category
- Handles user context for My Products filters
- Dynamically retrieves picklist values
- **NOT cacheable** - ensures user-specific End User values are fresh

### Lightning Message Service

**FilterChangeChannel__c**
- Enables sibling component communication
- Carries filter change events between components
- Fields: `filterId`, `value`, `checked`, `category`, `action`
- Queries End User relationships

## Installation

### Prerequisites
- Salesforce DX CLI
- VS Code with Salesforce Extensions (recommended)
- Authorized Salesforce org

### Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd customresultfilters
   ```

2. **Authenticate with your Salesforce org**
   ```bash
   sfdx auth:web:login -a myorg
   ```

3. **Deploy to your org**
   ```bash
   sfdx force:source:deploy -p force-app -u myorg
   ```

## Configuration

### Custom Fields Required

Before deploying, ensure the following custom fields exist in your org:

#### Product2 Object
- `Shape__c` (Picklist) - Shape options for products
- `Rush_Ready__c` (Checkbox) - Indicates if product is rush ready
- `End_User__c` (Lookup to End_User__c) - Reference to end user
- `Contact__c` (Lookup to Contact) - Contact associated with product
- `Account__c` (Lookup to Account) - Account associated with product

#### Custom Objects
- `End_User__c` - Custom object for end users
  - `Name` (Text/Auto-number) - End user name/identifier

### Update Field API Names

If your field API names differ, update the following files:

**CustomFilterController.cls** (Lines 62, 108-155):
```apex
// Update these references:
Schema.DescribeFieldResult fieldResult = Product2.Shape__c.getDescribe();

String query = 'SELECT Id, End_User__c, End_User__r.Name FROM Product2 WHERE ';
```

## Usage

### Adding to a Lightning Page

1. Navigate to the Lightning App Builder
2. Edit your target page
3. Drag the **customResultsFilter** component to the desired region
4. Save and activate the page

### URL Parameters

The component supports multiple URL formats to detect the category:

#### Experience Cloud Sites (Path-based URLs)
The component automatically detects categories from Experience Cloud URLs:

**Quick Turn Category (with slug):**
```
https://yoursite.force.com/shop/category/quick-turn/0ZGbb000000F5llGAC
```

**My Products Category (with slug):**
```
https://yoursite.force.com/shop/category/my-products/0ZGbb000000F5llGAC
```

**My Products Category (ID-only URL):**
```
https://yoursite.force.com/shop/category/detail/0ZGbb000000FFOXGA4
```

The component uses two mapping strategies:

1. **Category ID Mapping** (Priority 1):
```javascript
categoryIdMapping = {
    '0ZGbb000000FFOXGA4': 'My Products',
    '0ZGbb000000F5llGAC': 'Quick Turn'
};
```

2. **URL Slug Mapping** (Priority 2):
- `quick-turn` → "Quick Turn"
- `my-products` → "My Products"

For other slugs, the component automatically formats them (e.g., `custom-category` → "Custom Category").

#### Standard Salesforce Pages (Query Parameters)
For standard Salesforce pages, use query parameters:

**Quick Turn Category:**
```
/lightning/r/Product2/list?category=Quick%20Turn
```

**My Products Category:**
```
/lightning/r/Product2/list?category=My%20Products
```

#### Manual Override
You can also manually specify the category in the Lightning App Builder by setting the **Category Override** property. This is useful if the URL doesn't contain category information or you want to force a specific category.

### Integration with Results Components

#### Option 1: Native Salesforce Results Component

To integrate with native Salesforce results components:

1. Add the **resultsFilterBridge** component to your Experience Cloud page
2. Set the `categoryName` property to match your filter category (e.g., "Quick Turn")
3. Place it anywhere on the page (it's invisible)

The bridge component will:
- Listen for filter changes via Lightning Message Service
- Update URL parameters with refinements
- Trigger native results component to reload with filters

**Experience Builder Setup:**
```
1. Open Experience Builder
2. Navigate to your category page
3. Click "+ Add Component"
4. Search for "resultsFilterBridge"
5. Drag it anywhere on the page
6. Set Category Name: "Quick Turn" (or "My Products")
7. Publish
```

#### Option 2: Custom Product Grid Component

To integrate with a custom product grid like `customCategoryProductGrid`:

1. Add Lightning Message Service imports
2. Subscribe to `FilterChangeChannel__c`
3. Handle filter change events
4. Build refinements and merge with URL parameters

See `QUICKSTART_INTEGRATION.md` for complete step-by-step code examples.

#### Option 3: Parent Component Event Handling

To capture filter changes in a parent component using DOM events:

```javascript
// In parent component JS
handleFilterChange(event) {
    const category = event.detail.category;
    const filterId = event.detail.filterId;
    const value = event.detail.value;
    const checked = event.detail.checked;

    // Apply filters to your search/query
}

handleClearAllFilters(event) {
    const category = event.detail.category;

    // Clear all filters for the category
}
```

```html
<!-- In parent component HTML -->
<c-custom-results-filter
    onfilterchange={handleFilterChange}
    onclearallfilters={handleClearAllFilters}>
</c-custom-results-filter>
```

**Note:** Option 1 (LMS) is recommended for sibling components. Option 3 (events) is for parent-child relationships.

## Customization

### Adding New Categories

1. **Update CustomFilterController.cls**:
```apex
@AuraEnabled
public static FilterDataWrapper getFilterData(String category, Boolean includeAccountEndUsers) {
    FilterDataWrapper filterData = new FilterDataWrapper();

    if (category == 'Quick Turn') {
        filterData.quickTurnFilters = getQuickTurnFilters();
    } else if (category == 'My Products') {
        filterData.myProductsFilters = getMyProductsFilters(includeAccountEndUsers);
    } else if (category == 'New Category') {
        filterData.newCategoryFilters = getNewCategoryFilters();
    }

    return filterData;
}
```
**Note:** Do NOT use `cacheable=true` if your filters depend on user context or change frequently.

2. **Add filter method**:
```apex
private static List<FilterWrapper> getNewCategoryFilters() {
    List<FilterWrapper> filters = new List<FilterWrapper>();
    // Add your filters
    return filters;
}
```

3. **Update customResultsFilter.js**:
```javascript
get isNewCategory() {
    return this.currentCategory === 'New Category';
}

get displayFilters() {
    // Add new category condition
    if (this.isNewCategory) {
        return this.filterData.newCategoryFilters || [];
    }
}
```

### Adding New Filter Types

1. **Update customFilterFacet.js** to add a new field type getter
2. **Update customFilterFacet.html** to add the corresponding template section

## Testing

Run Apex tests:
```bash
sfdx force:apex:test:run -n CustomFilterControllerTest -r human -u myorg
```

## Troubleshooting

For common issues and solutions, see:
- **TROUBLESHOOTING.md** - Diagnostic guide for filter integration issues
- **SCHEMA_SETUP.md** - Required Salesforce schema and field setup

### Quick Diagnostics

**Filters not showing:**
- Check browser console for error messages
- Verify category name matches in customResultsFilter and results component
- Check Apex debug logs for CustomFilterController errors

**Filters not persisting:**
- Verify filter data isn't reloading on every URL change
- Check sessionStorage in browser DevTools

**Invalid refinement errors:**
- Verify field API names match in your Salesforce org
- Check attributeType mapping (Custom vs ProductAttribute for booleans)
- Ensure fields are indexed in Commerce Search Index

**End User filters showing sample data:**
- Check Apex debug logs for query errors
- Verify Product2 custom fields exist (Contact__c, Account__c, End_User__c)
- Ensure user has a ContactId (required for B2B Commerce)
- Run validation queries from SCHEMA_SETUP.md

## References

This project is based on Salesforce's open-source commerce components:
- [Commerce on Lightning Components Repository](https://github.com/forcedotcom/commerce-on-lightning-components)
- [Lightning Web Components Documentation](https://developer.salesforce.com/docs/platform/lwc/guide)

## License

This project follows the same Apache 2.0 license as the Salesforce commerce components it's based on.

## Support

For issues or questions, please create an issue in the repository.