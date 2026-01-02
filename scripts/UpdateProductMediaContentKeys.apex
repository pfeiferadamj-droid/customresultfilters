/**
 * Script to populate ContentKey__c on ProductMedia records
 * Run this in Execute Anonymous window or via Apex script
 *
 * This script finds ProductMedia records without ContentKey__c and attempts to populate them
 * by matching with ManagedContent records based on product information
 */

// Get the webstore ID from metadata
String webstoreId = StoreDefaultsHelper.getWebstoreId();
System.debug('WebStore ID: ' + webstoreId);

// Step 1: Get all ProductMedia records that don't have ContentKey__c
List<ProductMedia> mediaToUpdate = [
    SELECT Id, ProductId, ContentKey__c, Product.ProductCode, Product.Name
    FROM ProductMedia
    WHERE ContentKey__c = NULL
    LIMIT 2000
];

System.debug('Found ' + mediaToUpdate.size() + ' ProductMedia records without ContentKey__c');

if (mediaToUpdate.isEmpty()) {
    System.debug('No ProductMedia records need updating. Exiting.');
} else {
    // Collect product IDs
    Set<Id> productIds = new Set<Id>();
    Map<Id, ProductMedia> productToMediaMap = new Map<Id, ProductMedia>();

    for (ProductMedia pm : mediaToUpdate) {
        productIds.add(pm.ProductId);
        productToMediaMap.put(pm.ProductId, pm);
    }

    System.debug('Looking for ManagedContent for ' + productIds.size() + ' products');

    // Step 2: Query ManagedContent records for these products
    // ManagedContent records are typically linked by product name or product code in the title
    List<ManagedContent> managedContents = [
        SELECT Id, ContentKey, Title, ManagedContentSpace.NetworkId
        FROM ManagedContent
        WHERE ManagedContentSpace.NetworkId = :webstoreId
        AND Type = 'media'
        LIMIT 2000
    ];

    System.debug('Found ' + managedContents.size() + ' ManagedContent records in webstore');

    // Step 3: Create a map of product identifiers to ContentKey
    // This is the tricky part - we need to match ManagedContent to Products
    Map<String, String> productCodeToContentKey = new Map<String, String>();
    Map<String, String> productNameToContentKey = new Map<String, String>();

    for (ManagedContent mc : managedContents) {
        if (mc.Title != null) {
            // Store by title (which might contain product code or name)
            String titleLower = mc.Title.toLowerCase();
            productCodeToContentKey.put(titleLower, mc.ContentKey);
            productNameToContentKey.put(titleLower, mc.ContentKey);
        }
    }

    // Step 4: Update ProductMedia records with matching ContentKey
    List<ProductMedia> toUpdate = new List<ProductMedia>();
    Integer matchCount = 0;

    for (ProductMedia pm : mediaToUpdate) {
        String contentKey = null;

        // Try to match by product code first
        if (pm.Product.ProductCode != null) {
            String productCodeLower = pm.Product.ProductCode.toLowerCase();
            contentKey = productCodeToContentKey.get(productCodeLower);
        }

        // If no match, try by product name
        if (contentKey == null && pm.Product.Name != null) {
            String productNameLower = pm.Product.Name.toLowerCase();
            contentKey = productNameToContentKey.get(productNameLower);
        }

        // If we found a match, update the record
        if (contentKey != null) {
            pm.ContentKey__c = contentKey;
            toUpdate.add(pm);
            matchCount++;
            System.debug('Matched Product "' + pm.Product.Name + '" to ContentKey: ' + contentKey);
        } else {
            System.debug('WARNING: No ManagedContent found for Product "' + pm.Product.Name + '" (Code: ' + pm.Product.ProductCode + ')');
        }
    }

    System.debug('\nMatched ' + matchCount + ' out of ' + mediaToUpdate.size() + ' ProductMedia records');

    // Step 5: Perform the update
    if (!toUpdate.isEmpty()) {
        System.debug('Updating ' + toUpdate.size() + ' ProductMedia records...');

        try {
            update toUpdate;
            System.debug('SUCCESS: Updated ' + toUpdate.size() + ' ProductMedia records with ContentKey__c values');
        } catch (DmlException e) {
            System.debug('ERROR updating ProductMedia records: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    } else {
        System.debug('No ProductMedia records could be matched to ManagedContent. No updates performed.');
        System.debug('\nTroubleshooting steps:');
        System.debug('1. Verify ManagedContent records exist in this webstore');
        System.debug('2. Check that ManagedContent.Title matches Product.ProductCode or Product.Name');
        System.debug('3. Manually inspect a few ManagedContent records to understand the naming pattern');
    }
}

System.debug('\n=== Script Complete ===');
