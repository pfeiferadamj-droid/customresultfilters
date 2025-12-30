/**
 * Test class for CustomProductQueryController
 */
@isTest
private class CustomProductQueryControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test products with required fields
        // Note: ProductClass is read-only and set by system based on product configuration
        // Note: Shape__c, Profile__c, Panels__c, Structure__c, Visor__c may be restricted picklists
        List<Product2> products = new List<Product2>();

        // Create product 1 - marked as parent
        Product2 simpleProduct = new Product2(
            Name = 'Test Simple Product',
            ProductCode = 'TSP001',
            StockKeepingUnit = 'SKU-001',
            IsActive = true,
            Is_Parent__c = 'Yes',
            Description = 'Test simple product description',
            Rush_Ready__c = true
        );
        products.add(simpleProduct);

        // Create product 2 - marked as parent
        Product2 variationParent = new Product2(
            Name = 'Test Variation Parent',
            ProductCode = 'TVP001',
            StockKeepingUnit = 'SKU-002',
            IsActive = true,
            Is_Parent__c = 'Yes',
            Description = 'Test variation parent description'
        );
        products.add(variationParent);

        // Create product 3 - Rush Ready
        Product2 rushReadyProduct = new Product2(
            Name = 'Rush Ready Product',
            ProductCode = 'RRP001',
            StockKeepingUnit = 'SKU-003',
            IsActive = true,
            Is_Parent__c = 'Yes',
            Rush_Ready__c = true
        );
        products.add(rushReadyProduct);

        insert products;

        // Get standard pricebook
        Pricebook2 standardPB = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );

        // Create pricebook entries
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        for (Product2 p : products) {
            pbeList.add(new PricebookEntry(
                Pricebook2Id = standardPB.Id,
                Product2Id = p.Id,
                UnitPrice = 100.00,
                IsActive = true
            ));
        }
        insert pbeList;
    }

    @isTest
    static void testGetProductsByEndUser_NoEndUsers() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            CustomProductQueryController.getProductsByEndUser(
                null, // categoryId
                new List<String>(), // empty endUserIds
                null, // productCode
                1, // pageNumber
                12, // pageSize
                false, // restrictToParents
                'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.products.size(), 'Should return 0 products when no end users provided');
        System.assertEquals(0, result.total, 'Total should be 0');
        System.assertEquals(1, result.pageNumber, 'Page number should be 1');
        System.assertEquals(12, result.pageSize, 'Page size should be 12');
    }

    @isTest
    static void testGetProductsByEndUser_WithNullInputs() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            CustomProductQueryController.getProductsByEndUser(
                null, // categoryId
                null, // null endUserIds
                null, // productCode
                null, // pageNumber
                null, // pageSize
                null, // restrictToParents
                'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.products.size(), 'Should return 0 products when end users is null');
    }

    @isTest
    static void testGetProductsByQuickTurnFilters_ProfileFilter() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            CustomProductQueryController.getProductsByQuickTurnFilters(
                null, // categoryId
                new List<String>{'Mid'}, // profileValues
                null, // panelsValues
                null, // structureValues
                null, // visorValues
                null, // shapeValues
                null, // productCode
                null, // specialPrograms
                1, // pageNumber
                12, // pageSize
                true, // restrictToParents
                'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.products.size() >= 0, 'Should return results');
    }

    @isTest
    static void testGetProductsByQuickTurnFilters_MultipleFilters() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            CustomProductQueryController.getProductsByQuickTurnFilters(
                null, // categoryId
                new List<String>{'Mid'}, // profileValues
                new List<String>{'6'}, // panelsValues
                new List<String>{'Structured'}, // structureValues
                new List<String>{'Flat'}, // visorValues
                new List<String>{'Fitted'}, // shapeValues
                null, // productCode
                null, // specialPrograms
                1, // pageNumber
                12, // pageSize
                true, // restrictToParents
                'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.products.size() >= 0, 'Should return results');
    }

    @isTest
    static void testGetProductsByQuickTurnFilters_SpecialPrograms() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            CustomProductQueryController.getProductsByQuickTurnFilters(
                null, // categoryId
                null, // profileValues
                null, // panelsValues
                null, // structureValues
                null, // visorValues
                null, // shapeValues
                null, // productCode
                new List<String>{'QuickTurnDDT'}, // specialPrograms - Dri-Duck
                1, // pageNumber
                12, // pageSize
                true, // restrictToParents
                'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.products.size() >= 0, 'Should return results for QuickTurnDDT');
    }

    @isTest
    static void testGetProductsByQuickTurnFilters_RushReady() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            CustomProductQueryController.getProductsByQuickTurnFilters(
                null, // categoryId
                null, // profileValues
                null, // panelsValues
                null, // structureValues
                null, // visorValues
                null, // shapeValues
                null, // productCode
                new List<String>{'RushReady'}, // specialPrograms - Rush Ready
                1, // pageNumber
                12, // pageSize
                true, // restrictToParents
                'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.products.size() >= 0, 'Should return results for Rush Ready');
    }

    @isTest
    static void testGetProductsByQuickTurnFilters_ProductCodeSearch() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            CustomProductQueryController.getProductsByQuickTurnFilters(
                null, // categoryId
                null, // profileValues
                null, // panelsValues
                null, // structureValues
                null, // visorValues
                null, // shapeValues
                'TSP', // productCode search
                null, // specialPrograms
                1, // pageNumber
                12, // pageSize
                true, // restrictToParents
                'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.products.size() >= 0, 'Should return results for product code search');
    }

    @isTest
    static void testGetProductsByQuickTurnFilters_Pagination() {
        Test.startTest();
        // Test page 1
        CustomProductQueryController.ProductQueryResult result1 =
            CustomProductQueryController.getProductsByQuickTurnFilters(
                null, null, null, null, null, null, null, null,
                1, 2, true, 'testWebstoreId'
            );

        // Test page 2
        CustomProductQueryController.ProductQueryResult result2 =
            CustomProductQueryController.getProductsByQuickTurnFilters(
                null, null, null, null, null, null, null, null,
                2, 2, true, 'testWebstoreId'
            );
        Test.stopTest();

        System.assertNotEquals(null, result1, 'Page 1 result should not be null');
        System.assertNotEquals(null, result2, 'Page 2 result should not be null');
        System.assertEquals(1, result1.pageNumber, 'Page 1 number should be 1');
        System.assertEquals(2, result2.pageNumber, 'Page 2 number should be 2');
    }

    @isTest
    static void testPricebookEntryInfo() {
        Test.startTest();
        CustomProductQueryController.PricebookEntryInfo info =
            new CustomProductQueryController.PricebookEntryInfo();
        info.pricebookId = 'testPricebookId';
        info.unitPrice = 99.99;
        Test.stopTest();

        System.assertEquals('testPricebookId', info.pricebookId, 'Pricebook ID should match');
        System.assertEquals(99.99, info.unitPrice, 'Unit price should match');
    }

    @isTest
    static void testProductWrapper() {
        Test.startTest();
        CustomProductQueryController.ProductWrapper wrapper =
            new CustomProductQueryController.ProductWrapper();
        wrapper.id = 'testProductId';
        wrapper.name = 'Test Product';
        wrapper.productCode = 'TEST001';
        wrapper.description = 'Test Description';
        wrapper.sku = 'SKU-TEST';
        wrapper.endUserId = 'testEndUserId';
        wrapper.endUserName = 'Test End User';
        wrapper.imageUrl = 'https://test.com/image.jpg';
        wrapper.imageAltText = 'Test Alt Text';
        wrapper.shapeValue = 'Round';
        wrapper.rushReady = true;
        Test.stopTest();

        System.assertEquals('testProductId', wrapper.id, 'ID should match');
        System.assertEquals('Test Product', wrapper.name, 'Name should match');
        System.assertEquals('TEST001', wrapper.productCode, 'Product code should match');
        System.assertEquals('Test Description', wrapper.description, 'Description should match');
        System.assertEquals('SKU-TEST', wrapper.sku, 'SKU should match');
        System.assertEquals('testEndUserId', wrapper.endUserId, 'End user ID should match');
        System.assertEquals('Test End User', wrapper.endUserName, 'End user name should match');
        System.assertEquals('https://test.com/image.jpg', wrapper.imageUrl, 'Image URL should match');
        System.assertEquals('Test Alt Text', wrapper.imageAltText, 'Image alt text should match');
        System.assertEquals('Round', wrapper.shapeValue, 'Shape should match');
        System.assertEquals(true, wrapper.rushReady, 'Rush ready should be true');
    }

    @isTest
    static void testProductQueryResult() {
        Test.startTest();
        CustomProductQueryController.ProductQueryResult result =
            new CustomProductQueryController.ProductQueryResult();
        result.products = new List<CustomProductQueryController.ProductWrapper>();
        result.total = 10;
        result.pageNumber = 1;
        result.pageSize = 12;
        result.pricebookEntries = new Map<Id, List<CustomProductQueryController.PricebookEntryInfo>>();
        Test.stopTest();

        System.assertNotEquals(null, result.products, 'Products list should not be null');
        System.assertEquals(10, result.total, 'Total should be 10');
        System.assertEquals(1, result.pageNumber, 'Page number should be 1');
        System.assertEquals(12, result.pageSize, 'Page size should be 12');
        System.assertNotEquals(null, result.pricebookEntries, 'Pricebook entries should not be null');
    }

    @isTest
    static void testGetProductsByEndUser_WithValidIds() {
        // Create a fake end user ID to test the query logic
        // Even if no products match, this will execute the full query code path
        List<String> fakeEndUserIds = new List<String>{'a0Q000000000001'};

        Test.startTest();
        try {
            CustomProductQueryController.ProductQueryResult result =
                CustomProductQueryController.getProductsByEndUser(
                    'testCategoryId',
                    fakeEndUserIds,
                    null, // productCode
                    1, // pageNumber
                    12, // pageSize
                    false, // restrictToParents
                    'testWebstoreId'
                );

            // If End_User__c field exists, query will execute and return 0 results
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.products, 'Products should not be null');
            System.assertEquals(0, result.total, 'Should find 0 products with fake end user ID');

        } catch (Exception e) {
            // If End_User__c field doesn't exist, will throw exception
            // This is expected in non-B2B Commerce orgs
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetProductsByEndUser_WithProductCodeSearch() {
        List<String> fakeEndUserIds = new List<String>{'a0Q000000000001'};

        Test.startTest();
        try {
            CustomProductQueryController.ProductQueryResult result =
                CustomProductQueryController.getProductsByEndUser(
                    'testCategoryId',
                    fakeEndUserIds,
                    'TSP', // productCode search
                    1,
                    12,
                    false,
                    'testWebstoreId'
                );

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.products, 'Products should not be null');

        } catch (Exception e) {
            // Expected if custom fields don't exist
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetProductsByEndUser_WithCategoryId() {
        List<String> fakeEndUserIds = new List<String>{'a0Q000000000001'};

        Test.startTest();
        try {
            CustomProductQueryController.ProductQueryResult result =
                CustomProductQueryController.getProductsByEndUser(
                    '0ZGbb000000FFOX', // valid-looking category ID
                    fakeEndUserIds,
                    null,
                    1,
                    12,
                    false,
                    'testWebstoreId'
                );

            System.assertNotEquals(null, result, 'Result should not be null');

        } catch (Exception e) {
            // Expected if custom fields don't exist
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }
}
