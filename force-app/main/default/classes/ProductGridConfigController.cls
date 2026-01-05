/**
 * Controller for automated product grid configuration
 * Determines grid settings based on user profile and category
 */
public with sharing class ProductGridConfigController {

    /**
     * Get the current user's profile ID
     */
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfileId() {
        return UserInfo.getProfileId();
    }

    /**
     * Get configuration for the product grid based on user profile and category
     * @param categoryId The current category ID
     * @return ProductGridConfig Configuration wrapper with all settings
     */
    @AuraEnabled(cacheable=true)
    public static ProductGridConfig getProductGridConfig(String categoryId) {
        ProductGridConfig config = new ProductGridConfig();

        // Get current user's profile ID
        String currentProfileId = UserInfo.getProfileId();

        // Get configuration from metadata
        String webStoreId = StoreDefaultsHelper.getWebStoreId();
        String guestProfileId = StoreDefaultsHelper.getGuestBrowserProfileId();
        String shopperProfileId = StoreDefaultsHelper.getShopShopperProfileId();
        String quickTurnCategoryId = StoreDefaultsHelper.getQuickTurnCategoryId();
        String myProductsCategoryId = StoreDefaultsHelper.getMyProductsCategoryId();
        String guestPricebookId = StoreDefaultsHelper.getGuestPricebookId();
        String authenticatedPricebookId = StoreDefaultsHelper.getAuthenticatedPriceBookId();
        String myProductsCategoryName = StoreDefaultsHelper.getMyProductsCategoryName();

        // Set common defaults
        config.webstoreId = webStoreId;
        config.layout = 'grid';
        config.productsPerPage = 24;
        config.showProductImage = true;
        config.showCallToActionButton = false;
        config.showQuantitySelector = false;
        config.showNegotiatedPrice = true;
        config.showListingPrice = true;

        // Scenario 1: Guest User in Quick Turn Category
        if (currentProfileId == guestProfileId && categoryId == quickTurnCategoryId) {
            config.currentPricebookId = guestPricebookId;
            config.specialPricebookIds = guestPricebookId;
            config.restrictToParents = false;
        }
        // Scenario 2: Shop Shopper in Quick Turn Category
        else if (currentProfileId == shopperProfileId && categoryId == quickTurnCategoryId) {
            config.currentPricebookId = authenticatedPricebookId;
            config.specialPricebookIds = null;
            config.restrictToParents = false;
        }
        // Scenario 3: Shop Shopper in My Products Category
        else if (currentProfileId == shopperProfileId && categoryId == myProductsCategoryId) {
            config.categoryId = myProductsCategoryId;
            config.categoryName = myProductsCategoryName;
            config.currentPricebookId = null;
            config.specialPricebookIds = null;
            config.restrictToParents = true;
        }

        // config.categoryId = categoryId;

        return config;
    }

    /**
     * Wrapper class for product grid configuration
     */
    public class ProductGridConfig {
        @AuraEnabled public String webstoreId { get; set; }
        @AuraEnabled public String categoryId { get; set; }
        @AuraEnabled public String categoryName { get; set; }
        @AuraEnabled public String layout { get; set; }
        @AuraEnabled public Integer productsPerPage { get; set; }
        @AuraEnabled public Boolean showProductImage { get; set; }
        @AuraEnabled public Boolean showCallToActionButton { get; set; }
        @AuraEnabled public Boolean showQuantitySelector { get; set; }
        @AuraEnabled public Boolean showNegotiatedPrice { get; set; }
        @AuraEnabled public Boolean showListingPrice { get; set; }
        @AuraEnabled public Boolean restrictToParents { get; set; }
        @AuraEnabled public String currentPricebookId { get; set; }
        @AuraEnabled public String specialPricebookIds { get; set; }
    }
}
