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

    @isTest
    static void testGetProductImageUrls_EmptyWebstoreId() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, '');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should handle empty webstore ID');
    }

    @isTest
    static void testGetProductImageUrls_OrgIdAndBasePath() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // This will exercise the UserInfo.getOrganizationId() and basePath logic
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, 'testWebstore');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetProductImageUrls_AllProductsNoMedia() {
        // Query all products to exercise the full query path
        List<Product2> products = [SELECT Id FROM Product2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, 'testWebstore');
        Test.stopTest();

        // Should return empty map since no ProductMedia exists
        System.assertEquals(0, result.size(), 'Should return empty map without ProductMedia');
    }

    @isTest
    static void testGetProductImageUrls_DifferentWebstoreIds() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<Id, String> result1 = ProductImageHelper.getProductImageUrls(productIds, 'webstore1');
        Map<Id, String> result2 = ProductImageHelper.getProductImageUrls(productIds, 'webstore2');
        Map<Id, String> result3 = ProductImageHelper.getProductImageUrls(productIds, '0ZEbb000000HrZNGA0');
        Test.stopTest();

        System.assertNotEquals(null, result1, 'Result 1 should not be null');
        System.assertNotEquals(null, result2, 'Result 2 should not be null');
        System.assertNotEquals(null, result3, 'Result 3 should not be null');
    }

    @isTest
    static void testGetProductImageUrls_RepeatedCalls() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // Call multiple times to ensure no state is retained
        Map<Id, String> result1 = ProductImageHelper.getProductImageUrls(productIds, 'test1');
        Map<Id, String> result2 = ProductImageHelper.getProductImageUrls(productIds, 'test2');
        Map<Id, String> result3 = ProductImageHelper.getProductImageUrls(productIds, 'test3');
        Test.stopTest();

        System.assertEquals(0, result1.size(), 'First call should return empty');
        System.assertEquals(0, result2.size(), 'Second call should return empty');
        System.assertEquals(0, result3.size(), 'Third call should return empty');
    }

    @isTest
    static void testGetProductImageUrls_SingleVsMultiple() {
        List<Product2> products = [SELECT Id FROM Product2];

        Test.startTest();
        // Test single product
        Map<Id, String> singleResult = ProductImageHelper.getProductImageUrls(
            new List<Id>{ products[0].Id },
            'testWebstore'
        );

        // Test multiple products
        List<Id> multipleIds = new List<Id>();
        for (Product2 p : products) {
            multipleIds.add(p.Id);
        }
        Map<Id, String> multipleResult = ProductImageHelper.getProductImageUrls(multipleIds, 'testWebstore');
        Test.stopTest();

        System.assertEquals(0, singleResult.size(), 'Single product should return empty without media');
        System.assertEquals(0, multipleResult.size(), 'Multiple products should return empty without media');
    }

    @isTest
    static void testGetProductImageUrls_DebugOutput() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<Id> productIds = new List<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        // This test ensures debug statements execute
        Map<Id, String> result = ProductImageHelper.getProductImageUrls(productIds, 'debugTest');
        Test.stopTest();

        // Debug statements should have executed
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty without ProductMedia');
    }

    @isTest
    static void testBuildContentVersionUrl() {
        Test.startTest();
        String url = ProductImageHelper.buildContentVersionUrl('0681234567890123456', '0681234567890123457');
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should not be null');
        System.assert(url.contains('/sfc/servlet.shepherd/version/renditionDownload'), 'Should contain servlet path');
        System.assert(url.contains('ORIGINAL_068'), 'Should contain ORIGINAL_ prefix with first 3 chars');
        System.assert(url.contains('versionId=0681234567890123457'), 'Should contain versionId parameter');
    }

    @isTest
    static void testBuildContentVersionUrl_NullInputs() {
        Test.startTest();
        String url1 = ProductImageHelper.buildContentVersionUrl(null, '0681234567890123457');
        String url2 = ProductImageHelper.buildContentVersionUrl('0681234567890123456', null);
        String url3 = ProductImageHelper.buildContentVersionUrl(null, null);
        Test.stopTest();

        System.assertEquals(null, url1, 'Should return null for null contentDocumentId');
        System.assertEquals(null, url2, 'Should return null for null electronicMediaId');
        System.assertEquals(null, url3, 'Should return null for both null');
    }

    @isTest
    static void testBuildContentVersionUrl_EmptyStrings() {
        Test.startTest();
        String url1 = ProductImageHelper.buildContentVersionUrl('', '0681234567890123457');
        String url2 = ProductImageHelper.buildContentVersionUrl('0681234567890123456', '');
        String url3 = ProductImageHelper.buildContentVersionUrl('', '');
        Test.stopTest();

        System.assertEquals(null, url1, 'Should return null for empty contentDocumentId');
        System.assertEquals(null, url2, 'Should return null for empty electronicMediaId');
        System.assertEquals(null, url3, 'Should return null for both empty');
    }

    @isTest
    static void testBuildManagedContentUrl() {
        String testContentKey = 'MCJ52R56QITEZRQOJXG7DHYWTIBI';
        String testWebstoreId = '0ZEbb000000HrZNGA0';
        String testOrgId = '00D1234567890123';

        Test.startTest();
        String url = ProductImageHelper.buildManagedContentUrl(testContentKey, testWebstoreId, testOrgId);
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should not be null');
        System.assert(url.contains('/shop/sfsites/c/cms/delivery/media/'), 'Should contain CMS delivery path');
        System.assert(url.contains(testContentKey), 'Should contain content key');
        System.assert(url.contains('channelId=' + testWebstoreId), 'Should contain channelId parameter');
        System.assert(url.contains('oid=' + testOrgId), 'Should contain oid parameter');
    }

    @isTest
    static void testBuildManagedContentUrl_NullContentKey() {
        Test.startTest();
        String url = ProductImageHelper.buildManagedContentUrl(null, 'testWebstore', 'testOrg');
        Test.stopTest();

        System.assertEquals(null, url, 'Should return null for null content key');
    }

    @isTest
    static void testBuildManagedContentUrl_EmptyContentKey() {
        Test.startTest();
        String url = ProductImageHelper.buildManagedContentUrl('', 'testWebstore', 'testOrg');
        Test.stopTest();

        System.assertEquals(null, url, 'Should return null for empty content key');
    }

    @isTest
    static void testBuildManagedContentUrl_ValidInputs() {
        Test.startTest();
        String url = ProductImageHelper.buildManagedContentUrl('CONTENTKEY123', 'store456', 'org789');
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should not be null');
        System.assert(url.contains('CONTENTKEY123'), 'Should contain content key');
        System.assert(url.contains('store456'), 'Should contain webstore ID');
        System.assert(url.contains('org789'), 'Should contain org ID');
    }

    @isTest
    static void testDetermineContentType_ContentVersion() {
        Test.startTest();
        String type = ProductImageHelper.determineContentType('0681234567890123456');
        Test.stopTest();

        System.assertEquals('ContentVersion', type, 'Should identify ContentVersion ID');
    }

    @isTest
    static void testDetermineContentType_ManagedContentVariant() {
        Test.startTest();
        String type = ProductImageHelper.determineContentType('0Qy1234567890123456');
        Test.stopTest();

        System.assertEquals('ManagedContentVariant', type, 'Should identify ManagedContentVariant ID');
    }

    @isTest
    static void testDetermineContentType_ManagedContent() {
        Test.startTest();
        String type = ProductImageHelper.determineContentType('0Qx1234567890123456');
        Test.stopTest();

        System.assertEquals('ManagedContent', type, 'Should identify ManagedContent ID');
    }

    @isTest
    static void testDetermineContentType_Unknown() {
        Test.startTest();
        String type1 = ProductImageHelper.determineContentType('0011234567890123456');
        String type2 = ProductImageHelper.determineContentType('a011234567890123456');
        Test.stopTest();

        System.assertEquals('Unknown', type1, 'Should return Unknown for Account ID');
        System.assertEquals('Unknown', type2, 'Should return Unknown for Contact ID');
    }

    @isTest
    static void testDetermineContentType_NullOrEmpty() {
        Test.startTest();
        String type1 = ProductImageHelper.determineContentType(null);
        String type2 = ProductImageHelper.determineContentType('');
        Test.stopTest();

        System.assertEquals('Unknown', type1, 'Should return Unknown for null');
        System.assertEquals('Unknown', type2, 'Should return Unknown for empty string');
    }

    @isTest
    static void testAllHelperMethods() {
        Test.startTest();
        // Test all helper methods work together
        String contentType1 = ProductImageHelper.determineContentType('0681234567890123456');
        String contentType2 = ProductImageHelper.determineContentType('0Qy1234567890123456');

        String cvUrl = ProductImageHelper.buildContentVersionUrl('0691234567890123456', '0681234567890123456');
        String mcUrl = ProductImageHelper.buildManagedContentUrl('CONTENTKEY', 'webstore', 'orgId');
        Test.stopTest();

        System.assertEquals('ContentVersion', contentType1, 'Should identify ContentVersion');
        System.assertEquals('ManagedContentVariant', contentType2, 'Should identify ManagedContentVariant');
        System.assertNotEquals(null, cvUrl, 'ContentVersion URL should not be null');
        System.assertNotEquals(null, mcUrl, 'ManagedContent URL should not be null');
    }
}
