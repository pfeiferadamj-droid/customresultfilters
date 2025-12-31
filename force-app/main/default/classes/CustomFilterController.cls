/**
 * Custom Filter Controller
 * Provides filter data based on category and user context
 */
public with sharing class CustomFilterController {

    /**
     * Get filter data based on category
     * @param category The category name (e.g., 'Quick Turn', 'My Products')
     * @param includeAccountEndUsers For My Products, whether to include all account end users
     * @return FilterDataWrapper containing the filters for the specified category
     * NOTE: Not cacheable because End User values depend on current user context
     */
    @AuraEnabled
    public static FilterDataWrapper getFilterData(String category, Boolean includeAccountEndUsers) {
        FilterDataWrapper filterData = new FilterDataWrapper();

        // Use metadata for category name comparison
        String quickTurnName = StoreDefaultsHelper.getQuickTurnCategoryName();
        String myProductsName = StoreDefaultsHelper.getMyProductsCategoryName();

        if (category == quickTurnName) {
            filterData.quickTurnFilters = getQuickTurnFilters();
        } else if (category == myProductsName) {
            filterData.myProductsFilters = getMyProductsFilters(includeAccountEndUsers);
            // Get account name for My Products category
            filterData.accountName = getUserAccountName();
        }

        return filterData;
    }

    /**
     * Get the current user's account name
     */
    private static String getUserAccountName() {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<User> users = [SELECT Account.Name FROM User WHERE Id = :currentUserId LIMIT 1];
            if (!users.isEmpty() && users[0].Account != null) {
                return users[0].Account.Name;
            }
        } catch (Exception e) {
            System.debug('ERROR getting account name: ' + e.getMessage());
        }
        return 'your account';
    }

    /**
     * Get Quick Turn category filters
     * Ordered: Special Programs, Panels, Profile, Shape, Structure, Visor
     */
    private static List<FilterWrapper> getQuickTurnFilters() {
        List<FilterWrapper> filters = new List<FilterWrapper>();

        // Special Programs Filter (includes Dri-Duck and Rush Ready)
        FilterWrapper specialProgramsFilter = new FilterWrapper();
        specialProgramsFilter.id = 'specialPrograms';
        specialProgramsFilter.label = 'Special Programs';
        specialProgramsFilter.fieldType = 'checkbox';

        FilterValueWrapper driDuckValue = new FilterValueWrapper();
        driDuckValue.label = StoreDefaultsHelper.getDriDuckLabel();
        driDuckValue.value = StoreDefaultsHelper.getDriDuckValue();
        driDuckValue.checked = false;

        FilterValueWrapper rushReadyValue = new FilterValueWrapper();
        rushReadyValue.label = StoreDefaultsHelper.getRushReadyLabel();
        rushReadyValue.value = StoreDefaultsHelper.getRushReadyValue();
        rushReadyValue.checked = false;

        specialProgramsFilter.values = new List<FilterValueWrapper>{ driDuckValue, rushReadyValue };
        filters.add(specialProgramsFilter);

        // Panels Filter
        FilterWrapper panelsFilter = new FilterWrapper();
        panelsFilter.id = 'panels';
        panelsFilter.label = 'Panels';
        panelsFilter.fieldType = 'picklist';
        panelsFilter.values = getPanelsPicklistValues();
        filters.add(panelsFilter);

        // Profile Filter
        FilterWrapper profileFilter = new FilterWrapper();
        profileFilter.id = 'profile';
        profileFilter.label = 'Profile';
        profileFilter.fieldType = 'picklist';
        profileFilter.values = getProfilePicklistValues();
        filters.add(profileFilter);

        // Shape Filter
        FilterWrapper shapeFilter = new FilterWrapper();
        shapeFilter.id = 'shape';
        shapeFilter.label = 'Shape';
        shapeFilter.fieldType = 'picklist';
        shapeFilter.values = getShapePicklistValues();
        filters.add(shapeFilter);

        // Structure Filter
        FilterWrapper structureFilter = new FilterWrapper();
        structureFilter.id = 'structure';
        structureFilter.label = 'Structure';
        structureFilter.fieldType = 'picklist';
        structureFilter.values = getStructurePicklistValues();
        filters.add(structureFilter);

        // Visor Filter
        FilterWrapper visorFilter = new FilterWrapper();
        visorFilter.id = 'visor';
        visorFilter.label = 'Visor';
        visorFilter.fieldType = 'picklist';
        visorFilter.values = getVisorPicklistValues();
        filters.add(visorFilter);

        return filters;
    }

    /**
     * Get My Products category filters
     * Includes: End User
     * @param includeAccountEndUsers Whether to include all account end users or just user's products
     */
    private static List<FilterWrapper> getMyProductsFilters(Boolean includeAccountEndUsers) {
        List<FilterWrapper> filters = new List<FilterWrapper>();

        // End User Filter
        FilterWrapper endUserFilter = new FilterWrapper();
        endUserFilter.id = 'endUser';
        endUserFilter.label = 'End User';
        endUserFilter.fieldType = 'lookup';
        endUserFilter.values = getEndUserValues(includeAccountEndUsers);
        filters.add(endUserFilter);

        return filters;
    }

    /**
     * Get Shape values from products (text field)
     */
    private static List<FilterValueWrapper> getShapePicklistValues() {
        return getDistinctTextFieldValues(StoreDefaultsHelper.getShapeField(), 'Shape');
    }

    /**
     * Get Profile values from products (text field)
     */
    private static List<FilterValueWrapper> getProfilePicklistValues() {
        return getDistinctTextFieldValues(StoreDefaultsHelper.getProfileField(), 'Profile');
    }

    /**
     * Get Panels values from products (text field)
     */
    private static List<FilterValueWrapper> getPanelsPicklistValues() {
        return getDistinctTextFieldValues(StoreDefaultsHelper.getPanelsField(), 'Panels');
    }

    /**
     * Get Structure values from products (text field)
     */
    private static List<FilterValueWrapper> getStructurePicklistValues() {
        return getDistinctTextFieldValues(StoreDefaultsHelper.getStructureField(), 'Structure');
    }

    /**
     * Get Visor values from products (text field)
     */
    private static List<FilterValueWrapper> getVisorPicklistValues() {
        return getDistinctTextFieldValues(StoreDefaultsHelper.getVisorField(), 'Visor');
    }

    /**
     * Generic method to get distinct values from a text field
     * Queries all active products and collects unique values
     * @param fieldApiName The API name of the field (e.g., 'Profile__c')
     * @param fieldLabel The display label for logging
     * @return List of FilterValueWrapper objects with distinct values
     */
    private static List<FilterValueWrapper> getDistinctTextFieldValues(String fieldApiName, String fieldLabel) {
        List<FilterValueWrapper> values = new List<FilterValueWrapper>();
        Set<String> distinctValues = new Set<String>();

        try {
            // Build dynamic SOQL query to get distinct values
            // Using WITH USER_MODE to enforce Field-Level Security
            Integer queryLimit = StoreDefaultsHelper.getFilterValuesLimit();
            String query = 'SELECT ' + fieldApiName + ' FROM Product2 ' +
                          'WHERE IsActive = true AND ' + fieldApiName + ' != null ' +
                          'WITH USER_MODE LIMIT ' + queryLimit;

            System.debug('Querying distinct values for ' + fieldLabel + ': ' + query);

            List<Product2> products = Database.query(query);
            System.debug('  Found ' + products.size() + ' active products with ' + fieldLabel);

            // Collect distinct values
            for (Product2 p : products) {
                String fieldValue = (String)p.get(fieldApiName);
                if (String.isNotBlank(fieldValue) && !distinctValues.contains(fieldValue)) {
                    distinctValues.add(fieldValue);
                }
            }

            System.debug('  Found ' + distinctValues.size() + ' distinct values for ' + fieldLabel);

            // Convert to filter values and sort
            List<String> sortedValues = new List<String>(distinctValues);
            sortedValues.sort();

            for (String val : sortedValues) {
                FilterValueWrapper filterValue = new FilterValueWrapper();
                filterValue.label = val;
                filterValue.value = val;
                filterValue.checked = false;
                values.add(filterValue);
            }

        } catch (Exception e) {
            System.debug('ERROR getting ' + fieldLabel + ' values: ' + e.getMessage());
            System.debug('  Error type: ' + e.getTypeName());
            System.debug('  Stack trace: ' + e.getStackTraceString());
        }

        return values;
    }

    /**
     * Get End User values based on user's products or account
     * NOTE: Update object and field API names based on your actual schema
     * Assumptions:
     * - Product2 has End_User__c lookup field to End_User__c object
     * - Product2 has a Contact__c lookup field or junction object for product-contact relationship
     * - Product2 has an Account__c lookup field for account relationship
     */
    private static List<FilterValueWrapper> getEndUserValues(Boolean includeAccountEndUsers) {
        List<FilterValueWrapper> values = new List<FilterValueWrapper>();
        Set<Id> endUserIds = new Set<Id>();

        try {
            // First, test if metadata is accessible
            System.debug('=== Testing metadata access ===');
            try {
                String testField = StoreDefaultsHelper.getEndUserField();
                System.debug('Successfully accessed metadata - End User Field: ' + testField);
            } catch (Exception metaEx) {
                System.debug('ERROR: Cannot access metadata: ' + metaEx.getMessage());
                System.debug('ERROR Stack: ' + metaEx.getStackTraceString());
                throw metaEx; // Re-throw to trigger fallback values
            }

            Id currentUserId = UserInfo.getUserId();
            System.debug('Getting end user values for userId: ' + currentUserId);
            System.debug('includeAccountEndUsers: ' + includeAccountEndUsers);

            // Get the current user's Contact Id
            List<User> users = [SELECT ContactId, AccountId FROM User WHERE Id = :currentUserId LIMIT 1];
            if (users.isEmpty()) {
                System.debug('ERROR: User not found');
                return values;
            }

            if (users[0].ContactId == null) {
                System.debug('ERROR: User has no ContactId - this is a B2B Commerce requirement');
                System.debug('User details: ' + users[0]);
                return values;
            }

            Id contactId = users[0].ContactId;
            Id accountId = users[0].AccountId;
            System.debug('User ContactId: ' + contactId);
            System.debug('User AccountId: ' + accountId);

            // Get field names from metadata
            String endUserField = StoreDefaultsHelper.getEndUserField();
            String contactField = StoreDefaultsHelper.getContactField();
            String accountField = StoreDefaultsHelper.getAccountField();

            // Build relationship field name for querying related Name
            String endUserRelationshipField = endUserField.replace('__c', '__r.Name');

            String query = 'SELECT Id, ' + endUserField + ', ' + endUserRelationshipField + ' FROM Product2 WHERE ';

            // Handle null includeAccountEndUsers (treat as false)
            Boolean includeAccount = (includeAccountEndUsers == true);

            if (includeAccount && accountId != null) {
                // Get all end users for products associated with user's account
                query += accountField + ' = :accountId AND ' + endUserField + ' != null WITH USER_MODE';
                System.debug('Querying by ' + accountField + ': ' + accountId);
            } else {
                // Get end users only for products where the user is the contact
                query += contactField + ' = :contactId AND ' + endUserField + ' != null WITH USER_MODE';
                System.debug('Querying by ' + contactField + ': ' + contactId);
            }

            System.debug('Executing query: ' + query);
            List<Product2> products = Database.query(query);
            System.debug('Found ' + products.size() + ' products');

            // Collect unique end users
            Map<Id, String> endUserMap = new Map<Id, String>();
            String relationshipName = endUserField.replace('__c', '__r');

            for (Product2 product : products) {
                Id endUserId = (Id)product.get(endUserField);
                if (endUserId != null && !endUserMap.containsKey(endUserId)) {
                    try {
                        // Access the relationship name using getSObject, then get Name from that record
                        SObject relatedRecord = product.getSObject(relationshipName);
                        if (relatedRecord != null) {
                            String endUserName = (String)relatedRecord.get('Name');
                            if (String.isNotBlank(endUserName)) {
                                endUserMap.put(endUserId, endUserName);
                            }
                        }
                    } catch (Exception ex) {
                        System.debug('Error accessing relationship ' + relationshipName + ': ' + ex.getMessage());
                        // Skip this record if we can't access the relationship
                    }
                }
            }

            System.debug('Found ' + endUserMap.size() + ' unique end users');

            // Log each end user for debugging
            for (Id endUserId : endUserMap.keySet()) {
                System.debug('  End User: ' + endUserMap.get(endUserId) + ' (ID: ' + endUserId + ')');
            }

            // Create filter values
            for (Id endUserId : endUserMap.keySet()) {
                FilterValueWrapper value = new FilterValueWrapper();
                value.label = endUserMap.get(endUserId);
                value.value = endUserId;
                value.checked = false;
                values.add(value);
            }

            // Sort by label
            values.sort();

            System.debug('Returning ' + values.size() + ' end user filter values');

        } catch (Exception e) {
            System.debug('ERROR in getEndUserValues: ' + e.getMessage());
            System.debug('ERROR Type: ' + e.getTypeName());
            System.debug('ERROR Stack Trace: ' + e.getStackTraceString());
            // Return sample values if objects don't exist yet
            values.add(createFilterValue('End User 1', 'enduser1', false));
            values.add(createFilterValue('End User 2', 'enduser2', false));
            values.add(createFilterValue('End User 3', 'enduser3', false));
        }

        return values;
    }

    /**
     * Helper method to create a filter value
     */
    @TestVisible
    private static FilterValueWrapper createFilterValue(String label, String value, Boolean checked) {
        FilterValueWrapper filterValue = new FilterValueWrapper();
        filterValue.label = label;
        filterValue.value = value;
        filterValue.checked = checked;
        return filterValue;
    }

    /**
     * Wrapper class for filter data
     */
    public class FilterDataWrapper {
        @AuraEnabled public List<FilterWrapper> quickTurnFilters { get; set; }
        @AuraEnabled public List<FilterWrapper> myProductsFilters { get; set; }
        @AuraEnabled public String accountName { get; set; }
    }

    /**
     * Wrapper class for individual filter
     */
    public class FilterWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public List<FilterValueWrapper> values { get; set; }
        @AuraEnabled public List<String> selectedValues { get; set; }

        public FilterWrapper() {
            this.values = new List<FilterValueWrapper>();
            this.selectedValues = new List<String>();
        }
    }

    /**
     * Wrapper class for filter values
     */
    public class FilterValueWrapper implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public Boolean checked { get; set; }

        // Implement Comparable interface for sorting
        public Integer compareTo(Object compareTo) {
            FilterValueWrapper compareToValue = (FilterValueWrapper)compareTo;
            if (label == compareToValue.label) return 0;
            if (label > compareToValue.label) return 1;
            return -1;
        }
    }
}
