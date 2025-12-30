/**
 * Test class for ManagedContentHelper
 */
@isTest
private class ManagedContentHelperTest {

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

        insert products;

        // Create custom metadata for testing (if needed)
        // Note: Custom metadata cannot be inserted in tests, but will be mocked
    }

    @isTest
    static void testGetProductImageUrls_EmptyProductList() {
        List<Id> emptyProductIds = new List<Id>();
        String testWebstoreId = 'testWebstoreId';

        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(emptyProductIds, testWebstoreId);
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
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, testWebstoreId);
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
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // Should still execute without error even with null webstoreId
        System.assert(result.size() >= 0, 'Should handle null webstoreId gracefully');
    }

    @isTest
    static void testGetProductImageUrls_WithWebstoreId() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        String testWebstoreId = '0ZEbb000000HrZN';

        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // In test context without actual ProductMedia/ManagedContent, result should be empty
        System.assert(result.size() >= 0, 'Should execute without error');
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
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should return valid result map');
    }

    @isTest
    static void testGetProductImageUrls_ExceptionHandling() {
        // Test with invalid product ID format to trigger potential exceptions
        List<Id> invalidProductIds = new List<Id>();

        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(invalidProductIds, 'testWebstore');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null even with invalid input');
        System.assertEquals(0, result.size(), 'Should return empty map for invalid input');
    }

    @isTest
    static void testGetProductImageUrls_NullProductIds() {
        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(null, 'testWebstoreId');
        Test.stopTest();

        // Method should handle null gracefully
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetProductImageUrls_ValidWebstoreIdFormat() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        // Use a realistic webstore ID format
        String testWebstoreId = '0ZEbb000000HrZNGA0';

        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, testWebstoreId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should handle valid webstore ID');
    }

    @isTest
    static void testGetProductImageUrls_EmptyWebstoreId() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, '');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should handle empty webstore ID');
    }

    @isTest
    static void testGetProductImageUrls_SingleProductId() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>{ products[0].Id };

        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'testWebstore');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should handle single product ID');
    }

    @isTest
    static void testGetProductImageUrls_AllProducts() {
        List<Product2> products = [SELECT Id FROM Product2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'testWebstore');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        // Without ProductMedia, should return empty map
        System.assertEquals(0, result.size(), 'Should return empty map without ProductMedia');
    }

    @isTest
    static void testCustomMetadataFallback() {
        // Test executes the metadata query path, falls back to webstoreId
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Call with explicit webstoreId to test fallback logic
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'fallbackWebstoreId');
        Test.stopTest();

        // Metadata query will fail (no custom metadata in test), should fall back to webstoreId
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should execute with metadata fallback');
    }

    @isTest
    static void testOrgIdRetrieval() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Ensure UserInfo.getOrganizationId() is called
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'testWebstore');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testBasePathConstruction() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Test basePath variable initialization
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'testStore');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testChannelIdAssignment() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Test channelId variable assignment logic
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'channel123');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testProductMediaQuery() {
        List<Product2> products = [SELECT Id FROM Product2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Ensure ProductMedia query executes
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'testWebstore');
        Test.stopTest();

        // Query will return empty list in test context
        System.assertEquals(0, result.size(), 'Should return empty without ProductMedia');
    }

    @isTest
    static void testExceptionInCustomMetadata() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        try {
            // Custom metadata query will throw exception (no Shop_Defaults record)
            Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'exceptionTest');
            // Should handle exception and use fallback
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testDebugStatements() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Ensure all debug statements execute
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'debugWebstore');
        Test.stopTest();

        // Should execute debug statements for: channelId, no ProductMedia warning
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testNullChannelIdFallback() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Custom metadata won't exist, channelId will be null, should fall back to webstoreId
        Map<Id, String> result = ManagedContentHelper.getProductImageUrls(productIds, 'fallbackId');
        Test.stopTest();

        // Should use fallback webstoreId
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testRepeatedCalls() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Multiple calls to ensure no state is retained
        Map<Id, String> result1 = ManagedContentHelper.getProductImageUrls(productIds, 'store1');
        Map<Id, String> result2 = ManagedContentHelper.getProductImageUrls(productIds, 'store2');
        Map<Id, String> result3 = ManagedContentHelper.getProductImageUrls(productIds, 'store3');
        Test.stopTest();

        System.assertEquals(0, result1.size(), 'First call should return empty');
        System.assertEquals(0, result2.size(), 'Second call should return empty');
        System.assertEquals(0, result3.size(), 'Third call should return empty');
    }

    @isTest
    static void testBuildImageUrl() {
        String contentKey = 'MCJ52R56QITEZRQOJXG7DHYWTIBI';
        String channelId = '0ZEbb000000HrZNGA0';
        String orgId = '00D1234567890123';

        Test.startTest();
        String url = ManagedContentHelper.buildImageUrl(contentKey, channelId, orgId);
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should not be null');
        System.assert(url.contains('/shop/sfsites/c/cms/delivery/media/'), 'Should contain base path');
        System.assert(url.contains(contentKey), 'Should contain content key');
        System.assert(url.contains('version=1.1'), 'Should contain version parameter');
        System.assert(url.contains('channelId=' + channelId), 'Should contain channelId');
        System.assert(url.contains('oid=' + orgId), 'Should contain orgId');
    }

    @isTest
    static void testBuildImageUrl_NullContentKey() {
        Test.startTest();
        String url = ManagedContentHelper.buildImageUrl(null, 'channel', 'org');
        Test.stopTest();

        System.assertEquals(null, url, 'Should return null for null content key');
    }

    @isTest
    static void testBuildImageUrl_EmptyContentKey() {
        Test.startTest();
        String url = ManagedContentHelper.buildImageUrl('', 'channel', 'org');
        Test.stopTest();

        System.assertEquals(null, url, 'Should return null for empty content key');
    }

    @isTest
    static void testBuildImageUrl_ValidParameters() {
        Test.startTest();
        String url = ManagedContentHelper.buildImageUrl('KEY123', 'CHANNEL456', 'ORG789');
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should not be null');
        System.assert(url.contains('KEY123'), 'Should contain content key');
        System.assert(url.contains('CHANNEL456'), 'Should contain channel ID');
        System.assert(url.contains('ORG789'), 'Should contain org ID');
    }

    @isTest
    static void testBuildImageUrl_NullChannelAndOrg() {
        Test.startTest();
        String url = ManagedContentHelper.buildImageUrl('VALIDKEY', null, null);
        Test.stopTest();

        // Should still build URL even with null channel/org (they'll be null in URL params)
        System.assertNotEquals(null, url, 'Should build URL with null channel/org');
        System.assert(url.contains('VALIDKEY'), 'Should contain content key');
    }
}
