# Shop_Defaults Metadata Field Reference

This document explains each field in the `B2B_Store_Defaults__mdt.Shop_Defaults` metadata record.

## Current Values (as of deployment)

All 27 fields are currently populated in `B2B_Store_Defaults.Shop_Defaults.md-meta.xml`:

### Category IDs
| Field Name | Current Value | Purpose |
|------------|---------------|---------|
| `My_Products_Category_ID__c` | `0ZGPU0000001iob4AA` | Production category ID for "My Products" |
| `Quick_Turn_Category_ID__c` | `0ZGPU0000001iqD4AQ` | Production category ID for "Quick Turn" (Essentials) |

> **Important**: These IDs are environment-specific! Update these when deploying to a new org.

---

### Category Names
| Field Name | Current Value | Purpose |
|------------|---------------|---------|
| `Quick_Turn_Category_Name__c` | `Quick Turn` | Display name for Quick Turn category |
| `My_Products_Category_Name__c` | `My Products` | Display name for My Products category |

> Used for category comparisons in filters and product grids.

---

### Field API Names
| Field Name | Current Value | Purpose |
|------------|---------------|---------|
| `Shape_Field__c` | `Shape__c` | Product field for cap shape |
| `Profile_Field__c` | `Profile__c` | Product field for profile type |
| `Panels_Field__c` | `Panels__c` | Product field for panel count |
| `Structure_Field__c` | `Structure__c` | Product field for structure type |
| `Visor_Field__c` | `Visor__c` | Product field for visor style |
| `End_User_Field__c` | `End_User__c` | Product lookup to End User |
| `Rush_Ready_Field__c` | `Rush_Ready__c` | Product checkbox for rush ready |
| `Is_Parent_Field__c` | `Is_Parent__c` | Product field indicating parent product |
| `Special_Program_Field__c` | `Special_Program_SAP__c` | Product field for special programs |
| `Contact_Field__c` | `Contact__c` | Product lookup to Contact |
| `Account_Field__c` | `Account__c` | Product lookup to Account |

> These allow the code to work even if your org uses different field names.

---

### Special Program Values
| Field Name | Current Value | Purpose |
|------------|---------------|---------|
| `Dri_Duck_Value__c` | `QuickTurnDDT` | Value stored in Special_Program_SAP__c for Dri-Duck |
| `Rush_Ready_Value__c` | `RushReady` | Checkbox value identifier for Rush Ready |
| `Dri_Duck_Label__c` | `Dri-Duck` | Display label for Dri-Duck filter |
| `Rush_Ready_Label__c` | `Rush Ready` | Display label for Rush Ready filter |

> Used in special programs filter for Quick Turn category.

---

### Product Values
| Field Name | Current Value | Purpose |
|------------|---------------|---------|
| `Parent_Product_Value__c` | `Yes` | Value in Is_Parent__c indicating parent product |
| `Simple_Product_Class__c` | `Simple` | ProductClass value for simple products |

> Used when filtering to parent/simple products only.

---

### Pagination Settings
| Field Name | Current Value | Purpose |
|------------|---------------|---------|
| `Default_Page_Size__c` | `12` | Default products per page (My Products) |
| `Quick_Turn_Page_Size__c` | `24` | Products per page for Quick Turn |
| `Filter_Values_Limit__c` | `2000` | Max records to query for filter values |

> Controls how many products appear per page in each category.

---

### URL Slugs
| Field Name | Current Value | Purpose |
|------------|---------------|---------|
| `Quick_Turn_URL_Slug__c` | `quick-turn` | URL slug for Quick Turn: /category/quick-turn/... |
| `My_Products_URL_Slug__c` | `my-products` | URL slug for My Products: /category/my-products/... |
| `Detail_URL_Slug__c` | `detail` | URL slug for detail pages: /category/detail/... |

> Used to map URLs to category names in customResultsFilter.js.

---

## How to Update Values

### Method 1: Via Salesforce UI (Recommended)

1. Go to **Setup** → **Custom Metadata Types**
2. Click **Manage Records** next to "B2B Store Defaults"
3. Click **Shop Defaults** record
4. Click **Edit**
5. Update the field values
6. Click **Save**

