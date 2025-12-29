public without sharing class ManagedContentHelper {

    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

        String orgId = UserInfo.getOrganizationId();
        String basePath = '/shop/sfsites/c';

        // Get ProductMedia -> ManagedContent mapping
        // Try using ContentDocumentID__c if available, otherwise fall back to ElectronicMediaId
        Map<Id, Id> productToManagedContentMap = new Map<Id, Id>();
        Map<Id, String> productToContentDocumentMap = new Map<Id, String>();
        List<String> managedContentIdStrings = new List<String>();
        List<String> contentDocumentIds = new List<String>();

        // Query ProductMedia - check for both ElectronicMediaId and ContentDocumentID__c
        String pmQuery = 'SELECT ProductId, ElectronicMediaId';

        // Check if ContentDocumentID__c field exists (custom field)
        Boolean hasContentDocField = false;
        try {
            Schema.SObjectType pmType = Schema.getGlobalDescribe().get('ProductMedia');
            if (pmType != null) {
                Map<String, Schema.SObjectField> fieldMap = pmType.getDescribe().fields.getMap();
                hasContentDocField = fieldMap.containsKey('ContentDocumentID__c');
            }
        } catch (Exception e) {
            System.debug('Error checking for ContentDocumentID__c field: ' + e.getMessage());
        }

        if (hasContentDocField) {
            pmQuery += ', ContentDocumentID__c';
            System.debug('ContentDocumentID__c field found on ProductMedia - will use for lookup');
        }

        pmQuery += ' FROM ProductMedia WHERE ProductId IN :productIds AND ElectronicMediaId != null ORDER BY SortOrder ASC NULLS LAST';

        for (SObject pmObj : Database.query(pmQuery)) {
            Id productId = (Id) pmObj.get('ProductId');
            Id electronicMediaId = (Id) pmObj.get('ElectronicMediaId');

            if (!productToManagedContentMap.containsKey(productId)) {
                productToManagedContentMap.put(productId, electronicMediaId);
                managedContentIdStrings.add(String.valueOf(electronicMediaId));

                // Also store ContentDocumentID__c if available
                if (hasContentDocField) {
                    String contentDocId = (String) pmObj.get('ContentDocumentID__c');
                    if (String.isNotBlank(contentDocId)) {
                        productToContentDocumentMap.put(productId, contentDocId);
                        contentDocumentIds.add(contentDocId);
                        System.debug('Product ' + productId + ' has ContentDocumentID: ' + contentDocId);
                    }
                }
            }
        }

        if (productToManagedContentMap.isEmpty()) {
            System.debug('No ProductMedia records found');
            return productImageMap;
        }

        System.debug('ManagedContent IDs: ' + managedContentIdStrings);
        System.debug('ContentDocument IDs: ' + contentDocumentIds);

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

        // APPROACH 1: Try using ContentDocument → ManagedContent relationship if we have ContentDocumentIDs
        if (!contentDocumentIds.isEmpty()) {
            try {
                System.debug('Attempting to query ManagedContent via ContentDocument relationship');

                // Query ContentDocumentLink to find ManagedContent linked to these ContentDocuments
                // Note: Cannot filter on LinkedEntity.Type in SOQL, must filter in Apex
                List<ContentDocumentLink> cdLinks = [
                    SELECT ContentDocumentId, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE ContentDocumentId IN :contentDocumentIds
                ];

                System.debug('Found ' + cdLinks.size() + ' ContentDocumentLinks');

                // Get the ManagedContent IDs from the links
                // Filter to only ManagedContent (ID prefix '20Y')
                Set<String> managedContentIdsFromCD = new Set<String>();
                Map<String, String> contentDocToManagedContentMap = new Map<String, String>();

                for (ContentDocumentLink cdl : cdLinks) {
                    String linkedEntityId = String.valueOf(cdl.LinkedEntityId);
                    // ManagedContent IDs start with '20Y'
                    if (linkedEntityId.startsWith('20Y')) {
                        managedContentIdsFromCD.add(linkedEntityId);
                        contentDocToManagedContentMap.put(String.valueOf(cdl.ContentDocumentId), linkedEntityId);
                    }
                }

                System.debug('Found ' + managedContentIdsFromCD.size() + ' links to ManagedContent (filtered by 20Y prefix)');

                if (!managedContentIdsFromCD.isEmpty()) {

                    // Query ManagedContent for ContentKeys
                    List<ManagedContent> managedContents = [
                        SELECT Id, ContentKey
                        FROM ManagedContent
                        WHERE Id IN :managedContentIdsFromCD
                    ];

                    System.debug('Retrieved ' + managedContents.size() + ' ManagedContent records via ContentDocument');

                    if (!managedContents.isEmpty()) {
                        Map<String, String> mcIdToKeyMap = new Map<String, String>();
                        for (ManagedContent mc : managedContents) {
                            mcIdToKeyMap.put(String.valueOf(mc.Id), mc.ContentKey);
                            System.debug('ContentDocument approach - ManagedContent: Id=' + mc.Id + ', ContentKey=' + mc.ContentKey);
                        }

                        // Build image URLs for products that have ContentDocumentID__c
                        for (Id productId : productToContentDocumentMap.keySet()) {
                            String contentDocId = productToContentDocumentMap.get(productId);
                            String mcId = contentDocToManagedContentMap.get(contentDocId);
                            if (mcId != null) {
                                String contentKey = mcIdToKeyMap.get(mcId);
                                if (String.isNotBlank(contentKey)) {
                                    String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                                     '?version=1.1&channelId=' + channelId + '&oid=' + orgId;
                                    productImageMap.put(productId, imageUrl);
                                    System.debug('SUCCESS: Built URL via ContentDocument for ' + productId + ': ' + imageUrl);
                                }
                            }
                        }

                        // If we got all images, return early
                        if (productImageMap.size() == productIds.size()) {
                            System.debug('All images retrieved via ContentDocument approach - returning');
                            return productImageMap;
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error using ContentDocument approach: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
            }
        }

        // APPROACH 2: Try direct SOQL query on ManagedContent (bypasses ConnectAPI permission issues)
        // Only runs if we haven't retrieved all images via ContentDocument approach
        if (productImageMap.size() < productIds.size()) {
            try {
                System.debug('Attempting direct SOQL query for ManagedContent ContentKeys via ElectronicMediaId');

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
                        System.debug('Direct SOQL - ManagedContent: Id=' + mc.Id + ', ContentKey=' + mc.ContentKey);
                    }

                    // Build image URLs for products not already in the map
                    for (Id productId : productToManagedContentMap.keySet()) {
                        if (!productImageMap.containsKey(productId)) {
                            Id managedContentId = productToManagedContentMap.get(productId);
                            String contentKey = idToKeyMap.get(String.valueOf(managedContentId));

                            if (String.isNotBlank(contentKey)) {
                                String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                                 '?version=1.1&channelId=' + channelId + '&oid=' + orgId;
                                productImageMap.put(productId, imageUrl);
                                System.debug('SUCCESS: Built URL via direct SOQL for ' + productId + ': ' + imageUrl);
                            }
                        }
                    }
                } else {
                    System.debug('WARNING: Direct SOQL returned 0 ManagedContent records');
                    System.debug('Falling back to ConnectAPI approach...');

                        // APPROACH 3: Fallback to ConnectAPI if SOQL fails
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
                        System.debug('ERROR: All approaches failed (ContentDocument, Direct SOQL, ConnectAPI) for ManagedContent IDs: ' + managedContentIdStrings);
                        System.debug('Possible causes:');
                        System.debug('  1. ManagedContent records do not exist or are not published');
                        System.debug('  2. External Apps Login user lacks object permissions');
                        System.debug('  3. Consider populating ContentDocumentID__c field on ProductMedia');
                    }

                    // Build map of ManagedContent ID to ContentKey from ConnectAPI
                    Map<String, String> idToKeyMap = new Map<String, String>();
                    for (ConnectApi.ManagedContentVersion item : contentCollection.items) {
                        System.debug('ConnectAPI Content: ' + item.contentKey + ', managedContentId: ' + item.managedContentId);
                        idToKeyMap.put(item.managedContentId, item.contentKey);
                    }

                    // Build image URLs for products not already in the map
                    for (Id productId : productToManagedContentMap.keySet()) {
                        if (!productImageMap.containsKey(productId)) {
                            Id managedContentId = productToManagedContentMap.get(productId);
                            String contentKey = idToKeyMap.get(String.valueOf(managedContentId));

                            if (String.isNotBlank(contentKey)) {
                                String imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                                 '?version=1.1&channelId=' + channelId + '&oid=' + orgId;
                                productImageMap.put(productId, imageUrl);
                                System.debug('SUCCESS: Built URL via ConnectAPI for ' + productId + ': ' + imageUrl);
                            }
                        }
                    }
                }

            } catch (Exception e) {
                System.debug('Error retrieving ManagedContent: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
            }
        }

        return productImageMap;
    }
}
