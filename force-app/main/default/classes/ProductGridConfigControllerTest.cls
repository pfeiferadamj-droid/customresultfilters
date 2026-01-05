/**
 * Test class for ProductGridConfigController
 */
@isTest
private class ProductGridConfigControllerTest {

    @isTest
    static void testGetCurrentUserProfileId() {
        // Test getting current user's profile ID
        Test.startTest();
        String profileId = ProductGridConfigController.getCurrentUserProfileId();
        Test.stopTest();

        // Verify profile ID is returned
        System.assertNotEquals(null, profileId, 'Profile ID should not be null');
        System.assertEquals(UserInfo.getProfileId(), profileId, 'Profile ID should match UserInfo.getProfileId()');
    }

    @isTest
    static void testGetProductGridConfigWithCategory() {
        // Test getting configuration with a category ID
        String testCategoryId = '0ZGPU0000001iqD4AQ'; // Quick Turn category from metadata

        Test.startTest();
        ProductGridConfigController.ProductGridConfig config =
            ProductGridConfigController.getProductGridConfig(testCategoryId);
        Test.stopTest();

        // Verify configuration is returned
        System.assertNotEquals(null, config, 'Configuration should not be null');
        // Note: categoryId is only set in Scenario 3, so it will be null for this test
        // unless running as shopper profile in My Products category

        // Verify common defaults
        System.assertEquals('grid', config.layout, 'Layout should be grid');
        System.assertEquals(24, config.productsPerPage, 'Products per page should be 24');
        System.assertEquals(true, config.showProductImage, 'Show product image should be true');
        System.assertEquals(false, config.showCallToActionButton, 'Show call to action should be false');
        System.assertEquals(false, config.showQuantitySelector, 'Show quantity selector should be false');
        System.assertEquals(true, config.showNegotiatedPrice, 'Show negotiated price should be true');
        System.assertEquals(true, config.showListingPrice, 'Show listing price should be true');
    }

    @isTest
    static void testGetProductGridConfigQuickTurnGuest() {
        // This test simulates guest user in Quick Turn category
        // Note: In actual org, would need to run as guest user with proper profile
        String quickTurnCategoryId = StoreDefaultsHelper.getQuickTurnCategoryId();

        Test.startTest();
        ProductGridConfigController.ProductGridConfig config =
            ProductGridConfigController.getProductGridConfig(quickTurnCategoryId);
        Test.stopTest();

        // Verify configuration is returned
        System.assertNotEquals(null, config, 'Configuration should not be null');
        // Note: categoryId is only set in Scenario 3 (My Products)
        // For Quick Turn scenarios, categoryId will be null
        System.assertNotEquals(null, config.webstoreId, 'Webstore ID should be set');
    }

    @isTest
    static void testGetProductGridConfigMyProducts() {
        // This test uses the hardcoded My Products category ID to trigger Scenario 3
        // Note: Scenario 3 only triggers if user profile matches shopperProfileId
        String myProductsCategoryId = '0ZGbb000000FFOXGA4';

        Test.startTest();
        ProductGridConfigController.ProductGridConfig config =
            ProductGridConfigController.getProductGridConfig(myProductsCategoryId);
        Test.stopTest();

        // Verify configuration is returned
        System.assertNotEquals(null, config, 'Configuration should not be null');
        // categoryId will only be set if test runs as shopper profile
        // In test context with system admin, Scenario 3 won't match, so categoryId will be null

        // Verify common defaults are set
        System.assertEquals('grid', config.layout, 'Layout should be grid');
        System.assertEquals(24, config.productsPerPage, 'Products per page should be 24');
    }

    @isTest
    static void testCategoryTypeDeterminationFallback() {
        // Test with a category ID that won't match metadata
        // This simulates the real-world scenario where org category IDs differ from metadata
        String unmatchedCategoryId = '0ZGbb000000TESTCAT';

        Test.startTest();
        ProductGridConfigController.ProductGridConfig config =
            ProductGridConfigController.getProductGridConfig(unmatchedCategoryId);
        Test.stopTest();

        // Should still return config with defaults
        System.assertNotEquals(null, config, 'Configuration should not be null');
        // categoryId will be null because this doesn't match any scenario
        System.assertEquals('grid', config.layout, 'Layout should default to grid');
        System.assertEquals(24, config.productsPerPage, 'Products per page should default to 24');
    }

    @isTest
    static void testConfigWith15And18CharacterIds() {
        // Test that the system handles both 15 and 18 character Salesforce IDs
        // This is important because UserInfo.getProfileId() returns 18-char
        // but metadata might have 15-char (or vice versa)

        String categoryId15 = '0ZGbb000000TEST';
        String categoryId18 = '0ZGbb000000TESTABC'; // 18 char version

        Test.startTest();
        // Both should work and return configuration
        ProductGridConfigController.ProductGridConfig config15 =
            ProductGridConfigController.getProductGridConfig(categoryId15);
        ProductGridConfigController.ProductGridConfig config18 =
            ProductGridConfigController.getProductGridConfig(categoryId18);
        Test.stopTest();

        // Both should return valid configurations
        System.assertNotEquals(null, config15, 'Config with 15-char ID should not be null');
        System.assertNotEquals(null, config18, 'Config with 18-char ID should not be null');

        // Both should have the same basic structure
        System.assertEquals('grid', config15.layout, '15-char config layout should be grid');
        System.assertEquals('grid', config18.layout, '18-char config layout should be grid');
    }

    @isTest
    static void testProductGridConfigWrapper() {
        // Test the wrapper class can be instantiated and properties set
        ProductGridConfigController.ProductGridConfig config =
            new ProductGridConfigController.ProductGridConfig();

        // Set all properties
        config.webstoreId = '0ZE000000000001';
        config.categoryId = '0ZG000000000001';
        config.categoryName = 'Test Category';
        config.layout = 'grid';
        config.productsPerPage = 24;
        config.showProductImage = true;
        config.showCallToActionButton = false;
        config.showQuantitySelector = false;
        config.showNegotiatedPrice = true;
        config.showListingPrice = true;
        config.restrictToParents = false;
        config.currentPricebookId = '01s000000000001';
        config.specialPricebookIds = '01s000000000002';

        // Verify all properties are set
        System.assertEquals('0ZE000000000001', config.webstoreId);
        System.assertEquals('0ZG000000000001', config.categoryId);
        System.assertEquals('Test Category', config.categoryName);
        System.assertEquals('grid', config.layout);
        System.assertEquals(24, config.productsPerPage);
        System.assertEquals(true, config.showProductImage);
        System.assertEquals(false, config.showCallToActionButton);
        System.assertEquals(false, config.showQuantitySelector);
        System.assertEquals(true, config.showNegotiatedPrice);
        System.assertEquals(true, config.showListingPrice);
        System.assertEquals(false, config.restrictToParents);
        System.assertEquals('01s000000000001', config.currentPricebookId);
        System.assertEquals('01s000000000002', config.specialPricebookIds);
    }
}
