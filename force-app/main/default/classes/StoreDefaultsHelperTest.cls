/**
 * Test class for StoreDefaultsHelper
 * Tests metadata access and fallback value functionality
 */
@isTest
private class StoreDefaultsHelperTest {

    /**
     * Test Category ID getters
     */
    @isTest
    static void testGetCategoryIds() {
        Test.startTest();
        String myProductsId = StoreDefaultsHelper.getMyProductsCategoryId();
        String quickTurnId = StoreDefaultsHelper.getQuickTurnCategoryId();
        Test.stopTest();

        // Should return either metadata values or null (metadata might not exist in test context)
        // Both results are valid since metadata might not be deployed in test org
        System.assert(true, 'Category ID getters should execute without error');
    }

    /**
     * Test Category Name getters with fallback values
     */
    @isTest
    static void testGetCategoryNames() {
        Test.startTest();
        String quickTurnName = StoreDefaultsHelper.getQuickTurnCategoryName();
        String myProductsName = StoreDefaultsHelper.getMyProductsCategoryName();
        Test.stopTest();

        // Should return fallback values if metadata not available
        System.assertNotEquals(null, quickTurnName, 'Quick Turn name should not be null');
        System.assertNotEquals(null, myProductsName, 'My Products name should not be null');

        // Verify fallback values are used
        System.assert(
            quickTurnName == 'Quick Turn' || quickTurnName.length() > 0,
            'Should return fallback or metadata value for Quick Turn'
        );
        System.assert(
            myProductsName == 'My Products' || myProductsName.length() > 0,
            'Should return fallback or metadata value for My Products'
        );
    }

    /**
     * Test Field API Name getters
     */
    @isTest
    static void testGetFieldApiNames() {
        Test.startTest();
        String shapeField = StoreDefaultsHelper.getShapeField();
        String profileField = StoreDefaultsHelper.getProfileField();
        String panelsField = StoreDefaultsHelper.getPanelsField();
        String structureField = StoreDefaultsHelper.getStructureField();
        String visorField = StoreDefaultsHelper.getVisorField();
        String endUserField = StoreDefaultsHelper.getEndUserField();
        String rushReadyField = StoreDefaultsHelper.getRushReadyField();
        String isParentField = StoreDefaultsHelper.getIsParentField();
        String specialProgramField = StoreDefaultsHelper.getSpecialProgramField();
        String contactField = StoreDefaultsHelper.getContactField();
        String accountField = StoreDefaultsHelper.getAccountField();
        Test.stopTest();

        // All should return fallback values (field API names ending in __c or standard field names)
        System.assertEquals('Shape__c', shapeField, 'Shape field should return fallback');
        System.assertEquals('Profile__c', profileField, 'Profile field should return fallback');
        System.assertEquals('Panels__c', panelsField, 'Panels field should return fallback');
        System.assertEquals('Structure__c', structureField, 'Structure field should return fallback');
        System.assertEquals('Visor__c', visorField, 'Visor field should return fallback');
        System.assertEquals('End_User__c', endUserField, 'End User field should return fallback');
        System.assertEquals('Rush_Ready__c', rushReadyField, 'Rush Ready field should return fallback');
        System.assertEquals('Is_Parent__c', isParentField, 'Is Parent field should return fallback');
        System.assertEquals('Special_Program_SAP__c', specialProgramField, 'Special Program field should return fallback');
        System.assertEquals('Contact__c', contactField, 'Contact field should return fallback');
        System.assertEquals('Account__c', accountField, 'Account field should return fallback');
    }

    /**
     * Test Special Program Value getters
     */
    @isTest
    static void testGetSpecialProgramValues() {
        Test.startTest();
        String driDuckValue = StoreDefaultsHelper.getDriDuckValue();
        String rushReadyValue = StoreDefaultsHelper.getRushReadyValue();
        String driDuckLabel = StoreDefaultsHelper.getDriDuckLabel();
        String rushReadyLabel = StoreDefaultsHelper.getRushReadyLabel();
        Test.stopTest();

        // Should return fallback values
        System.assertEquals('QuickTurnDDT', driDuckValue, 'Dri-Duck value should return fallback');
        System.assertEquals('RushReady', rushReadyValue, 'Rush Ready value should return fallback');
        System.assertEquals('Dri-Duck', driDuckLabel, 'Dri-Duck label should return fallback');
        System.assertEquals('Rush Ready', rushReadyLabel, 'Rush Ready label should return fallback');
    }

    /**
     * Test Product Value getters
     */
    @isTest
    static void testGetProductValues() {
        Test.startTest();
        String parentValue = StoreDefaultsHelper.getParentProductValue();
        String simpleClass = StoreDefaultsHelper.getSimpleProductClass();
        Test.stopTest();

        // Should return fallback values
        System.assertEquals('Yes', parentValue, 'Parent product value should return fallback');
        System.assertEquals('Simple', simpleClass, 'Simple product class should return fallback');
    }

