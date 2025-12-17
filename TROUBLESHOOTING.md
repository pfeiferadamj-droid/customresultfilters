# Troubleshooting Filter Issues

## Issue 1: "Invalid refinement" Error for Rush_Ready__c

### Problem
Error: `Invalid refinement {attributeType: Custom, nameOrId: Rush_Ready__c}`

### Root Cause
One of these:
1. Field name is incorrect (not actually `Rush_Ready__c`)
2. Field is not indexed/searchable in Commerce
3. Boolean fields might need to be ProductAttribute, not Custom

### Solution
Find the actual field API name:
1. Go to **Setup** > **Object Manager** > **Product2**
2. Click **Fields & Relationships**
3. Find the Rush Ready field
4. Check the **Field Name** column (e.g., might be `Is_Rush_Ready__c` instead)
5. Check the field type - if it's a checkbox, it's boolean

Then update the field mapping in TWO places:
- `customCategoryProductGrid.js` line ~1189
- `resultsFilterBridge.js` line ~152

Also try changing attributeType from `Custom` to `ProductAttribute` for boolean fields.

---

## Issue 2: URL Not Changing When Filters Adjust

### Problem
The native Salesforce results component doesn't update because the URL doesn't change.

### Root Cause
The `resultsFilterBridge` component is either:
1. Not added to the page
2. Not receiving LMS messages
3. Not updating the URL correctly

### Solution

#### Step 1: Verify Bridge is on the Page
1. Open **Experience Builder**
2. Navigate to your Quick Turn category page
3. Look for `resultsFilterBridge` component
4. If missing, add it:
   - Click **+ Add Component**
   - Search for `resultsFilterBridge`
   - Drag it anywhere on the page (it's invisible)
   - Set **Category Name** to `Quick Turn`
   - Click **Publish**

#### Step 2: Check Console Logs
After clicking a filter, you should see:
```
✅ resultsFilterBridge: Received LMS message: {...}
✅ resultsFilterBridge: Updating URL parameters
✅ resultsFilterBridge: Built refinements JSON: [...]
✅ resultsFilterBridge: Updated URL: https://...?refinements=...
```

If you see "Received LMS message" but no URL update, there's a bug.

If you don't see "Received LMS message", the bridge isn't subscribed to LMS.

---

## Issue 3: No Filters for My Products Category

### Problem
Navigating to My Products category shows no filter options.

### Root Cause
Category name mismatch between URL slug and what the component expects.

The URL uses: `/shop/category/my-products/...` (slug: `my-products`)
The controller expects: `My Products` (with space and capitals)

### Solution

#### Check Category Mapping
In `customResultsFilter.js` line ~30, verify the mapping:
```javascript
categoryMapping = {
    'quick-turn': 'Quick Turn',
    'my-products': 'My Products'  // ← Add this if missing
};
```

#### Verify Category Name in Console
When on My Products page, check console:
```
customResultsFilter: Category changed from null to "My Products"
```

If you see a different name or null, update the categoryMapping.

---

## Quick Diagnostic Checklist

When a filter is clicked:

### ✅ Expected Console Output:
```
1. handleCheckboxChange called
2. Dispatching filtertoggle event: {filterId: 'rushReady', value: 'true', checked: true}
3. customFilterPanel: handleFilterToggle {...}
4. Updated selectedValues for rushReady: ['true']
5. customResultsFilter: Received filterchange, re-dispatching with category: {category: 'Quick Turn', ...}
6. customResultsFilter: Published LMS message: {...}
7. customCategoryProductGrid: Received LMS message: {...}  ← Custom grid
8. resultsFilterBridge: Received LMS message: {...}        ← Bridge for native
9. resultsFilterBridge: Updating URL parameters
10. resultsFilterBridge: Updated URL: https://...?refinements=...
11. [Native results component reloads with filters]
```

### ❌ Missing Logs Mean:
- **No #7**: customCategoryProductGrid not on page or wrong category name
- **No #8**: resultsFilterBridge not on page or wrong category name
- **No #9-10**: Bug in resultsFilterBridge URL update logic
- **No #11**: Native component not reading URL parameters

---

## Field Name Reference

Update these field names to match YOUR Salesforce schema:

| Filter ID    | Default Field Name | Your Field Name | Attribute Type |
|--------------|-------------------|-----------------|----------------|
| productCode  | ProductCode       | (check)         | Standard       |
| shape        | Shape__c          | (check)         | Custom         |
| rushReady    | Rush_Ready__c     | **← FIX THIS**  | Custom         |
| endUser      | End_User__c       | (check)         | Custom         |

To find your field names:
Setup > Object Manager > Product2 > Fields & Relationships
