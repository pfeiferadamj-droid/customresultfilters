/**
 * Diagnostic script to understand ProductMedia and ManagedContent setup
 * Run this first to understand your data structure
 */

System.debug('=== DIAGNOSTIC SCRIPT FOR PRODUCT MEDIA ===\n');

// Get webstore ID
String webstoreId = StoreDefaultsHelper.getWebstoreId();
System.debug('WebStore ID: ' + webstoreId);

// 1. Check ProductMedia records
List<ProductMedia> allMedia = [
    SELECT Id, ProductId, ContentKey__c, Product.ProductCode, Product.Name, Product.Rush_Ready__c
    FROM ProductMedia
    LIMIT 100
];

System.debug('\n--- PRODUCT MEDIA ANALYSIS ---');
System.debug('Total ProductMedia records: ' + allMedia.size());

Integer withContentKey = 0;
Integer withoutContentKey = 0;
Integer rushReadyProducts = 0;

for (ProductMedia pm : allMedia) {
    if (pm.ContentKey__c != null) {
        withContentKey++;
    } else {
        withoutContentKey++;
        // Show examples of products without ContentKey
        if (withoutContentKey <= 5) {
            System.debug('  Example without ContentKey: Product "' + pm.Product.Name + '" (Code: ' + pm.Product.ProductCode + ', Rush Ready: ' + pm.Product.Rush_Ready__c + ')');
        }
    }

    if (pm.Product.Rush_Ready__c == true) {
        rushReadyProducts++;
    }
}

System.debug('ProductMedia WITH ContentKey__c: ' + withContentKey);
System.debug('ProductMedia WITHOUT ContentKey__c: ' + withoutContentKey);
System.debug('Rush Ready products in ProductMedia: ' + rushReadyProducts);

// 2. Check ManagedContent in this webstore
System.debug('\n--- MANAGED CONTENT ANALYSIS ---');

try {
    List<ManagedContent> contents = [
        SELECT Id, ContentKey, Title, Type, ManagedContentSpace.NetworkId
        FROM ManagedContent
        WHERE ManagedContentSpace.NetworkId = :webstoreId
        LIMIT 100
    ];

    System.debug('Total ManagedContent records: ' + contents.size());

    // Show sample ManagedContent titles
    System.debug('Sample ManagedContent titles:');
    Integer sampleCount = 0;
    for (ManagedContent mc : contents) {
        if (sampleCount < 10) {
            System.debug('  "' + mc.Title + '" -> ContentKey: ' + mc.ContentKey + ' (Type: ' + mc.Type + ')');
            sampleCount++;
        }
    }
} catch (Exception e) {
    System.debug('ERROR querying ManagedContent: ' + e.getMessage());
}

// 3. Check if there's an alternative field being used
System.debug('\n--- CHECKING ALTERNATIVE APPROACHES ---');

// Check if ProductMedia has MediaUrl or other fields
List<ProductMedia> sampleMedia = [
    SELECT Id, MediaUrl, ProductId
    FROM ProductMedia
    LIMIT 1
];

if (!sampleMedia.isEmpty()) {
    System.debug('ProductMedia.MediaUrl exists: ' + (sampleMedia[0].MediaUrl != null));
    if (sampleMedia[0].MediaUrl != null) {
        System.debug('  Sample MediaUrl: ' + sampleMedia[0].MediaUrl);
    }
}

// 4. Recommendations
System.debug('\n--- RECOMMENDATIONS ---');
if (withoutContentKey > 0 && withContentKey == 0) {
    System.debug('1. All ProductMedia records are missing ContentKey__c');
    System.debug('2. Check if images are uploaded to Salesforce CMS');
    System.debug('3. Verify ManagedContent records exist for products');
    System.debug('4. You may need to manually create ProductMedia records with proper ContentKey__c values');
} else if (withoutContentKey > 0) {
    System.debug('1. Some ProductMedia records have ContentKey__c, some don\'t');
    System.debug('2. Examine records WITH ContentKey__c to understand the pattern');
    System.debug('3. Run UpdateProductMediaContentKeys.apex script to populate missing values');
}

System.debug('\n=== DIAGNOSTIC COMPLETE ===');