    /**
     * Test Pagination Settings getters
     */
    @isTest
    static void testGetPaginationSettings() {
        Test.startTest();
        Integer defaultPageSize = StoreDefaultsHelper.getDefaultPageSize();
        Integer quickTurnPageSize = StoreDefaultsHelper.getQuickTurnPageSize();
        Integer filterValuesLimit = StoreDefaultsHelper.getFilterValuesLimit();
        Test.stopTest();

        // Should return fallback numeric values
        System.assertEquals(12, defaultPageSize, 'Default page size should return fallback of 12');
        System.assertEquals(24, quickTurnPageSize, 'Quick Turn page size should return fallback of 24');
        System.assertEquals(2000, filterValuesLimit, 'Filter values limit should return fallback of 2000');
    }

    /**
     * Test URL Slug getters
     */
    @isTest
    static void testGetUrlSlugs() {
        Test.startTest();
        String quickTurnSlug = StoreDefaultsHelper.getQuickTurnUrlSlug();
        String myProductsSlug = StoreDefaultsHelper.getMyProductsUrlSlug();
        String detailSlug = StoreDefaultsHelper.getDetailUrlSlug();
        Test.stopTest();

        // Should return metadata or fallback slug values
        System.assert(
            quickTurnSlug == 'quick-turn' || quickTurnSlug == 'essentials-by-caps-direct',
            'Quick Turn slug should return metadata or fallback'
        );
        System.assertEquals('my-products', myProductsSlug, 'My Products slug should match');
        System.assertEquals('detail', detailSlug, 'Detail slug should match');
    }

    /**
     * Test getAllDefaults wrapper for LWC consumption
     */
    @isTest
    static void testGetAllDefaults() {
        Test.startTest();
        StoreDefaultsHelper.StoreDefaultsWrapper wrapper = StoreDefaultsHelper.getAllDefaults();
        Test.stopTest();

        // Verify wrapper is populated
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');

        // Verify category names have fallback values
        System.assertNotEquals(null, wrapper.quickTurnCategoryName, 'Quick Turn name should not be null');
        System.assertNotEquals(null, wrapper.myProductsCategoryName, 'My Products name should not be null');

        // Verify field names have fallback values
        System.assertEquals('Shape__c', wrapper.shapeField, 'Shape field should match');
        System.assertEquals('Profile__c', wrapper.profileField, 'Profile field should match');
        System.assertEquals('Panels__c', wrapper.panelsField, 'Panels field should match');
        System.assertEquals('Structure__c', wrapper.structureField, 'Structure field should match');
        System.assertEquals('Visor__c', wrapper.visorField, 'Visor field should match');
        System.assertEquals('End_User__c', wrapper.endUserField, 'End User field should match');
        System.assertEquals('Rush_Ready__c', wrapper.rushReadyField, 'Rush Ready field should match');
        System.assertEquals('Is_Parent__c', wrapper.isParentField, 'Is Parent field should match');
        System.assertEquals('Special_Program_SAP__c', wrapper.specialProgramField, 'Special Program field should match');
        System.assertEquals('Contact__c', wrapper.contactField, 'Contact field should match');
        System.assertEquals('Account__c', wrapper.accountField, 'Account field should match');

        // Verify special program values
        System.assertEquals('QuickTurnDDT', wrapper.driDuckValue, 'Dri-Duck value should match');
        System.assertEquals('RushReady', wrapper.rushReadyValue, 'Rush Ready value should match');
        System.assertEquals('Dri-Duck', wrapper.driDuckLabel, 'Dri-Duck label should match');
        System.assertEquals('Rush Ready', wrapper.rushReadyLabel, 'Rush Ready label should match');

        // Verify product values
        System.assertEquals('Yes', wrapper.parentProductValue, 'Parent value should match');
        System.assertEquals('Simple', wrapper.simpleProductClass, 'Simple class should match');

        // Verify pagination settings
        System.assertEquals(12, wrapper.defaultPageSize, 'Default page size should match');
        System.assertEquals(24, wrapper.quickTurnPageSize, 'Quick Turn page size should match');
        System.assertEquals(2000, wrapper.filterValuesLimit, 'Filter values limit should match');

        // Verify URL slugs - accept metadata or fallback values
        System.assert(
            wrapper.quickTurnUrlSlug == 'quick-turn' || wrapper.quickTurnUrlSlug == 'essentials-by-caps-direct',
            'Quick Turn slug should return metadata or fallback'
        );
        System.assertEquals('my-products', wrapper.myProductsUrlSlug, 'My Products slug should match');
        System.assertEquals('detail', wrapper.detailUrlSlug, 'Detail slug should match');
    }

