# Product Attributes Setup (Alternative to Lookup Fields)

## Why Product Attributes?

Salesforce B2B Commerce Search **cannot index lookup fields**. To make End User filters work with native commerce search components, use Product Attributes instead of custom fields.

## Comparison: Custom Fields vs Product Attributes

| Feature | Custom Fields | Product Attributes |
|---------|---------------|-------------------|
| Commerce Search Indexing | ❌ No (for lookups) | ✅ Yes |
| SOQL Queries | ✅ Yes | ❌ Limited |
| Data Type | Strongly typed | String/Number only |
| Use Case | Direct SOQL filtering | Commerce search refinements |

## Architecture Decision

### Hybrid Approach (Recommended)

Use **both** custom fields (for data integrity) and Product Attributes (for search):

1. **Custom Lookup Fields** - For data relationships and SOQL
   - `End_User__c` (Lookup to End_User__c)
   - `Contact__c` (Lookup to Contact)
   - `Account__c` (Lookup to Account)

2. **Product Attributes** - For Commerce Search indexing
   - `End_User_Id` (text attribute storing the End User ID)
   - `End_User_Name` (text attribute storing the End User Name)

3. **Sync Mechanism** - Keep them in sync
   - Flow/Process Builder: When Product2 is created/updated, copy lookup ID to attribute
   - Or handle in customCategoryProductGrid only (skip native results integration)

## Setup Steps

### Step 1: Create Attribute Set

1. Navigate to **Commerce** > **Product Attributes**
2. Click **New Attribute Set**
3. Configure:
   - Label: `Commerce Filter Attributes`
   - API Name: `Commerce_Filter_Attributes`
4. Click **Save**

### Step 2: Create End User ID Attribute

1. In the Attribute Set, click **New Attribute**
2. Configure:
   - Label: `End User ID`
   - API Name: `End_User_Id`
   - Data Type: **Text**
   - Length: 18
   - Description: `Stores the End User lookup ID for commerce filtering`
3. Click **Save**

### Step 3: Create End User Name Attribute

1. Click **New Attribute** again
2. Configure:
   - Label: `End User Name`
   - API Name: `End_User_Name`
   - Data Type: **Text**
   - Length: 255
   - Description: `Stores the End User name for display in filters`
3. Click **Save**

### Step 4: Assign Attribute Set to Product Catalog

1. Navigate to **Commerce** > **Product Catalogs**
2. Select your catalog
3. Click **Edit**
4. In **Attribute Sets**, add `Commerce_Filter_Attributes`
5. Click **Save**

### Step 5: Add Attributes to Commerce Search Index

1. Navigate to **Commerce** > **Search Indexes** > Your Webstore
2. Click **Edit Index**
3. Under **Product Attributes**, add:
   - `End_User_Id`
   - `End_User_Name`
4. Click **Save**
5. Click **Rebuild Index**

### Step 6: Sync Lookup to Attribute (Flow)

Create a Flow to sync the lookup field to the attribute:

**Flow Type:** Record-Triggered Flow
**Object:** Product2
**Trigger:** When a record is created or updated
**Conditions:** End_User__c is changed

**Flow Steps:**

1. **Get Records** - Get the End_User__c record
   - Object: End_User__c
   - Filter: Id = {!$Record.End_User__c}
   - Store in: `endUserRecord`

2. **Assignment** - Assign attribute values
   - Create a new ProductAttribute resource
   - Set `End_User_Id` = {!$Record.End_User__c}
   - Set `End_User_Name` = {!endUserRecord.Name}

3. **Update Records** - Update the Product2 with attributes
   - Use the Product Attribute API or custom Apex action

**Note:** Syncing Product Attributes via Flow can be complex. See alternative below.

## Alternative: Skip Native Results Integration

If Product Attributes are too complex, you can:

1. **Keep custom lookup fields** (End_User__c, Contact__c, Account__c)
2. **Only use customCategoryProductGrid** (which works with lookups via SOQL)
3. **Don't use resultsFilterBridge** or native results components

This approach works perfectly for your custom grid, just not for Salesforce's native commerce search.

## Code Updates for Product Attributes

### Update CustomFilterController.cls

**For Product Attribute approach**, change the query to use attributes instead of custom fields:

```apex
// Instead of querying Product2 fields directly,
// query ProductAttribute records

// Get products with End User attribute
List<ProductAttributeSet> attributeSets = [
    SELECT Product2Id,
           (SELECT StringValue FROM ProductAttributes
            WHERE AttributeDefinitionId = :endUserIdAttributeId)
    FROM ProductAttributeSet
    WHERE Product2.Contact__c = :contactId  // Still use lookup for filtering
];

// Extract unique End User IDs from attributes
Set<String> endUserIds = new Set<String>();
for (ProductAttributeSet pas : attributeSets) {
    for (ProductAttribute pa : pas.ProductAttributes) {
        if (pa.StringValue != null) {
            endUserIds.add(pa.StringValue);
        }
    }
}

// Get End User names
List<End_User__c> endUsers = [
    SELECT Id, Name
    FROM End_User__c
    WHERE Id IN :endUserIds
];
```

**This is complex!** Keep using custom fields for the Apex query (it works), only Product Attributes matter for Commerce Search refinements.

### Update resultsFilterBridge.js

```javascript
mapFilterIdToFieldName(filterId) {
    const fieldMapping = {
        'productCode': 'ProductCode',
        'shape': 'Shape__c',
        'rushReady': 'Rush_Ready__c',
        'endUser': 'End_User_Id'  // ← Changed to attribute name
    };
    return fieldMapping[filterId] || filterId;
}

getAttributeType(filterId) {
    const typeMapping = {
        'productCode': 'Standard',
        'shape': 'Custom',
        'rushReady': 'ProductAttribute',
        'endUser': 'ProductAttribute'  // ← Changed to ProductAttribute
    };
    return typeMapping[filterId] || 'Custom';
}
```

## Recommendation

### For Your Use Case:

Since you're primarily using **customCategoryProductGrid** (which does SOQL queries):

1. ✅ **Keep custom lookup fields** (End_User__c, Contact__c, Account__c)
2. ✅ **Keep using customCategoryProductGrid** (it works perfectly with lookups)
3. ❌ **Skip resultsFilterBridge** for End User filters
4. ❌ **Don't try to integrate End User filters with native results component**

### This Means:

- **Quick Turn filters** (Shape, Rush Ready, Product Code) → Can work with native results
- **My Products filters** (End User) → Only work with customCategoryProductGrid

If you absolutely need End User filters to work with native results, you'll need to:
1. Set up Product Attributes (complex)
2. Create a sync mechanism (Flow or trigger)
3. Update the code to use attributes for refinements but lookups for SOQL

## Validation Query

After setting up Product Attributes, test with:

```apex
// Check if Product Attribute exists
List<ProductAttributeDefinition> attrs = [
    SELECT Id, DeveloperName, MasterLabel
    FROM ProductAttributeDefinition
    WHERE DeveloperName = 'End_User_Id'
];
System.debug('Product Attribute exists: ' + !attrs.isEmpty());

// Check if products have the attribute set
List<ProductAttributeSet> sets = [
    SELECT Id, Product2Id,
           (SELECT AttributeDefinitionId, StringValue
            FROM ProductAttributes
            WHERE AttributeDefinition.DeveloperName = 'End_User_Id')
    FROM ProductAttributeSet
    LIMIT 5
];
System.debug('Products with End_User_Id attribute: ' + sets.size());
```
