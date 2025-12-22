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

        if (category == 'Quick Turn') {
            filterData.quickTurnFilters = getQuickTurnFilters();
        } else if (category == 'My Products') {
            filterData.myProductsFilters = getMyProductsFilters(includeAccountEndUsers);
        }

        return filterData;
    }

    /**
     * Get Quick Turn category filters
     * Includes: Product Code, Shape, Profile, Panels, Structure, Visor, Rush Ready
     */
    private static List<FilterWrapper> getQuickTurnFilters() {
        List<FilterWrapper> filters = new List<FilterWrapper>();

        // Product Code Filter
        FilterWrapper productCodeFilter = new FilterWrapper();
        productCodeFilter.id = 'productCode';
        productCodeFilter.label = 'Product Code';
        productCodeFilter.fieldType = 'text';
        productCodeFilter.values = new List<FilterValueWrapper>();
        filters.add(productCodeFilter);

        // Shape Filter
        FilterWrapper shapeFilter = new FilterWrapper();
        shapeFilter.id = 'shape';
        shapeFilter.label = 'Shape';
        shapeFilter.fieldType = 'picklist';
        shapeFilter.values = getShapePicklistValues();
        filters.add(shapeFilter);

        // Profile Filter
        FilterWrapper profileFilter = new FilterWrapper();
        profileFilter.id = 'profile';
        profileFilter.label = 'Profile';
        profileFilter.fieldType = 'picklist';
        profileFilter.values = getProfilePicklistValues();
        filters.add(profileFilter);

        // Panels Filter
        FilterWrapper panelsFilter = new FilterWrapper();
        panelsFilter.id = 'panels';
        panelsFilter.label = 'Panels';
        panelsFilter.fieldType = 'picklist';
        panelsFilter.values = getPanelsPicklistValues();
        filters.add(panelsFilter);

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

        // Rush Ready Filter (Checkbox)
        FilterWrapper rushReadyFilter = new FilterWrapper();
        rushReadyFilter.id = 'rushReady';
        rushReadyFilter.label = 'Rush Ready';
        rushReadyFilter.fieldType = 'checkbox';

        FilterValueWrapper rushReadyValue = new FilterValueWrapper();
        rushReadyValue.label = 'Rush Ready Only';
        rushReadyValue.value = 'true';
        rushReadyValue.checked = false;

        rushReadyFilter.values = new List<FilterValueWrapper>{ rushReadyValue };
        filters.add(rushReadyFilter);

        return filters;
    }

    /**
     * Get My Products category filters
     * Includes: End User (lookup to custom object)
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
     * Get Shape picklist values
     */
    private static List<FilterValueWrapper> getShapePicklistValues() {
        return getPicklistValues(Product2.Shape__c.getDescribe(), 'Shape');
    }

    /**
     * Get Profile picklist values
     */
    private static List<FilterValueWrapper> getProfilePicklistValues() {
        return getPicklistValues(Product2.Profile__c.getDescribe(), 'Profile');
    }

    /**
     * Get Panels picklist values
     */
    private static List<FilterValueWrapper> getPanelsPicklistValues() {
        return getPicklistValues(Product2.Panels__c.getDescribe(), 'Panels');
    }

    /**
     * Get Structure picklist values
     */
    private static List<FilterValueWrapper> getStructurePicklistValues() {
        return getPicklistValues(Product2.Structure__c.getDescribe(), 'Structure');
    }

    /**
     * Get Visor picklist values
     */
    private static List<FilterValueWrapper> getVisorPicklistValues() {
        return getPicklistValues(Product2.Visor__c.getDescribe(), 'Visor');
    }

    /**
     * Generic method to get picklist values from a field
     * @param fieldResult The DescribeFieldResult for the picklist field
     * @param fieldName The field name for error logging
     * @return List of FilterValueWrapper objects
     */
    private static List<FilterValueWrapper> getPicklistValues(Schema.DescribeFieldResult fieldResult, String fieldName) {
        List<FilterValueWrapper> values = new List<FilterValueWrapper>();

        try {
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

            System.debug('Getting picklist values for ' + fieldName + ': Found ' + picklistValues.size() + ' total values');

            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    FilterValueWrapper value = new FilterValueWrapper();
                    value.label = entry.getLabel();
                    value.value = entry.getValue();
                    value.checked = false;
                    values.add(value);
                }
            }

            System.debug('  Active values for ' + fieldName + ': ' + values.size());
        } catch (Exception e) {
            System.debug('ERROR getting ' + fieldName + ' picklist values: ' + e.getMessage());
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

            String query = 'SELECT Id, End_User__c, End_User__r.Name FROM Product2 WHERE ';

            // Handle null includeAccountEndUsers (treat as false)
            Boolean includeAccount = (includeAccountEndUsers == true);

            if (includeAccount && accountId != null) {
                // Get all end users for products associated with user's account
                query += 'Account__c = :accountId AND End_User__c != null';
                System.debug('Querying by Account: ' + accountId);
            } else {
                // Get end users only for products where the user is the contact
                query += 'Contact__c = :contactId AND End_User__c != null';
                System.debug('Querying by Contact: ' + contactId);
            }

            System.debug('Executing query: ' + query);
            List<Product2> products = Database.query(query);
            System.debug('Found ' + products.size() + ' products');

            // Collect unique end users
            Map<Id, String> endUserMap = new Map<Id, String>();
            for (Product2 product : products) {
                if (product.End_User__c != null && !endUserMap.containsKey(product.End_User__c)) {
                    endUserMap.put(product.End_User__c, product.End_User__r.Name);
                }
            }

            System.debug('Found ' + endUserMap.size() + ' unique end users');

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