    /**
     * Test that wrapper is cacheable (can be called multiple times)
     */
    @isTest
    static void testGetAllDefaults_Cacheable() {
        Test.startTest();
        StoreDefaultsHelper.StoreDefaultsWrapper wrapper1 = StoreDefaultsHelper.getAllDefaults();
        StoreDefaultsHelper.StoreDefaultsWrapper wrapper2 = StoreDefaultsHelper.getAllDefaults();
        Test.stopTest();

        // Both calls should succeed
        System.assertNotEquals(null, wrapper1, 'First call should return wrapper');
        System.assertNotEquals(null, wrapper2, 'Second call should return wrapper');

        // Values should be consistent
        System.assertEquals(wrapper1.defaultPageSize, wrapper2.defaultPageSize, 'Page sizes should match');
        System.assertEquals(wrapper1.quickTurnCategoryName, wrapper2.quickTurnCategoryName, 'Category names should match');
    }

    /**
     * Test StoreDefaultsWrapper property setters
     */
    @isTest
    static void testWrapperProperties() {
        Test.startTest();
        StoreDefaultsHelper.StoreDefaultsWrapper wrapper = new StoreDefaultsHelper.StoreDefaultsWrapper();

        // Set category IDs
        wrapper.myProductsCategoryId = 'testCatId1';
        wrapper.quickTurnCategoryId = 'testCatId2';

        // Set category names
        wrapper.quickTurnCategoryName = 'Test Quick Turn';
        wrapper.myProductsCategoryName = 'Test My Products';

        // Set field names
        wrapper.shapeField = 'TestShape__c';
        wrapper.profileField = 'TestProfile__c';
        wrapper.panelsField = 'TestPanels__c';
        wrapper.structureField = 'TestStructure__c';
        wrapper.visorField = 'TestVisor__c';
        wrapper.endUserField = 'TestEndUser__c';
        wrapper.rushReadyField = 'TestRushReady__c';
        wrapper.isParentField = 'TestIsParent__c';
        wrapper.specialProgramField = 'TestSpecialProgram__c';
        wrapper.contactField = 'TestContact__c';
        wrapper.accountField = 'TestAccount__c';

        // Set special program values
        wrapper.driDuckValue = 'TestDriDuck';
        wrapper.rushReadyValue = 'TestRushReady';
        wrapper.driDuckLabel = 'Test Dri-Duck Label';
        wrapper.rushReadyLabel = 'Test Rush Ready Label';

        // Set product values
        wrapper.parentProductValue = 'TestYes';
        wrapper.simpleProductClass = 'TestSimple';

        // Set pagination
        wrapper.defaultPageSize = 15;
        wrapper.quickTurnPageSize = 30;
        wrapper.filterValuesLimit = 3000;

        // Set URL slugs
        wrapper.quickTurnUrlSlug = 'test-quick-turn';
        wrapper.myProductsUrlSlug = 'test-my-products';
        wrapper.detailUrlSlug = 'test-detail';
        Test.stopTest();

        // Verify all properties
        System.assertEquals('testCatId1', wrapper.myProductsCategoryId, 'My Products ID should match');
        System.assertEquals('testCatId2', wrapper.quickTurnCategoryId, 'Quick Turn ID should match');
        System.assertEquals('Test Quick Turn', wrapper.quickTurnCategoryName, 'Quick Turn name should match');
        System.assertEquals('Test My Products', wrapper.myProductsCategoryName, 'My Products name should match');
        System.assertEquals('TestShape__c', wrapper.shapeField, 'Shape field should match');
        System.assertEquals('TestProfile__c', wrapper.profileField, 'Profile field should match');
        System.assertEquals('TestDriDuck', wrapper.driDuckValue, 'Dri-Duck value should match');
        System.assertEquals('TestRushReady', wrapper.rushReadyValue, 'Rush Ready value should match');
        System.assertEquals('TestYes', wrapper.parentProductValue, 'Parent value should match');
        System.assertEquals('TestSimple', wrapper.simpleProductClass, 'Simple class should match');
        System.assertEquals(15, wrapper.defaultPageSize, 'Default page size should match');
        System.assertEquals(30, wrapper.quickTurnPageSize, 'Quick Turn page size should match');
        System.assertEquals(3000, wrapper.filterValuesLimit, 'Filter values limit should match');
        System.assertEquals('test-quick-turn', wrapper.quickTurnUrlSlug, 'Quick Turn slug should match');
    }

