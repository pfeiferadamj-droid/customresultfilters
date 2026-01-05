// Diagnostic script to investigate why My Products category shows 0 products

// Get the My Products category ID from metadata
String myProductsCategoryId = '0ZGbb000000FFOXGA4';
String webstoreId = '0ZEPU0000002fv74AA';

System.debug('==== CATEGORY DIAGNOSIS ====');
System.debug('My Products Category ID: ' + myProductsCategoryId);
System.debug('Webstore ID: ' + webstoreId);
System.debug('');

// 1. Check if category exists
List<ProductCategory> categories = [
    SELECT Id, Name, IsNavigational, ParentCategoryId
    FROM ProductCategory
    WHERE Id = :myProductsCategoryId
];

if (categories.isEmpty()) {
    System.debug('ERROR: Category not found!');
} else {
    ProductCategory cat = categories[0];
    System.debug('Category found: ' + cat.Name);
    System.debug('IsNavigational: ' + cat.IsNavigational);
    System.debug('ParentCategoryId: ' + cat.ParentCategoryId);
}
System.debug('');

// 2. Check products assigned to this category
List<ProductCategoryProduct> categoryProducts = [
    SELECT Id, ProductId, Product.Name, Product.IsActive, Product.ProductCode
    FROM ProductCategoryProduct
    WHERE ProductCategoryId = :myProductsCategoryId
    LIMIT 100
];

System.debug('==== PRODUCTS IN CATEGORY ====');
System.debug('Total products assigned to category: ' + categoryProducts.size());
if (!categoryProducts.isEmpty()) {
    System.debug('First 10 products:');
    for (Integer i = 0; i < Math.min(10, categoryProducts.size()); i++) {
        ProductCategoryProduct pcp = categoryProducts[i];
        System.debug('  - ' + pcp.Product.ProductCode + ': ' + pcp.Product.Name +
                     ' (Active: ' + pcp.Product.IsActive + ')');
    }
}
System.debug('');

// 3. Check entitlements for these products
if (!categoryProducts.isEmpty()) {
    Set<Id> productIds = new Set<Id>();
    for (ProductCategoryProduct pcp : categoryProducts) {
        productIds.add(pcp.ProductId);
    }

    List<CommerceEntitlementProduct> entitlements = [
        SELECT Id, ProductId, Product.Name, PolicyId
        FROM CommerceEntitlementProduct
        WHERE ProductId IN :productIds
        LIMIT 100
    ];

    System.debug('==== ENTITLEMENTS ====');
    System.debug('Products with entitlements: ' + entitlements.size() + ' out of ' + productIds.size());
    if (!entitlements.isEmpty()) {
        System.debug('Sample entitlements:');
        for (Integer i = 0; i < Math.min(5, entitlements.size()); i++) {
            CommerceEntitlementProduct ent = entitlements[i];
            System.debug('  - ' + ent.Product.Name + ' (Policy: ' + ent.PolicyId + ')');
        }
    } else {
        System.debug('WARNING: No entitlements found for any products in this category!');
    }
}
System.debug('');

// 4. Check current user's buyer groups
User currentUser = [
    SELECT Id, Name, ContactId, Contact.AccountId
    FROM User
    WHERE Id = :UserInfo.getUserId()
];

System.debug('==== CURRENT USER ====');
System.debug('User: ' + currentUser.Name);
System.debug('ContactId: ' + currentUser.ContactId);
System.debug('AccountId: ' + currentUser.Contact?.AccountId);

if (currentUser.Contact?.AccountId != null) {
    List<BuyerGroupMember> buyerGroupMembers = [
        SELECT Id, BuyerGroupId, BuyerGroup.Name
        FROM BuyerGroupMember
        WHERE BuyerId = :currentUser.Contact.AccountId
    ];

    System.debug('Buyer groups: ' + buyerGroupMembers.size());
    for (BuyerGroupMember bgm : buyerGroupMembers) {
        System.debug('  - ' + bgm.BuyerGroup.Name + ' (' + bgm.BuyerGroupId + ')');
    }
} else {
    System.debug('WARNING: User has no associated Account (not a buyer)');
}
System.debug('');

System.debug('==== DIAGNOSIS COMPLETE ====');
