import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import FILTER_CHANGE_CHANNEL from '@salesforce/messageChannel/FilterChangeChannel__c';
import getCategoryProducts from '@salesforce/apex/CategoryProductController.getCategoryProducts';
import getProductsByEndUser from '@salesforce/apex/CustomProductQueryController.getProductsByEndUser';

// Field used to filter to parents only.
import FIELD_ISPARENT from '@salesforce/schema/Product2.Is_Parent__c';
// Value that specifies parent.
const PARENT_VALUE = 'Yes';

/**
 * Custom category product grid component for B2B Commerce
 * Displays products using the customSearchProductCard component with custom pricing
 */
export default class CustomCategoryProductGrid extends NavigationMixin(LightningElement) {

    /**
     * The layout to use for displaying products (grid or list)
     * @type {string}
     */
    @api layout = 'grid';

    /**
     * Number of products to show per page
     * @type {number}
     */
    @api productsPerPage = 12;

    /**
     * Show or hide product images
     * @type {boolean}
     */
    @api showProductImage;

    /**
     * Show or hide the call to action button
     * @type {boolean}
     */
    @api showCallToActionButton;

    /**
     * Show or hide the quantity selector
     * @type {boolean}
     */
    @api showQuantitySelector = false;

    /**
     * Show or hide pricing information
     * @type {boolean}
     */
    @api showNegotiatedPrice;

    /**
     * Show or hide list price
     * @type {boolean}
     */
    @api showListingPrice;

    /**
     * The current active pricebook ID
     * @type {string}
     */
    @api currentPricebookId;

    /**
     * The special pricebook IDs that trigger 'c' suffix (comma-separated)
     * @type {string}
     */
    @api specialPricebookIds;

    /**
     * True to force restriction to parent products only.
     * @type {boolean}
     */
    @api restrictToParents = false;

    /**
     * The webstore ID (REQUIRED - must be configured in Experience Builder)
     * @type {string}
     */
    @api webstoreId;

    /**
     * The category name for this grid (e.g., "Quick Turn", "My Products")
     * Used to filter which filter events this component should respond to
     * @type {string}
     */
    @api categoryName;

    /**
     * The category ID to display products from
     * If not provided, will attempt to resolve from URL or page context
     * @type {string}
     */
    @api
    get categoryId() {
        return this._categoryId;
    }
    set categoryId(value) {
        const oldValue = this._categoryId;
        this._categoryId = value;
        if (value && value !== oldValue) {
            this.resolvedCategoryId = value;
            // Only fetch if component is already initialized (not during initial setup)
            if (this._isInitialized && this.webstoreId && this.resolvedCategoryId) {
                this.fetchProducts();
            }
        }
    }

    _categoryId;
    _isInitialized = false;

    /**
     * Text for the add to cart button
     * @type {string}
     */
    @api addToCartButtonText = 'Add to Cart';

    /**
     * Text for the view options button
     * @type {string}
     */
    @api viewOptionsButtonText = 'View Options';

    /**
     * Text for the quantity selector label
     * @type {string}
     */
    @api quantitySelectorLabelText = 'Quantity';

    @track resolvedCategoryId;
    @track error;
    @track searchResults;
    @track pricebookEntries;
    @track isLoadingProducts = false;

    // Pagination state
    @track currentPage = 1;
    @track totalPages = 1;
    @track totalProducts = 0;

    // Sort state - use sortRuleId for native Salesforce sort menu integration
    @track sortRuleId = null;

    // Filter state
    @track activeFilters = {};

    // Custom filter state - tracks filters from customResultsFilter component
    currentFilters = {};

    // Store previous URL state to detect changes
    _previousSortRuleId = null;
    _previousRefinements = null;

    // Lightning Message Service for filter communication
    @wire(MessageContext)
    messageContext;

    subscription = null;

    @wire(CurrentPageReference)
    handlePageReference(pageRef) {
        this.pageRef = pageRef;

        if (pageRef && this._isInitialized) {
            // Check for sort/filter changes in URL
            const urlParams = new URLSearchParams(window.location.search);
            // Native Salesforce uses 'sortRule' parameter
            const newSortRuleId = urlParams.get('sortRule') || pageRef.state?.sortRule || null;
            const newRefinements = urlParams.get('refinements') || pageRef.state?.refinements || null;

            console.log('URL params detected:', {
                sortRule: newSortRuleId,
                refinements: newRefinements,
                fullUrl: window.location.href,
                pageRefState: pageRef.state
            });

            // Check if sort changed
            if (newSortRuleId !== this._previousSortRuleId) {
                console.log('Sort rule changed from URL:', this._previousSortRuleId, '->', newSortRuleId);
                this._previousSortRuleId = newSortRuleId;
                this.sortRuleId = newSortRuleId;
                this.currentPage = 1;
                this.fetchProducts();
            }

            // Check if refinements changed
            if (newRefinements !== this._previousRefinements) {
                console.log('Refinements changed from URL:', newRefinements);
                this._previousRefinements = newRefinements;
                if (newRefinements) {
                    try {
                        this.activeFilters = JSON.parse(decodeURIComponent(newRefinements));
                    } catch (e) {
                        console.error('Error parsing refinements:', e);
                        this.activeFilters = {};
                    }
                } else {
                    this.activeFilters = {};
                }
                this.currentPage = 1;
                this.fetchProducts();
            }
        }
    }

