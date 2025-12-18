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
     * Includes: Product Code, Shape (custom field), Rush Ready (checkbox)
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

        // Shape Filter (Custom Field - assuming picklist)
        FilterWrapper shapeFilter = new FilterWrapper();
        shapeFilter.id = 'shape';
        shapeFilter.label = 'Shape';
        shapeFilter.fieldType = 'picklist';
        shapeFilter.values = getShapePicklistValues();
        filters.add(shapeFilter);

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
     * NOTE: Update the Product2 object name and field API name based on your actual schema
     */
    private static List<FilterValueWrapper> getShapePicklistValues() {
        List<FilterValueWrapper> values = new List<FilterValueWrapper>();

        try {
            // Get the picklist values from the Shape__c field on Product2
            Schema.DescribeFieldResult fieldResult = Product2.Shape__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    FilterValueWrapper value = new FilterValueWrapper();
                    value.label = entry.getLabel();
                    value.value = entry.getValue();
                    value.checked = false;
                    values.add(value);
                }
            }
        } catch (Exception e) {
            System.debug('Error getting shape picklist values: ' + e.getMessage());
            // Return sample values if field doesn't exist yet
            values.add(createFilterValue('Round', 'Round', false));
            values.add(createFilterValue('Square', 'Square', false));
            values.add(createFilterValue('Rectangle', 'Rectangle', false));
            values.add(createFilterValue('Oval', 'Oval', false));
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

            // Get the current user's Contact Id
            List<User> users = [SELECT ContactId, AccountId FROM User WHERE Id = :currentUserId LIMIT 1];
            if (users.isEmpty() || users[0].ContactId == null) {
                return values;
            }

            Id contactId = users[0].ContactId;
            Id accountId = users[0].AccountId;

            String query = 'SELECT Id, End_User__c, End_User__r.Name FROM Product2 WHERE ';

            if (includeAccountEndUsers && accountId != null) {
                // Get all end users for products associated with user's account
                query += 'Account__c = :accountId AND End_User__c != null';
            } else {
                // Get end users only for products where the user is the contact
                query += 'Contact__c = :contactId AND End_User__c != null';
            }

            List<Product2> products = Database.query(query);

            // Collect unique end users
            Map<Id, String> endUserMap = new Map<Id, String>();
            for (Product2 product : products) {
                if (product.End_User__c != null && !endUserMap.containsKey(product.End_User__c)) {
                    endUserMap.put(product.End_User__c, product.End_User__r.Name);
                }
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

        } catch (Exception e) {
            System.debug('Error getting end user values: ' + e.getMessage());
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
