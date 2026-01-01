/**
 * Anonymous Apex Script: Verify and Display Shop_Defaults Metadata
 *
 * This script checks all fields in the Shop_Defaults custom metadata record
 * and shows which values are populated vs. using fallback defaults.
 *
 * HOW TO RUN:
 * 1. Copy this entire script
 * 2. Go to Developer Console > Debug > Open Execute Anonymous Window
 * 3. Paste the script and click "Execute"
 * 4. Check the debug logs for the results
 */

// Query the Shop_Defaults metadata record directly
B2B_Store_Defaults__mdt shopDefaults = B2B_Store_Defaults__mdt.getInstance('Shop_Defaults');

System.debug('='.repeat(80));
System.debug('SHOP DEFAULTS METADATA VERIFICATION');
System.debug('='.repeat(80));

if (shopDefaults == null) {
    System.debug('❌ ERROR: Shop_Defaults record NOT FOUND in the org!');
    System.debug('   You need to deploy the B2B_Store_Defaults.Shop_Defaults.md-meta.xml file');
    System.debug('='.repeat(80));
} else {
    System.debug('✅ Shop_Defaults record found!');
    System.debug('');

    // Check each field and show if populated or using fallback
    Integer populatedCount = 0;
    Integer emptyCount = 0;

    System.debug('--- CATEGORY IDs ---');
    if (shopDefaults.My_Products_Category_ID__c != null) {
        System.debug('✅ My_Products_Category_ID__c: ' + shopDefaults.My_Products_Category_ID__c);
        populatedCount++;
    } else {
        System.debug('❌ My_Products_Category_ID__c: NULL (using fallback)');
        emptyCount++;
    }

    if (shopDefaults.Quick_Turn_Category_ID__c != null) {
        System.debug('✅ Quick_Turn_Category_ID__c: ' + shopDefaults.Quick_Turn_Category_ID__c);
        populatedCount++;
    } else {
        System.debug('❌ Quick_Turn_Category_ID__c: NULL (using fallback)');
        emptyCount++;
    }

    System.debug('');
    System.debug('--- CATEGORY NAMES ---');
    if (shopDefaults.Quick_Turn_Category_Name__c != null) {
        System.debug('✅ Quick_Turn_Category_Name__c: ' + shopDefaults.Quick_Turn_Category_Name__c);
        populatedCount++;
    } else {
        System.debug('❌ Quick_Turn_Category_Name__c: NULL (fallback: "Quick Turn")');
        emptyCount++;
    }

    if (shopDefaults.My_Products_Category_Name__c != null) {
        System.debug('✅ My_Products_Category_Name__c: ' + shopDefaults.My_Products_Category_Name__c);
        populatedCount++;
    } else {
        System.debug('❌ My_Products_Category_Name__c: NULL (fallback: "My Products")');
        emptyCount++;
    }

    System.debug('');
    System.debug('--- FIELD API NAMES ---');
    if (shopDefaults.Shape_Field__c != null) {
        System.debug('✅ Shape_Field__c: ' + shopDefaults.Shape_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Shape_Field__c: NULL (fallback: "Shape__c")');
        emptyCount++;
    }

    if (shopDefaults.Profile_Field__c != null) {
        System.debug('✅ Profile_Field__c: ' + shopDefaults.Profile_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Profile_Field__c: NULL (fallback: "Profile__c")');
        emptyCount++;
    }

    if (shopDefaults.Panels_Field__c != null) {
        System.debug('✅ Panels_Field__c: ' + shopDefaults.Panels_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Panels_Field__c: NULL (fallback: "Panels__c")');
        emptyCount++;
    }

    if (shopDefaults.Structure_Field__c != null) {
        System.debug('✅ Structure_Field__c: ' + shopDefaults.Structure_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Structure_Field__c: NULL (fallback: "Structure__c")');
        emptyCount++;
    }

    if (shopDefaults.Visor_Field__c != null) {
        System.debug('✅ Visor_Field__c: ' + shopDefaults.Visor_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Visor_Field__c: NULL (fallback: "Visor__c")');
        emptyCount++;
    }

    if (shopDefaults.End_User_Field__c != null) {
        System.debug('✅ End_User_Field__c: ' + shopDefaults.End_User_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ End_User_Field__c: NULL (fallback: "End_User__c")');
        emptyCount++;
    }

    if (shopDefaults.Rush_Ready_Field__c != null) {
        System.debug('✅ Rush_Ready_Field__c: ' + shopDefaults.Rush_Ready_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Rush_Ready_Field__c: NULL (fallback: "Rush_Ready__c")');
        emptyCount++;
    }

    if (shopDefaults.Is_Parent_Field__c != null) {
        System.debug('✅ Is_Parent_Field__c: ' + shopDefaults.Is_Parent_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Is_Parent_Field__c: NULL (fallback: "Is_Parent__c")');
        emptyCount++;
    }

    if (shopDefaults.Special_Program_Field__c != null) {
        System.debug('✅ Special_Program_Field__c: ' + shopDefaults.Special_Program_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Special_Program_Field__c: NULL (fallback: "Special_Program_SAP__c")');
        emptyCount++;
    }

    if (shopDefaults.Contact_Field__c != null) {
        System.debug('✅ Contact_Field__c: ' + shopDefaults.Contact_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Contact_Field__c: NULL (fallback: "Contact__c")');
        emptyCount++;
    }

    if (shopDefaults.Account_Field__c != null) {
        System.debug('✅ Account_Field__c: ' + shopDefaults.Account_Field__c);
        populatedCount++;
    } else {
        System.debug('❌ Account_Field__c: NULL (fallback: "Account__c")');
        emptyCount++;
    }

    System.debug('');
    System.debug('--- SPECIAL PROGRAM VALUES ---');
    if (shopDefaults.Dri_Duck_Value__c != null) {
        System.debug('✅ Dri_Duck_Value__c: ' + shopDefaults.Dri_Duck_Value__c);
        populatedCount++;
    } else {
        System.debug('❌ Dri_Duck_Value__c: NULL (fallback: "QuickTurnDDT")');
        emptyCount++;
    }

    if (shopDefaults.Rush_Ready_Value__c != null) {
        System.debug('✅ Rush_Ready_Value__c: ' + shopDefaults.Rush_Ready_Value__c);
        populatedCount++;
    } else {
        System.debug('❌ Rush_Ready_Value__c: NULL (fallback: "RushReady")');
        emptyCount++;
    }

    if (shopDefaults.Dri_Duck_Label__c != null) {
        System.debug('✅ Dri_Duck_Label__c: ' + shopDefaults.Dri_Duck_Label__c);
        populatedCount++;
    } else {
        System.debug('❌ Dri_Duck_Label__c: NULL (fallback: "Dri-Duck")');
        emptyCount++;
    }

    if (shopDefaults.Rush_Ready_Label__c != null) {
        System.debug('✅ Rush_Ready_Label__c: ' + shopDefaults.Rush_Ready_Label__c);
        populatedCount++;
    } else {
        System.debug('❌ Rush_Ready_Label__c: NULL (fallback: "Rush Ready")');
        emptyCount++;
    }

    System.debug('');
    System.debug('--- PRODUCT VALUES ---');
    if (shopDefaults.Parent_Product_Value__c != null) {
        System.debug('✅ Parent_Product_Value__c: ' + shopDefaults.Parent_Product_Value__c);
        populatedCount++;
    } else {
        System.debug('❌ Parent_Product_Value__c: NULL (fallback: "Yes")');
        emptyCount++;
    }

    if (shopDefaults.Simple_Product_Class__c != null) {
        System.debug('✅ Simple_Product_Class__c: ' + shopDefaults.Simple_Product_Class__c);
        populatedCount++;
    } else {
        System.debug('❌ Simple_Product_Class__c: NULL (fallback: "Simple")');
        emptyCount++;
    }

    System.debug('');
    System.debug('--- PAGINATION SETTINGS ---');
    if (shopDefaults.Default_Page_Size__c != null) {
        System.debug('✅ Default_Page_Size__c: ' + shopDefaults.Default_Page_Size__c);
        populatedCount++;
    } else {
        System.debug('❌ Default_Page_Size__c: NULL (fallback: 12)');
        emptyCount++;
    }

    if (shopDefaults.Quick_Turn_Page_Size__c != null) {
        System.debug('✅ Quick_Turn_Page_Size__c: ' + shopDefaults.Quick_Turn_Page_Size__c);
        populatedCount++;
    } else {
        System.debug('❌ Quick_Turn_Page_Size__c: NULL (fallback: 24)');
        emptyCount++;
    }

    if (shopDefaults.Filter_Values_Limit__c != null) {
        System.debug('✅ Filter_Values_Limit__c: ' + shopDefaults.Filter_Values_Limit__c);
        populatedCount++;
    } else {
        System.debug('❌ Filter_Values_Limit__c: NULL (fallback: 2000)');
        emptyCount++;
    }

    System.debug('');
    System.debug('--- URL SLUGS ---');
    if (shopDefaults.Quick_Turn_URL_Slug__c != null) {
        System.debug('✅ Quick_Turn_URL_Slug__c: ' + shopDefaults.Quick_Turn_URL_Slug__c);
        populatedCount++;
    } else {
        System.debug('❌ Quick_Turn_URL_Slug__c: NULL (fallback: "quick-turn")');
        emptyCount++;
    }

    if (shopDefaults.My_Products_URL_Slug__c != null) {
        System.debug('✅ My_Products_URL_Slug__c: ' + shopDefaults.My_Products_URL_Slug__c);
        populatedCount++;
    } else {
        System.debug('❌ My_Products_URL_Slug__c: NULL (fallback: "my-products")');
        emptyCount++;
    }

    if (shopDefaults.Detail_URL_Slug__c != null) {
        System.debug('✅ Detail_URL_Slug__c: ' + shopDefaults.Detail_URL_Slug__c);
        populatedCount++;
    } else {
        System.debug('❌ Detail_URL_Slug__c: NULL (fallback: "detail")');
        emptyCount++;
    }

    System.debug('');
    System.debug('='.repeat(80));
    System.debug('SUMMARY:');
    System.debug('  ✅ Populated Fields: ' + populatedCount + '/27');
    System.debug('  ❌ Empty Fields: ' + emptyCount + '/27');

    if (emptyCount > 0) {
        System.debug('');
        System.debug('⚠️  WARNING: ' + emptyCount + ' fields are empty!');
        System.debug('   The code will use hardcoded fallback values for these fields.');
        System.debug('   To fix this, you need to populate these fields in the Shop_Defaults metadata record.');
        System.debug('   See the generated update script in: scripts/populate-shop-defaults.txt');
    } else {
        System.debug('');
        System.debug('✅ SUCCESS: All fields are populated!');
        System.debug('   Your Shop_Defaults metadata is fully configured.');
    }
    System.debug('='.repeat(80));
}