    connectedCallback() {
        this.initialize();
        // Listen for URL changes (back/forward navigation)
        window.addEventListener('popstate', this.handleUrlChange);
        // Also listen for pushState/replaceState changes
        this.setupUrlChangeListener();

        // Subscribe to Lightning Message Service for filter events
        this.subscribeToFilterMessages();

        // Listen for custom filter events from customResultsFilter component (for parent-child hierarchy)
        this.addEventListener('filterchange', this.handleCustomFilterChange.bind(this));
        this.addEventListener('clearallfilters', this.handleClearAllFilters.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('popstate', this.handleUrlChange);
        // Unsubscribe from Lightning Message Service
        this.unsubscribeFromFilterMessages();
    }

    /**
     * Subscribe to Lightning Message Service for filter events
     */
    subscribeToFilterMessages() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                FILTER_CHANGE_CHANNEL,
                (message) => this.handleLMSMessage(message)
            );
            console.log('customCategoryProductGrid: Subscribed to LMS filter messages');
        }
    }

    /**
     * Unsubscribe from Lightning Message Service
     */
    unsubscribeFromFilterMessages() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
            console.log('customCategoryProductGrid: Unsubscribed from LMS filter messages');
        }
    }

    /**
     * Handle Lightning Message Service messages
     */
    handleLMSMessage(message) {
        console.log('customCategoryProductGrid: Received LMS message:', message);

        if (message.action === 'filterchange') {
            // Process filter change from LMS
            this.handleCustomFilterChange({
                detail: {
                    category: message.category,
                    filterId: message.filterId,
                    value: message.value,
                    checked: message.checked
                }
            });
        } else if (message.action === 'clearall') {
            // Process clear all from LMS
            this.handleClearAllFilters({
                detail: {
                    category: message.category
                }
            });
        }
    }

    /**
     * Setup listener for URL changes via pushState/replaceState
     */
    setupUrlChangeListener() {
        // Override pushState and replaceState to detect URL changes
        const originalPushState = history.pushState;
        const originalReplaceState = history.replaceState;
        const self = this;

        history.pushState = function() {
            originalPushState.apply(this, arguments);
            self.handleUrlChange();
        };

        history.replaceState = function() {
            originalReplaceState.apply(this, arguments);
            self.handleUrlChange();
        };
    }

    /**
     * Handle URL changes and check for sort/filter updates
     */
    handleUrlChange = () => {
        if (!this._isInitialized) return;

        const urlParams = new URLSearchParams(window.location.search);
        const newSortRuleId = urlParams.get('sortRule') || null;
        const newRefinements = urlParams.get('refinements') || null;

        console.log('URL change detected:', {
            sortRule: newSortRuleId,
            refinements: newRefinements,
            fullUrl: window.location.href
        });

        let shouldFetch = false;

        // Check if sort changed
        if (newSortRuleId !== this._previousSortRuleId) {
            console.log('Sort rule changed:', this._previousSortRuleId, '->', newSortRuleId);
            this._previousSortRuleId = newSortRuleId;
            this.sortRuleId = newSortRuleId;
            this.currentPage = 1;
            shouldFetch = true;
        }

        // Check if refinements changed
        if (newRefinements !== this._previousRefinements) {
            console.log('Refinements changed:', newRefinements);
            this._previousRefinements = newRefinements;
            this.currentPage = 1;
            shouldFetch = true;
        }

        if (shouldFetch) {
            this.fetchProducts();
        }
    }

    /**
     * Initialize component by getting category ID and fetching products
     */
    async initialize() {
        // Get category ID from URL or context if not already set
        if (!this.categoryId) {
            this.resolveCategoryIdFromContext();
        } else {
            this.resolvedCategoryId = this.categoryId;
        }

        // Get initial sort rule from URL
        const urlParams = new URLSearchParams(window.location.search);
        const initialSortRule = urlParams.get('sortRule');
        if (initialSortRule) {
            this.sortRuleId = initialSortRule;
            this._previousSortRuleId = initialSortRule;
            console.log('Initial sort rule from URL:', initialSortRule);
        }

        console.log('CustomCategoryProductGrid - Initialize:', {
            categoryId: this.categoryId,
            resolvedCategoryId: this.resolvedCategoryId,
            webstoreId: this.webstoreId,
            categoryName: this.categoryName,
            url: window.location.href
        });

        if (!this.webstoreId) {
            console.warn('Webstore ID not configured. Please set the webstoreId property in Experience Builder.');
            this.error = 'Webstore ID not configured';
        } else if (!this.resolvedCategoryId) {
            console.warn('Category ID not found in URL or navigation context.');
            this.error = 'Category ID not found';
        } else {
            // Load saved filters from sessionStorage before fetching
            this.loadFiltersFromSession();

            // Fetch products
            await this.fetchProducts();
        }

        // Mark as initialized to allow property changes to trigger refetch
        this._isInitialized = true;
    }

    /**
     * Gets the current category ID from the page context
     * Only called if categoryId is not already set via @api property
     */
    resolveCategoryIdFromContext() {
        // Try multiple methods to get category ID
        const urlParams = new URLSearchParams(window.location.search);

        // Method 1: From URL parameter
        let categoryId = urlParams.get('categoryId');

        // Method 2: From page reference state
        if (!categoryId && this.pageRef?.state?.recordId) {
            categoryId = this.pageRef.state.recordId;
        }

        // Method 3: From page reference attributes
        if (!categoryId && this.pageRef?.attributes?.recordId) {
            categoryId = this.pageRef.attributes.recordId;
        }

        // Method 4: From URL path (for category pages like /category/categoryName/categoryId)
        if (!categoryId) {
            const pathParts = window.location.pathname.split('/');
            const categoryIndex = pathParts.indexOf('category');
            if (categoryIndex !== -1 && pathParts.length > categoryIndex + 2) {
                categoryId = pathParts[categoryIndex + 2];
            }
        }

        this.resolvedCategoryId = categoryId;
        console.log('Category ID resolved:', categoryId);
    }

    /**
     * Fetch products for the category using Apex
     */
    async fetchProducts() {
        // Prevent multiple simultaneous calls
        if (this.isLoadingProducts) {
            console.log('Fetch already in progress, skipping duplicate call');
            return;
        }

        this.isLoadingProducts = true;
        this.error = null;
        try {
            // Check if filtering by End User (lookup field)
            const endUserFilterValues = this.currentFilters['endUser'];
            const hasEndUserFilter = endUserFilterValues && endUserFilterValues.length > 0;

            if (hasEndUserFilter) {
                // Use custom SOQL query for End User filtering (lookup fields don't work in Commerce Search)
                console.log('Using custom SOQL query for End User filter:', endUserFilterValues);
                await this.fetchProductsByEndUser(endUserFilterValues);
            } else {
                // Use standard Commerce Search API for other filters
                await this.fetchProductsViaCommerceSearch();
            }
        } catch (error) {
            console.error('Error fetching products:', error);
            console.error('Error details:', JSON.stringify(error));
            this.error = error;
            this.searchResults = null;
        } finally {
            this.isLoadingProducts = false;
        }
    }

    /**
     * Fetch products using Commerce Search API (for non-lookup filters)
     */
    async fetchProductsViaCommerceSearch() {
        // Start with an empty array of refinements
        let refinementsArr = [];

        // 1. Add custom filter refinements (from customResultsFilter component)
        // NOTE: buildRefinementsFromFilters() already excludes 'endUser' filter
        const customFilterRefinements = this.buildRefinementsFromFilters();
        if (customFilterRefinements) {
            const customRefinements = JSON.parse(customFilterRefinements);
            refinementsArr.push(...customRefinements);
            console.log('Added custom filter refinements:', customRefinements);
        }

        // 2. Get refinements from URL (double URL-encoded) - for native Salesforce filters
        const urlParams = new URLSearchParams(window.location.search);
        const refinementsParam = urlParams.get('refinements');
        if (refinementsParam) {
            try {
                // Decode double URL encoding
                const decoded = decodeURIComponent(decodeURIComponent(refinementsParam));
                const urlRefinements = JSON.parse(decoded);
                refinementsArr.push(...urlRefinements);
                console.log('Added URL refinements:', urlRefinements);
            } catch (e) {
                console.error('Error decoding URL refinements:', e);
            }
        }

        // 3. Add parent restriction if needed
        if (this.restrictToParents) {
            refinementsArr.push({
                attributeType: 'Custom',
                nameOrId: FIELD_ISPARENT.fieldApiName,
                values: [ PARENT_VALUE ],
            });
            console.log('Added parent restriction refinement');
        }

        // Convert to JSON for Apex call
        const refinementsJSON = refinementsArr.length > 0 ? JSON.stringify(refinementsArr) : null;

        console.log('Fetching products via Commerce Search with params:', {
            categoryId: this.resolvedCategoryId,
            webstoreId: this.webstoreId,
            pageSize: this.productsPerPage,
            pageNumber: this.currentPage,
            sortRuleId: this.sortRuleId,
            refinementsJSON: refinementsJSON
        });

        const result = await getCategoryProducts({
            categoryId: this.resolvedCategoryId,
            webstoreId: this.webstoreId,
            effectiveAccountId: null, // Will use current user's account
            pageSize: this.productsPerPage,
            pageNumber: this.currentPage,
            sortRuleId: this.sortRuleId,
            refinementsJSON: refinementsJSON
        });

        console.log('Apex result (raw):', result);

        // Parse the JSON result from Apex
        const parsedResult = JSON.parse(result);

        // Extract search results and pricebook entries
        this.searchResults = parsedResult.searchResults;
        this.pricebookEntries = parsedResult.pricebookEntries;

        // Calculate pagination info
        const totalCount = this.searchResults?.productsPage?.total || 0;
        this.totalProducts = totalCount;
        this.totalPages = Math.ceil(totalCount / this.productsPerPage) || 1;

        console.log('Parsed search results:', this.searchResults);
        console.log('Pricebook entries:', this.pricebookEntries);
        console.log('Products found:', this.searchResults?.productsPage?.products?.length || 0);
        console.log('Total products:', this.totalProducts);
        console.log('Total pages:', this.totalPages);
    }

    /**
     * Fetch products using custom SOQL query (for End User lookup filter)
     */
    async fetchProductsByEndUser(endUserIds) {
        console.log('Fetching products by End User using SOQL:', {
            categoryId: this.resolvedCategoryId,
            endUserIds: endUserIds,
            pageNumber: this.currentPage,
            pageSize: this.productsPerPage,
            restrictToParents: this.restrictToParents
        });

        const result = await getProductsByEndUser({
            categoryId: this.resolvedCategoryId,
            endUserIds: endUserIds,
            pageNumber: this.currentPage,
            pageSize: this.productsPerPage,
            restrictToParents: this.restrictToParents
        });

        console.log('SOQL query result:', result);

        // Convert custom result format to match Commerce Search format
        // This allows the rest of the component to work unchanged
        this.searchResults = {
            productsPage: {
                products: result.products.map(p => ({
                    id: p.id,
                    name: p.name,
                    fields: {
                        ProductCode: p.productCode,
                        StockKeepingUnit: p.sku,
                        Description: p.description,
                        Shape__c: p.shapeValue,
                        Rush_Ready__c: p.rushReady,
                        End_User__c: p.endUserId
                    }
                })),
                total: result.total
            }
        };

        // Clear pricebook entries for now (could be enhanced later)
        this.pricebookEntries = [];

        // Calculate pagination info
        this.totalProducts = result.total;
        this.totalPages = Math.ceil(result.total / this.productsPerPage) || 1;

        console.log('Converted to search results format');
        console.log('Products found:', this.searchResults.productsPage.products.length);
        console.log('Total products:', this.totalProducts);
        console.log('Total pages:', this.totalPages);
    }

    /**
     * Gets the products to display
     * @returns {Array} Array of product data
     */
    get productList() {
        if (!this.searchResults?.productsPage?.products) {
            console.log('No product data:', {
                hasSearchResults: !!this.searchResults,
                hasProductsPage: !!this.searchResults?.productsPage,
                hasProducts: !!this.searchResults?.productsPage?.products,
                searchResults: this.searchResults
            });
            return [];
        }
        const products = this.searchResults.productsPage.products.map(product =>
            this.getDisplayDataForProduct(product)
        );
        console.log('Product list:', products);
        return products;
    }

    /**
     * Checks if there's an error
     * @returns {boolean} True if error exists
     */
    get hasError() {
        return !!this.error;
    }

    /**
     * Gets the error message to display
     * @returns {string} Error message
     */
    get errorMessage() {
        if (!this.error) return 'Unknown error';

        if (typeof this.error === 'string') {
            return this.error;
        }

        // Handle Apex error format
        if (this.error.body && this.error.body.message) {
            return this.error.body.message;
        }

        if (this.error.message) {
            return this.error.message;
        }

        return JSON.stringify(this.error);
    }

    /**
     * Gets the configuration object for each product card
     * @returns {Object} Configuration object
     */
    get cardConfiguration() {
        return {
            layout: this.layout,
            showProductImage: this.showProductImage,
            showCallToActionButton: this.showCallToActionButton,
            showQuantitySelector: this.showQuantitySelector,
            addToCartButtonText: this.addToCartButtonText,
            viewOptionsButtonText: this.viewOptionsButtonText,
            quantitySelectorLabelText: this.quantitySelectorLabelText,
            addToCartDisabled: false,
            priceConfiguration: {
                showNegotiatedPrice: this.showNegotiatedPrice,
                showListingPrice: this.showListingPrice
            },
            fieldConfiguration: {}
        };
    }

    /**
     * Checks if products are loading
     * @returns {boolean} True if loading
     */
    get isLoading() {
        return this.isLoadingProducts;
    }

    /**
     * Checks if there are no products
     * @returns {boolean} True if no products
     */
    get hasNoProducts() {
        const noProducts = !this.isLoading && !this.hasError && this.productList.length === 0;
        if (noProducts) {
            console.log('No products state:', {
                isLoading: this.isLoading,
                hasError: this.hasError,
                productListLength: this.productList.length,
                searchResults: this.searchResults
            });
        }
        return noProducts;
    }

    /**
     * Gets the CSS class for the product grid container
     * @returns {string} CSS class
     */
    get gridClass() {
        return this.layout === 'grid' ? 'product-grid' : 'product-list';
    }

    /**
     * Formats product data for the product card component
     * @param {Object} product Raw product data from API
     * @returns {Object} Formatted product data
     */
    getDisplayDataForProduct(product) {
        // Build display fields array with Name, SKU, and Variation
        let fields = [];

        // Add Product Name field
        const productName = product.name || product.fields?.Name?.value;
        if (productName) {
            fields.push({
                name: 'Name',
                value: productName,
                displayData: {
                    value: productName,
                    name: 'Name',
                    tabStoppable: true
                }
            });
        }

        // Add SKU field - check multiple possible locations
        let sku = product.fields?.StockKeepingUnit?.value ||
                    product.fields?.ProductCode?.value ||
                    product.sku ||
                    product.productCode ||
                    product.stockKeepingUnit;
        if (this.restrictToParents && product.fields?.ProductCode?.value) {
            // If restricted to parent, try to use overall product SKU.
            sku = product.fields.ProductCode.value;
        }
        if (sku) {
            fields.push({
                name: 'SKU',
                value: sku,
                displayData: {
                    value: sku,
                    name: 'SKU',
                    tabStoppable: false
                }
            });
        }

        // Add Variation attributes from variationAttributeSet, unless restricting to parents only.
        if (!this.restrictToParents && product.variationAttributeSet?.attributes && Array.isArray(product.variationAttributeSet.attributes)) {
            product.variationAttributeSet.attributes.forEach(attr => {
                if (attr.value) {
                    const attrName = attr.label || attr.apiName || 'Variation';
                    const displayValue = `${attrName}: ${attr.value}`;
                    fields.push({
                        name: attrName,
                        value: displayValue,
                        displayData: {
                            value: displayValue,
                            name: attrName,
                            tabStoppable: false
                        }
                    });
                }
            });
        }

        // Also check for variationAttributes (alternate structure)
        if (product.variationAttributes && Array.isArray(product.variationAttributes)) {
            product.variationAttributes.forEach(attr => {
                if (attr.selectedValue) {
                    const attrName = attr.name || 'Variation';
                    const displayValue = `${attrName}: ${attr.selectedValue}`;
                    fields.push({
                        name: attrName,
                        value: displayValue,
                        displayData: {
                            value: displayValue,
                            name: attrName,
                            tabStoppable: false
                        }
                    });
                }
            });
        }

        // Get the correct prices based on pricebook selection
        const selectedPrices = this.selectPriceForPricebook(product);

        return {
            id: product.id,
            name: productName,
            fields: fields,
            image: {
                url: product.defaultImage?.url || '',
                alternateText: product.defaultImage?.alternateText || productName
            },
            prices: selectedPrices
        };
    }

    /**
     * Selects the correct price for the product based on currentPricebookId
     * @param {Object} product Raw product data from ConnectApi
     * @returns {Object} Price object with negotiatedPrice, listingPrice, and currencyIsoCode
     */
    selectPriceForPricebook(product) {
        console.log('Selecting price for product:', {
            productId: product.id,
            productName: product.name,
            currentPricebookId: this.currentPricebookId,
            productPrices: product.prices,
            hasPricebookEntries: !!this.pricebookEntries
        });

        // Default price structure
        let selectedPrice = {
            negotiatedPrice: null,
            listingPrice: null,
            currencyIsoCode: 'USD'
        };

        // If no prices available, return default
        if (!product.prices) {
            console.log('No prices available for product');
            return selectedPrice;
        }

        // Get pricebook entries for this product from our SOQL query results
        const productPricebookEntries = this.pricebookEntries?.[product.id];

        // If currentPricebookId is specified and we have pricebook entries, find matching price
        if (this.currentPricebookId && productPricebookEntries && productPricebookEntries.length > 0) {
            console.log('Looking for pricebook entry:', this.currentPricebookId);
            console.log('Available pricebook entries for product:', productPricebookEntries);

            // Find the pricebook entry that matches currentPricebookId
            const matchingEntry = productPricebookEntries.find(
                entry => entry.pricebookId === this.currentPricebookId
            );

            if (matchingEntry) {
                console.log('Found matching pricebook entry:', matchingEntry);
                selectedPrice.negotiatedPrice = matchingEntry.unitPrice;
                selectedPrice.listingPrice = matchingEntry.unitPrice; // Use same price for both
                // Use currency from product data since pricebook entries don't have currency field
                selectedPrice.currencyIsoCode = product.prices.currencyIsoCode || product.currencyIsoCode || 'USD';
                return selectedPrice;
            } else {
                console.log('No matching pricebook entry found for:', this.currentPricebookId);
            }
        } else if (this.currentPricebookId) {
            console.log('No pricebook entries available for product:', product.id);
        }

        // Fallback: use the default prices from the product
        selectedPrice.negotiatedPrice = product.prices.unitPrice || product.prices.negotiatedPrice;
        selectedPrice.listingPrice = product.prices.listPrice || product.prices.listingPrice;
        selectedPrice.currencyIsoCode = product.prices.currencyIsoCode || product.currencyIsoCode || 'USD';

        console.log('Selected price (fallback):', selectedPrice);
        return selectedPrice;
    }

    /**
     * Handle product card click to navigate to product detail page
     */
    /**
 * Handle product card click to navigate to product detail page
 */

