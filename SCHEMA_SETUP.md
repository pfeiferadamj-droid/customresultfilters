# Schema Setup Guide

## Overview
The custom filter system requires specific custom fields and objects in your Salesforce org. This guide provides the exact schema requirements and setup instructions.

## Required Custom Objects

### 1. End_User__c (Custom Object)
**Purpose:** Represents end users that can be associated with products for the "My Products" filter.

**Fields:**
- **Name** (Standard Name field) - Text(80) - Required

**Setup Steps:**
1. Navigate to **Setup** > **Object Manager** > **Create** > **Custom Object**
2. Configure:
   - Label: `End User`
   - Plural Label: `End Users`
   - Object Name: `End_User__c`
   - Record Name: `End User Name`
   - Data Type: Text
3. Click **Save**

## Required Product2 Custom Fields

The filter system expects the following custom fields on the **Product2** standard object:

### 1. Shape__c (Picklist)
**Purpose:** Product shape options for Quick Turn filtering

**Configuration:**
- **API Name:** `Shape__c`
- **Label:** `Shape`
- **Type:** Picklist
- **Values:** (customize based on your products)
  - Round
  - Square
  - Rectangle
  - Oval
  - Custom (add more as needed)
- **Required:** No
- **Default:** (none)

**Setup Steps:**
1. **Setup** > **Object Manager** > **Product2** > **Fields & Relationships**
2. Click **New**
3. Select **Picklist** > **Next**
4. Enter field details:
   - Field Label: `Shape`
   - Values: Enter one per line (see values above)
5. Click **Next** > **Next** > **Save**

### 2. Rush_Ready__c (Checkbox)
**Purpose:** Indicates if product is rush-ready for Quick Turn filtering

**Configuration:**
- **API Name:** `Rush_Ready__c`
- **Label:** `Rush Ready`
- **Type:** Checkbox
- **Default:** Unchecked

**Setup Steps:**
1. **Setup** > **Object Manager** > **Product2** > **Fields & Relationships**
2. Click **New**
3. Select **Checkbox** > **Next**
4. Enter field details:
   - Field Label: `Rush Ready`
   - Default: Unchecked
5. Click **Next** > **Next** > **Save**

### 3. End_User__c (Lookup to End_User__c)
**Purpose:** Associates products with end users for My Products filtering

**Configuration:**
- **API Name:** `End_User__c`
- **Label:** `End User`
- **Type:** Lookup Relationship
- **Related To:** `End_User__c` custom object
- **Required:** No

**Setup Steps:**
1. **Setup** > **Object Manager** > **Product2** > **Fields & Relationships**
2. Click **New**
3. Select **Lookup Relationship** > **Next**
4. Related To: Select **End User** > **Next**
5. Enter field details:
   - Field Label: `End User`
   - Field Name: `End_User__c`
6. Click **Next** > **Next** > **Next** > **Save**

### 4. Contact__c (Lookup to Contact)
**Purpose:** Links products to specific contacts (for user-specific product filtering)

**Configuration:**
- **API Name:** `Contact__c`
- **Label:** `Contact`
- **Type:** Lookup Relationship
- **Related To:** `Contact` (standard object)
- **Required:** No

**Setup Steps:**
1. **Setup** > **Object Manager** > **Product2** > **Fields & Relationships**
2. Click **New**
3. Select **Lookup Relationship** > **Next**
4. Related To: Select **Contact** > **Next**
5. Enter field details:
   - Field Label: `Contact`
   - Field Name: `Contact__c`
6. Click **Next** > **Next** > **Next** > **Save**

### 5. Account__c (Lookup to Account)
**Purpose:** Links products to accounts (for account-level product filtering)

**Configuration:**
- **API Name:** `Account__c`
- **Label:** `Account`
- **Type:** Lookup Relationship
- **Related To:** `Account` (standard object)
- **Required:** No

**Setup Steps:**
1. **Setup** > **Object Manager** > **Product2** > **Fields & Relationships**
2. Click **New**
3. Select **Lookup Relationship** > **Next**
4. Related To: Select **Account** > **Next**
5. Enter field details:
   - Field Label: `Account`
   - Field Name: `Account__c`
6. Click **Next** > **Next** > **Next** > **Save**

## Field Indexing for Commerce Search

To ensure filters work with Salesforce B2B Commerce search, these fields should be indexed:

### Enable Search Indexing:
1. **Setup** > **Commerce** > **Search Indexes** > Your Webstore
2. Click **Edit Index**
3. Under **Product Fields**, add:
   - `Shape__c`
   - `Rush_Ready__c`
   - `End_User__c`
4. Click **Save**
5. Click **Rebuild Index**

## Validation Queries

After creating the fields, run these queries in **Developer Console** to validate:

