import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getCategoryProducts from '@salesforce/apex/CategoryProductController.getCategoryProducts';

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

    // Store previous URL state to detect changes
    _previousSortRuleId = null;
    _previousRefinements = null;

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
    }

    disconnectedCallback() {
        window.removeEventListener('popstate', this.handleUrlChange);
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
            url: window.location.href
        });

        if (!this.webstoreId) {
            console.warn('Webstore ID not configured. Please set the webstoreId property in Experience Builder.');
            this.error = 'Webstore ID not configured';
        } else if (!this.resolvedCategoryId) {
            console.warn('Category ID not found in URL or navigation context.');
            this.error = 'Category ID not found';
        } else {
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
            // Get refinements from URL (double URL-encoded)
            const urlParams = new URLSearchParams(window.location.search);
            const refinementsParam = urlParams.get('refinements');
            let refinementsJSON = null;

            if (refinementsParam) {
                try {
                    // Decode double URL encoding
                    const decoded = decodeURIComponent(decodeURIComponent(refinementsParam));
                    refinementsJSON = decoded;
                    console.log('Decoded refinements:', decoded);
                } catch (e) {
                    console.error('Error decoding refinements:', e);
                }
            }

            if (this.restrictToParents) {
                // 2025-12-16: when parents-only is specified, add a refinement to achieve this by custom field value.
                let refinementsArr = JSON.parse(refinementsJSON ?? '[]');
                refinementsArr.push({
                    attributeType: 'Custom',
                    nameOrId: FIELD_ISPARENT.fieldApiName,
                    values: [ PARENT_VALUE ],
                });
                refinementsJSON = JSON.stringify(refinementsArr);
            }

            console.log('Fetching products with params:', {
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
     * Check if any filters are active
     */
    get hasActiveFilters() {
        return Object.keys(this.activeFilters).length > 0;
    }
}