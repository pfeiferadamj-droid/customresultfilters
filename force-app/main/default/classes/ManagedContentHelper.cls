public without sharing class ManagedContentHelper {

    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

        System.debug('==== ManagedContentHelper.getProductImageUrls START ====');
        System.debug('  Product IDs count: ' + (productIds != null ? productIds.size() : 0));
        System.debug('  Product IDs: ' + productIds);
        System.debug('  Webstore ID: ' + webstoreId);

        // Handle null or empty productIds
        if (productIds == null || productIds.isEmpty()) {
            System.debug('ManagedContentHelper: No product IDs provided');
            System.debug('==== ManagedContentHelper.getProductImageUrls END (no IDs) ====');
            return productImageMap;
        }

        String orgId = UserInfo.getOrganizationId();
        String basePath = '/shop/sfsites/c';
        System.debug('  Org ID: ' + orgId);

        // Get configuration from Custom Metadata for channelId
        String channelId = null;

        try {
            // Try to query custom metadata for store defaults
            // Note: ManagedContentChannel_Id__c field may not exist yet, so handle errors gracefully
            List<B2B_Store_Defaults__mdt> storeDefaultsList = [
                SELECT Id
                FROM B2B_Store_Defaults__mdt
                WHERE DeveloperName = 'Shop_Defaults'
                LIMIT 1
            ];

            if (!storeDefaultsList.isEmpty()) {
                // Field doesn't exist yet in metadata, will be added in future version
                // For now, always fall back to webstoreId
                System.debug('Store defaults found, using webstoreId as channelId');
            }
        } catch (Exception e) {
            System.debug('Error reading Custom Metadata: ' + e.getMessage());
        }

        // Use webstoreId as channelId
        channelId = webstoreId;
        System.debug('Using webstoreId as channelId: ' + channelId);

        // Validate channelId
        if (String.isBlank(channelId)) {
            System.debug('ERROR: channelId is blank! Cannot build image URLs without channelId.');
            System.debug('Make sure webstoreId is configured in Experience Builder for customCategoryProductGrid');
            return productImageMap;
        }

        // Query ProductMedia with cached ContentKey__c field
        // ContentKey__c is automatically populated by ProductMediaTrigger
        try {
            List<ProductMedia> mediaList = [
                SELECT ProductId, ContentKey__c
                FROM ProductMedia
                WHERE ProductId IN :productIds
                AND ContentKey__c != null
                ORDER BY SortOrder ASC NULLS LAST
            ];

            System.debug('Found ' + mediaList.size() + ' ProductMedia records with ContentKey__c');

            // Build image URLs using cached ContentKey
            for (ProductMedia pm : mediaList) {
                if (!productImageMap.containsKey(pm.ProductId) && String.isNotBlank(pm.ContentKey__c)) {
                    String imageUrl = buildImageUrl(pm.ContentKey__c, channelId, orgId);
                    if (imageUrl != null) {
                        productImageMap.put(pm.ProductId, imageUrl);
                        System.debug('SUCCESS: Built URL for Product ' + pm.ProductId + ' using cached ContentKey: ' + imageUrl);
                    }
                }
            }

            if (productImageMap.isEmpty()) {
                System.debug('WARNING: No ProductMedia records with ContentKey__c found');
                System.debug('Ensure ProductMediaTrigger is active and ContentKey__c has been populated');
                System.debug('NOTE: This is likely why images are not rendering!');
            } else {
                System.debug('Successfully built ' + productImageMap.size() + ' image URLs');
            }
        } catch (Exception e) {
            System.debug('ERROR retrieving ProductMedia: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }

        System.debug('  Returning image map with ' + productImageMap.size() + ' entries');
        System.debug('  Image map: ' + productImageMap);
        System.debug('==== ManagedContentHelper.getProductImageUrls END ====');

        return productImageMap;
    }

    /**
     * Helper method to build image URL from ContentKey
     * @param contentKey The content key from ProductMedia
     * @param channelId The channel ID (from metadata or webstore)
     * @param orgId The organization ID
     * @return The complete image URL
     */
    @TestVisible
    private static String buildImageUrl(String contentKey, String channelId, String orgId) {
        if (String.isBlank(contentKey)) {
            return null;
        }
        String basePath = '/shop/sfsites/c';
        return basePath + '/cms/delivery/media/' + contentKey +
               '?version=1.1&channelId=' + channelId + '&oid=' + orgId;
    }
}
