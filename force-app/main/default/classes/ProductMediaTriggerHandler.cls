public without sharing class ProductMediaTriggerHandler {

    public static void syncContentKeys(List<ProductMedia> mediaList) {
        // Collect ManagedContent IDs
        Set<Id> managedContentIds = new Set<Id>();
        for (ProductMedia pm : mediaList) {
            if (pm.ElectronicMediaId != null) {
                managedContentIds.add(pm.ElectronicMediaId);
            }
        }

        if (managedContentIds.isEmpty()) {
            return;
        }

        // Query ManagedContent for ContentKeys (System mode - can access)
        Map<Id, String> mcIdToKeyMap = new Map<Id, String>();
        try {
            for (ManagedContent mc : [
                SELECT Id, ContentKey
                FROM ManagedContent
                WHERE Id IN :managedContentIds
            ]) {
                mcIdToKeyMap.put(mc.Id, mc.ContentKey);
                System.debug('ManagedContent ' + mc.Id + ' → ContentKey: ' + mc.ContentKey);
            }
        } catch (Exception e) {
            System.debug('Error querying ManagedContent: ' + e.getMessage());
        }

        // Update ProductMedia records with ContentKeys
        for (ProductMedia pm : mediaList) {
            if (pm.ElectronicMediaId != null) {
                String contentKey = mcIdToKeyMap.get(pm.ElectronicMediaId);
                if (String.isNotBlank(contentKey)) {
                    pm.ContentKey__c = contentKey;
                    System.debug('Setting ProductMedia ' + pm.Id + ' ContentKey__c = ' + contentKey);
                }
            }
        }
    }
}
