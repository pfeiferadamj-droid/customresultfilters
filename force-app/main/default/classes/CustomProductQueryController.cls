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
        String productCode,
        Integer pageNumber,
        Integer pageSize,
        Boolean restrictToParents,
        String webstoreId
    ) {
        try {
            System.debug('CustomProductQueryController.getProductsByEndUser called');
            System.debug('  categoryId: ' + categoryId);
            System.debug('  endUserIds: ' + endUserIds);
            System.debug('  productCode: ' + productCode);
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

            // Add product code search if provided
            if (String.isNotBlank(productCode)) {
                String productCodePattern = '%' + productCode + '%';
                query += 'AND (Name LIKE :productCodePattern OR ProductCode LIKE :productCodePattern OR StockKeepingUnit LIKE :productCodePattern) ';
                System.debug('  Adding product code search: ' + productCode);
            }

            // Note: Category filter NOT applied for My Products
            // My Products should show ALL products for the selected end user(s),
            // regardless of category assignment in ProductCategoryProduct
            System.debug('  Skipping category filter - My Products shows all products for end user');

            query += 'ORDER BY Name ASC ' +
                    'LIMIT :size OFFSET :offset';

            System.debug('Executing query: ' + query);
            List<Product2> products = Database.query(query);
            System.debug('Found ' + products.size() + ' products');

            // Get product images - query ProductMedia separately
            // Get product images using ManagedContentHelper with ConnectAPI
            Map<Id, String> productImageMap = new Map<Id, String>();
            if (!products.isEmpty()) {
                List<Id> productIds = new List<Id>();
                for (Product2 p : products) {
                    productIds.add(p.Id);
                }

                System.debug('About to call ManagedContentHelper.getProductImageUrls');
                System.debug('  Product IDs: ' + productIds);
                System.debug('  Webstore ID: ' + webstoreId);

                // Use ManagedContentHelper with ConnectAPI (bypasses object permissions)
                productImageMap = ManagedContentHelper.getProductImageUrls(productIds, webstoreId);

                System.debug('ManagedContentHelper returned: ' + productImageMap.size() + ' image URLs');
                System.debug('  Image map: ' + productImageMap);
            } else {
                System.debug('No products found - skipping image retrieval');
            }

            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Product2 ' +
                               'WHERE IsActive = true ' +
                               'AND End_User__c IN :endUserIds ';

            // Add parent restriction to count query
            if (restrictToParents != null && restrictToParents) {
                countQuery += 'AND Is_Parent__c = \'Yes\' ';
            }

            // Add product code search to count query
            if (String.isNotBlank(productCode)) {
                String productCodePattern = '%' + productCode + '%';
                countQuery += 'AND (Name LIKE :productCodePattern OR ProductCode LIKE :productCodePattern OR StockKeepingUnit LIKE :productCodePattern) ';
            }

            // Note: Category filter NOT applied (see main query comment above)

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
     * Query products by Quick Turn filters using direct SOQL
     * This bypasses Commerce Search API which cannot handle text field refinements
     *
     * @param categoryId The category ID to filter by
     * @param profileValues List of Profile values to filter by
     * @param panelsValues List of Panels values to filter by
     * @param structureValues List of Structure values to filter by
     * @param visorValues List of Visor values to filter by
     * @param shapeValues List of Shape values to filter by
     * @param productCode Product code search term (partial match)
     * @param rushReadyOnly True to only show rush ready products
     * @param pageNumber Current page number (1-indexed)
     * @param pageSize Number of products per page
     * @param restrictToParents True to only return parent products
     * @param webstoreId The webstore ID for constructing image URLs
     * @return ProductQueryResult containing products and pagination info
     */
    @AuraEnabled
    public static ProductQueryResult getProductsByQuickTurnFilters(
        String categoryId,
        List<String> profileValues,
        List<String> panelsValues,
        List<String> structureValues,
        List<String> visorValues,
        List<String> shapeValues,
        String productCode,
        List<String> specialPrograms,
        Integer pageNumber,
        Integer pageSize,
        Boolean restrictToParents,
        String webstoreId
    ) {
        try {
            System.debug('CustomProductQueryController.getProductsByQuickTurnFilters called');
            System.debug('  categoryId: ' + categoryId);
            System.debug('  profileValues: ' + profileValues);
            System.debug('  panelsValues: ' + panelsValues);
            System.debug('  structureValues: ' + structureValues);
            System.debug('  visorValues: ' + visorValues);
            System.debug('  shapeValues: ' + shapeValues);
            System.debug('  specialPrograms: ' + specialPrograms);
            System.debug('  productCode: ' + productCode);
            System.debug('  pageNumber: ' + pageNumber);
            System.debug('  pageSize: ' + pageSize);
            System.debug('  restrictToParents: ' + restrictToParents);

            ProductQueryResult result = new ProductQueryResult();

            // Set up pagination
            Integer page = pageNumber != null ? pageNumber : 1;
            Integer size = pageSize != null ? pageSize : 24;
            Integer offset = (page - 1) * size;

            // Build dynamic query
            String query = 'SELECT Id, Name, ProductCode, Description, StockKeepingUnit, ' +
                          'Shape__c, Profile__c, Panels__c, Structure__c, Visor__c, ' +
                          'Rush_Ready__c, IsActive, Is_Parent__c ' +
                          'FROM Product2 ' +
                          'WHERE IsActive = true ';

            // Add filter conditions
            if (profileValues != null && !profileValues.isEmpty()) {
                query += 'AND Profile__c IN :profileValues ';
            }

            if (panelsValues != null && !panelsValues.isEmpty()) {
                query += 'AND Panels__c IN :panelsValues ';
            }

            if (structureValues != null && !structureValues.isEmpty()) {
                query += 'AND Structure__c IN :structureValues ';
            }

            if (visorValues != null && !visorValues.isEmpty()) {
                query += 'AND Visor__c IN :visorValues ';
            }

            if (shapeValues != null && !shapeValues.isEmpty()) {
                query += 'AND Shape__c IN :shapeValues ';
            }

            if (String.isNotBlank(productCode)) {
                String productCodePattern = '%' + productCode + '%';
                query += 'AND (Name LIKE :productCodePattern OR ProductCode LIKE :productCodePattern OR StockKeepingUnit LIKE :productCodePattern) ';
            }

            if (specialPrograms != null && !specialPrograms.isEmpty()) {
                // Build OR conditions for special programs
                // Supports: 'QuickTurnDDT' (Dri-Duck) and 'RushReady' (Rush Ready)
                List<String> programConditions = new List<String>();
                for (String programValue : specialPrograms) {
                    if (programValue == 'QuickTurnDDT') {
                        programConditions.add('Special_Program_SAP__c LIKE \'%QuickTurnDDT%\'');
                    } else if (programValue == 'RushReady') {
                        programConditions.add('Rush_Ready__c = true');
                    }
                }
                if (!programConditions.isEmpty()) {
                    query += 'AND (' + String.join(programConditions, ' OR ') + ') ';
                }
            }

            if (restrictToParents != null && restrictToParents) {
                query += 'AND Is_Parent__c = \'Yes\' ';
                System.debug('  Adding parent restriction: Is_Parent__c = Yes');
            }

            // Note: Category filter NOT applied for Quick Turn filtering
            // Quick Turn filters (Shape, Profile, Panels, etc.) are already specific enough
            // ProductCategoryProduct is often not fully populated, so category filter is too restrictive
            System.debug('  Skipping category filter - Quick Turn filters are specific enough');

            query += 'ORDER BY Name ASC ' +
                    'LIMIT :size OFFSET :offset';

            System.debug('Executing query: ' + query);
            List<Product2> products = Database.query(query);
            System.debug('Found ' + products.size() + ' products');

            // Get product images using ManagedContentHelper with ConnectAPI
            Map<Id, String> productImageMap = new Map<Id, String>();
            if (!products.isEmpty()) {
                List<Id> productIds = new List<Id>();
                for (Product2 p : products) {
                    productIds.add(p.Id);
                }

                System.debug('About to call ManagedContentHelper.getProductImageUrls');
                System.debug('  Product IDs: ' + productIds);
                System.debug('  Webstore ID: ' + webstoreId);

                productImageMap = ManagedContentHelper.getProductImageUrls(productIds, webstoreId);

                System.debug('ManagedContentHelper returned: ' + productImageMap.size() + ' image URLs');
                System.debug('  Image map: ' + productImageMap);
            } else {
                System.debug('No products found - skipping image retrieval');
            }

            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Product2 ' +
                               'WHERE IsActive = true ';

            if (profileValues != null && !profileValues.isEmpty()) {
                countQuery += 'AND Profile__c IN :profileValues ';
            }

            if (panelsValues != null && !panelsValues.isEmpty()) {
                countQuery += 'AND Panels__c IN :panelsValues ';
            }

            if (structureValues != null && !structureValues.isEmpty()) {
                countQuery += 'AND Structure__c IN :structureValues ';
            }

            if (visorValues != null && !visorValues.isEmpty()) {
                countQuery += 'AND Visor__c IN :visorValues ';
            }

            if (shapeValues != null && !shapeValues.isEmpty()) {
                countQuery += 'AND Shape__c IN :shapeValues ';
            }

            if (String.isNotBlank(productCode)) {
                String productCodePattern = '%' + productCode + '%';
                countQuery += 'AND (Name LIKE :productCodePattern OR ProductCode LIKE :productCodePattern OR StockKeepingUnit LIKE :productCodePattern) ';
            }

            if (specialPrograms != null && !specialPrograms.isEmpty()) {
                // Build OR conditions for special programs
                List<String> programConditions = new List<String>();
                for (String programValue : specialPrograms) {
                    if (programValue == 'QuickTurnDDT') {
                        programConditions.add('Special_Program_SAP__c LIKE \'%QuickTurnDDT%\'');
                    } else if (programValue == 'RushReady') {
                        programConditions.add('Rush_Ready__c = true');
                    }
                }
                if (!programConditions.isEmpty()) {
                    countQuery += 'AND (' + String.join(programConditions, ' OR ') + ') ';
                }
            }

            if (restrictToParents != null && restrictToParents) {
                countQuery += 'AND Is_Parent__c = \'Yes\' ';
            }

            // Note: Category filter NOT applied (see main query comment above)

            Integer totalCount = Database.countQuery(countQuery);
            System.debug('Total count: ' + totalCount);

            // Query pricebook entries for products
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
                    ORDER BY Product2Id, Pricebook2Id
                ];

                System.debug('Found ' + priceEntries.size() + ' pricebook entries');

                // Group by product
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

            // Convert products to wrapper objects
            List<ProductWrapper> wrappedProducts = new List<ProductWrapper>();
            for (Product2 p : products) {
                ProductWrapper pw = new ProductWrapper();
                pw.id = p.Id;
                pw.name = p.Name;
                pw.productCode = p.ProductCode;
                pw.description = p.Description;
                pw.sku = p.StockKeepingUnit;
                pw.shapeValue = p.Shape__c;
                pw.rushReady = p.Rush_Ready__c;
                pw.imageUrl = productImageMap.get(p.Id);
                pw.imageAltText = p.Name;
                wrappedProducts.add(pw);
            }

            result.products = wrappedProducts;
            result.total = totalCount;
            result.pageNumber = page;
            result.pageSize = size;
            result.pricebookEntries = productPriceMap;

            System.debug('Returning result with ' + result.products.size() + ' products');
            System.debug('  With pricebook entries for ' + result.pricebookEntries.size() + ' products');

            return result;

        } catch (Exception e) {
            System.debug('ERROR in getProductsByQuickTurnFilters: ' + e.getMessage());
            System.debug('ERROR Type: ' + e.getTypeName());
            System.debug('ERROR Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error querying products by Quick Turn filters: ' + e.getMessage());
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
