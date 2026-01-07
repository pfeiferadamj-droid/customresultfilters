import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import FILTER_CHANGE_CHANNEL from '@salesforce/messageChannel/FilterChangeChannel__c';
import getFilterData from '@salesforce/apex/CustomFilterController.getFilterData';
import getAllDefaults from '@salesforce/apex/StoreDefaultsHelper.getAllDefaults';

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

    // My Products end user scope (show all account end users vs just user's products)
    showAllAccountEndUsers = false;

    // Store defaults from metadata
    storeDefaults;

    // Lightning Message Service context
    @wire(MessageContext)
    messageContext;

    // Wire to get store defaults from metadata
    @wire(getAllDefaults)
    wiredStoreDefaults({ error, data }) {
        if (data) {
            this.storeDefaults = data;
            console.log('customResultsFilter: Loaded store defaults from metadata:', data);
        } else if (error) {
            console.error('customResultsFilter: Error loading store defaults:', error);
        }
    }

    // Category slug to display name mapping (dynamically built from metadata)
    get categoryMapping() {
        if (!this.storeDefaults) {
            // Fallback to hardcoded values if metadata not loaded yet
            // IMPORTANT: These must match production metadata exactly!
            return {
                'essentials-by-caps-direct': 'Essentials by Caps Direct',
                'my-products': 'My Products',
                'detail': 'My Products'
            };
        }

        return {
            [this.storeDefaults.quickTurnUrlSlug]: this.storeDefaults.quickTurnCategoryName,
            [this.storeDefaults.myProductsUrlSlug]: this.storeDefaults.myProductsCategoryName,
            [this.storeDefaults.detailUrlSlug]: this.storeDefaults.myProductsCategoryName
        };
    }

    // Category ID to display name mapping (dynamically built from metadata)
    get categoryIdMapping() {
        if (!this.storeDefaults) {
            // Fallback to hardcoded values if metadata not loaded yet
            // IMPORTANT: These must match production metadata exactly!
            return {
                '0ZGPU0000001iob4AA': 'My Products',
                '0ZGPU0000001iqD4AQ': 'Essentials by Caps Direct'
            };
        }

        return {
            [this.storeDefaults.myProductsCategoryId]: this.storeDefaults.myProductsCategoryName,
            [this.storeDefaults.quickTurnCategoryId]: this.storeDefaults.quickTurnCategoryName
        };
    }

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
        // URL format: /category/quick-turn/0ZGbb000000F5llGAC or /category/detail/0ZGbb000000FFOXGA4
        if (pageRef.attributes?.name || pageRef.type) {
            const url = window.location.href;
            const categoryMatch = url.match(/\/category\/([^\/]+)(?:\/([a-zA-Z0-9]{15,18}))?/);

            if (categoryMatch) {
                const categorySlug = categoryMatch[1]; // e.g., "quick-turn" or "detail"
                this.categoryId = categoryMatch[2]; // e.g., "0ZGbb000000F5llGAC"

                // Try to map by category ID first (more reliable)
                if (this.categoryId && this.categoryIdMapping[this.categoryId]) {
                    this.currentCategory = this.categoryIdMapping[this.categoryId];
                    console.log('customResultsFilter: Mapped category ID', this.categoryId, 'to', this.currentCategory);
                    return;
                }

                // Fallback to slug-based mapping
                this.currentCategory = this.categoryMapping[categorySlug] || this.formatCategoryName(categorySlug);
                console.log('customResultsFilter: Mapped category slug', categorySlug, 'to', this.currentCategory);
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
        console.log('customResultsFilter: Category ID:', this.categoryId);
        this.isLoading = true;
        getFilterData({
            category: this.currentCategory,
            includeAccountEndUsers: this.showAllAccountEndUsers
        })
            .then(result => {
                console.log('customResultsFilter: Received filter data from Apex:', result);

                // Restore checked state from sessionStorage and get updated data
                const restoredData = this.restoreFilterCheckedState(result);

                console.log('customResultsFilter: Setting filterData with restored checked state');
                this.filterData = restoredData;
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
     * Restore filter checked state from sessionStorage
     * Updates the filter values' checked property based on saved state
     * Returns a new object to ensure LWC reactivity
     */
    restoreFilterCheckedState(filterData) {
        if (!filterData) {
            console.log('customResultsFilter: No filter data to restore');
            return filterData;
        }

        if (!this.categoryId) {
            console.log('customResultsFilter: No categoryId available, skipping restore. categoryId:', this.categoryId);
            return filterData;
        }

        // Get saved filters from sessionStorage
        const storageKey = `customFilters_${this.categoryId}`;
        try {
            const savedFilters = sessionStorage.getItem(storageKey);
            if (!savedFilters) {
                console.log('customResultsFilter: No saved filters found for category', this.categoryId);
                return filterData;
            }

            const currentFilters = JSON.parse(savedFilters);
            console.log('customResultsFilter: Restoring filter checked state from session:', currentFilters);
            console.log('customResultsFilter: Storage key:', storageKey);

            // Create a deep copy of filterData to ensure reactivity
            const updatedFilterData = JSON.parse(JSON.stringify(filterData));

            // Get the appropriate filter list based on category
            let filterList = null;
            if (this.isQuickTurn && updatedFilterData.quickTurnFilters) {
                filterList = updatedFilterData.quickTurnFilters;
                console.log('customResultsFilter: Restoring Quick Turn filters');
            } else if (this.isMyProducts && updatedFilterData.myProductsFilters) {
                filterList = updatedFilterData.myProductsFilters;
                console.log('customResultsFilter: Restoring My Products filters');
            }

            if (!filterList) {
                console.log('customResultsFilter: No filter list found in data');
                return filterData;
            }

            // Update checked state for each filter
            let totalChecked = 0;
            filterList.forEach(filter => {
                const savedFilterValues = currentFilters[filter.id];
                if (savedFilterValues && Array.isArray(savedFilterValues)) {
                    // Mark values as checked if they're in the saved filter state
                    filter.values.forEach(value => {
                        value.checked = savedFilterValues.includes(value.value);
                        if (value.checked) {
                            totalChecked++;
                            console.log(`customResultsFilter: ✓ Marked ${filter.label} - ${value.label} as checked`);
                        }
                    });
                }
            });

            console.log(`customResultsFilter: Restored ${totalChecked} checked filter values`);
            return updatedFilterData;

        } catch (e) {
            console.error('customResultsFilter: Error restoring filter checked state:', e);
            return filterData;
        }
    }

    /**
     * Check if current category is Quick Turn
     */
    get isQuickTurn() {
        if (this.storeDefaults) {
            return this.currentCategory === this.storeDefaults.quickTurnCategoryName;
        }
        // Fallback if metadata not loaded yet
        // IMPORTANT: Must match production metadata exactly!
        return this.currentCategory === 'Essentials by Caps Direct';
    }

    /**
     * Check if current category is My Products
     */
    get isMyProducts() {
        if (this.storeDefaults) {
            return this.currentCategory === this.storeDefaults.myProductsCategoryName;
        }
        // Fallback if metadata not loaded yet
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
     * Get account name for My Products category
     */
    get accountName() {
        return this.filterData?.accountName || 'your account';
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
        this.showAllAccountEndUsers = event.detail.checked;
        console.log('End user scope toggled to:', this.showAllAccountEndUsers);

        // Reload filter data with new scope
        this.loadFilterData();
    }
}
