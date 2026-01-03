import { LightningElement, api, wire } from 'lwc';
import getProductGridConfig from '@salesforce/apex/ProductGridConfigController.getProductGridConfig';

/**
 * Automated Product Grid Controller
 * Automatically configures the customCategoryProductGrid based on user profile and category
 */
export default class AutomatedProductGrid extends LightningElement {
    /**
     * Category ID to display products from
     * This is the only required input property
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

    /**
     * Wire to get configuration from Apex based on categoryId
     */
    @wire(getProductGridConfig, { categoryId: '$categoryId' })
    wiredConfig({ error, data }) {
        if (data) {
            this.config = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.config = undefined;
            this.isLoading = false;
            console.error('Error loading product grid configuration:', error);
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
     * Get category ID from config
     */
    get resolvedCategoryId() {
        return this.config?.categoryId || this.categoryId;
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
