/**
 * Product Image Helper
 * Retrieves product image URLs by querying ManagedContent for ContentKeys
 * Alternative to ManagedContentHelper that uses direct SOQL instead of ConnectApi
 */
public without sharing class ProductImageHelper {

    /**
     * Get product image URLs using direct ManagedContent queries
     * @param productIds List of Product2 IDs
     * @param webstoreId The webstore ID for the image URL
     * @return Map of Product2 Id to image URL
     */
    @AuraEnabled
    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

        String orgId = UserInfo.getOrganizationId();
        String basePath = '/shop/sfsites/c';

        // Step 1: Get ProductMedia -> ManagedContent mapping
        Map<Id, Id> productToManagedContentMap = new Map<Id, Id>();
        Set<Id> managedContentIds = new Set<Id>();

        System.debug('ProductImageHelper: Fetching ProductMedia for ' + productIds.size() + ' products');

        for (ProductMedia pm : [
            SELECT ProductId, ElectronicMediaId
            FROM ProductMedia
            WHERE ProductId IN :productIds
            AND ElectronicMediaId != null
            ORDER BY SortOrder ASC NULLS LAST
        ]) {
            // Only take the first image per product (lowest SortOrder)
            if (!productToManagedContentMap.containsKey(pm.ProductId)) {
                productToManagedContentMap.put(pm.ProductId, pm.ElectronicMediaId);
                managedContentIds.add(pm.ElectronicMediaId);
                System.debug('  Product ' + pm.ProductId + ' -> ManagedContent ' + pm.ElectronicMediaId);
            }
        }

        if (productToManagedContentMap.isEmpty()) {
            System.debug('ProductImageHelper: No ProductMedia records found');
            return productImageMap;
        }

        System.debug('ProductImageHelper: Found ' + managedContentIds.size() + ' ManagedContent IDs');

        // Step 2: Query ManagedContent to get ContentKeys
        // Note: ElectronicMediaId is a ManagedContent ID, NOT a ContentKey
        // We need to query ManagedContent.ContentKey field
        Map<Id, String> contentKeyMap = new Map<Id, String>();

        try {
            List<ManagedContent> managedContentList = [
                SELECT Id, ContentKey
                FROM ManagedContent
                WHERE Id IN :managedContentIds
            ];

            System.debug('ProductImageHelper: Found ' + managedContentList.size() + ' ManagedContent records');

            for (ManagedContent mc : managedContentList) {
                if (String.isNotBlank(mc.ContentKey)) {
                    contentKeyMap.put(mc.Id, mc.ContentKey);
                    System.debug('  ManagedContent ' + mc.Id + ' -> ContentKey: ' + mc.ContentKey);
                } else {
                    System.debug('  WARNING: ManagedContent ' + mc.Id + ' has null ContentKey');
                }
            }

        } catch (Exception e) {
            System.debug('ERROR querying ManagedContent: ' + e.getMessage());
            System.debug('  Error type: ' + e.getTypeName());
            System.debug('  Stack trace: ' + e.getStackTraceString());
            return productImageMap;
        }

        // Step 3: Build image URLs using ContentKeys
        for (Id productId : productToManagedContentMap.keySet()) {
            Id managedContentId = productToManagedContentMap.get(productId);
            String contentKey = contentKeyMap.get(managedContentId);

            if (String.isNotBlank(contentKey)) {
                // Build CMS delivery URL
                String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                 '?channelId=' + webstoreId + '&oid=' + orgId;
                productImageMap.put(productId, imageUrl);
                System.debug('  Built URL for Product ' + productId + ': ' + imageUrl);
            } else {
                System.debug('  ERROR: No ContentKey found for ManagedContent ' + managedContentId + ' (Product ' + productId + ')');
            }
        }

        System.debug('ProductImageHelper: Returning ' + productImageMap.size() + ' image URLs');
        return productImageMap;
    }
}
