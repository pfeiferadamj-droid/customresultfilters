import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getProductGridConfig from '@salesforce/apex/ProductGridConfigController.getProductGridConfig';

/**
 * Automated Product Grid Controller
 * Automatically configures the customCategoryProductGrid based on user profile and category
 * Detects category from URL automatically
 */
export default class AutomatedProductGrid extends LightningElement {
    /**
     * Category ID to display products from
     * Optional - will be auto-detected from URL if not provided
     */
    @api categoryId;

    /**
     * Optional: Override any configuration settings
     */
    @api addToCartButtonText = 'Add to Cart';
    @api viewOptionsButtonText = 'View Options';
    @api quantitySelectorLabelText = 'Quantity';

    // Configuration from Apex
    config;
    error;
    isLoading = true;

    // Resolved category ID (from URL or @api)
    resolvedCategoryId;

    /**
     * Wire to get current page reference (URL)
     * Auto-detect category ID from URL if not provided via @api
     */
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            // If categoryId is explicitly provided, use it
            if (this.categoryId) {
                this.resolvedCategoryId = this.categoryId;
            } else {
                // Otherwise, extract from URL
                this.extractCategoryIdFromUrl(pageRef);
            }
        }
    }

    /**
     * Extract category ID from page reference
     * Supports Experience Cloud URL format: /category/slug/categoryId
     */
    extractCategoryIdFromUrl(pageRef) {
        // Method 1: Parse URL path for Experience Cloud sites
        // URL format: /category/quick-turn/0ZGbb000000F5llGAC or /category/my-products/0ZGbb000000FFOXGA4
        const url = window.location.href;
        const categoryMatch = url.match(/\/category\/([^\/]+)(?:\/([a-zA-Z0-9]{15,18}))?/);

        if (categoryMatch && categoryMatch[2]) {
            this.resolvedCategoryId = categoryMatch[2];
            console.log('automatedProductGrid: Detected category ID from URL:', this.resolvedCategoryId);
            return;
        }

        // Method 2: Check query parameters
        if (pageRef.state?.categoryId) {
            this.resolvedCategoryId = pageRef.state.categoryId;
            console.log('automatedProductGrid: Detected category ID from query param:', this.resolvedCategoryId);
            return;
        }

        // Method 3: Check for recordId (direct category record page)
        if (pageRef.attributes?.recordId) {
            this.resolvedCategoryId = pageRef.attributes.recordId;
            console.log('automatedProductGrid: Detected category ID from recordId:', this.resolvedCategoryId);
            return;
        }

        console.warn('automatedProductGrid: Could not detect category ID from URL');
    }

    /**
     * Wire to get configuration from Apex based on resolved categoryId
     */
    @wire(getProductGridConfig, { categoryId: '$resolvedCategoryId' })
    wiredConfig({ error, data }) {
        if (data) {
            this.config = data;
            this.error = undefined;
            this.isLoading = false;
            console.log('automatedProductGrid: Loaded configuration:', data);
        } else if (error) {
            this.error = error;
            this.config = undefined;
            this.isLoading = false;
            console.error('automatedProductGrid: Error loading configuration:', error);
        }
    }

    /**
     * Check if configuration is loaded
     */
    get hasConfig() {
        return this.config != null;
    }

    /**
     * Get webstore ID from config
     */
    get webstoreId() {
        return this.config?.webstoreId;
    }

    /**
     * Get category ID to pass to child component
     */
    get finalCategoryId() {
        return this.config?.categoryId || this.resolvedCategoryId;
    }

    /**
     * Get category name from config
     */
    get categoryName() {
        return this.config?.categoryName;
    }

    /**
     * Get layout from config
     */
    get layout() {
        return this.config?.layout || 'grid';
    }

    /**
     * Get products per page from config
     */
    get productsPerPage() {
        return this.config?.productsPerPage || 24;
    }

    /**
     * Get show product image from config
     */
    get showProductImage() {
        return this.config?.showProductImage !== undefined ? this.config.showProductImage : true;
    }

    /**
     * Get show call to action button from config
     */
    get showCallToActionButton() {
        return this.config?.showCallToActionButton !== undefined ? this.config.showCallToActionButton : false;
    }

    /**
     * Get show quantity selector from config
     */
    get showQuantitySelector() {
        return this.config?.showQuantitySelector !== undefined ? this.config.showQuantitySelector : false;
    }

    /**
     * Get show negotiated price from config
     */
    get showNegotiatedPrice() {
        return this.config?.showNegotiatedPrice !== undefined ? this.config.showNegotiatedPrice : true;
    }

    /**
     * Get show listing price from config
     */
    get showListingPrice() {
        return this.config?.showListingPrice !== undefined ? this.config.showListingPrice : true;
    }

    /**
     * Get restrict to parents from config
     */
    get restrictToParents() {
        return this.config?.restrictToParents !== undefined ? this.config.restrictToParents : false;
    }

    /**
     * Get current pricebook ID from config
     */
    get currentPricebookId() {
        return this.config?.currentPricebookId;
    }

    /**
     * Get special pricebook IDs from config
     */
    get specialPricebookIds() {
        return this.config?.specialPricebookIds;
    }
}
