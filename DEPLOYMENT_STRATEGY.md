# Deployment Strategy

## The Lookup Field Problem

Salesforce B2B Commerce Search **cannot index lookup fields**. This affects End User filters.

## Quick Decision Tree

### Question 1: Do you need End User filters to work with **native Salesforce results components**?

**No, I only use customCategoryProductGrid:**
→ ✅ **Use SCHEMA_SETUP.md** - Create custom lookup fields (simple, works great)

**Yes, I need native results to filter by End User:**
→ ⚠️ **Use PRODUCT_ATTRIBUTES_SETUP.md** - Complex setup with attributes and sync

## Recommended Approach: Split Strategy

Use different integration approaches for different categories:

### Quick Turn Category
**Filters:** Product Code, Shape, Rush Ready

✅ **Works with native results** - All fields are indexable:
- `ProductCode` - Standard field
- `Shape__c` - Custom picklist (indexable)
- `Rush_Ready__c` - Checkbox field (indexable as ProductAttribute)

**Components to use:**
- ✅ `customResultsFilter` (filter UI)
- ✅ `resultsFilterBridge` (for native results)
- ✅ Native Salesforce results component (if desired)
- ✅ `customCategoryProductGrid` (if desired)

### My Products Category
**Filters:** End User

❌ **Does NOT work with native results** - Lookup field not indexable

**Components to use:**
- ✅ `customResultsFilter` (filter UI)
- ✅ `customCategoryProductGrid` (uses SOQL, works with lookups)
- ❌ `resultsFilterBridge` (skip this for My Products)
- ❌ Native Salesforce results component (won't filter by End User)

## Deployment Steps

### Phase 1: Setup Schema (All Categories)

1. Follow **SCHEMA_SETUP.md** to create:
   - End_User__c custom object
   - Product2 custom fields (Shape__c, Rush_Ready__c, End_User__c, Contact__c, Account__c)

2. Populate test data

3. Run validation queries

### Phase 2: Deploy Components

Deploy all components to your org:
```bash
sfdx force:source:deploy -p force-app/main/default -u yourorg
```

### Phase 3: Configure Quick Turn Page (Native + Custom Results)

In Experience Builder on your Quick Turn category page:

1. **Add customResultsFilter:**
   - Drag to sidebar
   - No configuration needed (auto-detects from URL)

2. **Add resultsFilterBridge:**
   - Drag anywhere (invisible)
   - Set Category Name: `Quick Turn`

3. **Add results component** (choose one):
   - **Option A:** Native Salesforce results component
   - **Option B:** customCategoryProductGrid
     - Set Category Name: `Quick Turn`
     - Set Webstore ID: (your webstore)

4. Publish

### Phase 4: Configure My Products Page (Custom Results Only)

In Experience Builder on your My Products category page:

1. **Add customResultsFilter:**
   - Drag to sidebar
   - No configuration needed (auto-detects from URL)

2. **Skip resultsFilterBridge** - Don't add it (lookup fields won't work)

3. **Add customCategoryProductGrid:**
   - Drag to main content area
   - Set Category Name: `My Products`
   - Set Webstore ID: (your webstore)

4. Publish

### Phase 5: Test

**Test Quick Turn:**
1. Navigate to Quick Turn category
2. Select Shape filter → Products should filter (both native and custom grids)
3. Check Rush Ready → Products should filter
4. Type in Product Code → Products should filter
5. Check URL - should contain `?refinements=...`

**Test My Products:**
1. Navigate to My Products category
2. End User filters should appear (from CustomFilterController query)
3. Select an End User → customCategoryProductGrid should filter
4. Toggle "Show all account end users" → Should show more/fewer end users
5. URL may not change (that's OK - customCategoryProductGrid doesn't need it)

## Troubleshooting by Component

### customCategoryProductGrid Issues

**Symptom:** Products not filtering when End User selected

**Check:**
1. Browser console for LMS messages:
   ```
   customCategoryProductGrid: Received LMS message
   customCategoryProductGrid: Updated filters
   customCategoryProductGrid: Fetching products with filters
   ```

2. Developer console for Apex errors:
   ```
   System.QueryException: No such column 'End_User__c' on entity 'Product2'
   ```
   → Run SCHEMA_SETUP.md to create fields

