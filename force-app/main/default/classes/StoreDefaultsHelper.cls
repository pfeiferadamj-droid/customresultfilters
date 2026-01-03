/**
 * Helper class to access B2B Store configuration from Custom Metadata
 * Provides centralized access to all store defaults including category IDs, field names, and settings
 */
public with sharing class StoreDefaultsHelper {

    private static B2B_Store_Defaults__mdt defaults;

    /**
     * Get the store defaults metadata record
     * Cached for performance
     */
    private static B2B_Store_Defaults__mdt getDefaults() {
        if (defaults == null) {
            try {
                defaults = B2B_Store_Defaults__mdt.getInstance('Shop_Defaults');
                if (defaults == null) {
                    System.debug('WARNING: Shop_Defaults custom metadata record not found. Using fallback defaults.');
                    System.debug('Please deploy B2B_Store_Defaults__mdt.Shop_Defaults metadata record.');
                }
            } catch (Exception e) {
                System.debug('ERROR loading Shop_Defaults metadata: ' + e.getMessage());
                System.debug('Using fallback defaults. Please ensure B2B_Store_Defaults__mdt is deployed.');
            }
        }
        return defaults;
    }

    // ===== CATEGORY IDs =====

    public static String getMyProductsCategoryId() {
        return getDefaults().My_Products_Category_ID__c;
    }

    public static String getQuickTurnCategoryId() {
        return getDefaults().Quick_Turn_Category_ID__c;
    }

    // ===== CATEGORY NAMES =====

    public static String getQuickTurnCategoryName() {
        return getDefaults().Quick_Turn_Category_Name__c != null
            ? getDefaults().Quick_Turn_Category_Name__c
            : 'Quick Turn';
    }

    public static String getMyProductsCategoryName() {
        return getDefaults().My_Products_Category_Name__c != null
            ? getDefaults().My_Products_Category_Name__c
            : 'My Products';
    }

    // ===== FIELD API NAMES =====

    public static String getShapeField() {
        return getDefaults().Shape_Field__c != null ? getDefaults().Shape_Field__c : 'Shape__c';
    }

    public static String getProfileField() {
        return getDefaults().Profile_Field__c != null ? getDefaults().Profile_Field__c : 'Profile__c';
    }

    public static String getPanelsField() {
        return getDefaults().Panels_Field__c != null ? getDefaults().Panels_Field__c : 'Panels__c';
    }

    public static String getStructureField() {
        return getDefaults().Structure_Field__c != null ? getDefaults().Structure_Field__c : 'Structure__c';
    }

    public static String getVisorField() {
        return getDefaults().Visor_Field__c != null ? getDefaults().Visor_Field__c : 'Visor__c';
    }

    public static String getEndUserField() {
        return getDefaults().End_User_Field__c != null ? getDefaults().End_User_Field__c : 'End_User__c';
    }

    public static String getRushReadyField() {
        return getDefaults().Rush_Ready_Field__c != null ? getDefaults().Rush_Ready_Field__c : 'Rush_Ready__c';
    }

    public static String getIsParentField() {
        return getDefaults().Is_Parent_Field__c != null ? getDefaults().Is_Parent_Field__c : 'Is_Parent__c';
    }

    public static String getSpecialProgramField() {
        return getDefaults().Special_Program_Field__c != null ? getDefaults().Special_Program_Field__c : 'Special_Program_SAP__c';
    }

    public static String getContactField() {
        return getDefaults().Contact_Field__c != null ? getDefaults().Contact_Field__c : 'Contact__c';
    }

    public static String getAccountField() {
        return getDefaults().Account_Field__c != null ? getDefaults().Account_Field__c : 'Account__c';
    }

    // ===== SPECIAL PROGRAM VALUES =====

    public static String getDriDuckValue() {
        return getDefaults().Dri_Duck_Value__c != null ? getDefaults().Dri_Duck_Value__c : 'QuickTurnDDT';
    }

    public static String getRushReadyValue() {
        return getDefaults().Rush_Ready_Value__c != null ? getDefaults().Rush_Ready_Value__c : 'RushReady';
    }

    public static String getDriDuckLabel() {
        return getDefaults().Dri_Duck_Label__c != null ? getDefaults().Dri_Duck_Label__c : 'Dri-Duck';
    }

    public static String getRushReadyLabel() {
        return getDefaults().Rush_Ready_Label__c != null ? getDefaults().Rush_Ready_Label__c : 'Rush Ready';
    }

    // ===== PRODUCT VALUES =====

    public static String getParentProductValue() {
        return getDefaults().Parent_Product_Value__c != null ? getDefaults().Parent_Product_Value__c : 'Yes';
    }

    public static String getSimpleProductClass() {
        return getDefaults().Simple_Product_Class__c != null ? getDefaults().Simple_Product_Class__c : 'Simple';
    }

    // ===== PAGINATION SETTINGS =====

    public static Integer getDefaultPageSize() {
        return getDefaults().Default_Page_Size__c != null ? getDefaults().Default_Page_Size__c.intValue() : 12;
    }

    public static Integer getQuickTurnPageSize() {
        return getDefaults().Quick_Turn_Page_Size__c != null ? getDefaults().Quick_Turn_Page_Size__c.intValue() : 24;
    }

    public static Integer getFilterValuesLimit() {
        return getDefaults().Filter_Values_Limit__c != null ? getDefaults().Filter_Values_Limit__c.intValue() : 2000;
    }

    // ===== URL SLUGS =====

    public static String getQuickTurnUrlSlug() {
        return getDefaults().Quick_Turn_URL_Slug__c != null ? getDefaults().Quick_Turn_URL_Slug__c : 'quick-turn';
    }

    public static String getMyProductsUrlSlug() {
        return getDefaults().My_Products_URL_Slug__c != null ? getDefaults().My_Products_URL_Slug__c : 'my-products';
    }

    public static String getDetailUrlSlug() {
        return getDefaults().Detail_URL_Slug__c != null ? getDefaults().Detail_URL_Slug__c : 'detail';
    }

    // ===== WEBSTORE & PROFILE CONFIGURATION =====

    public static String getWebStoreId() {
        return getDefaults().WebStoreId__c;
    }

    public static String getGuestBrowserProfileId() {
        return getDefaults().Guest_Browser_Profile_Id__c;
    }

    public static String getShopShopperProfileId() {
        return getDefaults().Shop_Shopper_Profile_ID__c;
    }

    // ===== PRICEBOOK CONFIGURATION =====

    public static String getGuestPricebookId() {
        return getDefaults().GuestPricebookID__c;
    }

    public static String getAuthenticatedPriceBookId() {
        return getDefaults().Authenticated_Price_Book_ID__c;
    }

    // ===== WRAPPER FOR JAVASCRIPT ACCESS =====

    /**
     * Get all store defaults as a wrapper for LWC consumption
     * Exposed as @AuraEnabled for Lightning components
     */
    @AuraEnabled(cacheable=true)
    public static StoreDefaultsWrapper getAllDefaults() {
        StoreDefaultsWrapper wrapper = new StoreDefaultsWrapper();

        // Category IDs
        wrapper.myProductsCategoryId = getMyProductsCategoryId();
        wrapper.quickTurnCategoryId = getQuickTurnCategoryId();

        // Category Names
        wrapper.quickTurnCategoryName = getQuickTurnCategoryName();
        wrapper.myProductsCategoryName = getMyProductsCategoryName();

        // Field API Names
        wrapper.shapeField = getShapeField();
        wrapper.profileField = getProfileField();
        wrapper.panelsField = getPanelsField();
        wrapper.structureField = getStructureField();
        wrapper.visorField = getVisorField();
        wrapper.endUserField = getEndUserField();
        wrapper.rushReadyField = getRushReadyField();
        wrapper.isParentField = getIsParentField();
        wrapper.specialProgramField = getSpecialProgramField();
        wrapper.contactField = getContactField();
        wrapper.accountField = getAccountField();

        // Special Program Values
        wrapper.driDuckValue = getDriDuckValue();
        wrapper.rushReadyValue = getRushReadyValue();
        wrapper.driDuckLabel = getDriDuckLabel();
        wrapper.rushReadyLabel = getRushReadyLabel();

        // Product Values
        wrapper.parentProductValue = getParentProductValue();
        wrapper.simpleProductClass = getSimpleProductClass();

        // Pagination
        wrapper.defaultPageSize = getDefaultPageSize();
        wrapper.quickTurnPageSize = getQuickTurnPageSize();
        wrapper.filterValuesLimit = getFilterValuesLimit();

        // URL Slugs
        wrapper.quickTurnUrlSlug = getQuickTurnUrlSlug();
        wrapper.myProductsUrlSlug = getMyProductsUrlSlug();
        wrapper.detailUrlSlug = getDetailUrlSlug();

        // WebStore & Profile Configuration
        wrapper.webStoreId = getWebStoreId();
        wrapper.guestBrowserProfileId = getGuestBrowserProfileId();
        wrapper.shopShopperProfileId = getShopShopperProfileId();

        // Pricebook Configuration
        wrapper.guestPricebookId = getGuestPricebookId();
        wrapper.authenticatedPriceBookId = getAuthenticatedPriceBookId();

        return wrapper;
    }

    /**
     * Wrapper class for JavaScript consumption
     */
    public class StoreDefaultsWrapper {
        @AuraEnabled public String myProductsCategoryId { get; set; }
        @AuraEnabled public String quickTurnCategoryId { get; set; }
        @AuraEnabled public String quickTurnCategoryName { get; set; }
        @AuraEnabled public String myProductsCategoryName { get; set; }
        @AuraEnabled public String shapeField { get; set; }
        @AuraEnabled public String profileField { get; set; }
        @AuraEnabled public String panelsField { get; set; }
        @AuraEnabled public String structureField { get; set; }
        @AuraEnabled public String visorField { get; set; }
        @AuraEnabled public String endUserField { get; set; }
        @AuraEnabled public String rushReadyField { get; set; }
        @AuraEnabled public String isParentField { get; set; }
        @AuraEnabled public String specialProgramField { get; set; }
        @AuraEnabled public String contactField { get; set; }
        @AuraEnabled public String accountField { get; set; }
        @AuraEnabled public String driDuckValue { get; set; }
        @AuraEnabled public String rushReadyValue { get; set; }
        @AuraEnabled public String driDuckLabel { get; set; }
        @AuraEnabled public String rushReadyLabel { get; set; }
        @AuraEnabled public String parentProductValue { get; set; }
        @AuraEnabled public String simpleProductClass { get; set; }
        @AuraEnabled public Integer defaultPageSize { get; set; }
        @AuraEnabled public Integer quickTurnPageSize { get; set; }
        @AuraEnabled public Integer filterValuesLimit { get; set; }
        @AuraEnabled public String quickTurnUrlSlug { get; set; }
        @AuraEnabled public String myProductsUrlSlug { get; set; }
        @AuraEnabled public String detailUrlSlug { get; set; }
        @AuraEnabled public String webStoreId { get; set; }
        @AuraEnabled public String guestBrowserProfileId { get; set; }
        @AuraEnabled public String shopShopperProfileId { get; set; }
        @AuraEnabled public String guestPricebookId { get; set; }
        @AuraEnabled public String authenticatedPriceBookId { get; set; }
    }

    /**
     * Custom exception for store defaults errors
     */
    public class StoreDefaultsException extends Exception {}
}
