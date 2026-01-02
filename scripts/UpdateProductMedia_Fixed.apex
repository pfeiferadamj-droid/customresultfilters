/**
 * Script to populate ElectronicMediaId on ProductMedia records
 * Links ProductMedia to ManagedContent based on product information
 */

System.debug('=== UPDATE PRODUCT MEDIA (Using ElectronicMediaId) ===\n');

// Step 1: Get ProductMedia records without ElectronicMediaId
List<ProductMedia> mediaToUpdate = [
    SELECT Id, ProductId, ElectronicMediaId, Product.ProductCode, Product.Name
    FROM ProductMedia
    WHERE ElectronicMediaId = NULL
    LIMIT 2000
];

System.debug('Found ' + mediaToUpdate.size() + ' ProductMedia records without ElectronicMediaId');

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

    // Step 2: Query ManagedContent records
    List<ManagedContent> managedContents = [
        SELECT Id, ContentKey, Title
        FROM ManagedContent
        WHERE Type = 'media'
        LIMIT 2000
    ];

    System.debug('Found ' + managedContents.size() + ' ManagedContent records');

    // Step 3: Create mapping from product identifiers to ManagedContent ID
    Map<String, Id> productCodeToContentId = new Map<String, Id>();
    Map<String, Id> productNameToContentId = new Map<String, Id>();

    for (ManagedContent mc : managedContents) {
        if (mc.Title != null) {
            String titleLower = mc.Title.toLowerCase();
            productCodeToContentId.put(titleLower, mc.Id);
            productNameToContentId.put(titleLower, mc.Id);

            // Also try matching by ContentKey if it looks like a product code
            if (mc.ContentKey != null) {
                String keyLower = mc.ContentKey.toLowerCase();
                productCodeToContentId.put(keyLower, mc.Id);
            }
        }
    }

    // Step 4: Update ProductMedia records with matching ManagedContent ID
    List<ProductMedia> toUpdate = new List<ProductMedia>();
    Integer matchCount = 0;

    for (ProductMedia pm : mediaToUpdate) {
        Id contentId = null;

        // Try to match by product code first
        if (pm.Product.ProductCode != null) {
            String productCodeLower = pm.Product.ProductCode.toLowerCase();
            contentId = productCodeToContentId.get(productCodeLower);
        }

        // If no match, try by product name
        if (contentId == null && pm.Product.Name != null) {
            String productNameLower = pm.Product.Name.toLowerCase();
            contentId = productNameToContentId.get(productNameLower);
        }

        // If we found a match, update the record
        if (contentId != null) {
            pm.ElectronicMediaId = contentId;
            toUpdate.add(pm);
            matchCount++;
            System.debug('Matched Product "' + pm.Product.Name + '" to ManagedContent ID: ' + contentId);
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
            System.debug('SUCCESS: Updated ' + toUpdate.size() + ' ProductMedia records with ElectronicMediaId');
        } catch (DmlException e) {
            System.debug('ERROR updating ProductMedia records: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    } else {
        System.debug('No ProductMedia records could be matched to ManagedContent. No updates performed.');
        System.debug('\nTroubleshooting steps:');
        System.debug('1. Verify ManagedContent records exist with Type = \'media\'');
        System.debug('2. Check that ManagedContent.Title or ContentKey matches Product.ProductCode or Product.Name');
        System.debug('3. Upload product images to Salesforce CMS if they don\'t exist');
        System.debug('4. Manually inspect ManagedContent records to understand the naming pattern');
    }
}

System.debug('\n=== SCRIPT COMPLETE ===');