3. Network tab for ConnectApi call:
   - Should see `getCategoryProducts` call
   - Check if refinements are passed correctly

**Fix:**
- Ensure Category Name property matches exactly: `"My Products"` (with capital M and P)
- Verify Product2 records have `End_User__c` populated
- Check that user's Contact has products linked via `Contact__c`

### resultsFilterBridge Issues

**Symptom:** URL not updating when filters selected

**Check:**
1. Is resultsFilterBridge on the page?
   - View page in Experience Builder
   - Look for component (it's invisible but should be in component tree)

2. Browser console for LMS messages:
   ```
   resultsFilterBridge: Subscribed to LMS filter messages
   resultsFilterBridge: Received LMS message
   resultsFilterBridge: Updating URL parameters
   resultsFilterBridge: Updated URL: ...?refinements=...
   ```

3. Category Name property matches filter category

**Fix:**
- Add resultsFilterBridge to page if missing
- Set Category Name exactly: `"Quick Turn"` or `"My Products"`
- For My Products + End User filters: Don't use resultsFilterBridge (lookups not indexable)

### Native Results Component Issues

**Symptom:** Native results not responding to filters

**Causes:**
1. **Lookup fields** - Native results can't filter by End_User__c (not indexable)
2. **Field not indexed** - Check Commerce Search Index includes the fields
3. **URL encoding** - refinements parameter must be double-encoded
4. **Field name mismatch** - attributeType or nameOrId incorrect

**Fix for Quick Turn (indexable fields):**
1. Ensure resultsFilterBridge is on the page
2. Check URL contains `?refinements=...` after filtering
3. Verify fields are in Search Index:
   - Setup > Commerce > Search Indexes > Your Webstore
   - Check `Shape__c` and `Rush_Ready__c` are indexed
4. Rebuild Search Index

**Fix for My Products (End User lookup):**
- **Don't use native results component** for End User filtering
- Use customCategoryProductGrid instead (works with lookups)

## When You Must Use Native Results for End User

If you absolutely need native results component to filter by End User:

1. Follow **PRODUCT_ATTRIBUTES_SETUP.md** instead of SCHEMA_SETUP.md
2. Create Product Attributes instead of custom fields
3. Set up Flow/trigger to sync lookup to attribute
4. Update code to use attributes for refinements
5. This is significantly more complex

**Alternative:** Use customCategoryProductGrid for My Products, native results for Quick Turn.

## Field Mapping Reference

### customCategoryProductGrid Field Mapping

Location: `customCategoryProductGrid.js` lines ~1216-1223

```javascript
mapFilterIdToFieldName(filterId) {
    const fieldMapping = {
        'productCode': 'ProductCode',      // Standard field
        'shape': 'Shape__c',               // Custom picklist
        'rushReady': 'Rush_Ready__c',      // Custom checkbox
        'endUser': 'End_User__c'           // Custom lookup (SOQL only)
    };
    return fieldMapping[filterId] || filterId;
}
```

### resultsFilterBridge Field Mapping

Location: `resultsFilterBridge.js` lines ~149-154

```javascript
mapFilterIdToFieldName(filterId) {
    const fieldMapping = {
        'productCode': 'ProductCode',      // Standard field
        'shape': 'Shape__c',               // Custom picklist (indexable)
        'rushReady': 'Rush_Ready__c',      // Custom checkbox (indexable)
        'endUser': 'End_User__c'           // Custom lookup (NOT indexable!)
    };
    return fieldMapping[filterId] || filterId;
}
```

**For native results to work with End User:**
- Change `'endUser': 'End_User__c'` to `'endUser': 'End_User_Id'` (ProductAttribute)
- Change attributeType from `'Custom'` to `'ProductAttribute'`

## Summary

| Category | Filters | Works with Native Results? | Recommended Results Component |
|----------|---------|---------------------------|-------------------------------|
| Quick Turn | Product Code, Shape, Rush Ready | ✅ Yes (all indexable) | Native or customCategoryProductGrid |
| My Products | End User (lookup) | ❌ No (not indexable) | customCategoryProductGrid only |

**Bottom Line:**
- Use **SCHEMA_SETUP.md** (custom fields) if you're OK with customCategoryProductGrid for End User filtering
- Use **PRODUCT_ATTRIBUTES_SETUP.md** (attributes) if you must have native results support for End User filtering
