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
        String quickTurnCategoryName = StoreDefaultsHelper.getQuickTurnCategoryName();

        // Determine category type with fallback name matching
        String categoryType = determineCategoryType(categoryId, quickTurnCategoryId, myProductsCategoryId,
                                                     quickTurnCategoryName, myProductsCategoryName);

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
        if (currentProfileId == guestProfileId && categoryType == 'QuickTurn') {
            config.currentPricebookId = guestPricebookId;
            config.specialPricebookIds = guestPricebookId;
            config.restrictToParents = false;
        }
        // Scenario 2: Shop Shopper in Quick Turn Category
        else if (currentProfileId == shopperProfileId && categoryType == 'QuickTurn') {
            config.currentPricebookId = authenticatedPricebookId;
            config.specialPricebookIds = null;
            config.restrictToParents = false;
        }
        // Scenario 3: Shop Shopper in My Products Category
        else if (currentProfileId == shopperProfileId && categoryType == 'MyProducts') {
            config.categoryId = categoryId;
            config.categoryName = myProductsCategoryName;
            config.currentPricebookId = authenticatedPricebookId;
            config.specialPricebookIds = null;
            config.restrictToParents = true;
        }
        // Scenario 4: Guest User in My Products Category
        else if (currentProfileId == guestProfileId && categoryType == 'MyProducts') {
            config.categoryId = categoryId;
            config.categoryName = myProductsCategoryName;
            config.currentPricebookId = guestPricebookId;
            config.specialPricebookIds = null;  // No 'c' suffix for My Products
            config.restrictToParents = true;
        }
        // Default: Other categories use profile-appropriate pricebook
        else {
            if (currentProfileId == guestProfileId) {
                config.currentPricebookId = guestPricebookId;
                config.specialPricebookIds = null;
            } else {
                config.currentPricebookId = authenticatedPricebookId;
                config.specialPricebookIds = null;
            }
            config.restrictToParents = false;
        }

        return config;
    }

    /**
     * Determine category type by comparing IDs or querying category name
     * @param categoryId The category ID from URL
     * @param quickTurnCategoryId Quick Turn category ID from metadata
     * @param myProductsCategoryId My Products category ID from metadata
     * @param quickTurnCategoryName Quick Turn category name from metadata
     * @param myProductsCategoryName My Products category name from metadata
     * @return String 'QuickTurn', 'MyProducts', or 'Unknown'
     */
    private static String determineCategoryType(String categoryId, String quickTurnCategoryId,
                                                  String myProductsCategoryId, String quickTurnCategoryName,
                                                  String myProductsCategoryName) {
        // Direct ID match (fastest)
        if (categoryId == quickTurnCategoryId) {
            return 'QuickTurn';
        }
        if (categoryId == myProductsCategoryId) {
            return 'MyProducts';
        }

        // Fallback: Query category name to determine type
        try {
            List<ProductCategory> categories = [
                SELECT Name
                FROM ProductCategory
                WHERE Id = :categoryId
                LIMIT 1
            ];

            if (!categories.isEmpty()) {
                String categoryName = categories[0].Name;

                // Match by name (case-insensitive)
                if (categoryName.equalsIgnoreCase(myProductsCategoryName) ||
                    categoryName.containsIgnoreCase('My Products') ||
                    categoryName.containsIgnoreCase('detail')) {
                    return 'MyProducts';
                }
                else if (categoryName.equalsIgnoreCase(quickTurnCategoryName) ||
                         categoryName.containsIgnoreCase('Quick Turn') ||
                         categoryName.containsIgnoreCase('Essentials')) {
                    return 'QuickTurn';
                }
            }
        } catch (Exception e) {
            System.debug('ProductGridConfigController - Error querying category: ' + e.getMessage());
        }

        return 'Unknown';
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