handleShowProduct(event) {
    event.preventDefault();
    event.stopPropagation();

    const productId = event.detail?.productId;
    const productName = event.detail?.productName;

    if (!productId) {
        console.error('No product ID provided in showproduct event');
        return;
    }

    // Construct URL as: product/{productName}/{productId}
    // If no productName, use a slug version of the product name or just the ID
    const urlSlug = productName
        ? productName.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '')
        : 'product';

    const productUrl = `/product/${urlSlug}/${productId}`;

    console.log('Navigating to product:', productUrl);

    // Navigate to product detail page
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: productUrl
        }
    });
}

    /**
     * Handle add to cart event from product card
     */
    handleAddToCart(event) {
        console.log('Add to cart:', event.detail);

        // Bubble up the event for parent components to handle
        this.dispatchEvent(new CustomEvent('addproducttocart', {
            detail: event.detail,
            bubbles: true,
            composed: true
        }));
    }

    // ===== PAGINATION METHODS =====

    /**
     * Navigate to previous page
     */
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.fetchProducts();
            this.scrollToTop();
        }
    }

    /**
     * Navigate to next page
     */
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.fetchProducts();
            this.scrollToTop();
        }
    }

    /**
     * Navigate to first page
     */
    handleFirstPage() {
        if (this.currentPage !== 1) {
            this.currentPage = 1;
            this.fetchProducts();
            this.scrollToTop();
        }
    }

    /**
     * Navigate to last page
     */
    handleLastPage() {
        if (this.currentPage !== this.totalPages) {
            this.currentPage = this.totalPages;
            this.fetchProducts();
            this.scrollToTop();
        }
    }

    /**
     * Check if previous page button should be disabled
     */
    get isPreviousDisabled() {
        return this.currentPage <= 1 || this.isLoading;
    }

    /**
     * Check if next page button should be disabled
     */
    get isNextDisabled() {
        return this.currentPage >= this.totalPages || this.isLoading;
    }

    /**
     * Get pagination display text
     */
    get paginationText() {
        const start = ((this.currentPage - 1) * this.productsPerPage) + 1;
        const end = Math.min(this.currentPage * this.productsPerPage, this.totalProducts);
        return `${start}-${end} of ${this.totalProducts}`;
    }

    /**
     * Check if pagination should be shown
     */
    get showPagination() {
        return this.totalPages > 1 && !this.isLoading && !this.hasError;
    }

    /**
     * Generate page numbers with ellipsis for pagination
     * Shows first 3 pages, ellipsis, and last page
     */
    get pageNumbers() {
        const pages = [];
        const current = this.currentPage;
        const total = this.totalPages;

        if (total <= 4) {
            // Show all pages if 4 or fewer
            for (let i = 1; i <= total; i++) {
                const isCurrent = i === current;
                pages.push({
                    number: i,
                    label: String(i),
                    isEllipsis: false,
                    isCurrent: isCurrent,
                    className: isCurrent ? 'pagination-number active' : 'pagination-number',
                    key: `page-${i}`
                });
            }
        } else {
            // Show first 3 pages
            for (let i = 1; i <= 3; i++) {
                const isCurrent = i === current;
                pages.push({
                    number: i,
                    label: String(i),
                    isEllipsis: false,
                    isCurrent: isCurrent,
                    className: isCurrent ? 'pagination-number active' : 'pagination-number',
                    key: `page-${i}`
                });
            }

            // Add ellipsis
            pages.push({
                number: null,
                label: '...',
                isEllipsis: true,
                isCurrent: false,
                className: 'pagination-ellipsis',
                key: 'ellipsis'
            });

            // Add last page
            const lastIsCurrent = total === current;
            pages.push({
                number: total,
                label: String(total),
                isEllipsis: false,
                isCurrent: lastIsCurrent,
                className: lastIsCurrent ? 'pagination-number active' : 'pagination-number',
                key: `page-${total}`
            });
        }

        return pages;
    }

    /**
     * Handle clicking on a specific page number
     */
    handlePageClick(event) {
        const pageNumber = parseInt(event.target.dataset.page, 10);
        if (pageNumber && pageNumber !== this.currentPage) {
            this.currentPage = pageNumber;
            this.fetchProducts();
            this.scrollToTop();
        }
    }

    /**
     * Scroll to top of grid
     */
    scrollToTop() {
        const gridElement = this.template.querySelector('.grid-container');
        if (gridElement) {
            gridElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    // ===== SORT METHODS =====

    /**
     * Handle sort field change
     */
    handleSortChange(event) {
        const selectedValue = event.detail.value;
        console.log('Sort changed:', selectedValue);

        // Parse sortField and sortDirection from value (format: "field_direction")
        const [field, direction] = selectedValue.split('_');
        this.sortField = field;
        this.sortDirection = direction;

        // Reset to first page when sorting changes
        this.currentPage = 1;
        this.fetchProducts();
    }

    /**
     * Get current sort value for combobox
     */
    get currentSortValue() {
        return `${this.sortField}_${this.sortDirection}`;
    }

    /**
     * Get sort options for combobox
     */
    get sortOptions() {
        return [
            { label: 'Name (A-Z)', value: 'Name_ASC' },
            { label: 'Name (Z-A)', value: 'Name_DESC' },
            { label: 'Price (Low to High)', value: 'UnitPrice_ASC' },
            { label: 'Price (High to Low)', value: 'UnitPrice_DESC' },
            { label: 'Newest First', value: 'CreatedDate_DESC' },
            { label: 'Oldest First', value: 'CreatedDate_ASC' }
        ];
    }

    /**
     * Check if sort controls should be shown
     */
    get showSortControls() {
        return !this.isLoading && !this.hasError && this.productList.length > 0;
    }

    // ===== FILTER METHODS =====

    /**
     * Handle native Salesforce filter events (from faceted filter components)
     */
    handleNativeFilterChange(event) {
        console.log('Native filter event received:', event);

        if (event && event.detail) {
            // Salesforce native filter events have a specific structure
            // Extract refinements from the event
            const refinements = event.detail.refinements || event.detail.filters || event.detail;
            console.log('Processing refinements:', refinements);

            this.activeFilters = { ...refinements };
            this.currentPage = 1;
            this.fetchProducts();
        }
    }

    /**
     * Handle filter changes from external filter components
     * This method can be called via an event or directly
     */
    handleFilterChange(event) {
        const filters = event.detail || {};
        console.log('Filters changed:', filters);

        this.activeFilters = { ...filters };

        // Reset to first page when filters change
        this.currentPage = 1;
        this.fetchProducts();
    }

    /**
     * Clear all active filters
     */
    handleClearFilters() {
        this.activeFilters = {};
        this.currentPage = 1;
        this.fetchProducts();
    }

    /**
     * Handle filter value change from customResultsFilter component
     * Event format: { category, filterId, value, checked }
     */
    handleCustomFilterChange(event) {
        console.log('customCategoryProductGrid: Received filterchange event', event.detail);

        const { category, filterId, value, checked } = event.detail;

        // Only process events for this component's category
        if (this.categoryName && category && category !== this.categoryName) {
            console.log(`customCategoryProductGrid: Ignoring filter event for category "${category}" (this component is for "${this.categoryName}")`);
            return;
        }

        console.log('customCategoryProductGrid: Processing filter change for matching category');

        // Initialize filter array if needed
        if (!this.currentFilters[filterId]) {
            this.currentFilters[filterId] = [];
        }

        // Update filter values
        if (checked) {
            // Add value if not already present
            if (!this.currentFilters[filterId].includes(value)) {
                this.currentFilters[filterId].push(value);
            }
        } else {
            // Remove value
            this.currentFilters[filterId] = this.currentFilters[filterId].filter(v => v !== value);

            // Remove filter key if empty
            if (this.currentFilters[filterId].length === 0) {
                delete this.currentFilters[filterId];
            }
        }

        console.log('customCategoryProductGrid: Current filters:', this.currentFilters);

        // Save filters to sessionStorage to persist across re-initializations
        this.saveFiltersToSession();

        // Reset to page 1 when filters change
        this.currentPage = 1;

        // Reload products with updated filters
        this.fetchProducts();
    }

    /**
     * Handle clear all filters from customResultsFilter component
     */
    handleClearAllFilters(event) {
        console.log('customCategoryProductGrid: Clearing all custom filters');

        const category = event?.detail?.category;

        // Only process events for this component's category
        if (this.categoryName && category && category !== this.categoryName) {
            console.log(`customCategoryProductGrid: Ignoring clear filters event for category "${category}" (this component is for "${this.categoryName}")`);
            return;
        }

        // Clear all custom filters
        this.currentFilters = {};
        this.clearFiltersFromSession();
        this.currentPage = 1;
        this.fetchProducts();
    }

    /**
     * Build refinements JSON for CategoryProductController from currentFilters
     * Converts our filter format to the format expected by the Apex controller
     * NOTE: Excludes 'endUser' filter because lookup fields cannot be used in Commerce Search refinements
     */
    buildRefinementsFromFilters() {
        const refinements = [];

        for (const [filterId, values] of Object.entries(this.currentFilters)) {
            // Skip endUser filter - it's a lookup field and cannot be used in Commerce Search
            // We'll handle End User filtering via direct SOQL query instead
            if (filterId === 'endUser') {
                console.log('customCategoryProductGrid: Skipping endUser filter (lookup field not supported in refinements)');
                continue;
            }

            if (values && values.length > 0) {
                const refinement = {
                    nameOrId: this.mapFilterIdToFieldName(filterId),
                    attributeType: this.getAttributeType(filterId),
                    values: values
                };
                refinements.push(refinement);
            }
        }

        const json = refinements.length > 0 ? JSON.stringify(refinements) : null;
        console.log('customCategoryProductGrid: Built refinementsJSON from filters:', json);
        return json;
    }

    /**
     * Map filter IDs to actual Salesforce field API names
     * TODO: Update these field names to match your actual Salesforce schema
     */
    mapFilterIdToFieldName(filterId) {
        const fieldMapping = {
            'productCode': 'ProductCode',      // Standard field
            'shape': 'Shape__c',               // TODO: Replace with actual Shape field API name
            'rushReady': 'Rush_Ready__c',      // TODO: Replace with actual Rush Ready field API name
            'endUser': 'End_User__c'           // TODO: Replace with actual End User field API name
        };

        return fieldMapping[filterId] || filterId;
    }

    /**
     * Get attribute type for a field (Standard, Custom, or ProductAttribute)
     */
    getAttributeType(filterId) {
        const typeMapping = {
            'productCode': 'Standard',          // Standard Salesforce field
            'shape': 'Custom',                  // Custom field (picklist)
            'rushReady': 'ProductAttribute',    // Boolean field - use ProductAttribute
            'endUser': 'Custom'                 // Custom field (lookup)
        };

        return typeMapping[filterId] || 'Custom';
    }

    /**
     * Save current filters to sessionStorage to persist across component re-initializations
     */
    saveFiltersToSession() {
        if (!this.resolvedCategoryId) return;

        const storageKey = `customFilters_${this.resolvedCategoryId}`;
        try {
            sessionStorage.setItem(storageKey, JSON.stringify(this.currentFilters));
            console.log('customCategoryProductGrid: Saved filters to session:', storageKey, this.currentFilters);
        } catch (e) {
            console.error('customCategoryProductGrid: Error saving filters to session:', e);
        }
    }

    /**
     * Load filters from sessionStorage
     */
    loadFiltersFromSession() {
        if (!this.resolvedCategoryId) return;

        const storageKey = `customFilters_${this.resolvedCategoryId}`;
        try {
            const savedFilters = sessionStorage.getItem(storageKey);
            if (savedFilters) {
                this.currentFilters = JSON.parse(savedFilters);
                console.log('customCategoryProductGrid: Loaded filters from session:', storageKey, this.currentFilters);
            }
        } catch (e) {
            console.error('customCategoryProductGrid: Error loading filters from session:', e);
            this.currentFilters = {};
        }
    }

    /**
     * Clear filters from sessionStorage
     */
    clearFiltersFromSession() {
        if (!this.resolvedCategoryId) return;

        const storageKey = `customFilters_${this.resolvedCategoryId}`;
        try {
            sessionStorage.removeItem(storageKey);
            console.log('customCategoryProductGrid: Cleared filters from session:', storageKey);
        } catch (e) {
            console.error('customCategoryProductGrid: Error clearing filters from session:', e);
        }
    }

    /**
     * Check if any filters are active
     */
    get hasActiveFilters() {
        return Object.keys(this.activeFilters).length > 0;
    }
}