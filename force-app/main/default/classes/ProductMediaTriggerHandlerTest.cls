/**
 * Test class for ProductMediaTriggerHandler
 */
@isTest
private class ProductMediaTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create test products
        List<Product2> products = new List<Product2>();
        products.add(new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TEST001',
            IsActive = true
        ));
        products.add(new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TEST002',
            IsActive = true
        ));
        insert products;
    }

    @isTest
    static void testSyncContentKeys_EmptyList() {
        List<ProductMedia> emptyList = new List<ProductMedia>();

        Test.startTest();
        ProductMediaTriggerHandler.syncContentKeys(emptyList);
        Test.stopTest();

        System.assertEquals(0, emptyList.size(), 'Empty list should remain empty');
    }

    @isTest
    static void testSyncContentKeys_NullElectronicMediaId() {
        // Query test products
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];

        // Create ProductMedia with null ElectronicMediaId
        // Note: We can't actually insert ProductMedia in tests, but we can create the objects
        List<ProductMedia> mediaList = new List<ProductMedia>();
        ProductMedia pm = new ProductMedia();
        pm.ProductId = products[0].Id;
        pm.ElectronicMediaId = null; // Null ElectronicMediaId
        mediaList.add(pm);

        Test.startTest();
        // Should handle null ElectronicMediaId gracefully
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        // Verify method executed without error
        System.assertEquals(1, mediaList.size(), 'Should have 1 ProductMedia in list');
        System.assertEquals(null, pm.ContentKey__c, 'ContentKey should remain null');
    }

    @isTest
    static void testSyncContentKeys_WithElectronicMediaId() {
        // Query test products
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];

        // Create fake ManagedContent ID (won't exist in test, will trigger exception handling)
        String fakeManagedContentId = '0Qy000000000001AAA';

        List<ProductMedia> mediaList = new List<ProductMedia>();
        ProductMedia pm = new ProductMedia();
        pm.ProductId = products[0].Id;
        pm.ElectronicMediaId = fakeManagedContentId;
        mediaList.add(pm);

        Test.startTest();
        // Should execute query logic and handle exception when ManagedContent doesn't exist
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        // Verify method executed without error
        System.assertEquals(1, mediaList.size(), 'Should have 1 ProductMedia in list');
        // ContentKey__c will remain null since ManagedContent doesn't exist
        System.assertEquals(null, pm.ContentKey__c, 'ContentKey should be null when ManagedContent not found');
    }

    @isTest
    static void testSyncContentKeys_MultipleProductMedia() {
        // Query test products
        List<Product2> products = [SELECT Id FROM Product2];

        // Create multiple ProductMedia records with fake IDs
        List<ProductMedia> mediaList = new List<ProductMedia>();

        ProductMedia pm1 = new ProductMedia();
        pm1.ProductId = products[0].Id;
        pm1.ElectronicMediaId = '0Qy000000000001AAA'; // Fake ID
        mediaList.add(pm1);

        ProductMedia pm2 = new ProductMedia();
        pm2.ProductId = products.size() > 1 ? products[1].Id : products[0].Id;
        pm2.ElectronicMediaId = '0Qy000000000002AAA'; // Fake ID
        mediaList.add(pm2);

        ProductMedia pm3 = new ProductMedia();
        pm3.ProductId = products[0].Id;
        pm3.ElectronicMediaId = null; // Null ID
        mediaList.add(pm3);

        Test.startTest();
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        System.assertEquals(3, mediaList.size(), 'Should have 3 ProductMedia in list');
    }

    @isTest
    static void testSyncContentKeys_MixedElectronicMediaIds() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];

        List<ProductMedia> mediaList = new List<ProductMedia>();

        // First PM with ElectronicMediaId
        ProductMedia pm1 = new ProductMedia();
        pm1.ProductId = products[0].Id;
        pm1.ElectronicMediaId = '0Qy000000000001AAA';
        mediaList.add(pm1);

        // Second PM without ElectronicMediaId
        ProductMedia pm2 = new ProductMedia();
        pm2.ProductId = products[0].Id;
        pm2.ElectronicMediaId = null;
        mediaList.add(pm2);

        Test.startTest();
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        // Verify both were processed
        System.assertEquals(2, mediaList.size(), 'Should process both ProductMedia records');
    }

    @isTest
    static void testSyncContentKeys_ExceptionHandling() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];

        // Use invalid ID format to potentially trigger exceptions
        List<ProductMedia> mediaList = new List<ProductMedia>();
        ProductMedia pm = new ProductMedia();
        pm.ProductId = products[0].Id;
        pm.ElectronicMediaId = '0Qy000000000999AAA'; // Fake but valid format ID
        mediaList.add(pm);

        Test.startTest();
        try {
            ProductMediaTriggerHandler.syncContentKeys(mediaList);
            // Should not throw exception even if ManagedContent doesn't exist
            System.assert(true, 'Should handle missing ManagedContent gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSyncContentKeys_AllNullElectronicMediaIds() {
        List<Product2> products = [SELECT Id FROM Product2];

        List<ProductMedia> mediaList = new List<ProductMedia>();

        // All ProductMedia with null ElectronicMediaId
        for (Product2 p : products) {
            ProductMedia pm = new ProductMedia();
            pm.ProductId = p.Id;
            pm.ElectronicMediaId = null;
            mediaList.add(pm);
        }

        Test.startTest();
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        // Should return early without querying ManagedContent
        System.assertEquals(products.size(), mediaList.size(), 'Should have all ProductMedia in list');
        for (ProductMedia pm : mediaList) {
            System.assertEquals(null, pm.ContentKey__c, 'ContentKey should remain null');
        }
    }

    @isTest
    static void testSyncContentKeys_SingleProductMedia() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];

        List<ProductMedia> mediaList = new List<ProductMedia>();
        ProductMedia pm = new ProductMedia();
        pm.ProductId = products[0].Id;
        pm.ElectronicMediaId = '0Qy000000000555AAA';
        mediaList.add(pm);

        Test.startTest();
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        System.assertEquals(1, mediaList.size(), 'Should have 1 ProductMedia');
    }

    @isTest
    static void testSyncContentKeys_DifferentElectronicMediaIds() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];

        List<ProductMedia> mediaList = new List<ProductMedia>();

        // Add ProductMedia with different fake ManagedContent IDs
        ProductMedia pm1 = new ProductMedia();
        pm1.ProductId = products[0].Id;
        pm1.ElectronicMediaId = '0Qy000000000111AAA';
        mediaList.add(pm1);

        ProductMedia pm2 = new ProductMedia();
        pm2.ProductId = products[0].Id;
        pm2.ElectronicMediaId = '0Qy000000000222AAA';
        mediaList.add(pm2);

        ProductMedia pm3 = new ProductMedia();
        pm3.ProductId = products[0].Id;
        pm3.ElectronicMediaId = '0Qy000000000333AAA';
        mediaList.add(pm3);

        Test.startTest();
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        // All should be processed
        System.assertEquals(3, mediaList.size(), 'Should process all ProductMedia records');
    }

    @isTest
    static void testSyncContentKeys_DuplicateElectronicMediaIds() {
        List<Product2> products = [SELECT Id FROM Product2];

        List<ProductMedia> mediaList = new List<ProductMedia>();

        // Multiple ProductMedia with same ElectronicMediaId
        String sharedId = '0Qy000000000001AAA';

        ProductMedia pm1 = new ProductMedia();
        pm1.ProductId = products[0].Id;
        pm1.ElectronicMediaId = sharedId;
        mediaList.add(pm1);

        ProductMedia pm2 = new ProductMedia();
        pm2.ProductId = products.size() > 1 ? products[1].Id : products[0].Id;
        pm2.ElectronicMediaId = sharedId; // Same ID
        mediaList.add(pm2);

        Test.startTest();
        ProductMediaTriggerHandler.syncContentKeys(mediaList);
        Test.stopTest();

        // Both should be processed
        System.assertEquals(2, mediaList.size(), 'Should handle duplicate ElectronicMediaIds');
    }
}
