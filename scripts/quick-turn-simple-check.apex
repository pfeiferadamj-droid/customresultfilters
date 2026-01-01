// Simple Quick Turn diagnostic - run in Developer Console

// Get metadata
B2B_Store_Defaults__mdt md = [SELECT Quick_Turn_Category_Name__c FROM B2B_Store_Defaults__mdt WHERE DeveloperName = 'Shop_Defaults'];
String categoryName = md.Quick_Turn_Category_Name__c;

System.debug('Category name from metadata: "' + categoryName + '"');
System.debug('Category name length: ' + categoryName.length());

// Test filter call
CustomFilterController.FilterDataWrapper result = CustomFilterController.getFilterData(categoryName, false);

if (result.quickTurnFilters != null) {
    System.debug('✅ Quick Turn filters returned: ' + result.quickTurnFilters.size() + ' filters');
    for (CustomFilterController.FilterWrapper f : result.quickTurnFilters) {
        System.debug('  - ' + f.label + ': ' + (f.values != null ? f.values.size() : 0) + ' values');
    }
} else if (result.myProductsFilters != null) {
    System.debug('❌ PROBLEM: My Products filters returned instead!');
    System.debug('This means category name "' + categoryName + '" did not match Quick Turn');
} else {
    System.debug('❌ PROBLEM: No filters returned at all');
}
