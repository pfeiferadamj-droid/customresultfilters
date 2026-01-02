/**
 * Diagnostic script for ProductMedia using the correct ElectronicMediaId field
 */

System.debug('=== PRODUCT MEDIA DIAGNOSTIC (Using ElectronicMediaId) ===\n');

// 1. Check ProductMedia records
List<ProductMedia> allMedia = [
    SELECT Id, ProductId, ElectronicMediaId, Product.ProductCode, Product.Name, Product.Rush_Ready__c
    FROM ProductMedia
    LIMIT 100
];

System.debug('--- PRODUCT MEDIA ANALYSIS ---');
System.debug('Total ProductMedia records: ' + allMedia.size());

Integer withMedia = 0;
Integer withoutMedia = 0;
Integer rushReadyProducts = 0;

for (ProductMedia pm : allMedia) {
    if (pm.ElectronicMediaId != null) {
        withMedia++;
    } else {
        withoutMedia++;
        // Show examples of products without media
        if (withoutMedia <= 5) {
            System.debug('  Example without ElectronicMediaId: Product "' + pm.Product.Name + '" (Code: ' + pm.Product.ProductCode + ', Rush Ready: ' + pm.Product.Rush_Ready__c + ')');
        }
    }

    if (pm.Product.Rush_Ready__c == true) {
        rushReadyProducts++;
    }
}

System.debug('ProductMedia WITH ElectronicMediaId: ' + withMedia);
System.debug('ProductMedia WITHOUT ElectronicMediaId: ' + withoutMedia);
System.debug('Rush Ready products in ProductMedia: ' + rushReadyProducts);

// 2. Check ManagedContent records
System.debug('\n--- MANAGED CONTENT ANALYSIS ---');

try {
    List<ManagedContent> contents = [
        SELECT Id, Title, ContentKey
        FROM ManagedContent
        WHERE Type = 'media'
        LIMIT 100
    ];

    System.debug('Total ManagedContent (media type) records: ' + contents.size());

    // Show sample ManagedContent
    System.debug('Sample ManagedContent records:');
    Integer sampleCount = 0;
    for (ManagedContent mc : contents) {
        if (sampleCount < 10) {
            System.debug('  ID: ' + mc.Id + ' | Title: "' + mc.Title + '" | ContentKey: ' + mc.ContentKey);
            sampleCount++;
        }
    }
} catch (Exception e) {
    System.debug('ERROR querying ManagedContent: ' + e.getMessage());
}

// 3. Recommendations
System.debug('\n--- RECOMMENDATIONS ---');
if (withoutMedia > 0 && withMedia == 0) {
    System.debug('1. All ProductMedia records are missing ElectronicMediaId');
    System.debug('2. You need to create/upload images to Salesforce CMS first');
    System.debug('3. Then link ProductMedia records to ManagedContent via ElectronicMediaId');
    System.debug('4. Run UpdateProductMedia_Fixed.apex script to populate missing links');
} else if (withoutMedia > 0) {
    System.debug('1. Some ProductMedia records have ElectronicMediaId, some don\'t');
    System.debug('2. Examine records WITH ElectronicMediaId to understand the pattern');
    System.debug('3. Run UpdateProductMedia_Fixed.apex script to populate missing links');
} else {
    System.debug('1. All ProductMedia records have ElectronicMediaId - images should display!');
    System.debug('2. If images still don\'t show, check guest user permissions');
}

System.debug('\n=== DIAGNOSTIC COMPLETE ===');
