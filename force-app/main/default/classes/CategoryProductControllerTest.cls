/**
 * Test class for CategoryProductController
 */
@isTest
private class CategoryProductControllerTest {

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

        // Get standard pricebook
        Id standardPBId = Test.getStandardPricebookId();

        // Query for existing pricebook entries to avoid duplicates
        Set<Id> productIds = new Set<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        List<PricebookEntry> existingPBEs = [
            SELECT Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND Pricebook2Id = :standardPBId
        ];

        Set<Id> existingProductIds = new Set<Id>();
        for (PricebookEntry pbe : existingPBEs) {
            existingProductIds.add(pbe.Product2Id);
        }

        // Create pricebook entries only for products that don't have them
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        for (Product2 p : products) {
            if (!existingProductIds.contains(p.Id)) {
                pbeList.add(new PricebookEntry(
                    Pricebook2Id = standardPBId,
                    Product2Id = p.Id,
                    UnitPrice = 100.00,
                    IsActive = true
                ));
            }
        }

        if (!pbeList.isEmpty()) {
            insert pbeList;
        }
    }

    @isTest
    static void testGetCategoryProducts_Success() {
        // Use a mock category ID
        String categoryId = 'testCategoryId123';
        String webstoreId = 'testWebstoreId';
        String effectiveAccountId = 'testAccountId';

        Test.startTest();
        String result = CategoryProductController.getCategoryProducts(
            categoryId,
            webstoreId,
            effectiveAccountId,
            12, // pageSize
            1,  // pageNumber
            null, // sortRuleId
            null  // refinementsJSON
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.length() > 0, 'Result should contain data');

        // Verify JSON structure
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(resultMap.containsKey('searchResults'), 'Result should contain searchResults');
        System.assert(resultMap.containsKey('pricebookEntries'), 'Result should contain pricebookEntries');
    }

    @isTest
    static void testValidateRequiredParams_MissingCategoryId() {
        Test.startTest();
        try {
            CategoryProductController.validateRequiredParams(null, 'testWebstoreId');
            System.assert(false, 'Should throw exception for missing categoryId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Category ID'), 'Exception message should mention Category ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateRequiredParams_MissingWebstoreId() {
        Test.startTest();
        try {
            CategoryProductController.validateRequiredParams('testCategoryId', null);
            System.assert(false, 'Should throw exception for missing webstoreId');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Webstore ID'), 'Exception message should mention Webstore ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetEffectivePageSize() {
        Test.startTest();
        System.assertEquals(12, CategoryProductController.getEffectivePageSize(null), 'Should return default page size');
        System.assertEquals(24, CategoryProductController.getEffectivePageSize(24), 'Should return provided page size');
        System.assertEquals(0, CategoryProductController.getEffectivePageSize(0), 'Should return 0 if provided');
        Test.stopTest();
    }

    @isTest
    static void testGetEffectivePage() {
        Test.startTest();
        System.assertEquals(0, CategoryProductController.getEffectivePage(null), 'Should return 0 for null');
        System.assertEquals(0, CategoryProductController.getEffectivePage(1), 'Should convert 1 to 0');
        System.assertEquals(1, CategoryProductController.getEffectivePage(2), 'Should convert 2 to 1');
        System.assertEquals(0, CategoryProductController.getEffectivePage(0), 'Should return 0 for 0');
        System.assertEquals(0, CategoryProductController.getEffectivePage(-1), 'Should return 0 for negative');
        Test.stopTest();
    }

    @isTest
    static void testParseRefinements_ValidJSON() {
        String refinementsJSON = '[{"nameOrId":"Color","attributeType":"ProductAttribute","values":["Red","Blue"]}]';

        Test.startTest();
        List<Map<String, Object>> result = CategoryProductController.parseRefinements(refinementsJSON);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should have 1 refinement');

        Map<String, Object> refinement = result[0];
        System.assertEquals('Color', refinement.get('nameOrId'), 'nameOrId should be Color');
        System.assertEquals('ProductAttribute', refinement.get('attributeType'), 'attributeType should be ProductAttribute');

        List<String> values = (List<String>) refinement.get('values');
        System.assertEquals(2, values.size(), 'Should have 2 values');
        System.assert(values.contains('Red'), 'Should contain Red');
        System.assert(values.contains('Blue'), 'Should contain Blue');
    }

    @isTest
    static void testParseRefinements_EmptyJSON() {
        Test.startTest();
        List<Map<String, Object>> result = CategoryProductController.parseRefinements(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for null');

        result = CategoryProductController.parseRefinements('');
        System.assertEquals(0, result.size(), 'Should return empty list for empty string');
    }

    @isTest
    static void testCalculateTotalPages() {
        Test.startTest();
        System.assertEquals(0, CategoryProductController.calculateTotalPages(null, 12), 'Should return 0 for null items');
        System.assertEquals(0, CategoryProductController.calculateTotalPages(0, 12), 'Should return 0 for 0 items');
        System.assertEquals(1, CategoryProductController.calculateTotalPages(12, 12), 'Should return 1 page for 12 items');
        System.assertEquals(2, CategoryProductController.calculateTotalPages(13, 12), 'Should return 2 pages for 13 items');
        System.assertEquals(3, CategoryProductController.calculateTotalPages(25, 12), 'Should return 3 pages for 25 items');
        System.assertEquals(1, CategoryProductController.calculateTotalPages(1, 12), 'Should return 1 page for 1 item');
        Test.stopTest();
    }

    @isTest
    static void testHasNextPage() {
        Test.startTest();
        System.assertEquals(false, CategoryProductController.hasNextPage(null, 5), 'Should return false for null page');
        System.assertEquals(false, CategoryProductController.hasNextPage(1, null), 'Should return false for null total');
        System.assertEquals(true, CategoryProductController.hasNextPage(1, 5), 'Should return true when page < total');
        System.assertEquals(false, CategoryProductController.hasNextPage(5, 5), 'Should return false when page = total');
        System.assertEquals(false, CategoryProductController.hasNextPage(6, 5), 'Should return false when page > total');
        Test.stopTest();
    }

    @isTest
    static void testHasPreviousPage() {
        Test.startTest();
        System.assertEquals(false, CategoryProductController.hasPreviousPage(null), 'Should return false for null page');
        System.assertEquals(false, CategoryProductController.hasPreviousPage(1), 'Should return false for page 1');
        System.assertEquals(true, CategoryProductController.hasPreviousPage(2), 'Should return true for page 2');
        System.assertEquals(true, CategoryProductController.hasPreviousPage(5), 'Should return true for page 5');
        System.assertEquals(false, CategoryProductController.hasPreviousPage(0), 'Should return false for page 0');
        Test.stopTest();
    }

    @isTest
    static void testSanitizeSortRuleId() {
        Test.startTest();
        System.assertEquals(null, CategoryProductController.sanitizeSortRuleId(null), 'Should return null for null');
        System.assertEquals(null, CategoryProductController.sanitizeSortRuleId(''), 'Should return null for empty');
        System.assertEquals(null, CategoryProductController.sanitizeSortRuleId('  '), 'Should return null for whitespace');
        System.assertEquals('0SR000000000001', CategoryProductController.sanitizeSortRuleId('0SR000000000001'), 'Should return valid ID');
        System.assertEquals('0SR000000000001AAA', CategoryProductController.sanitizeSortRuleId('0SR000000000001AAA'), 'Should return valid 18-char ID');
        System.assertEquals('0SR000000000001', CategoryProductController.sanitizeSortRuleId(' 0SR000000000001 '), 'Should trim whitespace');
        System.assertEquals(null, CategoryProductController.sanitizeSortRuleId('short'), 'Should return null for short string');
        System.assertEquals(null, CategoryProductController.sanitizeSortRuleId('waytooooooooooooooolong'), 'Should return null for long string');
        Test.stopTest();
    }

    @isTest
    static void testGetAttributeTypeLabel() {
        Test.startTest();
        System.assertEquals('Default', CategoryProductController.getAttributeTypeLabel(null), 'Should return Default for null');
        System.assertEquals('Default', CategoryProductController.getAttributeTypeLabel(''), 'Should return Default for empty');
        System.assertEquals('Product Attribute', CategoryProductController.getAttributeTypeLabel('ProductAttribute'), 'Should return Product Attribute');
        System.assertEquals('Custom Field', CategoryProductController.getAttributeTypeLabel('Custom'), 'Should return Custom Field');
        System.assertEquals('Standard Field', CategoryProductController.getAttributeTypeLabel('Standard'), 'Should return Standard Field');
        System.assertEquals('Unknown', CategoryProductController.getAttributeTypeLabel('InvalidType'), 'Should return Unknown for invalid');
        Test.stopTest();
    }

    @isTest
    static void testFormatPrice() {
        Test.startTest();
        System.assertEquals('$0.00', CategoryProductController.formatPrice(null), 'Should return $0.00 for null');
        System.assertEquals('$10.00', CategoryProductController.formatPrice(10), 'Should format 10 as $10.00');
        System.assertEquals('$99.99', CategoryProductController.formatPrice(99.99), 'Should format 99.99 as $99.99');
        System.assertEquals('$0.50', CategoryProductController.formatPrice(0.5), 'Should format 0.5 as $0.50');
        System.assertEquals('$1000.00', CategoryProductController.formatPrice(1000), 'Should format 1000 as $1000.00');
        Test.stopTest();
    }

    @isTest
    static void testHasRefinementForField() {
        List<Map<String, Object>> refinements = new List<Map<String, Object>>();
        Map<String, Object> ref1 = new Map<String, Object>();
        ref1.put('nameOrId', 'Color');
        refinements.add(ref1);

        Test.startTest();
        System.assertEquals(true, CategoryProductController.hasRefinementForField(refinements, 'Color'), 'Should find Color refinement');
        System.assertEquals(true, CategoryProductController.hasRefinementForField(refinements, 'color'), 'Should be case insensitive');
        System.assertEquals(false, CategoryProductController.hasRefinementForField(refinements, 'Size'), 'Should not find Size refinement');
        System.assertEquals(false, CategoryProductController.hasRefinementForField(null, 'Color'), 'Should return false for null refinements');
        System.assertEquals(false, CategoryProductController.hasRefinementForField(refinements, null), 'Should return false for null field');
        Test.stopTest();
    }

    @isTest
    static void testGetRefinementValues() {
        List<Map<String, Object>> refinements = new List<Map<String, Object>>();
        Map<String, Object> ref1 = new Map<String, Object>();
        ref1.put('nameOrId', 'Color');
        ref1.put('values', new List<String>{'Red', 'Blue'});
        refinements.add(ref1);

        Test.startTest();
        List<String> values = CategoryProductController.getRefinementValues(refinements, 'Color');
        System.assertEquals(2, values.size(), 'Should return 2 values');
        System.assert(values.contains('Red'), 'Should contain Red');
        System.assert(values.contains('Blue'), 'Should contain Blue');

        List<String> emptyValues = CategoryProductController.getRefinementValues(refinements, 'Size');
        System.assertEquals(0, emptyValues.size(), 'Should return empty list for non-existent field');

        List<String> nullValues = CategoryProductController.getRefinementValues(null, 'Color');
        System.assertEquals(0, nullValues.size(), 'Should return empty list for null refinements');
        Test.stopTest();
    }

    @isTest
    static void testCountTotalRefinementValues() {
        List<Map<String, Object>> refinements = new List<Map<String, Object>>();

        Map<String, Object> ref1 = new Map<String, Object>();
        ref1.put('values', new List<String>{'Red', 'Blue'});
        refinements.add(ref1);

        Map<String, Object> ref2 = new Map<String, Object>();
        ref2.put('values', new List<String>{'Small', 'Medium', 'Large'});
        refinements.add(ref2);

        Test.startTest();
        System.assertEquals(5, CategoryProductController.countTotalRefinementValues(refinements), 'Should count 5 total values');
        System.assertEquals(0, CategoryProductController.countTotalRefinementValues(null), 'Should return 0 for null');
        System.assertEquals(0, CategoryProductController.countTotalRefinementValues(new List<Map<String, Object>>()), 'Should return 0 for empty list');
        Test.stopTest();
    }

    @isTest
    static void testGetPricebookEntriesForProducts() {
        List<Product2> products = [SELECT Id FROM Product2];
        Set<String> productIds = new Set<String>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<String, List<CategoryProductController.PricebookEntryInfo>> result =
            CategoryProductController.getPricebookEntriesForProducts(productIds);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should have entries for 2 products');

        for (String productId : result.keySet()) {
            List<CategoryProductController.PricebookEntryInfo> entries = result.get(productId);
            System.assert(entries.size() > 0, 'Should have at least one pricebook entry');
            System.assertNotEquals(null, entries[0].pricebookId, 'Pricebook ID should not be null');
            System.assertNotEquals(null, entries[0].unitPrice, 'Unit price should not be null');
        }
    }

    @isTest
    static void testGetPricebookEntriesForProducts_EmptySet() {
        Set<String> emptySet = new Set<String>();

        Test.startTest();
        Map<String, List<CategoryProductController.PricebookEntryInfo>> result =
            CategoryProductController.getPricebookEntriesForProducts(emptySet);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty map for empty set');
    }

    @isTest
    static void testPricebookEntryInfo_Constructor() {
        String testPricebookId = 'testPB123';
        Decimal testPrice = 99.99;

        Test.startTest();
        CategoryProductController.PricebookEntryInfo info =
            new CategoryProductController.PricebookEntryInfo(testPricebookId, testPrice);
        Test.stopTest();

        System.assertEquals(testPricebookId, info.pricebookId, 'Pricebook ID should match');
        System.assertEquals(testPrice, info.unitPrice, 'Unit price should match');
    }

    @isTest
    static void testGetMockSearchResults() {
        Test.startTest();
        Map<String, Object> mockResults = CategoryProductController.getMockSearchResults();
        Test.stopTest();

        System.assertNotEquals(null, mockResults, 'Mock results should not be null');
        System.assert(mockResults.containsKey('productsPage'), 'Should contain productsPage');

        Map<String, Object> productsPage = (Map<String, Object>) mockResults.get('productsPage');
        System.assertEquals(0, productsPage.get('total'), 'Total should be 0');
    }

    @isTest
    static void testBuildResponse() {
        Object searchResults = new Map<String, Object>();
        Map<String, List<CategoryProductController.PricebookEntryInfo>> pricebookEntries =
            new Map<String, List<CategoryProductController.PricebookEntryInfo>>();

        Test.startTest();
        Map<String, Object> response = CategoryProductController.buildResponse(searchResults, pricebookEntries);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.containsKey('searchResults'), 'Response should contain searchResults');
        System.assert(response.containsKey('pricebookEntries'), 'Response should contain pricebookEntries');
    }
}
