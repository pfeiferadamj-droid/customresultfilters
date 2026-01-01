// Diagnostic script for Quick Turn filters issue
// Run this in Developer Console to debug why no filters are showing

System.debug('=== QUICK TURN FILTER DIAGNOSTIC ===');

// 1. Check metadata values
B2B_Store_Defaults__mdt defaults = [
    SELECT Quick_Turn_Category_Name__c, Quick_Turn_Category_ID__c,
           Shape_Field__c, Profile_Field__c, Panels_Field__c,
           Structure_Field__c, Visor_Field__c,
           Dri_Duck_Label__c, Dri_Duck_Value__c,
           Rush_Ready_Label__c, Rush_Ready_Value__c
    FROM B2B_Store_Defaults__mdt
    WHERE DeveloperName = 'Shop_Defaults'
    LIMIT 1
];

System.debug('1. METADATA VALUES:');
System.debug('   Quick Turn Category Name: "' + defaults.Quick_Turn_Category_Name__c + '"');
System.debug('   Quick Turn Category ID: ' + defaults.Quick_Turn_Category_ID__c);
System.debug('   Shape Field: ' + defaults.Shape_Field__c);
System.debug('   Profile Field: ' + defaults.Profile_Field__c);
System.debug('   Panels Field: ' + defaults.Panels_Field__c);
System.debug('   Structure Field: ' + defaults.Structure_Field__c);
System.debug('   Visor Field: ' + defaults.Visor_Field__c);

// 2. Check if category exists
String categoryId = defaults.Quick_Turn_Category_ID__c;
if (String.isNotBlank(categoryId)) {
    try {
        ProductCategory cat = [SELECT Id, Name FROM ProductCategory WHERE Id = :categoryId LIMIT 1];
        System.debug('2. CATEGORY EXISTS:');
        System.debug('   Category Name: ' + cat.Name);

        // Count products in category
        Integer prodCount = [SELECT COUNT() FROM ProductCategoryProduct WHERE ProductCategoryId = :categoryId];
        System.debug('   Products in category: ' + prodCount);
    } catch (Exception e) {
        System.debug('2. ERROR: Category not found - ' + e.getMessage());
    }
}

// 3. Check if products have required fields populated
System.debug('3. CHECKING FIELD POPULATION:');

String shapeField = defaults.Shape_Field__c;
Integer shapeCount = Database.countQuery('SELECT COUNT() FROM Product2 WHERE IsActive = true AND ' + shapeField + ' != null LIMIT 100');
System.debug('   Active products with ' + shapeField + ': ' + shapeCount);

String profileField = defaults.Profile_Field__c;
Integer profileCount = Database.countQuery('SELECT COUNT() FROM Product2 WHERE IsActive = true AND ' + profileField + ' != null LIMIT 100');
System.debug('   Active products with ' + profileField + ': ' + profileCount);

String panelsField = defaults.Panels_Field__c;
Integer panelsCount = Database.countQuery('SELECT COUNT() FROM Product2 WHERE IsActive = true AND ' + panelsField + ' != null LIMIT 100');
System.debug('   Active products with ' + panelsField + ': ' + panelsCount);

String structureField = defaults.Structure_Field__c;
Integer structureCount = Database.countQuery('SELECT COUNT() FROM Product2 WHERE IsActive = true AND ' + structureField + ' != null LIMIT 100');
System.debug('   Active products with ' + structureField + ': ' + structureCount);

String visorField = defaults.Visor_Field__c;
Integer visorCount = Database.countQuery('SELECT COUNT() FROM Product2 WHERE IsActive = true AND ' + visorField + ' != null LIMIT 100');
System.debug('   Active products with ' + visorField + ': ' + visorCount);

// 4. Test getQuickTurnFilters() directly
System.debug('4. TESTING getQuickTurnFilters():');
String quickTurnName = defaults.Quick_Turn_Category_Name__c;
System.debug('   Calling CustomFilterController.getFilterData("' + quickTurnName + '", false)');

try {
    CustomFilterController.FilterDataWrapper filterData =
        CustomFilterController.getFilterData(quickTurnName, false);

    System.debug('   Quick Turn filters count: ' +
        (filterData.quickTurnFilters != null ? filterData.quickTurnFilters.size() : 0));

    if (filterData.quickTurnFilters != null && !filterData.quickTurnFilters.isEmpty()) {
        for (CustomFilterController.FilterWrapper filter : filterData.quickTurnFilters) {
            Integer valueCount = filter.values != null ? filter.values.size() : 0;
            System.debug('   - ' + filter.label + ' (' + filter.id + '): ' + valueCount + ' values');
        }
    } else {
        System.debug('   WARNING: No Quick Turn filters returned!');
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
    System.debug('   Stack: ' + e.getStackTraceString());
}

// 5. Sample some products to see field values
System.debug('5. SAMPLE PRODUCT FIELD VALUES:');
String sampleQuery = 'SELECT Id, Name, ' + shapeField + ', ' + profileField + ', ' +
                     panelsField + ', ' + structureField + ', ' + visorField +
                     ' FROM Product2 WHERE IsActive = true LIMIT 5';
List<Product2> samples = Database.query(sampleQuery);
for (Product2 p : samples) {
    System.debug('   Product: ' + p.Name);
    System.debug('     Shape: ' + p.get(shapeField));
    System.debug('     Profile: ' + p.get(profileField));
    System.debug('     Panels: ' + p.get(panelsField));
    System.debug('     Structure: ' + p.get(structureField));
    System.debug('     Visor: ' + p.get(visorField));
}

System.debug('=== END DIAGNOSTIC ===');
