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
   - Reads URL parameters to determine category
   - Manages filter data loading from Apex
   - Handles filter change events

2. **customFilterPanel** (Child Component)
   - Displays filter header and clear all button
   - Renders the End User scope toggle for My Products
   - Manages individual filter facets

3. **customFilterFacet** (Grandchild Component)
   - Renders individual filter controls
   - Supports multiple field types: text, picklist, checkbox, lookup
   - Collapsible sections

### Apex Controller

**CustomFilterController.cls**
- Provides filter data based on category
- Handles user context for My Products filters
- Dynamically retrieves picklist values
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

The component expects a category parameter in the URL:

**Quick Turn Category:**
```
/lightning/r/Product2/list?category=Quick%20Turn
```

**My Products Category:**
```
/lightning/r/Product2/list?category=My%20Products
```

### Handling Filter Events

To capture filter changes in a parent component:

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

## Customization

### Adding New Categories

1. **Update CustomFilterController.cls**:
```apex
@AuraEnabled(cacheable=true)
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

## References

This project is based on Salesforce's open-source commerce components:
- [Commerce on Lightning Components Repository](https://github.com/forcedotcom/commerce-on-lightning-components)
- [Lightning Web Components Documentation](https://developer.salesforce.com/docs/platform/lwc/guide)

## License

This project follows the same Apache 2.0 license as the Salesforce commerce components it's based on.

## Support

For issues or questions, please create an issue in the repository.