### Check Product2 Fields Exist:
```apex
// Run in Anonymous Apex
Schema.DescribeFieldResult shapeField = Product2.Shape__c.getDescribe();
System.debug('Shape field exists: ' + shapeField.getName());

Schema.DescribeFieldResult rushReadyField = Product2.Rush_Ready__c.getDescribe();
System.debug('Rush Ready field exists: ' + rushReadyField.getName());

Schema.DescribeFieldResult endUserField = Product2.End_User__c.getDescribe();
System.debug('End User field exists: ' + endUserField.getName());

Schema.DescribeFieldResult contactField = Product2.Contact__c.getDescribe();
System.debug('Contact field exists: ' + contactField.getName());

Schema.DescribeFieldResult accountField = Product2.Account__c.getDescribe();
System.debug('Account field exists: ' + accountField.getName());

System.debug('✅ All Product2 fields exist!');
```

### Check End_User__c Object Exists:
```apex
// Run in Anonymous Apex
Schema.DescribeSObjectResult endUserObj = End_User__c.SObjectType.getDescribe();
System.debug('End User object exists: ' + endUserObj.getName());
System.debug('End User label: ' + endUserObj.getLabel());
System.debug('✅ End_User__c object exists!');
```

### Test End User Query:
```apex
// Run in Anonymous Apex
Id currentUserId = UserInfo.getUserId();
User u = [SELECT ContactId, AccountId FROM User WHERE Id = :currentUserId LIMIT 1];
System.debug('User ContactId: ' + u.ContactId);
System.debug('User AccountId: ' + u.AccountId);

if (u.ContactId != null) {
    // This is the query CustomFilterController uses
    List<Product2> products = [
        SELECT Id, End_User__c, End_User__r.Name
        FROM Product2
        WHERE Contact__c = :u.ContactId
        AND End_User__c != null
    ];
    System.debug('Found ' + products.size() + ' products for this contact');
    for (Product2 p : products) {
        System.debug('Product: ' + p.Id + ', End User: ' + p.End_User__r.Name);
    }
}
```

## Common Issues

### "No such column 'Contact__c' on entity 'Product2'"
**Cause:** Contact__c field doesn't exist on Product2
**Fix:** Create the Contact__c lookup field (see section 4 above)

### "No such column 'Account__c' on entity 'Product2'"
**Cause:** Account__c field doesn't exist on Product2
**Fix:** Create the Account__c lookup field (see section 5 above)

### "No such column 'End_User__c' on entity 'Product2'"
**Cause:** End_User__c field doesn't exist on Product2
**Fix:** Create the End_User__c lookup field (see section 3 above)

### "sObject type 'End_User__c' is not supported"
**Cause:** End_User__c custom object doesn't exist
**Fix:** Create the End_User__c custom object (see section 1 above)

### Filters show sample data ("End User 1", "End User 2")
**Cause:** CustomFilterController caught an exception (likely missing fields) and returned sample data
**Fix:** Check Debug Logs for the actual error, then create missing fields

## Alternative: Using Existing Fields

If your org already has similar fields with different API names, you can update the code instead of creating new fields:

### Update CustomFilterController.cls
**Lines 95, 154, 161, 165, 176-177:** Change field API names in queries

### Update resultsFilterBridge.js
**Lines 215-224:** Update field mapping:
```javascript
mapFilterIdToFieldName(filterId) {
    const fieldMapping = {
        'productCode': 'ProductCode',
        'shape': 'Your_Shape_Field__c',      // ← Update
        'rushReady': 'Your_Rush_Field__c',    // ← Update
        'endUser': 'Your_End_User_Field__c'   // ← Update
    };
    return fieldMapping[filterId] || filterId;
}
```

### Update customCategoryProductGrid.js
**Lines 1216-1223:** Update field mapping (same as above)

## Next Steps

1. ✅ Create the End_User__c custom object
2. ✅ Create all 5 Product2 custom fields
3. ✅ Run validation queries to confirm fields exist
4. ✅ Add fields to Commerce Search Index
5. ✅ Rebuild Search Index
6. ✅ Populate test data (add products with these fields filled in)
7. ✅ Deploy the filter components
8. ✅ Test filters in Experience Cloud

## Test Data Setup

After creating the schema, populate test data:

### Create End Users:
1. Navigate to **End Users** tab (or App Launcher > End Users)
2. Click **New**
3. Enter End User Name
4. Save
5. Repeat for multiple end users

### Link Products to Users:
1. Navigate to a **Product2** record
2. Edit the record
3. Set:
   - Shape: (select a value)
   - Rush Ready: (check if applicable)
   - End User: (lookup to an End User)
   - Contact: (lookup to a Contact)
   - Account: (lookup to an Account)
4. Save
5. Repeat for multiple products

### Verify:
- User's Contact should have products linked via Contact__c
- User's Account should have products linked via Account__c
- Products should have End_User__c populated
