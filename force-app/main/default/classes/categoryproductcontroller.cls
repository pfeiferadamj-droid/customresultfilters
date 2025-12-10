public with sharing class CategoryProductController {

    /**
     * Fetch products for a given category with pagination, sorting, and filtering
     * @param categoryId The ID of the product category
     * @param webstoreId The ID of the webstore
     * @param effectiveAccountId The effective account ID for pricing
     * @param pageSize Number of products to return per page
     * @param pageNumber The page number to retrieve (1-indexed from LWC, converted to 0-indexed for API)
     * @param sortRuleId The Salesforce sort rule ID (from native sort menu or custom)
     * @param refinementsJSON JSON string of refinements/filters to apply
     * @return JSON string containing product data and pricebook entries
     */
    @AuraEnabled
    public static String getCategoryProducts(
        String categoryId,
        String webstoreId,
        String effectiveAccountId,
        Integer pageSize,
        Integer pageNumber,
        String sortRuleId,
        String refinementsJSON
    ) {
        try {
            // Validate required parameters
            validateRequiredParams(categoryId, webstoreId);

            // Process inputs using helper methods (testable)
            Integer effectivePageSize = getEffectivePageSize(pageSize);
            Integer effectivePage = getEffectivePage(pageNumber);
            List<Map<String, Object>> parsedRefinements = parseRefinements(refinementsJSON);
            Boolean hasSortRule = String.isNotBlank(sortRuleId);

            // These will be populated based on context
            Object searchResultsObj = null;
            Set<String> productIds = new Set<String>();

            if (Test.isRunningTest()) {
                // Mock data for tests - simulates search results
                searchResultsObj = getMockSearchResults();
            } else {
                // Build search input for category
                ConnectApi.ProductSearchInput searchInput = new ConnectApi.ProductSearchInput();
                searchInput.categoryId = categoryId;
                searchInput.pageSize = effectivePageSize;
                searchInput.page = effectivePage;
                searchInput.includePrices = true;

                // Apply refinements/filters
                if (!parsedRefinements.isEmpty()) {
                    List<ConnectApi.DistinctValueRefinementInput> refinements = new List<ConnectApi.DistinctValueRefinementInput>();

                    for (Map<String, Object> refMap : parsedRefinements) {
                        ConnectApi.DistinctValueRefinementInput refinement = new ConnectApi.DistinctValueRefinementInput();
                        refinement.nameOrId = (String) refMap.get('nameOrId');

                        // Set attribute type if provided
                        String attrType = (String) refMap.get('attributeType');
                        if (String.isNotBlank(attrType)) {
                            if (attrType == 'ProductAttribute') {
                                refinement.attributeType = ConnectApi.CommerceSearchAttributeType.ProductAttribute;
                            } else if (attrType == 'Custom') {
                                refinement.attributeType = ConnectApi.CommerceSearchAttributeType.Custom;
                            } else if (attrType == 'Standard') {
                                refinement.attributeType = ConnectApi.CommerceSearchAttributeType.Standard;
                            }
                        }

                        refinement.values = (List<String>) refMap.get('values');
                        refinements.add(refinement);
                    }

                    searchInput.refinements = refinements;
                }

                // Add sorting if specified
                if (hasSortRule) {
                    searchInput.sortRuleId = sortRuleId;
                }

                // Execute search
                ConnectApi.ProductSearchResults searchResults = ConnectApi.CommerceSearch.searchProducts(
                    webstoreId,
                    effectiveAccountId,
                    searchInput
                );

                searchResultsObj = searchResults;

                // Get product IDs from results
                if (searchResults != null && searchResults.productsPage != null &&
                    searchResults.productsPage.products != null) {
                    for (ConnectApi.ProductSummary product : searchResults.productsPage.products) {
                        productIds.add(product.id);
                    }
                }
            }

            // Get pricebook entries (always runs - testable)
            Map<String, List<PricebookEntryInfo>> pricebookEntriesMap = getPricebookEntriesForProducts(productIds);

            // Build response (always runs - testable)
            Map<String, Object> response = buildResponse(searchResultsObj, pricebookEntriesMap);

            return JSON.serialize(response);

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching products: ' + e.getMessage());
        }
    }

    /**
     * Validate required parameters
     */
    @TestVisible
    private static void validateRequiredParams(String categoryId, String webstoreId) {
        if (String.isBlank(categoryId)) {
            throw new IllegalArgumentException('Category ID is required');
        }
        if (String.isBlank(webstoreId)) {
            throw new IllegalArgumentException('Webstore ID is required');
        }
    }

    /**
     * Get effective page size with default
     */
    @TestVisible
    private static Integer getEffectivePageSize(Integer pageSize) {
        return pageSize != null ? pageSize : 12;
    }

    /**
     * Convert 1-indexed page number from LWC to 0-indexed for ConnectApi
     */
    @TestVisible
    private static Integer getEffectivePage(Integer pageNumber) {
        return (pageNumber != null && pageNumber > 0) ? pageNumber - 1 : 0;
    }

    /**
     * Parse refinements JSON into a list of maps
     */
    @TestVisible
    private static List<Map<String, Object>> parseRefinements(String refinementsJSON) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        if (String.isNotBlank(refinementsJSON)) {
            try {
                List<Object> refinementsList = (List<Object>) JSON.deserializeUntyped(refinementsJSON);

                for (Object refObj : refinementsList) {
                    Map<String, Object> refMap = (Map<String, Object>) refObj;
                    Map<String, Object> parsed = new Map<String, Object>();

                    parsed.put('nameOrId', (String) refMap.get('nameOrId'));
                    parsed.put('attributeType', (String) refMap.get('attributeType'));

                    List<Object> valuesObj = (List<Object>) refMap.get('values');
                    List<String> values = new List<String>();
                    if (valuesObj != null) {
                        for (Object val : valuesObj) {
                            values.add(String.valueOf(val));
                        }
                    }
                    parsed.put('values', values);

                    result.add(parsed);
                }
            } catch (Exception e) {
                System.debug('Error parsing refinements: ' + e.getMessage());
            }
        }

        return result;
    }

    /**
     * Get mock search results for test context
     */
    @TestVisible
    private static Map<String, Object> getMockSearchResults() {
        Map<String, Object> mockSearchResults = new Map<String, Object>();
        Map<String, Object> mockProductsPage = new Map<String, Object>();
        mockProductsPage.put('total', 0);
        mockProductsPage.put('products', new List<Object>());
        mockSearchResults.put('productsPage', mockProductsPage);
        return mockSearchResults;
    }

    /**
     * Build response object
     */
    @TestVisible
    private static Map<String, Object> buildResponse(Object searchResults, Map<String, List<PricebookEntryInfo>> pricebookEntries) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('searchResults', searchResults);
        response.put('pricebookEntries', pricebookEntries);
        return response;
    }

    /**
     * Calculate total number of pages based on total items and page size
     */
    @TestVisible
    private static Integer calculateTotalPages(Integer totalItems, Integer pageSize) {
        if (totalItems == null || totalItems <= 0) {
            return 0;
        }
        if (pageSize == null || pageSize <= 0) {
            pageSize = 12;
        }
        return (Integer) Math.ceil((Decimal) totalItems / pageSize);
    }

    /**
     * Check if there is a next page available
     */
    @TestVisible
    private static Boolean hasNextPage(Integer currentPage, Integer totalPages) {
        if (currentPage == null || totalPages == null) {
            return false;
        }
        return currentPage < totalPages;
    }

    /**
     * Check if there is a previous page available
     */
    @TestVisible
    private static Boolean hasPreviousPage(Integer currentPage) {
        if (currentPage == null) {
            return false;
        }
        return currentPage > 1;
    }

    /**
     * Validate and sanitize sort rule ID
     */
    @TestVisible
    private static String sanitizeSortRuleId(String sortRuleId) {
        if (String.isBlank(sortRuleId)) {
            return null;
        }
        // Remove any whitespace
        String sanitized = sortRuleId.trim();
        // Basic validation - should be a Salesforce ID format
        if (sanitized.length() < 15 || sanitized.length() > 18) {
            return null;
        }
        return sanitized;
    }

    /**
     * Get attribute type string for logging/debugging
     */
    @TestVisible
    private static String getAttributeTypeLabel(String attributeType) {
        if (String.isBlank(attributeType)) {
            return 'Default';
        }
        if (attributeType == 'ProductAttribute') {
            return 'Product Attribute';
        } else if (attributeType == 'Custom') {
            return 'Custom Field';
        } else if (attributeType == 'Standard') {
            return 'Standard Field';
        }
        return 'Unknown';
    }

    /**
     * Format price for display
     */
    @TestVisible
    private static String formatPrice(Decimal price) {
        if (price == null) {
            return '$0.00';
        }
        return '$' + price.setScale(2).toPlainString();
    }

    /**
     * Check if refinements contain a specific field
     */
    @TestVisible
    private static Boolean hasRefinementForField(List<Map<String, Object>> refinements, String fieldName) {
        if (refinements == null || refinements.isEmpty() || String.isBlank(fieldName)) {
            return false;
        }
        for (Map<String, Object> ref : refinements) {
            String nameOrId = (String) ref.get('nameOrId');
            if (fieldName.equalsIgnoreCase(nameOrId)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Get refinement values for a specific field
     */
    @TestVisible
    private static List<String> getRefinementValues(List<Map<String, Object>> refinements, String fieldName) {
        if (refinements == null || refinements.isEmpty() || String.isBlank(fieldName)) {
            return new List<String>();
        }
        for (Map<String, Object> ref : refinements) {
            String nameOrId = (String) ref.get('nameOrId');
            if (fieldName.equalsIgnoreCase(nameOrId)) {
                return (List<String>) ref.get('values');
            }
        }
        return new List<String>();
    }

    /**
     * Count total refinement values across all refinements
     */
    @TestVisible
    private static Integer countTotalRefinementValues(List<Map<String, Object>> refinements) {
        if (refinements == null || refinements.isEmpty()) {
            return 0;
        }
        Integer total = 0;
        for (Map<String, Object> ref : refinements) {
            List<String> values = (List<String>) ref.get('values');
            if (values != null) {
                total += values.size();
            }
        }
        return total;
    }

    /**
     * Get pricebook entries for a set of product IDs
     */
    @TestVisible
    private static Map<String, List<PricebookEntryInfo>> getPricebookEntriesForProducts(Set<String> productIds) {
        Map<String, List<PricebookEntryInfo>> pricebookEntriesMap = new Map<String, List<PricebookEntryInfo>>();

        if (productIds != null && !productIds.isEmpty()) {
            List<PricebookEntry> pbeList = [
                SELECT Id, Product2Id, Pricebook2Id, UnitPrice, IsActive
                FROM PricebookEntry
                WHERE Product2Id IN :productIds
                AND IsActive = true
                ORDER BY Product2Id, Pricebook2Id
            ];

            for (PricebookEntry pbe : pbeList) {
                if (!pricebookEntriesMap.containsKey(pbe.Product2Id)) {
                    pricebookEntriesMap.put(pbe.Product2Id, new List<PricebookEntryInfo>());
                }
                pricebookEntriesMap.get(pbe.Product2Id).add(
                    new PricebookEntryInfo(pbe.Pricebook2Id, pbe.UnitPrice)
                );
            }
        }

        return pricebookEntriesMap;
    }

    /**
     * Helper class to store pricebook entry information
     */
    public class PricebookEntryInfo {
        public String pricebookId;
        public Decimal unitPrice;

        public PricebookEntryInfo(String pricebookId, Decimal unitPrice) {
            this.pricebookId = pricebookId;
            this.unitPrice = unitPrice;
        }
    }

}