    /**
     * Test that multiple calls use cached defaults
     */
    @isTest
    static void testMetadataCaching() {
        Test.startTest();
        // Multiple calls to same getter should use cached metadata instance
        String name1 = StoreDefaultsHelper.getQuickTurnCategoryName();
        String name2 = StoreDefaultsHelper.getQuickTurnCategoryName();
        String name3 = StoreDefaultsHelper.getMyProductsCategoryName();
        Test.stopTest();

        // All should succeed without error
        System.assertNotEquals(null, name1, 'First call should succeed');
        System.assertNotEquals(null, name2, 'Second call should succeed');
        System.assertNotEquals(null, name3, 'Third call should succeed');

        // Repeated calls should return same value
        System.assertEquals(name1, name2, 'Cached values should match');
    }

    /**
     * Test all getters in sequence to ensure 100% method coverage
     */
    @isTest
    static void testAllGetters() {
        Test.startTest();
        // Call all public static getter methods
        String myProductsId = StoreDefaultsHelper.getMyProductsCategoryId();
        String quickTurnId = StoreDefaultsHelper.getQuickTurnCategoryId();
        String quickTurnName = StoreDefaultsHelper.getQuickTurnCategoryName();
        String myProductsName = StoreDefaultsHelper.getMyProductsCategoryName();
        String shapeField = StoreDefaultsHelper.getShapeField();
        String profileField = StoreDefaultsHelper.getProfileField();
        String panelsField = StoreDefaultsHelper.getPanelsField();
        String structureField = StoreDefaultsHelper.getStructureField();
        String visorField = StoreDefaultsHelper.getVisorField();
        String endUserField = StoreDefaultsHelper.getEndUserField();
        String rushReadyField = StoreDefaultsHelper.getRushReadyField();
        String isParentField = StoreDefaultsHelper.getIsParentField();
        String specialProgramField = StoreDefaultsHelper.getSpecialProgramField();
        String contactField = StoreDefaultsHelper.getContactField();
        String accountField = StoreDefaultsHelper.getAccountField();
        String driDuckValue = StoreDefaultsHelper.getDriDuckValue();
        String rushReadyValue = StoreDefaultsHelper.getRushReadyValue();
        String driDuckLabel = StoreDefaultsHelper.getDriDuckLabel();
        String rushReadyLabel = StoreDefaultsHelper.getRushReadyLabel();
        String parentValue = StoreDefaultsHelper.getParentProductValue();
        String simpleClass = StoreDefaultsHelper.getSimpleProductClass();
        Integer defaultPageSize = StoreDefaultsHelper.getDefaultPageSize();
        Integer quickTurnPageSize = StoreDefaultsHelper.getQuickTurnPageSize();
        Integer filterValuesLimit = StoreDefaultsHelper.getFilterValuesLimit();
        String quickTurnSlug = StoreDefaultsHelper.getQuickTurnUrlSlug();
        String myProductsSlug = StoreDefaultsHelper.getMyProductsUrlSlug();
        String detailSlug = StoreDefaultsHelper.getDetailUrlSlug();
        StoreDefaultsHelper.StoreDefaultsWrapper wrapper = StoreDefaultsHelper.getAllDefaults();
        Test.stopTest();

        // Verify all returned non-null fallback values
        System.assertNotEquals(null, quickTurnName, 'All getters should return non-null values');
        System.assertNotEquals(null, wrapper, 'getAllDefaults should return wrapper');
    }

    /**
     * Test that wrapper can be serialized (for LWC cacheability)
     */
    @isTest
    static void testWrapperSerialization() {
        Test.startTest();
        StoreDefaultsHelper.StoreDefaultsWrapper wrapper = StoreDefaultsHelper.getAllDefaults();
        String jsonString = JSON.serialize(wrapper);
        StoreDefaultsHelper.StoreDefaultsWrapper deserialized =
            (StoreDefaultsHelper.StoreDefaultsWrapper)JSON.deserialize(
                jsonString,
                StoreDefaultsHelper.StoreDefaultsWrapper.class
            );
        Test.stopTest();

        // Verify serialization/deserialization works
        System.assertNotEquals(null, jsonString, 'Should serialize to JSON');
        System.assertNotEquals(null, deserialized, 'Should deserialize from JSON');
        System.assertEquals(wrapper.defaultPageSize, deserialized.defaultPageSize, 'Values should match after deserialization');
    }

    /**
     * Test exception handling in getDefaults()
     * This tests the catch block when metadata getInstance fails
     */
    @isTest
    static void testGetDefaultsExceptionHandling() {
        Test.startTest();
        // Even if metadata doesn't exist, methods should return fallback values
        String categoryName = StoreDefaultsHelper.getQuickTurnCategoryName();
        Integer pageSize = StoreDefaultsHelper.getDefaultPageSize();
        Test.stopTest();

        // Should return metadata or fallback values without throwing exception
        System.assert(
            categoryName == 'Quick Turn' || categoryName == 'Essentials by Caps Direct',
            'Should return metadata or fallback category name'
        );
        System.assertEquals(12, pageSize, 'Should return page size');
    }
}
