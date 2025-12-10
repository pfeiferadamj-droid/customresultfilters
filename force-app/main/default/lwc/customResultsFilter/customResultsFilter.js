import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getFilterData from '@salesforce/apex/CustomFilterController.getFilterData';

/**
 * Custom Results Filter Component
 * Dynamically displays filters based on the category from the URL
 */
export default class CustomResultsFilter extends LightningElement {
    @api recordId;

    // Current category resolved from URL
    currentCategory;

    // Filter data from Apex
    filterData;
    error;
    isLoading = true;

    // Wire to get current page reference (URL parameters)
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            // Extract category from URL parameter
            this.currentCategory = pageRef.state?.category || pageRef.attributes?.category;
            this.loadFilterData();
        }
    }

    /**
     * Load filter data based on current category
     */
    loadFilterData() {
        if (!this.currentCategory) {
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        getFilterData({ category: this.currentCategory })
            .then(result => {
                this.filterData = result;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.filterData = undefined;
                this.isLoading = false;
                console.error('Error loading filter data:', error);
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

        // Dispatch event to parent/search results component
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
        // Dispatch event to clear all filters
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
