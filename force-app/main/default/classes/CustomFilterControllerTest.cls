/**
 * Test class for CustomFilterController
 */
@isTest
private class CustomFilterControllerTest {

    @isTest
    static void testGetQuickTurnFilters() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result = CustomFilterController.getFilterData('Quick Turn', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.quickTurnFilters, 'Quick Turn filters should not be null');
        System.assertEquals(3, result.quickTurnFilters.size(), 'Should have 3 Quick Turn filters');

        // Verify Product Code filter
        CustomFilterController.FilterWrapper productCodeFilter = result.quickTurnFilters[0];
        System.assertEquals('productCode', productCodeFilter.id, 'First filter should be Product Code');
        System.assertEquals('Product Code', productCodeFilter.label, 'Product Code label should match');
        System.assertEquals('text', productCodeFilter.fieldType, 'Product Code should be text type');

        // Verify Shape filter
        CustomFilterController.FilterWrapper shapeFilter = result.quickTurnFilters[1];
        System.assertEquals('shape', shapeFilter.id, 'Second filter should be Shape');
        System.assertEquals('Shape', shapeFilter.label, 'Shape label should match');
        System.assertEquals('picklist', shapeFilter.fieldType, 'Shape should be picklist type');

        // Verify Rush Ready filter
        CustomFilterController.FilterWrapper rushReadyFilter = result.quickTurnFilters[2];
        System.assertEquals('rushReady', rushReadyFilter.id, 'Third filter should be Rush Ready');
        System.assertEquals('Rush Ready', rushReadyFilter.label, 'Rush Ready label should match');
        System.assertEquals('checkbox', rushReadyFilter.fieldType, 'Rush Ready should be checkbox type');
        System.assertEquals(1, rushReadyFilter.values.size(), 'Rush Ready should have 1 value');
    }

    @isTest
    static void testGetMyProductsFilters() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result = CustomFilterController.getFilterData('My Products', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.myProductsFilters, 'My Products filters should not be null');
        System.assertEquals(1, result.myProductsFilters.size(), 'Should have 1 My Products filter');

        // Verify End User filter
        CustomFilterController.FilterWrapper endUserFilter = result.myProductsFilters[0];
        System.assertEquals('endUser', endUserFilter.id, 'Filter should be End User');
        System.assertEquals('End User', endUserFilter.label, 'End User label should match');
        System.assertEquals('lookup', endUserFilter.fieldType, 'End User should be lookup type');
    }

    @isTest
    static void testGetMyProductsFiltersWithAccountEndUsers() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result = CustomFilterController.getFilterData('My Products', true);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.myProductsFilters, 'My Products filters should not be null');
        System.assertEquals(1, result.myProductsFilters.size(), 'Should have 1 My Products filter');
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

        System.assertEquals(-1, value1.compareTo(value2), 'A should come before B');
        System.assertEquals(1, value2.compareTo(value1), 'B should come after A');
        System.assertEquals(0, value1.compareTo(value3), 'Equal labels should return 0');
    }

    @isTest
    static void testUnknownCategory() {
        Test.startTest();
        CustomFilterController.FilterDataWrapper result = CustomFilterController.getFilterData('Unknown Category', false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.quickTurnFilters, 'Quick Turn filters should be null for unknown category');
        System.assertEquals(null, result.myProductsFilters, 'My Products filters should be null for unknown category');
    }
}
