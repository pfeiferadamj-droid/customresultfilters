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
     * @param restrictToParents True to only return parent products (Is_Parent__c = 'Yes')
     * @param webstoreId The webstore ID for constructing image URLs
     * @return ProductQueryResult containing products and pagination info
     */
    @AuraEnabled
    public static ProductQueryResult getProductsByEndUser(
        String categoryId,
        List<String> endUserIds,
        Integer pageNumber,
        Integer pageSize,
        Boolean restrictToParents,
        String webstoreId
    ) {
        try {
            System.debug('CustomProductQueryController.getProductsByEndUser called');
            System.debug('  categoryId: ' + categoryId);
            System.debug('  endUserIds: ' + endUserIds);
            System.debug('  pageNumber: ' + pageNumber);
            System.debug('  pageSize: ' + pageSize);
            System.debug('  restrictToParents: ' + restrictToParents);

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

            // Build the query - include fields needed for product display
            String query = 'SELECT Id, Name, ProductCode, Description, StockKeepingUnit, ' +
                          'End_User__c, End_User__r.Name, Contact__c, Account__c, ' +
                          'Shape__c, Rush_Ready__c, IsActive, Is_Parent__c ' +
                          'FROM Product2 ' +
                          'WHERE IsActive = true ' +
                          'AND End_User__c IN :endUserIds ';

            // Add parent restriction if needed
            if (restrictToParents != null && restrictToParents) {
                query += 'AND Is_Parent__c = \'Yes\' ';
                System.debug('  Adding parent restriction: Is_Parent__c = Yes');
            }

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

            // Get product images - query ProductMedia separately
            // Get product images using existing ManagedContentHelper
            Map<Id, String> productImageMap = new Map<Id, String>();
            if (!products.isEmpty()) {
                List<Id> productIds = new List<Id>();
                for (Product2 p : products) {
                    productIds.add(p.Id);
                }

                // Use existing helper that handles ProductMedia and ManagedContent via ConnectApi
                productImageMap = ManagedContentHelper.getProductImageUrls(productIds, webstoreId);
                System.debug('Retrieved image URLs for ' + productImageMap.size() + ' products');
            }

            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Product2 ' +
                               'WHERE IsActive = true ' +
                               'AND End_User__c IN :endUserIds ';

            // Add parent restriction to count query
            if (restrictToParents != null && restrictToParents) {
                countQuery += 'AND Is_Parent__c = \'Yes\' ';
            }

            // Category filter disabled (see above)
            /*
            if (String.isNotBlank(categoryId)) {
                countQuery += 'AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE ProductCategoryId = :categoryId) ';
            }
            */

            Integer totalCount = Database.countQuery(countQuery);
            System.debug('Total count: ' + totalCount);

            // Query pricebook entries for these products
            Map<Id, List<PricebookEntryInfo>> productPriceMap = new Map<Id, List<PricebookEntryInfo>>();
            if (!products.isEmpty()) {
                Set<Id> productIds = new Set<Id>();
                for (Product2 p : products) {
                    productIds.add(p.Id);
                }

                List<PricebookEntry> priceEntries = [
                    SELECT Id, Product2Id, Pricebook2Id, UnitPrice, IsActive
                    FROM PricebookEntry
                    WHERE Product2Id IN :productIds
                    AND IsActive = true
                    ORDER BY Product2Id ASC, Pricebook2Id ASC
                ];

                System.debug('Found ' + priceEntries.size() + ' pricebook entries');

                for (PricebookEntry pbe : priceEntries) {
                    if (!productPriceMap.containsKey(pbe.Product2Id)) {
                        productPriceMap.put(pbe.Product2Id, new List<PricebookEntryInfo>());
                    }
                    PricebookEntryInfo priceInfo = new PricebookEntryInfo();
                    priceInfo.pricebookId = pbe.Pricebook2Id;
                    priceInfo.unitPrice = pbe.UnitPrice;
                    productPriceMap.get(pbe.Product2Id).add(priceInfo);
                }
            }

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

                // Include image from ProductMedia map
                pw.imageUrl = productImageMap.get(p.Id);
                pw.imageAltText = p.Name; // Use product name as alt text

                wrappedProducts.add(pw);
            }

            // Build result
            result.products = wrappedProducts;
            result.total = totalCount;
            result.pageNumber = page;
            result.pageSize = size;
            result.pricebookEntries = productPriceMap;

            System.debug('Returning result with ' + result.products.size() + ' products');
            System.debug('  With pricebook entries for ' + result.pricebookEntries.size() + ' products');
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
        @AuraEnabled public Map<Id, List<PricebookEntryInfo>> pricebookEntries { get; set; }
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
        @AuraEnabled public String imageUrl { get; set; }
        @AuraEnabled public String imageAltText { get; set; }
    }

    /**
     * Wrapper class for pricebook entry information
     */
    public class PricebookEntryInfo {
        @AuraEnabled public String pricebookId { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
    }
}