### Method 2: Via Metadata File

1. Edit `force-app/main/default/customMetadata/B2B_Store_Defaults.Shop_Defaults.md-meta.xml`
2. Update the `<value>` for any field you want to change
3. Deploy the metadata file to your org

### Method 3: Create New Record for Different Environment

If you want different values per environment (sandbox vs production):

1. Copy `B2B_Store_Defaults.Shop_Defaults.md-meta.xml`
2. Rename to `B2B_Store_Defaults.Sandbox_Defaults.md-meta.xml`
3. Update the `<label>` and values
4. Update `StoreDefaultsHelper.cls` line 16 to use environment-specific record:
   ```apex
   // Use different record based on environment
   String recordName = UserInfo.getOrganizationId() == 'PROD_ORG_ID'
       ? 'Shop_Defaults'
       : 'Sandbox_Defaults';
   defaults = B2B_Store_Defaults__mdt.getInstance(recordName);
   ```

---

## Verification Script

Run this Anonymous Apex script to verify all fields are populated:

```
/scripts/verify-shop-defaults.apex
```

This will show you:
- ✅ Which fields are populated
- ❌ Which fields are empty (using fallback values)
- Summary of populated vs empty fields

---

## Fallback Values

If a field is empty/null in the metadata record, the code uses these fallback values:

| Field | Fallback Value |
|-------|----------------|
| Quick_Turn_Category_Name__c | "Quick Turn" |
| My_Products_Category_Name__c | "My Products" |
| All field names (*_Field__c) | Standard Salesforce API names |
| Dri_Duck_Value__c | "QuickTurnDDT" |
| Rush_Ready_Value__c | "RushReady" |
| Dri_Duck_Label__c | "Dri-Duck" |
| Rush_Ready_Label__c | "Rush Ready" |
| Parent_Product_Value__c | "Yes" |
| Simple_Product_Class__c | "Simple" |
| Default_Page_Size__c | 12 |
| Quick_Turn_Page_Size__c | 24 |
| Filter_Values_Limit__c | 2000 |
| Quick_Turn_URL_Slug__c | "quick-turn" |
| My_Products_URL_Slug__c | "my-products" |
| Detail_URL_Slug__c | "detail" |

**Important**: While fallback values prevent errors, you should populate all fields in the metadata record to avoid relying on hardcoded defaults. This defeats the purpose of the metadata migration!

---

## Common Issues

### Issue: "Shop_Defaults record not found"

**Cause**: The metadata record wasn't deployed to the org.

**Solution**:
```bash
sf project deploy start --source-dir force-app/main/default/customMetadata
```

### Issue: "Fields show as empty in UI but work in code"

**Cause**: Salesforce UI sometimes doesn't display custom metadata values immediately.

**Solution**:
1. Run the verification script (verify-shop-defaults.apex)
2. Check debug logs to see actual values being used
3. Refresh metadata cache: Setup → Custom Metadata Types → Clear Cache

### Issue: "Category IDs are wrong after sandbox refresh"

**Cause**: Category IDs change when data is refreshed from production.

**Solution**:
1. Query the correct category IDs in your sandbox:
   ```sql
   SELECT Id, Name FROM ProductCategory WHERE Name IN ('My Products', 'Quick Turn')
   ```
2. Update the Shop_Defaults record with new IDs
3. Redeploy

---

## Benefits of Using Metadata

✅ **No Code Changes**: Update values without modifying Apex/LWC code
✅ **Environment-Specific**: Different values per sandbox/production
✅ **Version Controlled**: Metadata files tracked in Git
✅ **Deploy Together**: Metadata + code deploy as a single package
✅ **Type Safe**: Salesforce validates field types and values
✅ **Cacheable**: Metadata access is cached for performance

---

## Questions?

- Review `StoreDefaultsHelper.cls` to see how values are accessed
- Run `verify-shop-defaults.apex` to check current configuration
- Check debug logs for "Shop_Defaults" to see which values are being used
