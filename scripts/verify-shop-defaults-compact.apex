/**
 * Compact Anonymous Apex: Verify Shop_Defaults Metadata
 * Run in Developer Console > Debug > Open Execute Anonymous Window
 */

B2B_Store_Defaults__mdt sd = B2B_Store_Defaults__mdt.getInstance('Shop_Defaults');

if (sd == null) {
    System.debug('❌ ERROR: Shop_Defaults record NOT FOUND!');
} else {
    System.debug('✅ Shop_Defaults found!');
    System.debug('');

    Integer populated = 0;
    Integer empty = 0;

    // Category IDs
    if (sd.My_Products_Category_ID__c != null) { System.debug('✅ My_Products_Category_ID__c: ' + sd.My_Products_Category_ID__c); populated++; } else { System.debug('❌ My_Products_Category_ID__c: NULL'); empty++; }
    if (sd.Quick_Turn_Category_ID__c != null) { System.debug('✅ Quick_Turn_Category_ID__c: ' + sd.Quick_Turn_Category_ID__c); populated++; } else { System.debug('❌ Quick_Turn_Category_ID__c: NULL'); empty++; }

    // Category Names
    if (sd.Quick_Turn_Category_Name__c != null) { System.debug('✅ Quick_Turn_Category_Name__c: ' + sd.Quick_Turn_Category_Name__c); populated++; } else { System.debug('❌ Quick_Turn_Category_Name__c: NULL'); empty++; }
    if (sd.My_Products_Category_Name__c != null) { System.debug('✅ My_Products_Category_Name__c: ' + sd.My_Products_Category_Name__c); populated++; } else { System.debug('❌ My_Products_Category_Name__c: NULL'); empty++; }

    // Field Names
    if (sd.Shape_Field__c != null) { System.debug('✅ Shape_Field__c: ' + sd.Shape_Field__c); populated++; } else { System.debug('❌ Shape_Field__c: NULL'); empty++; }
    if (sd.Profile_Field__c != null) { System.debug('✅ Profile_Field__c: ' + sd.Profile_Field__c); populated++; } else { System.debug('❌ Profile_Field__c: NULL'); empty++; }
    if (sd.Panels_Field__c != null) { System.debug('✅ Panels_Field__c: ' + sd.Panels_Field__c); populated++; } else { System.debug('❌ Panels_Field__c: NULL'); empty++; }
    if (sd.Structure_Field__c != null) { System.debug('✅ Structure_Field__c: ' + sd.Structure_Field__c); populated++; } else { System.debug('❌ Structure_Field__c: NULL'); empty++; }
    if (sd.Visor_Field__c != null) { System.debug('✅ Visor_Field__c: ' + sd.Visor_Field__c); populated++; } else { System.debug('❌ Visor_Field__c: NULL'); empty++; }
    if (sd.End_User_Field__c != null) { System.debug('✅ End_User_Field__c: ' + sd.End_User_Field__c); populated++; } else { System.debug('❌ End_User_Field__c: NULL'); empty++; }
    if (sd.Rush_Ready_Field__c != null) { System.debug('✅ Rush_Ready_Field__c: ' + sd.Rush_Ready_Field__c); populated++; } else { System.debug('❌ Rush_Ready_Field__c: NULL'); empty++; }
    if (sd.Is_Parent_Field__c != null) { System.debug('✅ Is_Parent_Field__c: ' + sd.Is_Parent_Field__c); populated++; } else { System.debug('❌ Is_Parent_Field__c: NULL'); empty++; }
    if (sd.Special_Program_Field__c != null) { System.debug('✅ Special_Program_Field__c: ' + sd.Special_Program_Field__c); populated++; } else { System.debug('❌ Special_Program_Field__c: NULL'); empty++; }
    if (sd.Contact_Field__c != null) { System.debug('✅ Contact_Field__c: ' + sd.Contact_Field__c); populated++; } else { System.debug('❌ Contact_Field__c: NULL'); empty++; }
    if (sd.Account_Field__c != null) { System.debug('✅ Account_Field__c: ' + sd.Account_Field__c); populated++; } else { System.debug('❌ Account_Field__c: NULL'); empty++; }

    // Special Programs
    if (sd.Dri_Duck_Value__c != null) { System.debug('✅ Dri_Duck_Value__c: ' + sd.Dri_Duck_Value__c); populated++; } else { System.debug('❌ Dri_Duck_Value__c: NULL'); empty++; }
    if (sd.Rush_Ready_Value__c != null) { System.debug('✅ Rush_Ready_Value__c: ' + sd.Rush_Ready_Value__c); populated++; } else { System.debug('❌ Rush_Ready_Value__c: NULL'); empty++; }
    if (sd.Dri_Duck_Label__c != null) { System.debug('✅ Dri_Duck_Label__c: ' + sd.Dri_Duck_Label__c); populated++; } else { System.debug('❌ Dri_Duck_Label__c: NULL'); empty++; }
    if (sd.Rush_Ready_Label__c != null) { System.debug('✅ Rush_Ready_Label__c: ' + sd.Rush_Ready_Label__c); populated++; } else { System.debug('❌ Rush_Ready_Label__c: NULL'); empty++; }

    // Product Values
    if (sd.Parent_Product_Value__c != null) { System.debug('✅ Parent_Product_Value__c: ' + sd.Parent_Product_Value__c); populated++; } else { System.debug('❌ Parent_Product_Value__c: NULL'); empty++; }
    if (sd.Simple_Product_Class__c != null) { System.debug('✅ Simple_Product_Class__c: ' + sd.Simple_Product_Class__c); populated++; } else { System.debug('❌ Simple_Product_Class__c: NULL'); empty++; }

    // Pagination
    if (sd.Default_Page_Size__c != null) { System.debug('✅ Default_Page_Size__c: ' + sd.Default_Page_Size__c); populated++; } else { System.debug('❌ Default_Page_Size__c: NULL'); empty++; }
    if (sd.Quick_Turn_Page_Size__c != null) { System.debug('✅ Quick_Turn_Page_Size__c: ' + sd.Quick_Turn_Page_Size__c); populated++; } else { System.debug('❌ Quick_Turn_Page_Size__c: NULL'); empty++; }
    if (sd.Filter_Values_Limit__c != null) { System.debug('✅ Filter_Values_Limit__c: ' + sd.Filter_Values_Limit__c); populated++; } else { System.debug('❌ Filter_Values_Limit__c: NULL'); empty++; }

    // URL Slugs
    if (sd.Quick_Turn_URL_Slug__c != null) { System.debug('✅ Quick_Turn_URL_Slug__c: ' + sd.Quick_Turn_URL_Slug__c); populated++; } else { System.debug('❌ Quick_Turn_URL_Slug__c: NULL'); empty++; }
    if (sd.My_Products_URL_Slug__c != null) { System.debug('✅ My_Products_URL_Slug__c: ' + sd.My_Products_URL_Slug__c); populated++; } else { System.debug('❌ My_Products_URL_Slug__c: NULL'); empty++; }
    if (sd.Detail_URL_Slug__c != null) { System.debug('✅ Detail_URL_Slug__c: ' + sd.Detail_URL_Slug__c); populated++; } else { System.debug('❌ Detail_URL_Slug__c: NULL'); empty++; }

    System.debug('');
    System.debug('SUMMARY: ' + populated + '/27 populated, ' + empty + '/27 empty');

    if (empty == 0) {
        System.debug('✅ All fields populated!');
    } else {
        System.debug('⚠️  ' + empty + ' fields are empty - using fallback values');
    }
}
