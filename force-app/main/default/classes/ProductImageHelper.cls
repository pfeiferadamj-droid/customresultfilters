/**
 * Product Image Helper
 * Retrieves product image URLs by determining the type of ElectronicMediaId and querying accordingly
 * Alternative to ManagedContentHelper that uses direct SOQL instead of ConnectApi
 *
 * Supports multiple content types:
 * - ContentVersion (standard Salesforce files)
 * - ManagedContentVariant (CMS content with localization)
 * - ManagedContent (direct CMS content)
 *
 * Uses cascading query approach to determine the correct object type
 */
public without sharing class ProductImageHelper {

    /**
     * Get product image URLs by querying the appropriate content object
     * Tries ContentVersion, ManagedContentVariant, then ManagedContent in order
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

        // Step 2: Determine object type and get ContentKey
        // ElectronicMediaId could be: ContentVersion, ManagedContentVariant, or ManagedContent
        // We'll try each in order until we find matching records
        Map<Id, String> contentKeyMap = new Map<Id, String>();
        Map<Id, String> objectTypeMap = new Map<Id, String>(); // Track what type each ID is

        try {
            // First, try to determine what object type ElectronicMediaId refers to
            // It could be ContentVersion, ManagedContent, or ManagedContentVariant

            // Try 1: Query ContentVersion (standard Salesforce file version)
            List<ContentVersion> contentVersions = [
                SELECT Id, ContentDocumentId, FileExtension
                FROM ContentVersion
                WHERE Id IN :managedContentVersionIds
            ];

            System.debug('ProductImageHelper: Found ' + contentVersions.size() + ' ContentVersion records');

            if (!contentVersions.isEmpty()) {
                // ElectronicMediaId is a ContentVersion ID - use ContentDocumentId
                // Note: ContentVersion images may need different URL pattern
                for (ContentVersion cv : contentVersions) {
                    if (String.isNotBlank(cv.ContentDocumentId)) {
                        contentKeyMap.put(cv.Id, cv.ContentDocumentId);
                        objectTypeMap.put(cv.Id, 'ContentVersion');
                        System.debug('  ContentVersion ' + cv.Id + ' -> ContentDocumentId: ' + cv.ContentDocumentId);
                    }
                }
            } else {
                // Try 2: Query ManagedContentVariant
                System.debug('ProductImageHelper: No ContentVersion records found, trying ManagedContentVariant...');
                List<ManagedContentVariant> variantList = [
                    SELECT Id, ManagedContentId
                    FROM ManagedContentVariant
                    WHERE Id IN :managedContentVersionIds
                ];

                System.debug('ProductImageHelper: Found ' + variantList.size() + ' ManagedContentVariant records');

                if (!variantList.isEmpty()) {
                    // ElectronicMediaId is a ManagedContentVariant ID - get the parent ManagedContent
                    Set<Id> managedContentIds = new Set<Id>();
                    Map<Id, Id> variantToContentMap = new Map<Id, Id>();

                    for (ManagedContentVariant mcv : variantList) {
                        managedContentIds.add(mcv.ManagedContentId);
                        variantToContentMap.put(mcv.Id, mcv.ManagedContentId);
                    }

                    // Query ManagedContent for ContentKeys
                    List<ManagedContent> managedContentList = [
                        SELECT Id, ContentKey
                        FROM ManagedContent
                        WHERE Id IN :managedContentIds
                    ];

                    Map<Id, String> mcContentKeyMap = new Map<Id, String>();
                    for (ManagedContent mc : managedContentList) {
                        if (String.isNotBlank(mc.ContentKey)) {
                            mcContentKeyMap.put(mc.Id, mc.ContentKey);
                        }
                    }

                    // Map variant IDs to content keys
                    for (Id variantId : variantToContentMap.keySet()) {
                        Id contentId = variantToContentMap.get(variantId);
                        String contentKey = mcContentKeyMap.get(contentId);
                        if (String.isNotBlank(contentKey)) {
                            contentKeyMap.put(variantId, contentKey);
                            objectTypeMap.put(variantId, 'ManagedContentVariant');
                            System.debug('  ManagedContentVariant ' + variantId + ' -> ContentKey: ' + contentKey);
                        }
                    }
                } else {
                    // Try 3: Direct ManagedContent query as last resort
                    System.debug('ProductImageHelper: No ManagedContentVariant records found, trying ManagedContent...');
                    List<ManagedContent> managedContentList = [
                        SELECT Id, ContentKey
                        FROM ManagedContent
                        WHERE Id IN :managedContentVersionIds
                    ];

                    System.debug('ProductImageHelper: Found ' + managedContentList.size() + ' ManagedContent records');

                    for (ManagedContent mc : managedContentList) {
                        if (String.isNotBlank(mc.ContentKey)) {
                            contentKeyMap.put(mc.Id, mc.ContentKey);
                            objectTypeMap.put(mc.Id, 'ManagedContent');
                            System.debug('  ManagedContent ' + mc.Id + ' -> ContentKey: ' + mc.ContentKey);
                        }
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
            Id electronicMediaId = productToManagedContentVersionMap.get(productId);
            String contentKey = contentKeyMap.get(electronicMediaId);
            String objectType = objectTypeMap.get(electronicMediaId);

            if (String.isNotBlank(contentKey)) {
                String imageUrl;

                if (objectType == 'ContentVersion') {
                    // ContentVersion: use servlet endpoint with ContentDocumentId
                    imageUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_' +
                               contentKey.substring(0, 3) + '&versionId=' + electronicMediaId;
                    System.debug('  Built ContentVersion URL for Product ' + productId + ': ' + imageUrl);
                } else {
                    // ManagedContent/ManagedContentVariant: use CMS delivery URL
                    imageUrl = basePath + '/cms/delivery/media/' + contentKey +
                                     '?channelId=' + webstoreId + '&oid=' + orgId;
                    System.debug('  Built ' + objectType + ' URL for Product ' + productId + ': ' + imageUrl);
                }

                productImageMap.put(productId, imageUrl);
            } else {
                System.debug('  ERROR: No ContentKey found for ElectronicMediaId ' + electronicMediaId +
                           ' (type: ' + objectType + ') for Product ' + productId);
            }
        }

        System.debug('ProductImageHelper: Returning ' + productImageMap.size() + ' image URLs');
        return productImageMap;
    }
}
