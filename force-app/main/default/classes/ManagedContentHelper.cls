public without sharing class ManagedContentHelper {

    public static Map<Id, String> getProductImageUrls(List<Id> productIds, String webstoreId) {
        Map<Id, String> productImageMap = new Map<Id, String>();

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
                    String imageUrl = basePath + '/cms/delivery/media/' + pm.ContentKey__c +
                                     '?version=1.1&channelId=' + channelId + '&oid=' + orgId;
                    productImageMap.put(pm.ProductId, imageUrl);
                    System.debug('SUCCESS: Built URL for Product ' + pm.ProductId + ' using cached ContentKey: ' + imageUrl);
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
}
