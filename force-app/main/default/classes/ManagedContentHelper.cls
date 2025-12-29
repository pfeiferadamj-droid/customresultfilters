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

        // Get the Network ID and ManagedContentChannel ID
        String networkId = null;
        String channelId = null;
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

                // Get the ManagedContentChannel ID for the community
                // This is the correct channelId for CMS content delivery
                // Query for PublicUnauthenticated type channels
                List<ManagedContentChannel> channels = [
                    SELECT Id, Name, Type
                    FROM ManagedContentChannel
                    WHERE Type = 'PublicUnauthenticated'
                    LIMIT 1
                ];

                if (!channels.isEmpty()) {
                    channelId = channels[0].Id;
                    System.debug('Found ManagedContentChannel ID: ' + channelId + ' (Name: ' + channels[0].Name + ', Type: ' + channels[0].Type + ')');
                } else {
                    // If no community type found, try querying all channels
                    System.debug('No community-type ManagedContentChannel found, querying all channels...');
                    List<ManagedContentChannel> allChannels = [
                        SELECT Id, Name, Type
                        FROM ManagedContentChannel
                        LIMIT 5
                    ];
                    System.debug('Available ManagedContentChannels: ' + allChannels);
                    if (!allChannels.isEmpty()) {
                        channelId = allChannels[0].Id;
                        System.debug('Using first available channel: ' + channelId);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error getting NetworkId/ChannelId: ' + e.getMessage());
        }

        // If we don't have a NetworkId, we can't proceed with ConnectApi
        if (networkId == null) {
            System.debug('No NetworkId found - cannot retrieve ManagedContent');
            return productImageMap;
        }

        // Use ManagedContentChannel ID as channelId if available, otherwise fall back to webstoreId
        if (channelId == null) {
            channelId = webstoreId;
            System.debug('WARNING: No ManagedContentChannel found, falling back to webstoreId: ' + webstoreId);
        }
        System.debug('Using channelId: ' + channelId);

        // Use ConnectApi to get ManagedContent by IDs
        try {
            // Call ConnectAPI with the list of ManagedContent IDs
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
                System.debug('WARNING: ConnectAPI returned 0 items for ManagedContent IDs: ' + managedContentIdStrings);
                System.debug('This usually means:');
                System.debug('  1. ManagedContent is not published to the community/channel');
                System.debug('  2. ManagedContent is in a ContentSpace not associated with this community');
                System.debug('  3. Current user lacks permission to access this content via ConnectAPI');
                System.debug('  4. ElectronicMediaId field contains an ID that is not actually ManagedContent');
                System.debug('Consider adding a custom ContentKey__c field to ProductMedia to store the key directly.');
            }

            // Build map of ManagedContent ID to ContentKey
            Map<String, String> idToKeyMap = new Map<String, String>();
            for (ConnectApi.ManagedContentVersion item : contentCollection.items) {
                System.debug('Content: ' + item.contentKey + ', managedContentId: ' + item.managedContentId);
                idToKeyMap.put(item.managedContentId, item.contentKey);
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

        } catch (Exception e) {
            System.debug('Error using ConnectApi: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }

        return productImageMap;
    }
}
