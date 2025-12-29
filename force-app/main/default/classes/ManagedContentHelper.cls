public without sharing class ManagedContentHelper {

    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

        String orgId = UserInfo.getOrganizationId();
        String basePath = '/shop/sfsites/c';

        // Get ProductMedia -> ManagedContent mapping
        Map<Id, Id> productToManagedContentMap = new Map<Id, Id>();
        List<String> managedContentIdStrings = new List<String>();

        for (ProductMedia pm : [
            SELECT ProductId, ElectronicMediaId
            FROM ProductMedia
            WHERE ProductId IN :productIds
            AND ElectronicMediaId != null
            ORDER BY SortOrder ASC NULLS LAST
        ]) {
            if (!productToManagedContentMap.containsKey(pm.ProductId)) {
                productToManagedContentMap.put(pm.ProductId, pm.ElectronicMediaId);
                managedContentIdStrings.add(pm.ElectronicMediaId);
            }
        }

        if (productToManagedContentMap.isEmpty()) {
            System.debug('No ProductMedia records found');
            return productImageMap;
        }

        System.debug('ManagedContent IDs: ' + managedContentIdStrings);

        // Get the Network ID - query all networks and find the one named "Shop"
        String networkId = null;
        try {
            List<Network> networks = [
                SELECT Id, Name
                FROM Network
                WHERE Name = 'Shop'
                LIMIT 1
            ];

            if (!networks.isEmpty()) {
                networkId = networks[0].Id;
                System.debug('Found NetworkId for Shop: ' + networkId);
            }
        } catch (Exception e) {
            System.debug('Error getting NetworkId: ' + e.getMessage());
        }

        // If we don't have a NetworkId, we can't proceed with ConnectApi
        if (networkId == null) {
            System.debug('No NetworkId found - cannot retrieve ManagedContent');
            return productImageMap;
        }

        // Use ConnectApi to get ManagedContent by IDs (not ContentKeys)
        try {
            // Build map of ManagedContent ID to ContentKey by calling ConnectAPI for each ID
            Map<String, String> idToKeyMap = new Map<String, String>();

            for (String managedContentId : managedContentIdStrings) {
                try {
                    ConnectApi.ManagedContentVersion contentVersion =
                        ConnectApi.ManagedContent.getManagedContentByVersion(
                            networkId,
                            managedContentId,
                            0
                        );

                    if (contentVersion != null && String.isNotBlank(contentVersion.contentKey)) {
                        idToKeyMap.put(contentVersion.managedContentId, contentVersion.contentKey);
                        System.debug('Retrieved ContentKey for ' + managedContentId + ': ' + contentVersion.contentKey);
                    }
                } catch (Exception innerEx) {
                    System.debug('Error retrieving ManagedContent ' + managedContentId + ': ' + innerEx.getMessage());
                }
            }

            System.debug('ConnectApi returned ' + idToKeyMap.size() + ' ContentKeys');

            // Build image URLs
            for (Id productId : productToManagedContentMap.keySet()) {
                Id managedContentId = productToManagedContentMap.get(productId);
                String contentKey = idToKeyMap.get(String.valueOf(managedContentId));

                if (String.isNotBlank(contentKey)) {
                    String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                     '?channelId=' + webstoreId + '&oid=' + orgId;
                    productImageMap.put(productId, imageUrl);
                    System.debug('Built URL for ' + productId + ': ' + imageUrl);
                }
            }

        } catch (Exception e) {
            System.debug('Error using ConnectApi: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }

        return productImageMap;
    }
}
