// Find the correct My Products category ID

System.debug('==== FINDING MY PRODUCTS CATEGORY ====');

// 1. Check what the metadata says
String metadataId = '0ZGPU0000001iob4AA';
System.debug('Metadata My_Products_Category_ID__c: ' + metadataId);

// 2. Check if this category exists
List<ProductCategory> metadataCategory = [
    SELECT Id, Name, CatalogId
    FROM ProductCategory
    WHERE Id = :metadataId
];

if (!metadataCategory.isEmpty()) {
    System.debug('✓ Metadata category EXISTS: ' + metadataCategory[0].Name);
} else {
    System.debug('✗ Metadata category DOES NOT EXIST');
}

// 3. Check the category being used in the URL
String urlId = '0ZGbb000000FFOXGA4';
System.debug('');
System.debug('URL category ID: ' + urlId);

List<ProductCategory> urlCategory = [
    SELECT Id, Name, CatalogId
    FROM ProductCategory
    WHERE Id = :urlId
];

if (!urlCategory.isEmpty()) {
    System.debug('✓ URL category EXISTS: ' + urlCategory[0].Name);
} else {
    System.debug('✗ URL category DOES NOT EXIST - THIS IS THE PROBLEM!');
}

// 4. Search for categories with "My Products" in the name
System.debug('');
System.debug('Searching for categories with "My Products" in name...');

List<ProductCategory> myProductsCategories = [
    SELECT Id, Name, CatalogId, IsNavigational
    FROM ProductCategory
    WHERE Name LIKE '%My Products%'
    OR Name LIKE '%detail%'
    ORDER BY Name
];

System.debug('Found ' + myProductsCategories.size() + ' categories:');
for (ProductCategory cat : myProductsCategories) {
    System.debug('  - ' + cat.Name + ' (ID: ' + cat.Id + ', IsNavigational: ' + cat.IsNavigational + ')');
}

// 5. List all categories to help identify the correct one
System.debug('');
System.debug('All categories in system:');

List<ProductCategory> allCategories = [
    SELECT Id, Name, CatalogId, IsNavigational
    FROM ProductCategory
    ORDER BY Name
    LIMIT 50
];

for (ProductCategory cat : allCategories) {
    System.debug('  - ' + cat.Name + ' (ID: ' + cat.Id + ')');
}

System.debug('');
System.debug('==== NEXT STEPS ====');
System.debug('1. Update B2B_Store_Defaults__mdt.My_Products_Category_ID__c with the correct ID');
System.debug('2. OR update your URL/component to use the correct category ID');
