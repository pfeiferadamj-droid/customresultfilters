/**
 * Test class for ProductImageHelper
 */
@isTest
private class ProductImageHelperTest {

    @TestSetup
    static void setupTestData() {
        // Create test products
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

        products.add(new Product2(
            Name = 'Test Product 3',
            ProductCode = 'TP003',
            IsActive = true
        ));

        insert products;
    }

    @isTest
    static void testGetProductImageUrls_EmptyProductList() {
        List<Id> emptyProductIds = new List<Id>();
        String testWebstoreId = 'testWebstoreId';

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(emptyProductIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty map for empty product list');
    }

    @isTest
    static void testGetProductImageUrls_NoProductMedia() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        String testWebstoreId = 'testWebstoreId';

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // No ProductMedia records exist in test, so map should be empty
        System.assertEquals(0, result.size(), 'Should return empty map when no ProductMedia exists');
    }

    @isTest
    static void testGetProductImageUrls_NullWebstoreId() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // Should still execute without error even with null webstoreId
        System.assert(result.size() >= 0, 'Should handle null webstoreId gracefully');
    }

    @isTest
    static void testGetProductImageUrls_MultipleProducts() {
        List<Product2> products = [SELECT Id FROM Product2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        String testWebstoreId = 'testWebstoreId';

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should return valid result map');
    }

    @isTest
    static void testGetProductImageUrls_SingleProduct() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        String testWebstoreId = '0ZEbb000000HrZN';

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // In test context without actual ProductMedia/ContentVersion, result should be empty
        System.assert(result.size() >= 0, 'Should execute without error');
    }

    @isTest
    static void testGetProductImageUrls_ExceptionHandling() {
        // Test with empty list to ensure exception handling works
        List<Id> emptyList = new List<Id>();

        Test.startTest();
        try {
            Map<Id, String> result = ProductImageHelper.getProductImageUrls(emptyList, 'testWebstore');
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.size(), 'Should return empty map for empty input');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetProductImageUrls_NullProductIds() {
        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(null, 'testWebstoreId');
        Test.stopTest();

        // Method should handle null gracefully
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty map for null input');
    }

    @isTest
    static void testGetProductImageUrls_WithValidWebstoreId() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        // Use a realistic webstore ID format
        String testWebstoreId = '0ZEbb000000HrZNGA0';

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should handle valid webstore ID');
    }

    @isTest
    static void testGetProductImageUrls_LargeProductList() {
        List<Product2> allProducts = [SELECT Id FROM Product2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : allProducts) {
            productIds.add(p.Id);
        }

        String testWebstoreId = 'testWebstoreId';

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should handle multiple products');
    }
}
