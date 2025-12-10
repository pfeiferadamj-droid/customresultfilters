public with sharing class CategoryProductsWithParentsController {

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
    public static String getCategoryProductsWithParents(
        String categoryId,
        String webstoreId,
        String effectiveAccountId,
        Integer pageSize,
        Integer pageNumber,
        String sortRuleId,
        String refinementsJSON,
        Boolean restrictToParents,
        String parentFieldName
    ) {
        try {
            // Validate required parameters
            validateRequiredParams(categoryId, webstoreId);

            Integer effectivePageSize = getEffectivePageSize(pageSize);
            Integer effectivePage = getEffectivePage(pageNumber);
            List<Map<String, Object>> parsedRefinements = parseRefinements(refinementsJSON);
            Boolean hasSortRule = String.isNotBlank(sortRuleId);

            Object searchResultsObj = null;
            Set<String> productIds = new Set<String>();

            if (Test.isRunningTest()) {
                // Mock data for tests
                searchResultsObj = getMockSearchResults();
            } else {
                // Build search input
                ConnectApi.ProductSearchInput searchInput = new ConnectApi.ProductSearchInput();
                searchInput.categoryId = categoryId;
                searchInput.pageSize = effectivePageSize;
                searchInput.page = effectivePage;
                searchInput.includePrices = true;

                // Apply user-selected refinements
                if (!parsedRefinements.isEmpty()) {
                    List<ConnectApi.DistinctValueRefinementInput> refinements = 
                        new List<ConnectApi.DistinctValueRefinementInput>();
                    for (Map<String, Object> refMap : parsedRefinements) {
                        ConnectApi.DistinctValueRefinementInput refinement = new ConnectApi.DistinctValueRefinementInput();
                        refinement.nameOrId = (String) refMap.get('nameOrId');

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

                        // Safely convert values list
                        List<String> valuesList = new List<String>();
                        Object valuesObj = refMap.get('values');
                        if (valuesObj instanceof List<Object>) {
                            for (Object val : (List<Object>) valuesObj) {
                                if (val != null) {
                                    valuesList.add(String.valueOf(val));
                                }
                            }
                        }
                        refinement.values = valuesList;
                        refinements.add(refinement);
                    }
                    searchInput.refinements = refinements;
                }

                // Apply sort rule
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

                // Collect product IDs
                if (searchResults != null &&
                    searchResults.productsPage != null &&
                    searchResults.productsPage.products != null) 
                {
                    for (ConnectApi.ProductSummary product : searchResults.productsPage.products) {
                        productIds.add(product.id);
                    }
                }
            }

            // ---- POST-SEARCH FILTER: ONLY VARIATION PARENT ----
            Set<String> variationParentIds = new Set<String>();
            if (!productIds.isEmpty()) {
                // Build dynamic SOQL query
                String queryString = 'SELECT Id FROM Product2 WHERE Id IN :productIds AND ProductClass = \'VariationParent\'';

                // Add parent field filter if restrictToParents is enabled
                if (restrictToParents == true && String.isNotBlank(parentFieldName)) {
                    queryString += ' AND ' + parentFieldName + ' = \'Yes\'';
                }

                for (Product2 p : Database.query(queryString)) {
                    variationParentIds.add(p.Id);
                }
            }

            // Build serializable list of filtered products
            List<Map<String, Object>> filteredProducts = new List<Map<String, Object>>();
            if (searchResultsObj != null && searchResultsObj instanceof ConnectApi.ProductSearchResults) {
                ConnectApi.ProductSearchResults sr = (ConnectApi.ProductSearchResults) searchResultsObj;
                if (sr.productsPage != null && sr.productsPage.products != null) {
                    for (ConnectApi.ProductSummary prod : sr.productsPage.products) {
                        if (variationParentIds.contains(prod.id)) {
                            Map<String, Object> prodMap = new Map<String, Object>{
                                'id' => prod.id,
                                'name' => prod.name
                                // Add other fields as needed
                            };
                            filteredProducts.add(prodMap);
                        }
                    }
                }
            }

            // Build final response
            Map<String, Object> response = new Map<String, Object>{
                'products' => filteredProducts,
                'pricebookEntries' => getPricebookEntriesForProducts(variationParentIds)
            };

            return JSON.serialize(response);

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching products: ' + e.getMessage());
        }
    }

    // -------------------------
    // HELPER METHODS
    // -------------------------

    private static void validateRequiredParams(String categoryId, String webstoreId) {
        if (String.isBlank(categoryId)) {
            throw new AuraHandledException('categoryId is required.');
        }
        if (String.isBlank(webstoreId)) {
            throw new AuraHandledException('webstoreId is required.');
        }
    }

    private static Integer getEffectivePageSize(Integer pageSize) {
        return (pageSize != null && pageSize > 0) ? pageSize : 20;
    }

    private static Integer getEffectivePage(Integer pageNumber) {
        return (pageNumber != null && pageNumber > 0) ? pageNumber - 1 : 0;
    }

    private static List<Map<String, Object>> parseRefinements(String refinementsJSON) {
        if (String.isBlank(refinementsJSON)) return new List<Map<String, Object>>();

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        Object deserializedObj = JSON.deserializeUntyped(refinementsJSON);

        if (deserializedObj instanceof List<Object>) {
            for (Object item : (List<Object>) deserializedObj) {
                if (item instanceof Map<String, Object>) {
                    result.add((Map<String, Object>) item);
                }
            }
        }

        return result;
    }

    private static Object getMockSearchResults() {
        return null; // Implement as needed for unit tests
    }

    private static Map<String, List<PricebookEntryInfo>> getPricebookEntriesForProducts(Set<String> productIds) {
        return new Map<String, List<PricebookEntryInfo>>(); // Implement real logic
    }

    public class PricebookEntryInfo {
        public String id;
        public Decimal price;
    }
}
