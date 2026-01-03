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

        // Debug logging
        System.debug('ProductGridConfigController - Category ID: ' + categoryId);
        System.debug('ProductGridConfigController - Current Profile: ' + currentProfileId);
        System.debug('ProductGridConfigController - Guest Profile: ' + guestProfileId);
        System.debug('ProductGridConfigController - Shopper Profile: ' + shopperProfileId);
        System.debug('ProductGridConfigController - Quick Turn Category ID from metadata: ' + quickTurnCategoryId);
        System.debug('ProductGridConfigController - My Products Category ID from metadata: ' + myProductsCategoryId);

        // Determine category type by querying ProductCategory if needed
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
        if (matchesId(currentProfileId, guestProfileId) && categoryType == 'QuickTurn') {
            System.debug('ProductGridConfigController - Matched Scenario 1: Guest + Quick Turn');
            config.currentPricebookId = guestPricebookId;
            config.specialPricebookIds = guestPricebookId;
            config.restrictToParents = false;
        }
        // Scenario 2: Shop Shopper in Quick Turn Category
        else if (matchesId(currentProfileId, shopperProfileId) && categoryType == 'QuickTurn') {
            System.debug('ProductGridConfigController - Matched Scenario 2: Shopper + Quick Turn');
            config.currentPricebookId = authenticatedPricebookId;
            config.specialPricebookIds = null;
            config.restrictToParents = false;
        }
        // Scenario 3: Shop Shopper in My Products Category
        else if (matchesId(currentProfileId, shopperProfileId) && categoryType == 'MyProducts') {
            System.debug('ProductGridConfigController - Matched Scenario 3: Shopper + My Products');
            config.categoryName = myProductsCategoryName;
            config.currentPricebookId = null;
            config.specialPricebookIds = null;
            config.restrictToParents = true;
        }
        // Scenario 4: Guest User in My Products Category (fallback)
        else if (matchesId(currentProfileId, guestProfileId) && categoryType == 'MyProducts') {
            System.debug('ProductGridConfigController - Matched Scenario 4: Guest + My Products (fallback)');
            config.categoryName = myProductsCategoryName;
            config.currentPricebookId = guestPricebookId;
            config.specialPricebookIds = guestPricebookId;
            config.restrictToParents = true;
        }
        // Default: Use guest pricebook as safe fallback
        else {
            System.debug('ProductGridConfigController - No scenario matched, using default configuration');
            config.currentPricebookId = null;
            config.specialPricebookIds = null;
            config.restrictToParents = false;
        }

        config.categoryId = categoryId;

        return config;
    }

    /**
     * Helper method to compare Salesforce IDs (handles both 15 and 18 character formats)
     * @param id1 First ID to compare
     * @param id2 Second ID to compare
     * @return Boolean true if IDs match (accounting for 15 vs 18 character difference)
     */
    private static Boolean matchesId(String id1, String id2) {
        if (id1 == null || id2 == null) return false;
        if (id1 == id2) return true;

        // Handle 15 vs 18 character comparison
        // The first 15 characters are the same, the last 3 are checksum in 18-char version
        return id1.startsWith(id2) || id2.startsWith(id1);
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
        // Direct ID match (fastest) - handles 15 vs 18 character IDs
        if (matchesId(categoryId, quickTurnCategoryId)) {
            return 'QuickTurn';
        }
        if (matchesId(categoryId, myProductsCategoryId)) {
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
                System.debug('ProductGridConfigController - Queried category name: ' + categoryName);

                // Match by name (case-insensitive)
                if (categoryName.equalsIgnoreCase(myProductsCategoryName) ||
                    categoryName.containsIgnoreCase('My Products') ||
                    categoryName.containsIgnoreCase('detail')) {
                    System.debug('ProductGridConfigController - Category identified as My Products by name');
                    return 'MyProducts';
                }
                else if (categoryName.equalsIgnoreCase(quickTurnCategoryName) ||
                         categoryName.containsIgnoreCase('Quick Turn') ||
                         categoryName.containsIgnoreCase('Essentials')) {
                    System.debug('ProductGridConfigController - Category identified as Quick Turn by name');
                    return 'QuickTurn';
                }
            }
        } catch (Exception e) {
            System.debug('ProductGridConfigController - Error querying category: ' + e.getMessage());
        }

        System.debug('ProductGridConfigController - Category type could not be determined');
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
