public without sharing class ManagedContentHelper {

    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

        // Handle null or empty productIds
        if (productIds == null || productIds.isEmpty()) {
            System.debug('ManagedContentHelper: No product IDs provided');
            return productImageMap;
        }

        String orgId = UserInfo.getOrganizationId();
        String basePath = '/shop/sfsites/c';

        // Get configuration from Custom Metadata for channelId
        String channelId = null;

        try {
            // Query custom metadata for store defaults
            B2B_Store_Defaults__mdt storeDefaults = [
                SELECT ManagedContentChannel_Id__c
                FROM B2B_Store_Defaults__mdt
                WHERE DeveloperName = 'Shop_Defaults'
                LIMIT 1
            ];

            channelId = storeDefaults.ManagedContentChannel_Id__c;
            System.debug('Retrieved channelId from Custom Metadata: ' + channelId);
        } catch (Exception e) {
            System.debug('Error reading Custom Metadata: ' + e.getMessage());
        }

        // Use channelId from metadata, otherwise fall back to webstoreId
        if (channelId == null) {
            channelId = webstoreId;
            System.debug('WARNING: No ManagedContentChannel_Id in Custom Metadata, falling back to webstoreId: ' + webstoreId);
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
            }
        } catch (Exception e) {
            System.debug('Error retrieving ProductMedia: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }

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
