/**
 * Simplest verification: Test StoreDefaultsHelper methods
 * This verifies the metadata is loading correctly via the helper class
 */

System.debug('=== Testing StoreDefaultsHelper ===');
System.debug('My Products Category ID: ' + StoreDefaultsHelper.getMyProductsCategoryId());
System.debug('Quick Turn Category ID: ' + StoreDefaultsHelper.getQuickTurnCategoryId());
System.debug('Quick Turn Category Name: ' + StoreDefaultsHelper.getQuickTurnCategoryName());
System.debug('My Products Category Name: ' + StoreDefaultsHelper.getMyProductsCategoryName());
System.debug('');
System.debug('Shape Field: ' + StoreDefaultsHelper.getShapeField());
System.debug('Profile Field: ' + StoreDefaultsHelper.getProfileField());
System.debug('End User Field: ' + StoreDefaultsHelper.getEndUserField());
System.debug('');
System.debug('Default Page Size: ' + StoreDefaultsHelper.getDefaultPageSize());
System.debug('Quick Turn Page Size: ' + StoreDefaultsHelper.getQuickTurnPageSize());
System.debug('Filter Values Limit: ' + StoreDefaultsHelper.getFilterValuesLimit());
System.debug('');
System.debug('Parent Product Value: ' + StoreDefaultsHelper.getParentProductValue());
System.debug('Dri-Duck Value: ' + StoreDefaultsHelper.getDriDuckValue());
System.debug('Rush Ready Label: ' + StoreDefaultsHelper.getRushReadyLabel());
System.debug('');
System.debug('✅ If you see values above (not null), metadata is loaded correctly!');
