public without sharing class ManagedContentHelper {

    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

        String orgId = UserInfo.getOrganizationId();
        String basePath = '/shop/sfsites/c';

        // Get ProductMedia -> ManagedContent mapping
        Map<Id, Id> productToManagedContentMap = new Map<Id, Id>();
        Set<Id> managedContentIds = new Set<Id>();

        for (ProductMedia pm : [
            SELECT ProductId, ElectronicMediaId
            FROM ProductMedia
            WHERE ProductId IN :productIds
            AND ElectronicMediaId != null
            ORDER BY SortOrder ASC NULLS LAST
        ]) {
            if (!productToManagedContentMap.containsKey(pm.ProductId)) {
                productToManagedContentMap.put(pm.ProductId, pm.ElectronicMediaId);
                managedContentIds.add(pm.ElectronicMediaId);
            }
        }

        if (productToManagedContentMap.isEmpty()) {
            System.debug('No ProductMedia records found');
            return productImageMap;
        }

        System.debug('ManagedContent IDs: ' + managedContentIds);

        // Query ManagedContent to get ContentKeys (IDs are not the same as ContentKeys!)
        Map<Id, String> contentKeyMap = new Map<Id, String>();
        try {
            List<ManagedContent> managedContentList = [
                SELECT Id, ContentKey
                FROM ManagedContent
                WHERE Id IN :managedContentIds
            ];

            System.debug('Found ' + managedContentList.size() + ' ManagedContent records');

            for (ManagedContent mc : managedContentList) {
                if (String.isNotBlank(mc.ContentKey)) {
                    contentKeyMap.put(mc.Id, mc.ContentKey);
                    System.debug('  ManagedContent ' + mc.Id + ' -> ContentKey: ' + mc.ContentKey);
                }
            }

        } catch (Exception e) {
            System.debug('Error querying ManagedContent: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return productImageMap;
        }

        // Build image URLs using ContentKeys
        for (Id productId : productToManagedContentMap.keySet()) {
            Id managedContentId = productToManagedContentMap.get(productId);
            String contentKey = contentKeyMap.get(managedContentId);

            if (String.isNotBlank(contentKey)) {
                String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                 '?channelId=' + webstoreId + '&oid=' + orgId;
                productImageMap.put(productId, imageUrl);
                System.debug('Built URL for ' + productId + ': ' + imageUrl);
            } else {
                System.debug('No ContentKey found for ManagedContent ' + managedContentId);
            }
        }

        return productImageMap;
    }
}
