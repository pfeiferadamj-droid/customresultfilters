/**
 * Custom Filter Controller
 * Provides filter data based on category and user context
 * Enforces B2B Entitlements and Available_for_b2b__c = TRUE
 */
public without sharing class CustomFilterController {

    /**
     * Main entry point for the lightning component
     */
    @AuraEnabled
    public static FilterDataWrapper getFilterData(String category, Boolean includeAccountEndUsers) {
        FilterDataWrapper filterData = new FilterDataWrapper();

        String quickTurnName = StoreDefaultsHelper.getQuickTurnCategoryName();
        String myProductsName = StoreDefaultsHelper.getMyProductsCategoryName();

        if (category != null && category.equals(quickTurnName)) {
            filterData.quickTurnFilters = getQuickTurnFilters();
        } else if (category != null && category.equals(myProductsName)) {
            filterData.myProductsFilters = getMyProductsFilters(includeAccountEndUsers);
            filterData.accountName = getUserAccountName();
        }

        return filterData;
    }

    /**
     * HELPER: Fetches Product IDs the user is entitled to see via B2B Buyer Groups.
     * This ensures the custom filters match standard B2B storefront visibility.
     */
    private static Set<Id> getEntitledProductIds() {
        Set<Id> entitledProductIds = new Set<Id>();
        
        try {
            Id userId = UserInfo.getUserId();
            List<User> users = [SELECT AccountId FROM User WHERE Id = :userId LIMIT 1];
            if (users.isEmpty() || users[0].AccountId == null) return entitledProductIds;
            
            Id accountId = users[0].AccountId;

            // 1. Get Buyer Groups associated with the User's Account
            Set<Id> buyerGroupIds = new Set<Id>();
            for (BuyerGroupMember bgm : [SELECT BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = :accountId]) {
                buyerGroupIds.add(bgm.BuyerGroupId);
            }

            if (buyerGroupIds.isEmpty()) return entitledProductIds;

            // 2. Get Entitlement Policies assigned to those Buyer Groups
            // Object: CommerceEntitlementBuyerGroup (Links Policy to Buyer Group)
            Set<Id> policyIds = new Set<Id>();
            for (CommerceEntitlementBuyerGroup cebg : [SELECT PolicyId FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId IN :buyerGroupIds]) {
                policyIds.add(cebg.PolicyId);
            }

            if (policyIds.isEmpty()) return entitledProductIds;

            // 3. Get the Product IDs contained within those Policies
            for (CommerceEntitlementProduct cep : [SELECT ProductId FROM CommerceEntitlementProduct WHERE PolicyId IN :policyIds]) {
                entitledProductIds.add(cep.ProductId);
            }
        } catch (Exception e) {
            System.debug('Error resolving B2B Entitlements: ' + e.getMessage());
        }
        
        return entitledProductIds;
    }

    /**
     * Gets distinct values for picklist-style filters.
     * Filters by: IsActive, Available_for_b2b__c, and Entitlements.
     */
    private static List<FilterValueWrapper> getDistinctTextFieldValues(String fieldApiName, String fieldLabel) {
        List<FilterValueWrapper> values = new List<FilterValueWrapper>();
        Set<String> distinctValues = new Set<String>();

        // Get the list of products the user is allowed to see
        Set<Id> entitledIds = getEntitledProductIds();
        
        // Safety check: if no entitlements exist, return empty to prevent showing wrong data
        if (entitledIds.isEmpty()) return values;

        try {
            Integer queryLimit = StoreDefaultsHelper.getFilterValuesLimit();
            
            // This query enforces your custom B2B field and the Entitlement Policy
            String query = 'SELECT ' + fieldApiName + ' FROM Product2 ' +
                          'WHERE IsActive = true ' +
                          'AND Available_for_b2b__c = true ' + 
                          'AND Id IN :entitledIds ' +
                          'AND ' + fieldApiName + ' != null ' +
                          'LIMIT ' + queryLimit;

            List<Product2> products = Database.query(query);

            for (Product2 p : products) {
                String fieldValue = (String)p.get(fieldApiName);
                if (String.isNotBlank(fieldValue) && !distinctValues.contains(fieldValue)) {
                    distinctValues.add(fieldValue);
                }
            }

            List<String> sortedValues = new List<String>(distinctValues);
            sortedValues.sort();

            for (String val : sortedValues) {
                values.add(createFilterValue(val, val, false));
            }

        } catch (Exception e) {
            System.debug('ERROR in getDistinctTextFieldValues for ' + fieldLabel + ': ' + e.getMessage());
        }

        return values;
    }

    /**
     * Get End User values for "My Products"
     */
    private static List<FilterValueWrapper> getEndUserValues(Boolean includeAccountEndUsers) {
        List<FilterValueWrapper> values = new List<FilterValueWrapper>();
        
        Set<Id> entitledIds = getEntitledProductIds();
        if (entitledIds.isEmpty()) return values;

        try {
            Id currentUserId = UserInfo.getUserId();
            List<User> users = [SELECT ContactId, AccountId FROM User WHERE Id = :currentUserId LIMIT 1];
            if (users.isEmpty() || users[0].ContactId == null) return values;

            Id contactId = users[0].ContactId;
            Id accountId = users[0].AccountId;

            String endUserField = StoreDefaultsHelper.getEndUserField();
            String contactField = StoreDefaultsHelper.getContactField();
            String accountField = StoreDefaultsHelper.getAccountField();
            String relationshipName = endUserField.replace('__c', '__r');
            String namePath = endUserField.replace('__c', '__r.Name');

            String query = 'SELECT ' + endUserField + ', ' + namePath + ' FROM Product2 WHERE ' +
                          'IsActive = true AND Available_for_b2b__c = true AND Id IN :entitledIds AND ' + endUserField + ' != null ';

            if (includeAccountEndUsers == true && accountId != null) {
                query += 'AND ' + accountField + ' = :accountId';
            } else {
                query += 'AND ' + contactField + ' = :contactId';
            }

            List<Product2> products = Database.query(query);
            Map<Id, String> endUserMap = new Map<Id, String>();

            for (Product2 product : products) {
                Id endUserId = (Id)product.get(endUserField);
                SObject relatedRecord = product.getSObject(relationshipName);
                if (relatedRecord != null) {
                    endUserMap.put(endUserId, (String)relatedRecord.get('Name'));
                }
            }

            for (Id endUserId : endUserMap.keySet()) {
                values.add(createFilterValue(endUserMap.get(endUserId), (String)endUserId, false));
            }
            values.sort();

        } catch (Exception e) {
            System.debug('ERROR in getEndUserValues: ' + e.getMessage());
        }

        return values;
    }

    // --- HELPERS & WRAPPERS ---

    private static String getUserAccountName() {
        try {
            List<User> users = [SELECT Account.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            return (!users.isEmpty() && users[0].Account != null) ? users[0].Account.Name : 'your account';
        } catch (Exception e) { return 'your account'; }
    }

    private static List<FilterWrapper> getQuickTurnFilters() {
        List<FilterWrapper> filters = new List<FilterWrapper>();
        
        FilterWrapper sp = new FilterWrapper('specialPrograms', 'Special Programs', 'checkbox');
        sp.values.add(createFilterValue(StoreDefaultsHelper.getDriDuckLabel(), StoreDefaultsHelper.getDriDuckValue(), false));
        sp.values.add(createFilterValue(StoreDefaultsHelper.getRushReadyLabel(), StoreDefaultsHelper.getRushReadyValue(), false));
        filters.add(sp);

        filters.add(new FilterWrapper('panels', 'Panels', 'picklist', getDistinctTextFieldValues(StoreDefaultsHelper.getPanelsField(), 'Panels')));
        filters.add(new FilterWrapper('profile', 'Profile', 'picklist', getDistinctTextFieldValues(StoreDefaultsHelper.getProfileField(), 'Profile')));
        filters.add(new FilterWrapper('shape', 'Shape', 'picklist', getDistinctTextFieldValues(StoreDefaultsHelper.getShapeField(), 'Shape')));
        filters.add(new FilterWrapper('structure', 'Structure', 'picklist', getDistinctTextFieldValues(StoreDefaultsHelper.getStructureField(), 'Structure')));
        filters.add(new FilterWrapper('visor', 'Visor', 'picklist', getDistinctTextFieldValues(StoreDefaultsHelper.getVisorField(), 'Visor')));
        
        return filters;
    }

    private static List<FilterWrapper> getMyProductsFilters(Boolean includeAccountEndUsers) {
        List<FilterWrapper> filters = new List<FilterWrapper>();
        filters.add(new FilterWrapper('endUser', 'End User', 'lookup', getEndUserValues(includeAccountEndUsers)));
        return filters;
    }

    private static FilterValueWrapper createFilterValue(String label, String value, Boolean checked) {
        FilterValueWrapper fv = new FilterValueWrapper();
        fv.label = label; fv.value = value; fv.checked = checked;
        return fv;
    }

    public class FilterDataWrapper {
        @AuraEnabled public List<FilterWrapper> quickTurnFilters { get; set; }
        @AuraEnabled public List<FilterWrapper> myProductsFilters { get; set; }
        @AuraEnabled public String accountName { get; set; }
    }

    public class FilterWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public List<FilterValueWrapper> values { get; set; }

        public FilterWrapper(String id, String label, String type, List<FilterValueWrapper> values) {
            this.id = id; this.label = label; this.fieldType = type; this.values = values;
        }
        public FilterWrapper(String id, String label, String type) {
            this.id = id; this.label = label; this.fieldType = type; this.values = new List<FilterValueWrapper>();
        }
    }

    public class FilterValueWrapper implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public Boolean checked { get; set; }

        public Integer compareTo(Object compareTo) {
            FilterValueWrapper other = (FilterValueWrapper)compareTo;
            return (label == other.label) ? 0 : (label > other.label ? 1 : -1);
        }
    }
}
