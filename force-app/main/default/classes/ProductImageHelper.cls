/**
 * Product Image Helper
 * Retrieves product image URLs by querying ManagedContentVersion for ContentKeys
 * Alternative to ManagedContentHelper that uses direct SOQL instead of ConnectApi
 *
 * Note: ProductMedia.ElectronicMediaId is a ManagedContentVersion ID, not ManagedContent ID
 */
public without sharing class ProductImageHelper {

    /**
     * Get product image URLs using direct ManagedContentVersion queries
     * @param productIds List of Product2 IDs
     * @param webstoreId The webstore ID for the image URL
     * @return Map of Product2 Id to image URL
     */
    @AuraEnabled
    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

        String orgId = UserInfo.getOrganizationId();
        String basePath = '/shop/sfsites/c';

        // Step 1: Get ProductMedia -> ManagedContentVersion mapping
        Map<Id, Id> productToManagedContentVersionMap = new Map<Id, Id>();
        Set<Id> managedContentVersionIds = new Set<Id>();

        System.debug('ProductImageHelper: Fetching ProductMedia for ' + productIds.size() + ' products');

        for (ProductMedia pm : [
            SELECT ProductId, ElectronicMediaId
            FROM ProductMedia
            WHERE ProductId IN :productIds
            AND ElectronicMediaId != null
            ORDER BY SortOrder ASC NULLS LAST
        ]) {
            // Only take the first image per product (lowest SortOrder)
            if (!productToManagedContentVersionMap.containsKey(pm.ProductId)) {
                productToManagedContentVersionMap.put(pm.ProductId, pm.ElectronicMediaId);
                managedContentVersionIds.add(pm.ElectronicMediaId);
                System.debug('  Product ' + pm.ProductId + ' -> ElectronicMediaId ' + pm.ElectronicMediaId);
            }
        }

        if (productToManagedContentVersionMap.isEmpty()) {
            System.debug('ProductImageHelper: No ProductMedia records found');
            return productImageMap;
        }

        System.debug('ProductImageHelper: Found ' + managedContentVersionIds.size() + ' ElectronicMediaIds');

        // Step 2: Query ManagedContentVersion to get ManagedContentId and ContentKey
        // Note: ElectronicMediaId appears to be a ManagedContentVersion ID, not ManagedContent ID
        Map<Id, String> contentKeyMap = new Map<Id, String>();

        try {
            // Try querying ManagedContentVersion first
            List<ManagedContentVersion> versionList = [
                SELECT Id, ManagedContentId, ContentKey
                FROM ManagedContentVersion
                WHERE Id IN :managedContentVersionIds
            ];

            System.debug('ProductImageHelper: Found ' + versionList.size() + ' ManagedContentVersion records');

            if (!versionList.isEmpty()) {
                // ElectronicMediaId is a ManagedContentVersion ID
                for (ManagedContentVersion mcv : versionList) {
                    if (String.isNotBlank(mcv.ContentKey)) {
                        contentKeyMap.put(mcv.Id, mcv.ContentKey);
                        System.debug('  ManagedContentVersion ' + mcv.Id + ' -> ContentKey: ' + mcv.ContentKey);
                    } else {
                        System.debug('  WARNING: ManagedContentVersion ' + mcv.Id + ' has null ContentKey');
                    }
                }
            } else {
                // If no versions found, try querying ManagedContent directly
                System.debug('ProductImageHelper: No ManagedContentVersion records found, trying ManagedContent...');
                List<ManagedContent> managedContentList = [
                    SELECT Id, ContentKey
                    FROM ManagedContent
                    WHERE Id IN :managedContentVersionIds
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
            }

        } catch (Exception e) {
            System.debug('ERROR querying ManagedContent/Version: ' + e.getMessage());
            System.debug('  Error type: ' + e.getTypeName());
            System.debug('  Stack trace: ' + e.getStackTraceString());
            return productImageMap;
        }

        // Step 3: Build image URLs using ContentKeys
        for (Id productId : productToManagedContentVersionMap.keySet()) {
            Id versionId = productToManagedContentVersionMap.get(productId);
            String contentKey = contentKeyMap.get(versionId);

            if (String.isNotBlank(contentKey)) {
                // Build CMS delivery URL
                String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                 '?channelId=' + webstoreId + '&oid=' + orgId;
                productImageMap.put(productId, imageUrl);
                System.debug('  Built URL for Product ' + productId + ': ' + imageUrl);
            } else {
                System.debug('  ERROR: No ContentKey found for ElectronicMediaId ' + versionId + ' (Product ' + productId + ')');
            }
        }

        System.debug('ProductImageHelper: Returning ' + productImageMap.size() + ' image URLs');
        return productImageMap;
    }
}
