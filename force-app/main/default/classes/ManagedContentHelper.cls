/**
 * Helper class to query ManagedContent without sharing restrictions
 * ManagedContent has visibility restrictions in guest/community contexts
 * This allows the query to run in system mode to retrieve ContentKeys
 */
public without sharing class ManagedContentHelper {

    /**
     * Query ManagedContent records and return their ContentKeys
     * Runs without sharing to bypass guest user visibility restrictions
     *
     * @param managedContentIds Set of ManagedContent IDs to query
     * @return Map of ManagedContent ID to ContentKey
     */
    public static Map<Id, String> getContentKeys(Set<Id> managedContentIds) {
        Map<Id, String> contentKeyMap = new Map<Id, String>();

        if (managedContentIds == null || managedContentIds.isEmpty()) {
            return contentKeyMap;
        }

        try {
            List<ManagedContent> managedContentList = [
                SELECT Id, ContentKey
                FROM ManagedContent
                WHERE Id IN :managedContentIds
            ];

            System.debug('ManagedContentHelper found ' + managedContentList.size() + ' ManagedContent records');

            for (ManagedContent mc : managedContentList) {
                if (String.isNotBlank(mc.ContentKey)) {
                    contentKeyMap.put(mc.Id, mc.ContentKey);
                    System.debug('  ManagedContent ' + mc.Id + ' has ContentKey: ' + mc.ContentKey);
                }
            }
        } catch (Exception e) {
            System.debug('Error querying ManagedContent: ' + e.getMessage());
        }

        return contentKeyMap;
    }
}
