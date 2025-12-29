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
                // Explicitly convert Id to String to avoid truncation
                managedContentIdStrings.add(String.valueOf(pm.ElectronicMediaId));
            }
        }

        if (productToManagedContentMap.isEmpty()) {
            System.debug('No ProductMedia records found');
            return productImageMap;
        }

        System.debug('ManagedContent IDs: ' + managedContentIdStrings);

        // Get configuration from Custom Metadata
        String networkId = null;
        String channelId = null;

        try {
            // Query custom metadata for store defaults
            B2B_Store_Defaults__mdt storeDefaults = [
                SELECT Network_Id__c, ManagedContentChannel_Id__c
                FROM B2B_Store_Defaults__mdt
                WHERE DeveloperName = 'Shop_Defaults'
                LIMIT 1
            ];

            networkId = storeDefaults.Network_Id__c;
            channelId = storeDefaults.ManagedContentChannel_Id__c;

            System.debug('Retrieved from Custom Metadata - NetworkId: ' + networkId + ', ChannelId: ' + channelId);
        } catch (Exception e) {
            System.debug('Error reading Custom Metadata: ' + e.getMessage());
            System.debug('Falling back to querying Network directly');

            // Fallback: Query Network directly if custom metadata not configured
            try {
                List<Network> networks = [
                    SELECT Id, Name
                    FROM Network
                    WHERE Name = 'Shop'
                    LIMIT 1
                ];

                if (!networks.isEmpty()) {
                    networkId = networks[0].Id;
                    System.debug('Found NetworkId from query: ' + networkId);
                }
            } catch (Exception ex) {
                System.debug('Error querying Network: ' + ex.getMessage());
            }
        }

        // If we don't have a NetworkId, we can't proceed with ConnectApi
        if (networkId == null) {
            System.debug('No NetworkId found - cannot retrieve ManagedContent');
            return productImageMap;
        }

        // Use channelId from metadata, otherwise fall back to webstoreId
        if (channelId == null) {
            channelId = webstoreId;
            System.debug('WARNING: No ManagedContentChannel_Id in Custom Metadata, falling back to webstoreId: ' + webstoreId);
        }
        System.debug('Using channelId: ' + channelId);

        // Try direct SOQL query first (bypasses ConnectAPI permission issues)
        try {
            System.debug('Attempting direct SOQL query for ManagedContent ContentKeys');

            // Query ManagedContent directly to get ContentKey
            // Using WITHOUT SHARING mode to bypass user permissions
            List<ManagedContent> managedContents = [
                SELECT Id, ContentKey
                FROM ManagedContent
                WHERE Id IN :managedContentIdStrings
            ];

            System.debug('Direct SOQL returned ' + managedContents.size() + ' ManagedContent records');

            if (!managedContents.isEmpty()) {
                // Build map of ManagedContent ID to ContentKey
                Map<String, String> idToKeyMap = new Map<String, String>();
                for (ManagedContent mc : managedContents) {
                    idToKeyMap.put(String.valueOf(mc.Id), mc.ContentKey);
                    System.debug('SOQL Content: Id=' + mc.Id + ', ContentKey=' + mc.ContentKey);
                }

                // Build image URLs
                for (Id productId : productToManagedContentMap.keySet()) {
                    Id managedContentId = productToManagedContentMap.get(productId);
                    String contentKey = idToKeyMap.get(String.valueOf(managedContentId));

                    if (String.isNotBlank(contentKey)) {
                        // Use the same format as working Commerce Search URLs
                        String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                         '?version=1.1&channelId=' + channelId + '&oid=' + orgId;
                        productImageMap.put(productId, imageUrl);
                        System.debug('Built URL for ' + productId + ': ' + imageUrl);
                    }
                }
            } else {
                System.debug('WARNING: Direct SOQL returned 0 ManagedContent records');
                System.debug('Falling back to ConnectAPI approach...');

                // Fallback to ConnectAPI if SOQL fails
                ConnectApi.ManagedContentVersionCollection contentCollection =
                    ConnectApi.ManagedContent.getManagedContentByIds(
                        networkId,
                        managedContentIdStrings,
                        0,
                        managedContentIdStrings.size(),
                        null,
                        null,
                        false
                    );

                System.debug('ConnectApi returned ' + contentCollection.items.size() + ' items');

                if (contentCollection.items.isEmpty()) {
                    System.debug('ERROR: Both SOQL and ConnectAPI returned 0 items for ManagedContent IDs: ' + managedContentIdStrings);
                    System.debug('Possible causes:');
                    System.debug('  1. ManagedContent records do not exist or are not published');
                    System.debug('  2. External Apps Login user lacks object permissions');
                    System.debug('  3. Consider adding a custom ContentKey__c field to ProductMedia');
                }

                // Build map of ManagedContent ID to ContentKey from ConnectAPI
                Map<String, String> idToKeyMap = new Map<String, String>();
                for (ConnectApi.ManagedContentVersion item : contentCollection.items) {
                    System.debug('ConnectAPI Content: ' + item.contentKey + ', managedContentId: ' + item.managedContentId);
                    idToKeyMap.put(item.managedContentId, item.contentKey);
                }

                // Build image URLs
                for (Id productId : productToManagedContentMap.keySet()) {
                    Id managedContentId = productToManagedContentMap.get(productId);
                    String contentKey = idToKeyMap.get(String.valueOf(managedContentId));

                    if (String.isNotBlank(contentKey)) {
                        String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                         '?version=1.1&channelId=' + channelId + '&oid=' + orgId;
                        productImageMap.put(productId, imageUrl);
                        System.debug('Built URL for ' + productId + ': ' + imageUrl);
                    }
                }
            }

        } catch (Exception e) {
            System.debug('Error retrieving ManagedContent: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }

        return productImageMap;
    }
}
