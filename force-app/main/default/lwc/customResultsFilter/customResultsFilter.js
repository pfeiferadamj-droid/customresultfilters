import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import FILTER_CHANGE_CHANNEL from '@salesforce/messageChannel/FilterChangeChannel__c';
import getFilterData from '@salesforce/apex/CustomFilterController.getFilterData';

/**
 * Custom Results Filter Component
 * Dynamically displays filters based on the category from the URL
 */
export default class CustomResultsFilter extends LightningElement {
    @api recordId;
    @api categoryOverride;

    // Current category resolved from URL
    currentCategory;
    categoryId;
    previousCategory;  // Track previous category to detect changes

    // Filter data from Apex
    filterData;
    error;
    isLoading = true;

    // Lightning Message Service context
    @wire(MessageContext)
    messageContext;

    // Category slug to display name mapping
    categoryMapping = {
        'quick-turn': 'Quick Turn',
        'my-products': 'My Products'
    };

    // Wire to get current page reference (URL parameters)
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            // Check if category is manually overridden
            if (this.categoryOverride) {
                this.currentCategory = this.categoryOverride;
            } else {
                // Try multiple methods to extract category
                this.extractCategoryFromPageRef(pageRef);
            }

            // Only reload filter data if category actually changed
            if (this.currentCategory && this.currentCategory !== this.previousCategory) {
                console.log('Category changed from', this.previousCategory, 'to', this.currentCategory);
                this.previousCategory = this.currentCategory;
                this.loadFilterData();
            }
        }
    }

    /**
     * Extract category from page reference
     * Supports both query parameters and path-based URLs
     */
    extractCategoryFromPageRef(pageRef) {
        // Method 1: Check query parameters (legacy support)
        if (pageRef.state?.category) {
            this.currentCategory = pageRef.state.category;
            return;
        }

        // Method 2: Parse URL path for Experience Cloud sites
        // URL format: /category/quick-turn/0ZGbb000000F5llGAC
        if (pageRef.attributes?.name || pageRef.type) {
            const url = window.location.href;
            const categoryMatch = url.match(/\/category\/([^\/]+)(?:\/([a-zA-Z0-9]{15,18}))?/);

            if (categoryMatch) {
                const categorySlug = categoryMatch[1]; // e.g., "quick-turn"
                this.categoryId = categoryMatch[2]; // e.g., "0ZGbb000000F5llGAC"

                // Map slug to display name
                this.currentCategory = this.categoryMapping[categorySlug] || this.formatCategoryName(categorySlug);
                return;
            }
        }

        // Method 3: Check for recordId in URL (direct category record page)
        if (pageRef.attributes?.recordId) {
            this.categoryId = pageRef.attributes.recordId;
        }

        // Method 4: Try to get from state attributes
        if (pageRef.attributes?.category) {
            this.currentCategory = pageRef.attributes.category;
        }
    }

    /**
     * Format category slug to display name
     * Converts "quick-turn" to "Quick Turn"
     */
    formatCategoryName(slug) {
        return slug
            .split('-')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    /**
     * Load filter data based on current category
     */
    loadFilterData() {
        if (!this.currentCategory) {
            console.warn('customResultsFilter: No current category, skipping filter load');
            this.isLoading = false;
            return;
        }

        console.log('customResultsFilter: Loading filter data for category:', this.currentCategory);
        this.isLoading = true;
        getFilterData({ category: this.currentCategory })
            .then(result => {
                console.log('customResultsFilter: Received filter data:', result);
                this.filterData = result;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.filterData = undefined;
                this.isLoading = false;
                console.error('customResultsFilter: Error loading filter data:', error);
            });
    }

    /**
     * Check if current category is Quick Turn
     */
    get isQuickTurn() {
        return this.currentCategory === 'Quick Turn';
    }

    /**
     * Check if current category is My Products
     */
    get isMyProducts() {
        return this.currentCategory === 'My Products';
    }

    /**
     * Get filters to display based on category
     */
    get displayFilters() {
        if (!this.filterData) return [];

        if (this.isQuickTurn) {
            return this.filterData.quickTurnFilters || [];
        } else if (this.isMyProducts) {
            return this.filterData.myProductsFilters || [];
        }

        return [];
    }

    /**
     * Handle filter value change
     */
    handleFilterChange(event) {
        const filterId = event.detail.filterId;
        const filterValue = event.detail.value;
        const checked = event.detail.checked;

        console.log('customResultsFilter: Received filterchange, re-dispatching with category:', {
            category: this.currentCategory,
            filterId: filterId,
            value: filterValue,
            checked: checked
        });

        // Publish to Lightning Message Service for sibling components
        const payload = {
            action: 'filterchange',
            category: this.currentCategory,
            filterId: filterId,
            value: filterValue,
            checked: checked
        };
        publish(this.messageContext, FILTER_CHANGE_CHANNEL, payload);
        console.log('customResultsFilter: Published LMS message:', payload);

        // Also dispatch event for parent/child component hierarchy
        this.dispatchEvent(new CustomEvent('filterchange', {
            bubbles: true,
            composed: true,
            detail: {
                category: this.currentCategory,
                filterId: filterId,
                value: filterValue,
                checked: checked
            }
        }));
    }

    /**
     * Handle clear all filters
     */
    handleClearAll() {
        // Publish to Lightning Message Service for sibling components
        const payload = {
            action: 'clearall',
            category: this.currentCategory
        };
        publish(this.messageContext, FILTER_CHANGE_CHANNEL, payload);
        console.log('customResultsFilter: Published LMS clearall message:', payload);

        // Also dispatch event for parent/child component hierarchy
        this.dispatchEvent(new CustomEvent('clearallfilters', {
            bubbles: true,
            composed: true,
            detail: {
                category: this.currentCategory
            }
        }));

        // Reload filter data to reset
        this.loadFilterData();
    }

    /**
     * Handle end user scope toggle (My Products only)
     */
    handleEndUserScopeToggle(event) {
        const showAllAccountEndUsers = event.detail.checked;

        // Reload filter data with new scope
        this.isLoading = true;
        getFilterData({
            category: this.currentCategory,
            includeAccountEndUsers: showAllAccountEndUsers
        })
            .then(result => {
                this.filterData = result;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                console.error('Error loading filter data:', error);
            });
    }
}
