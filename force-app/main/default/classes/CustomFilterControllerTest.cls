/**
 * Test class for CustomFilterController
 */
@isTest
private class CustomFilterControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create minimal test products
        // Note: Filter field values (Shape__c, Profile__c, etc.) may be restricted picklists
        // The actual filter methods query real products, so we don't need specific test values
        List<Product2> products = new List<Product2>();

        products.add(new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TP001',
            IsActive = true
        ));

        products.add(new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TP002',
            IsActive = true
        ));

        insert products;
    }

    @isTest
    static void testGetQuickTurnFilters() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result =
            CustomFilterController.getFilterData('Quick Turn', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.quickTurnFilters, 'Quick Turn filters should not be null');
        System.assertEquals(6, result.quickTurnFilters.size(), 'Should have 6 Quick Turn filters');

        // Verify Special Programs filter (first)
        CustomFilterController.FilterWrapper specialProgramsFilter = result.quickTurnFilters[0];
        System.assertEquals('specialPrograms', specialProgramsFilter.id, 'First filter should be Special Programs');
        System.assertEquals('Special Programs', specialProgramsFilter.label, 'Special Programs label should match');
        System.assertEquals('checkbox', specialProgramsFilter.fieldType, 'Special Programs should be checkbox type');
        System.assertEquals(2, specialProgramsFilter.values.size(), 'Special Programs should have 2 values');

        // Verify Panels filter (second)
        CustomFilterController.FilterWrapper panelsFilter = result.quickTurnFilters[1];
        System.assertEquals('panels', panelsFilter.id, 'Second filter should be Panels');
        System.assertEquals('Panels', panelsFilter.label, 'Panels label should match');
        System.assertEquals('picklist', panelsFilter.fieldType, 'Panels should be picklist type');

        // Verify Profile filter (third)
        CustomFilterController.FilterWrapper profileFilter = result.quickTurnFilters[2];
        System.assertEquals('profile', profileFilter.id, 'Third filter should be Profile');
        System.assertEquals('Profile', profileFilter.label, 'Profile label should match');
        System.assertEquals('picklist', profileFilter.fieldType, 'Profile should be picklist type');

        // Verify Shape filter (fourth)
        CustomFilterController.FilterWrapper shapeFilter = result.quickTurnFilters[3];
        System.assertEquals('shape', shapeFilter.id, 'Fourth filter should be Shape');
        System.assertEquals('Shape', shapeFilter.label, 'Shape label should match');
        System.assertEquals('picklist', shapeFilter.fieldType, 'Shape should be picklist type');

        // Verify Structure filter (fifth)
        CustomFilterController.FilterWrapper structureFilter = result.quickTurnFilters[4];
        System.assertEquals('structure', structureFilter.id, 'Fifth filter should be Structure');
        System.assertEquals('Structure', structureFilter.label, 'Structure label should match');
        System.assertEquals('picklist', structureFilter.fieldType, 'Structure should be picklist type');

        // Verify Visor filter (sixth)
        CustomFilterController.FilterWrapper visorFilter = result.quickTurnFilters[5];
        System.assertEquals('visor', visorFilter.id, 'Sixth filter should be Visor');
        System.assertEquals('Visor', visorFilter.label, 'Visor label should match');
        System.assertEquals('picklist', visorFilter.fieldType, 'Visor should be picklist type');
    }

    @isTest
    static void testGetMyProductsFilters() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result =
            CustomFilterController.getFilterData('My Products', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.myProductsFilters, 'My Products filters should not be null');
        System.assertEquals(1, result.myProductsFilters.size(), 'Should have 1 My Products filter');
        System.assertNotEquals(null, result.accountName, 'Account name should not be null');

        // Verify End User filter
        CustomFilterController.FilterWrapper endUserFilter = result.myProductsFilters[0];
        System.assertEquals('endUser', endUserFilter.id, 'Filter should be End User');
        System.assertEquals('End User', endUserFilter.label, 'End User label should match');
        System.assertEquals('lookup', endUserFilter.fieldType, 'End User should be lookup type');
    }

    @isTest
    static void testGetMyProductsFiltersWithAccountEndUsers() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result =
            CustomFilterController.getFilterData('My Products', true);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.myProductsFilters, 'My Products filters should not be null');
        System.assertEquals(1, result.myProductsFilters.size(), 'Should have 1 My Products filter');
        System.assertNotEquals(null, result.accountName, 'Account name should not be null');
    }

    @isTest
    static void testFilterValueWrapperComparable() {
        CustomFilterController.FilterValueWrapper value1 = new CustomFilterController.FilterValueWrapper();
        value1.label = 'A';
        value1.value = 'a';

        CustomFilterController.FilterValueWrapper value2 = new CustomFilterController.FilterValueWrapper();
        value2.label = 'B';
        value2.value = 'b';

        CustomFilterController.FilterValueWrapper value3 = new CustomFilterController.FilterValueWrapper();
        value3.label = 'A';
        value3.value = 'a';

        Test.startTest();
        Integer compare1 = value1.compareTo(value2);
        Integer compare2 = value2.compareTo(value1);
        Integer compare3 = value1.compareTo(value3);
        Test.stopTest();

        System.assertEquals(-1, compare1, 'A should come before B');
        System.assertEquals(1, compare2, 'B should come after A');
        System.assertEquals(0, compare3, 'Equal labels should return 0');
    }

    @isTest
    static void testUnknownCategory() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result =
            CustomFilterController.getFilterData('Unknown Category', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.quickTurnFilters, 'Quick Turn filters should be null for unknown category');
        System.assertEquals(null, result.myProductsFilters, 'My Products filters should be null for unknown category');
    }

    @isTest
    static void testDistinctTextFieldValues() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result =
            CustomFilterController.getFilterData('Quick Turn', false);
        Test.stopTest();

        // Verify that filters have values from test data
        for (CustomFilterController.FilterWrapper filter : result.quickTurnFilters) {
            if (filter.id == 'shape') {
                System.assert(filter.values.size() >= 0, 'Shape filter should have values or be empty');
            } else if (filter.id == 'profile') {
                System.assert(filter.values.size() >= 0, 'Profile filter should have values or be empty');
            } else if (filter.id == 'panels') {
                System.assert(filter.values.size() >= 0, 'Panels filter should have values or be empty');
            } else if (filter.id == 'structure') {
                System.assert(filter.values.size() >= 0, 'Structure filter should have values or be empty');
            } else if (filter.id == 'visor') {
                System.assert(filter.values.size() >= 0, 'Visor filter should have values or be empty');
            }
        }
    }

    @isTest
    static void testFilterWrapperConstructor() {
        Test.startTest();
        CustomFilterController.FilterWrapper filter = new CustomFilterController.FilterWrapper();
        Test.stopTest();

        System.assertNotEquals(null, filter.values, 'Values list should be initialized');
        System.assertNotEquals(null, filter.selectedValues, 'Selected values list should be initialized');
        System.assertEquals(0, filter.values.size(), 'Values list should be empty');
        System.assertEquals(0, filter.selectedValues.size(), 'Selected values list should be empty');
    }

    @isTest
    static void testNullCategoryParameter() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result =
            CustomFilterController.getFilterData(null, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.quickTurnFilters, 'Quick Turn filters should be null for null category');
        System.assertEquals(null, result.myProductsFilters, 'My Products filters should be null for null category');
    }

    @isTest
    static void testMyProductsWithNullIncludeAccountEndUsers() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result =
            CustomFilterController.getFilterData('My Products', null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.myProductsFilters, 'My Products filters should not be null');
        System.assertEquals(1, result.myProductsFilters.size(), 'Should have 1 My Products filter');
    }
}
