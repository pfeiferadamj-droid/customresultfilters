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
        System.assertEquals(testCategoryId, config.categoryId, 'Category ID should match input');

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
        System.assertEquals(quickTurnCategoryId, config.categoryId, 'Category ID should match Quick Turn');
    }

    @isTest
    static void testGetProductGridConfigMyProducts() {
        // This test uses My Products category
        String myProductsCategoryId = StoreDefaultsHelper.getMyProductsCategoryId();

        Test.startTest();
        ProductGridConfigController.ProductGridConfig config =
            ProductGridConfigController.getProductGridConfig(myProductsCategoryId);
        Test.stopTest();

        // Verify configuration is returned
        System.assertNotEquals(null, config, 'Configuration should not be null');
        System.assertEquals(myProductsCategoryId, config.categoryId, 'Category ID should match My Products');
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
