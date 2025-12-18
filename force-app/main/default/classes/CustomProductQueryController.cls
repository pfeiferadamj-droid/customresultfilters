/**
 * Custom controller for querying products with filters that cannot be handled by Commerce Search API
 * Specifically handles End_User__c (lookup field) filtering via direct SOQL queries
 */
public with sharing class CustomProductQueryController {

    /**
     * Query products by End User using direct SOQL
     * This bypasses Commerce Search API which cannot handle lookup field refinements
     *
     * @param categoryId The category ID to filter by
     * @param endUserIds List of End User IDs to filter by
     * @param pageNumber Current page number (1-indexed)
     * @param pageSize Number of products per page
     * @return ProductQueryResult containing products and pagination info
     */
    @AuraEnabled
    public static ProductQueryResult getProductsByEndUser(
        String categoryId,
        List<String> endUserIds,
        Integer pageNumber,
        Integer pageSize
    ) {
        try {
            System.debug('CustomProductQueryController.getProductsByEndUser called');
            System.debug('  categoryId: ' + categoryId);
            System.debug('  endUserIds: ' + endUserIds);
            System.debug('  pageNumber: ' + pageNumber);
            System.debug('  pageSize: ' + pageSize);

            // Debug: Check how many products have these End Users (regardless of category)
            Integer productsWithEndUser = [SELECT COUNT() FROM Product2 WHERE End_User__c IN :endUserIds AND IsActive = true];
            System.debug('  DEBUG: Total products with End User (no category filter): ' + productsWithEndUser);

            // Debug: Check if category exists and has products
            if (String.isNotBlank(categoryId)) {
                Integer productsInCategory = [SELECT COUNT() FROM ProductCategoryProduct WHERE ProductCategoryId = :categoryId];
                System.debug('  DEBUG: Total products in category: ' + productsInCategory);
            }

            ProductQueryResult result = new ProductQueryResult();

            // Validate inputs
            if (endUserIds == null || endUserIds.isEmpty()) {
                System.debug('No end user IDs provided, returning empty result');
                result.products = new List<ProductWrapper>();
                result.total = 0;
                result.pageNumber = pageNumber != null ? pageNumber : 1;
                result.pageSize = pageSize != null ? pageSize : 12;
                return result;
            }

            // Set defaults
            Integer page = pageNumber != null ? pageNumber : 1;
            Integer size = pageSize != null ? pageSize : 12;
            Integer offset = (page - 1) * size;

            // Build the query
            String query = 'SELECT Id, Name, ProductCode, Description, StockKeepingUnit, ' +
                          'End_User__c, End_User__r.Name, Contact__c, Account__c, ' +
                          'Shape__c, Rush_Ready__c, IsActive ' +
                          'FROM Product2 ' +
                          'WHERE IsActive = true ' +
                          'AND End_User__c IN :endUserIds ';

            // Add category filter if provided (commented out temporarily for debugging)
            // TODO: Uncomment this once products are linked to categories via ProductCategoryProduct
            /*
            if (String.isNotBlank(categoryId)) {
                query += 'AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE ProductCategoryId = :categoryId) ';
                System.debug('  Adding category filter for: ' + categoryId);
            }
            */
            System.debug('  NOTE: Category filter temporarily disabled to test End User filtering');

            query += 'ORDER BY Name ASC ' +
                    'LIMIT :size OFFSET :offset';

            System.debug('Executing query: ' + query);
            List<Product2> products = Database.query(query);
            System.debug('Found ' + products.size() + ' products');

            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Product2 ' +
                               'WHERE IsActive = true ' +
                               'AND End_User__c IN :endUserIds ';
            // Category filter disabled (see above)
            /*
            if (String.isNotBlank(categoryId)) {
                countQuery += 'AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE ProductCategoryId = :categoryId) ';
            }
            */

            Integer totalCount = Database.countQuery(countQuery);
            System.debug('Total count: ' + totalCount);

            // Convert to wrapper objects
            List<ProductWrapper> wrappedProducts = new List<ProductWrapper>();
            for (Product2 p : products) {
                ProductWrapper pw = new ProductWrapper();
                pw.id = p.Id;
                pw.name = p.Name;
                pw.productCode = p.ProductCode;
                pw.description = p.Description;
                pw.sku = p.StockKeepingUnit;
                pw.endUserId = p.End_User__c;
                pw.endUserName = p.End_User__c != null ? p.End_User__r.Name : null;
                pw.shapeValue = p.Shape__c;
                pw.rushReady = p.Rush_Ready__c != null ? p.Rush_Ready__c : false;
                wrappedProducts.add(pw);
            }

            // Build result
            result.products = wrappedProducts;
            result.total = totalCount;
            result.pageNumber = page;
            result.pageSize = size;

            System.debug('Returning result with ' + result.products.size() + ' products');
            return result;

        } catch (Exception e) {
            System.debug('ERROR in getProductsByEndUser: ' + e.getMessage());
            System.debug('ERROR Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error querying products by End User: ' + e.getMessage());
        }
    }

    /**
     * Wrapper class for product query results
     */
    public class ProductQueryResult {
        @AuraEnabled public List<ProductWrapper> products { get; set; }
        @AuraEnabled public Integer total { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
    }

    /**
     * Wrapper class for product data
     */
    public class ProductWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String productCode { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String sku { get; set; }
        @AuraEnabled public String endUserId { get; set; }
        @AuraEnabled public String endUserName { get; set; }
        @AuraEnabled public String shapeValue { get; set; }
        @AuraEnabled public Boolean rushReady { get; set; }
    }
}
